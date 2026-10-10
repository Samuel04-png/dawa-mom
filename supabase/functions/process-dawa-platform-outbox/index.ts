import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import {
  createClient,
  type SupabaseClient,
} from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

/** Deliberately retryable forever so unconfigured risk-alert delivery never permanently drops an alert. */
const RISK_ALERT_ENDPOINT_NOT_CONFIGURED = 'RISK_ALERT_ENDPOINT_NOT_CONFIGURED';
const CARE_ITEM_ENDPOINT_NOT_CONFIGURED = 'CARE_ITEM_ENDPOINT_NOT_CONFIGURED';

type JsonRecord = Record<string, unknown>;
type SupabaseAdmin = SupabaseClient<any, 'public', any>;
type RiskAlertEventType = 'risk_alert.upsert' | 'risk_alert.archived';
type CareItemEventType = 'care_item.upsert' | 'care_item.archived';
type OutboxJob = {
  id: string;
  event_id: string;
  event_type:
    | 'patient.upsert'
    | 'patient.archived'
    | 'appointment.created'
    | 'appointment.cancelled'
    | RiskAlertEventType
    | CareItemEventType;
  aggregate_type: 'mother' | 'appointment' | 'risk_alert' | 'care_item';
  aggregate_id: string;
  payload: JsonRecord;
  attempt_count: number;
};

type DeliveryResult = {
  success: boolean;
  destinationId: string | null;
  errorCode: string | null;
  retryable: boolean;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return response({ error: 'Method not allowed.' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const syncSecret = Deno.env.get('DAWA_CLINICIAN_SYNC_SECRET');
  const patientUrl = Deno.env.get('DAWA_CLINICIAN_PATIENT_SYNC_URL');
  const appointmentUrl = Deno.env.get('DAWA_CLINICIAN_APPOINTMENT_URL');
  // Optional on purpose: patient and appointment delivery must keep working even
  // if the risk-alert endpoint has not been configured yet. A missing value only
  // holds back risk-alert jobs (see deliverRiskAlertJob).
  const riskAlertUrl = Deno.env.get('DAWA_CLINICIAN_RISK_ALERT_URL');
  // Care-plan sync is optional for the same rollout reason. Missing endpoint
  // configuration holds only care-item events; it never blocks appointments.
  const careItemUrl = Deno.env.get('DAWA_CLINICIAN_CARE_ITEM_URL');
  if (!supabaseUrl || !serviceRoleKey || !syncSecret || !patientUrl || !appointmentUrl) {
    return response({ error: 'Integration worker is not configured.' }, 500);
  }

  if (!isAuthorizedWorker(req, serviceRoleKey)) {
    return response({ error: 'Unauthorized.' }, 401);
  }

  let requestedLimit = 10;
  try {
    const body = await req.json();
    const parsed = Number(body?.limit);
    if (Number.isFinite(parsed)) requestedLimit = Math.round(parsed);
  } catch {
    // An empty body uses the safe default.
  }
  const limit = Math.max(1, Math.min(requestedLimit, 25));
  const workerId = `dawa-mom-${crypto.randomUUID()}`;
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data, error } = await supabase.rpc('claim_dawa_platform_outbox_events', {
    p_limit: limit,
    p_worker_id: workerId,
  });
  if (error) {
    console.error('[process-dawa-platform-outbox] Could not claim jobs.');
    return response({ error: 'Integration jobs could not be claimed.' }, 500);
  }

  const jobs = (data ?? []) as OutboxJob[];
  let completed = 0;
  let retrying = 0;
  let permanentlyFailed = 0;

  for (const job of jobs) {
    let result: DeliveryResult;
    try {
      result = await deliverJob(
        supabase,
        job,
        syncSecret,
        patientUrl,
        appointmentUrl,
        riskAlertUrl,
        careItemUrl,
      );
    } catch {
      result = {
        success: false,
        destinationId: null,
        errorCode: 'UPSTREAM_UNREACHABLE',
        retryable: true,
      };
    }

    // A missing risk-alert endpoint is a configuration gap rather than a data
    // problem, so the event stays queued instead of being permanently failed.
    const configurationGap = result.errorCode === RISK_ALERT_ENDPOINT_NOT_CONFIGURED ||
      result.errorCode === CARE_ITEM_ENDPOINT_NOT_CONFIGURED;
    const permanent = !result.success && !configurationGap &&
      (!result.retryable || job.attempt_count >= 8);
    const retryAt = result.success || permanent
      ? null
      : new Date(Date.now() + retryDelayMs(job.attempt_count)).toISOString();
    const { error: completeError } = await supabase.rpc(
      'complete_dawa_platform_outbox_event',
      {
        p_job_id: job.id,
        p_worker_id: workerId,
        p_success: result.success,
        p_destination_id: result.destinationId,
        p_error_code: result.errorCode,
        p_retry_at: retryAt,
        p_permanent: permanent,
      },
    );

    if (completeError) {
      console.error('[process-dawa-platform-outbox] Could not complete a claimed job.');
      retrying += 1;
      continue;
    }
    if (result.success) completed += 1;
    else if (permanent) permanentlyFailed += 1;
    else retrying += 1;
  }

  return response({
    claimed: jobs.length,
    completed,
    retrying,
    permanently_failed: permanentlyFailed,
  });
});

async function deliverJob(
  supabase: SupabaseAdmin,
  job: OutboxJob,
  syncSecret: string,
  patientUrl: string,
  appointmentUrl: string,
  riskAlertUrl: string | undefined,
  careItemUrl: string | undefined,
): Promise<DeliveryResult> {
  if (job.event_type === 'risk_alert.upsert' || job.event_type === 'risk_alert.archived') {
    return deliverRiskAlertJob(job, syncSecret, riskAlertUrl);
  }
  if (job.event_type === 'care_item.upsert' || job.event_type === 'care_item.archived') {
    return deliverCareItemJob(supabase, job, syncSecret, careItemUrl);
  }

  let endpoint = patientUrl;
  let body: JsonRecord;

  if (job.event_type === 'patient.upsert' || job.event_type === 'patient.archived') {
    body = {
      event_id: job.event_id,
      event_type: job.event_type,
      type: job.event_type === 'patient.archived' ? 'DELETE' : 'UPDATE',
      schema: 'public',
      table: 'mothers',
      record: job.payload,
    };
  } else {
    endpoint = appointmentUrl;
    const fresh = await loadAppointmentPayload(supabase, job);
    if (!fresh.ok) {
      return {
        success: false,
        destinationId: null,
        errorCode: fresh.errorCode,
        retryable: fresh.retryable,
      };
    }
    body = {
      event_id: job.event_id,
      event_type: job.event_type,
      record: fresh.payload,
    };
  }

  const upstream = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-dawa-sync-secret': syncSecret,
    },
    body: JSON.stringify(body),
  });

  let payload: JsonRecord = {};
  try {
    const parsed = await upstream.json();
    if (isRecord(parsed)) payload = parsed;
  } catch {
    // Status and a safe generic code are sufficient for retry decisions.
  }

  if (upstream.ok) {
    const destinationId = job.event_type === 'patient.upsert' ||
        job.event_type === 'patient.archived'
      ? optionalText(payload.patient_id)
      : optionalText(payload.external_appointment_id);
    if (job.event_type === 'patient.archived') {
      return {
        success: true,
        destinationId,
        errorCode: null,
        retryable: false,
      };
    }
    if (!destinationId) {
      return {
        success: false,
        destinationId: null,
        errorCode: 'MAPPING_MISSING',
        retryable: true,
      };
    }
    return { success: true, destinationId, errorCode: null, retryable: false };
  }

  const upstreamCode = optionalText(payload.code) ?? `HTTP_${upstream.status}`;
  const retryable = payload.retryable === true ||
    upstream.status === 408 || upstream.status === 429 || upstream.status >= 500 ||
    upstreamCode === 'PATIENT_NOT_SYNCED';
  return {
    success: false,
    destinationId: null,
    errorCode: upstreamCode.slice(0, 120),
    retryable,
  };
}

/**
 * Delivers risk-alert events with the same webhook-shaped contract the patient
 * receiver already accepts, so the destination follows one ingest convention.
 * The payload is read from the stored outbox row without extra database reads:
 * risk alerts are not mutated by clinician-side state, unlike appointments.
 */
async function deliverRiskAlertJob(
  job: OutboxJob,
  syncSecret: string,
  riskAlertUrl: string | undefined,
): Promise<DeliveryResult> {
  if (!riskAlertUrl) {
    return {
      success: false,
      destinationId: null,
      errorCode: RISK_ALERT_ENDPOINT_NOT_CONFIGURED,
      retryable: true,
    };
  }

  const upstream = await fetch(riskAlertUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-dawa-sync-secret': syncSecret,
    },
    body: JSON.stringify({
      event_id: job.event_id,
      event_type: job.event_type,
      type: job.event_type === 'risk_alert.archived' ? 'DELETE' : 'UPDATE',
      schema: 'public',
      table: 'clinician_risk_alerts',
      record: job.payload,
    }),
  });

  let payload: JsonRecord = {};
  try {
    const parsed = await upstream.json();
    if (isRecord(parsed)) payload = parsed;
  } catch {
    // Status and a safe generic code are sufficient for retry decisions.
  }

  if (upstream.ok) {
    const destinationId = optionalText(payload.alert_id);
    // A source DELETE is intentionally idempotent. The receiver returns a
    // successful `missing` action when this alert never reached Dawa Clinician,
    // so there is no destination id to write back. Treat that as delivered;
    // otherwise that valid archive event would be retried forever.
    if (job.event_type === 'risk_alert.archived') {
      return {
        success: true,
        destinationId,
        errorCode: null,
        retryable: false,
      };
    }
    if (!destinationId) {
      return {
        success: false,
        destinationId: null,
        errorCode: 'MAPPING_MISSING',
        retryable: true,
      };
    }
    return { success: true, destinationId, errorCode: null, retryable: false };
  }

  const upstreamCode = optionalText(payload.code) ?? `HTTP_${upstream.status}`;
  const retryable = payload.retryable === true ||
    upstream.status === 408 || upstream.status === 429 || upstream.status >= 500 ||
    upstreamCode === 'PATIENT_NOT_SYNCED';
  return {
    success: false,
    destinationId: null,
    errorCode: upstreamCode.slice(0, 120),
    retryable,
  };
}

/**
 * Care items use the same server-to-server shape as risk alerts. The payload is
 * freshly loaded to verify that patient mapping exists and to avoid delivering a
 * stale item after a clinician has changed it.
 */
async function deliverCareItemJob(
  supabase: SupabaseAdmin,
  job: OutboxJob,
  syncSecret: string,
  careItemUrl: string | undefined,
): Promise<DeliveryResult> {
  if (!careItemUrl) {
    return {
      success: false,
      destinationId: null,
      errorCode: CARE_ITEM_ENDPOINT_NOT_CONFIGURED,
      retryable: true,
    };
  }

  const fresh = await loadCareItemPayload(supabase, job);
  if (!fresh.ok) {
    return {
      success: false,
      destinationId: null,
      errorCode: fresh.errorCode,
      retryable: fresh.retryable,
    };
  }

  const upstream = await fetch(careItemUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-dawa-sync-secret': syncSecret,
    },
    body: JSON.stringify({
      event_id: job.event_id,
      event_type: job.event_type,
      type: job.event_type === 'care_item.archived' ? 'DELETE' : 'UPDATE',
      schema: 'public',
      table: 'care_plan_items',
      record: fresh.payload,
    }),
  });

  let payload: JsonRecord = {};
  try {
    const parsed = await upstream.json();
    if (isRecord(parsed)) payload = parsed;
  } catch {
    // A safe error code is enough for the retry policy below.
  }

  if (upstream.ok) {
    const destinationId = optionalText(payload.care_item_id);
    if (job.event_type === 'care_item.archived') {
      return { success: true, destinationId, errorCode: null, retryable: false };
    }
    if (!destinationId) {
      return {
        success: false,
        destinationId: null,
        errorCode: 'MAPPING_MISSING',
        retryable: true,
      };
    }
    return { success: true, destinationId, errorCode: null, retryable: false };
  }

  const upstreamCode = optionalText(payload.code) ?? `HTTP_${upstream.status}`;
  return {
    success: false,
    destinationId: null,
    errorCode: upstreamCode.slice(0, 120),
    retryable: payload.retryable === true || upstream.status === 408 ||
      upstream.status === 429 || upstream.status >= 500 ||
      upstreamCode === 'PATIENT_NOT_SYNCED' ||
      upstreamCode === 'APPOINTMENT_NOT_SYNCED',
  };
}

async function loadAppointmentPayload(
  supabase: SupabaseAdmin,
  job: OutboxJob,
): Promise<
  | { ok: true; payload: JsonRecord }
  | { ok: false; errorCode: string; retryable: boolean }
> {
  const { data: appointment, error } = await supabase
    .from('appointments')
    .select(
      'id,mother_id,clinician_id,clinic_id,appointment_date,start_time,end_time,appointment_type,reason,notes,status,payment_method,is_paid_snapshot,created_at,updated_at',
    )
    .eq('id', job.aggregate_id)
    .maybeSingle();
  if (error || !appointment) {
    return { ok: false, errorCode: 'SOURCE_APPOINTMENT_MISSING', retryable: false };
  }

  if (job.event_type === 'appointment.cancelled') {
    return {
      ok: true,
      payload: {
        source: 'dawa_mom',
        source_appointment_id: appointment.id,
        status: appointment.status,
        updated_at: appointment.updated_at,
      },
    };
  }

  const [{ data: mother }, { data: doctor }, { data: clinic }] = await Promise.all([
    supabase
      .from('mothers')
      .select('dawa_clinician_patient_id')
      .eq('id', appointment.mother_id)
      .maybeSingle(),
    supabase
      .from('doctors')
      .select('dawa_clinician_clinician_id')
      .eq('id', appointment.clinician_id)
      .maybeSingle(),
    supabase
      .from('clinics')
      .select('dawa_clinician_clinic_id')
      .eq('id', appointment.clinic_id)
      .maybeSingle(),
  ]);

  if (!mother?.dawa_clinician_patient_id) {
    return { ok: false, errorCode: 'PATIENT_NOT_SYNCED', retryable: true };
  }
  if (!doctor?.dawa_clinician_clinician_id || !clinic?.dawa_clinician_clinic_id) {
    return { ok: false, errorCode: 'DIRECTORY_MAPPING_MISSING', retryable: true };
  }

  return {
    ok: true,
    payload: {
      source: 'dawa_mom',
      source_appointment_id: appointment.id,
      source_mother_id: appointment.mother_id,
      dawa_clinician_patient_id: mother?.dawa_clinician_patient_id ?? null,
      dawa_clinician_clinician_id: doctor.dawa_clinician_clinician_id,
      dawa_clinician_clinic_id: clinic.dawa_clinician_clinic_id,
      appointment_date: appointment.appointment_date,
      start_time: appointment.start_time,
      end_time: appointment.end_time,
      appointment_type: appointment.appointment_type,
      reason: appointment.reason,
      notes: appointment.notes,
      status: appointment.status,
      payment_method: appointment.payment_method,
      payment_status: appointment.payment_method === 'cash'
        ? 'pay_at_clinic'
        : appointment.is_paid_snapshot
          ? 'paid'
          : 'not_required',
      created_at: appointment.created_at,
      updated_at: appointment.updated_at,
    },
  };
}

async function loadCareItemPayload(
  supabase: SupabaseAdmin,
  job: OutboxJob,
): Promise<
  | { ok: true; payload: JsonRecord }
  | { ok: false; errorCode: string; retryable: boolean }
> {
  if (job.event_type === 'care_item.archived') {
    return { ok: true, payload: job.payload };
  }
  const { data: item, error } = await supabase
    .from('care_plan_items')
    .select('id,mother_id,appointment_id')
    .eq('id', job.aggregate_id)
    .maybeSingle();
  if (error || !item) {
    return { ok: false, errorCode: 'SOURCE_CARE_ITEM_MISSING', retryable: false };
  }

  const { data: mother } = await supabase
    .from('mothers')
    .select('dawa_clinician_patient_id')
    .eq('id', item.mother_id)
    .maybeSingle();
  if (!mother?.dawa_clinician_patient_id) {
    return { ok: false, errorCode: 'PATIENT_NOT_SYNCED', retryable: true };
  }

  if (item.appointment_id) {
    const { data: appointment } = await supabase
      .from('appointments')
      .select('dawa_clinician_appointment_id')
      .eq('id', item.appointment_id)
      .maybeSingle();
    if (!appointment?.dawa_clinician_appointment_id) {
      return { ok: false, errorCode: 'APPOINTMENT_NOT_SYNCED', retryable: true };
    }
  }

  return { ok: true, payload: job.payload };
}

function isAuthorizedWorker(req: Request, serviceRoleKey: string): boolean {
  const workerSecret = Deno.env.get('DAWA_MOM_WORKER_SECRET');
  const providedWorkerSecret = req.headers.get('x-dawa-worker-secret') ?? '';
  if (workerSecret && timingSafeEqual(providedWorkerSecret, workerSecret)) return true;

  const authorization = req.headers.get('Authorization') ?? '';
  const bearer = authorization.startsWith('Bearer ')
    ? authorization.slice('Bearer '.length)
    : '';
  return timingSafeEqual(bearer, serviceRoleKey);
}

function retryDelayMs(attemptCount: number): number {
  const exponent = Math.max(0, Math.min(attemptCount - 1, 6));
  const base = 60_000 * 2 ** exponent;
  const jitter = Math.floor(Math.random() * 30_000);
  return Math.min(base + jitter, 60 * 60 * 1000);
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function optionalText(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const candidate = String(value).trim();
  return candidate.length === 0 ? null : candidate;
}

function timingSafeEqual(left: string, right: string): boolean {
  const encoder = new TextEncoder();
  const leftBytes = encoder.encode(left);
  const rightBytes = encoder.encode(right);
  const length = Math.max(leftBytes.length, rightBytes.length);
  let difference = leftBytes.length ^ rightBytes.length;
  for (let index = 0; index < length; index++) {
    difference |= (leftBytes[index] ?? 0) ^ (rightBytes[index] ?? 0);
  }
  return difference === 0;
}

function response(body: JsonRecord, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
