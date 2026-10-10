import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type JsonRecord = Record<string, unknown>;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed." }, 405);
  const expectedSecret = Deno.env.get("DAWA_MOM_SYNC_SECRET") ?? "";
  const providedSecret = req.headers.get("x-dawa-sync-secret") ?? "";
  if (!expectedSecret || !timingSafeEqual(expectedSecret, providedSecret)) return jsonResponse({ error: "Unauthorized." }, 401);

  let body: JsonRecord;
  try {
    const parsed = await req.json();
    if (!isRecord(parsed)) throw new Error("Invalid JSON");
    body = parsed;
  } catch {
    return jsonResponse({ error: "Invalid JSON payload." }, 400);
  }

  const externalServiceId = text(body.external_service_id);
  const name = text(body.name);
  const sourceUpdatedAt = timestamp(body.source_updated_at);
  if (!externalServiceId || !name || !sourceUpdatedAt) return jsonResponse({ error: "external_service_id, name, and source_updated_at are required." }, 400);
  const price = Number(body.price ?? 0);
  if (!Number.isFinite(price) || price < 0) return jsonResponse({ error: "Invalid price." }, 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return jsonResponse({ error: "Sync receiver is not configured." }, 500);
  const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } });
  const { data, error } = await supabase.rpc("apply_service_catalog_sync", {
    p_external_service_id: externalServiceId,
    p_external_clinic_id: text(body.external_clinic_id),
    p_name: name,
    p_description: text(body.description),
    p_category: text(body.category),
    p_is_paid: body.is_paid === true,
    p_price: price,
    p_currency: text(body.currency) ?? "ZMW",
    p_is_active: body.is_active !== false,
    p_source_updated_at: sourceUpdatedAt,
  });
  if (error) return jsonResponse({ error: "Service catalog update failed." }, 500);
  return jsonResponse((data ?? { ok: true }) as JsonRecord);
});

function isRecord(value: unknown): value is JsonRecord { return typeof value === "object" && value !== null && !Array.isArray(value); }
function text(value: unknown): string | null { const result = typeof value === "string" ? value.trim() : ""; return result || null; }
function timestamp(value: unknown): string | null { const result = text(value); if (!result || Number.isNaN(Date.parse(result))) return null; return new Date(result).toISOString(); }
function timingSafeEqual(left: string, right: string): boolean { const a = new TextEncoder().encode(left); const b = new TextEncoder().encode(right); if (a.length !== b.length) return false; let result = 0; for (let i = 0; i < a.length; i++) result |= a[i] ^ b[i]; return result === 0; }
