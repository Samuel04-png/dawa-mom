import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type JsonRecord = Record<string, unknown>;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed." }, 405);

  const authorization = req.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authorization || !supabaseUrl || !anonKey) {
    return jsonResponse({ error: "Authentication is required." }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) return jsonResponse({ error: "Invalid session." }, 401);

  let body: JsonRecord;
  try {
    const parsed = await req.json();
    if (!isRecord(parsed)) throw new Error("Invalid JSON");
    body = parsed;
  } catch {
    return jsonResponse({ error: "Invalid JSON body." }, 400);
  }

  const paymentId = text(body.payment_id);
  if (!paymentId) return jsonResponse({ error: "payment_id is required." }, 400);

  const { data: payment, error } = await userClient
    .from("payments")
    .select("id,status,amount,currency,reference_id,paid_at,failed_at,updated_at")
    .eq("id", paymentId)
    .maybeSingle();
  if (error) return jsonResponse({ error: "Payment status is unavailable." }, 500);
  if (!payment) return jsonResponse({ error: "Payment was not found." }, 404);

  return jsonResponse({ payment });
});

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function text(value: unknown): string | null {
  const result = typeof value === "string" ? value.trim() : "";
  return result || null;
}
