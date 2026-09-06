import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import {
  createClient,
  type SupabaseClient,
} from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

type JsonRecord = Record<string, unknown>;
type SupabaseAdmin = SupabaseClient<any, 'public', any>;
type OutboxJob = {
  id: string;
  event_id: string;
  event_type:
    | 'patient.upsert'
    | 'patient.archived'
    | 'appointment.created'
    | 'appointment.cancelled';
  aggregate_type: 'mother' | 'appointment';
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
      );
    } catch {
      result = {
        success: false,
        destinationId: null,
        errorCode: 'UPSTREAM_UNREACHABLE',
        retryable: true,
      };
    }

    const permanent = !result.success &&
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
): Promise<DeliveryResult> {
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
      'id,mother_id,clinician_id,clinic_id,appointment_date,start_time,end_time,appointment_type,reason,notes,status,created_at,updated_at',
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
      created_at: appointment.created_at,
      updated_at: appointment.updated_at,
    },
  };
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
