import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

type JsonRecord = Record<string, unknown>;
const maxAgeSeconds = 5 * 60;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed." }, 405);
  const webhookId = req.headers.get("webhook-id");
  const timestamp = req.headers.get("webhook-timestamp");
  const signature = req.headers.get("webhook-signature");
  const secret = Deno.env.get("LIPILA_WEBHOOK_SECRET");
  if (!webhookId || !timestamp || !signature || !secret) {
    return json({ error: "Invalid webhook." }, 400);
  }

  const timestampNumber = Number(timestamp);
  if (
    !Number.isSafeInteger(timestampNumber) ||
    Math.abs(Math.floor(Date.now() / 1000) - timestampNumber) > maxAgeSeconds
  ) {
    return json(
      { error: "Webhook timestamp is outside the allowed window." },
      400,
    );
  }

  const rawBody = await req.text();
  if (
    !(await verifySignature(
      `${webhookId}.${timestamp}.${rawBody}`,
      signature,
      secret,
    ))
  ) {
    return json({ error: "Invalid webhook signature." }, 401);
  }

  let payload: JsonRecord;
  try {
    const parsed = JSON.parse(rawBody);
    if (!isRecord(parsed)) throw new Error("Invalid payload");
    payload = parsed;
  } catch {
    return json({ error: "Invalid JSON payload." }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "Webhook backend is not configured." }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const referenceId = text(payload.referenceId) ??
    text(data(payload)?.referenceId);
  const status = normalizeStatus(
    text(payload.status) ?? text(data(payload)?.status),
  );
  const amount = number(payload.amount) ?? number(data(payload)?.amount);
  const currency = text(payload.currency) ?? text(data(payload)?.currency);
  if (!referenceId || !status) {
    return json({ error: "Payment reference and status are required." }, 400);
  }

  const { data: payment, error: paymentError } = await supabase.from("payments")
    .select("*").eq("reference_id", referenceId).maybeSingle();
  if (paymentError) return json({ error: "Payment lookup failed." }, 500);
  if (!payment) return json({ error: "Unknown payment reference." }, 404);
  if (amount !== null && Number(payment.amount) !== amount) {
    return json({ error: "Payment amount does not match." }, 409);
  }
  if (currency !== null && payment.currency !== currency) {
    return json({ error: "Payment currency does not match." }, 409);
  }
  // The SQL transition records the event and applies the ledger + appointment
  // state in one transaction. This avoids a duplicate callback being accepted
  // after event insertion but before the appointment has been released.
  const { data: transition, error: transitionError } = await supabase.rpc(
    "apply_lipila_payment_status",
    {
      p_payment_id: payment.id,
      p_webhook_id: webhookId,
      p_event_type: text(payload.event) ?? "collection.status.changed",
      p_status: status,
      p_payload: payload,
      p_provider_identifier: providerIdentifier(payload) ??
        providerIdentifier(data(payload)),
    },
  );
  if (transitionError) {
    return json({ error: "Payment status could not be applied safely." }, 500);
  }
  return json(isRecord(transition) ? transition : { ok: true, status });
});

async function verifySignature(
  content: string,
  header: string,
  secret: string,
): Promise<boolean> {
  const secretBytes = secret.startsWith("whsec_") ? secret.slice(6) : secret;
  const keyBytes = Uint8Array.from(
    atob(secretBytes),
    (char) => char.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(content)),
  );
  const expected = `v1,${btoa(String.fromCharCode(...digest))}`;
  return header.split(" ").some((candidate) =>
    timingSafeEqual(candidate, expected)
  );
}
function timingSafeEqual(left: string, right: string): boolean {
  const a = new TextEncoder().encode(left);
  const b = new TextEncoder().encode(right);
  if (a.length !== b.length) return false;
  let result = 0;
  for (let index = 0; index < a.length; index++) result |= a[index] ^ b[index];
  return result === 0;
}
function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function data(value: JsonRecord): JsonRecord | null {
  return isRecord(value.data) ? value.data : null;
}
function text(value: unknown): string | null {
  const result = typeof value === "string" ? value.trim() : "";
  return result || null;
}
function number(value: unknown): number | null {
  const result = Number(value);
  return Number.isFinite(result) ? result : null;
}
function providerIdentifier(value: JsonRecord | null): string | null {
  if (!value) return null;
  return text(value.id) ?? text(value.transactionId) ?? text(value.externalId);
}
function normalizeStatus(value: string | null): string | null {
  if (!value) return null;
  const normalized = value.toLowerCase();
  if (["successful", "success", "completed"].includes(normalized)) {
    return "successful";
  }
  if (["failed", "failure"].includes(normalized)) return "failed";
  if (["cancelled", "canceled"].includes(normalized)) return "cancelled";
  if (["expired"].includes(normalized)) return "expired";
  if (["pending", "processing"].includes(normalized)) return "pending";
  return null;
}
function json(body: JsonRecord, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
