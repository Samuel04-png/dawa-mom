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

  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) return jsonResponse({ error: "Invalid session." }, 401);

  let body: JsonRecord;
  try {
    const parsed = await req.json();
    if (!isRecord(parsed)) throw new Error("Invalid JSON");
    body = parsed;
  } catch {
    return jsonResponse({ error: "Invalid JSON body." }, 400);
  }

  const appointmentId = uuid(body.appointment_id);
  const phoneNumber = text(body.phone_number);
  if (!appointmentId || !phoneNumber) {
    return jsonResponse({ error: "appointment_id and phone_number are required." }, 400);
  }

  const { data: payment, error } = await supabase.rpc("create_lipila_payment", {
    p_appointment_id: appointmentId,
    p_phone_number: phoneNumber,
  });
  if (error || !isRecord(payment)) {
    return jsonResponse({ error: safeDatabaseError(error?.code) }, errorStatus(error?.code));
  }

  const apiKey = Deno.env.get("LIPILA_API_KEY");
  const baseUrl = Deno.env.get("LIPILA_BASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!apiKey || !baseUrl || !serviceRoleKey) return jsonResponse({ error: "Payment provider is not configured." }, 503);
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const response = await fetch(`${baseUrl.replace(/\/$/, "")}/api/v1/collections/mobile-money`, {
    method: "POST",
    headers: {
      accept: "application/json",
      "Content-Type": "application/json",
      "x-api-key": apiKey,
    },
    body: JSON.stringify({
      referenceId: payment.reference_id,
      amount: payment.amount,
      currency: payment.currency,
      narration: `DawaMom appointment ${payment.appointment_id}`,
      accountNumber: payment.phone_number,
      referenceData: payment.external_service_id ?? payment.reference_id,
    }),
  });
  const providerBody = await response.json().catch(() => ({}));
  if (!response.ok) {
    await admin.from("payments").update({ status: "failed", failed_at: new Date().toISOString() }).eq("id", payment.id);
    const providerCode = providerErrorCode(providerBody);
    return jsonResponse({
      error: response.status >= 500
        ? "The payment provider is temporarily unavailable. Please try again."
        : "Lipila rejected the Mobile Money request. Check that the number is a registered Zambian Mobile Money number and try again.",
      code: "LIPILA_REQUEST_REJECTED",
      provider_code: providerCode,
      provider_message: providerErrorMessage(providerBody),
    }, response.status >= 500 ? 502 : 400);
  }

  await admin.from("payments").update({ status: "pending", provider_identifier: providerIdentifier(providerBody) }).eq("id", payment.id);
  return jsonResponse({
    payment_id: payment.id,
    reference_id: payment.reference_id,
    status: "pending",
    amount: payment.amount,
    currency: payment.currency,
  });
});

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function text(value: unknown): string | null {
  const result = typeof value === "string" ? value.trim() : "";
  return result || null;
}
function uuid(value: unknown): string | null {
  const result = text(value);
  return result && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(result) ? result : null;
}
function providerIdentifier(value: unknown): string | null {
  if (!isRecord(value)) return null;
  return text(value.id) ?? text(value.transactionId) ?? text(value.externalId);
}
function providerErrorCode(value: unknown): string | null {
  if (!isRecord(value)) return null;
  const candidate = text(value.code) ?? text(value.errorCode) ?? text(value.status);
  return candidate ? candidate.slice(0, 80) : null;
}
function providerErrorMessage(value: unknown): string | null {
  if (!isRecord(value)) return null;
  const candidate = text(value.message) ?? text(value.error) ?? text(value.detail);
  return candidate ? candidate.slice(0, 160) : null;
}
function errorStatus(code?: string): number {
  return code === "42501" ? 401 : code === "P0002" ? 404 : code === "23514" || code === "22023" ? 409 : 500;
}
function safeDatabaseError(code?: string): string {
  if (code === "42501") return "Authentication is required.";
  if (code === "P0002") return "Appointment was not found.";
  if (code === "23514" || code === "22023") return "This appointment cannot be paid.";
  return "Payment could not be started.";
}
