import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

// This receiver is intentionally server-to-server. Flutter never calls it and
// never receives the directional integration secret. Dawa Clinician must have
// authenticated the staff member and checked that they are authorised at the
// specified clinic before sending this callback.
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type JsonRecord = Record<string, unknown>;

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return response({ error: 'Method not allowed.' }, 405);
  }

  const expectedSecret = Deno.env.get('DAWA_MOM_SYNC_SECRET') ?? '';
  const suppliedSecret = request.headers.get('x-dawa-sync-secret') ?? '';
  if (!expectedSecret) {
    return response({ error: 'Voucher sync secret is not configured.' }, 500);
  }
  if (!timingSafeEqual(suppliedSecret, expectedSecret)) {
    return response({ error: 'Unauthorized.' }, 401);
  }

  let payload: JsonRecord;
  try {
    const parsed = await request.json();
    if (!isRecord(parsed)) throw new Error('Invalid payload.');
    payload = parsed;
  } catch {
    return response({ error: 'Invalid JSON payload.' }, 400);
  }

  if (text(payload.event_type) !== 'voucher.redeemed') {
    return response({ error: 'Unsupported voucher event.' }, 400);
  }
  const eventId = uuid(payload.event_id);
  const claimId = uuid(payload.claim_id);
  const claimReference = boundedText(payload.claim_reference, 80);
  const clinicId = boundedText(payload.clinic_id, 160);
  const clinicianId = boundedText(payload.clinician_id, 160);
  const externalServiceId = boundedText(payload.external_service_id, 160);
  if (!eventId || !claimId || !claimReference || !clinicId || !clinicianId || !externalServiceId) {
    return response({ error: 'Invalid voucher redemption event.' }, 400);
  }

  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceRoleKey) {
    return response({ error: 'Receiver environment is incomplete.' }, 500);
  }
  const supabase = createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await supabase.rpc('redeem_dawa_mom_reward_voucher', {
    p_event_id: eventId,
    p_claim_id: claimId,
    p_claim_reference: claimReference,
    p_clinic_id: clinicId,
    p_clinician_id: clinicianId,
    p_external_service_id: externalServiceId,
  });
  if (!error && isRecord(data)) return response(data);

  if (error?.code === 'P0002') {
    return response({ code: 'VOUCHER_NOT_FOUND', error: 'Voucher was not found.', retryable: false }, 404);
  }
  if (error?.code === '23514' || error?.code === '22023') {
    return response({ code: 'VOUCHER_NOT_ACTIVE', error: 'Voucher cannot be redeemed.', retryable: false }, 409);
  }
  console.error('[receive-dawa-clinician-voucher-redemption] Callback failed.');
  return response({ code: 'VOUCHER_REDEMPTION_FAILED', error: 'Voucher could not be redeemed right now.', retryable: true }, 500);
});

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function text(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const valueText = String(value).trim();
  return valueText || null;
}

function boundedText(value: unknown, maxLength: number): string | null {
  const valueText = text(value);
  return valueText && valueText.length <= maxLength ? valueText : null;
}

function uuid(value: unknown): string | null {
  const valueText = text(value);
  return valueText && uuidPattern.test(valueText) ? valueText.toLowerCase() : null;
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let index = 0; index < a.length; index += 1) {
    result |= a.charCodeAt(index) ^ b.charCodeAt(index);
  }
  return result === 0;
}
