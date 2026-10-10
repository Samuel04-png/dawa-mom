import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const allowedStatuses = new Set([
  'confirmed',
  'declined',
  'rescheduled',
  'completed',
  'cancelled',
]);

type JsonRecord = Record<string, unknown>;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return response({ error: 'Method not allowed.' }, 405, { Allow: 'POST' });
  }

  const expectedSecret = Deno.env.get('DAWA_MOM_SYNC_SECRET') ?? '';
  const providedSecret = req.headers.get('x-dawa-sync-secret') ?? '';
  if (!expectedSecret) {
    return response({ error: 'Status sync secret is not configured.' }, 500);
  }
  if (!timingSafeEqual(providedSecret, expectedSecret)) {
    return response({ error: 'Unauthorized.' }, 401);
  }

  let payload: JsonRecord;
  try {
    const parsed = await req.json();
    if (!isRecord(parsed)) throw new Error('Invalid payload.');
    payload = parsed;
  } catch {
    return response({ error: 'Invalid JSON payload.' }, 400);
  }

  const eventId = uuid(payload.event_id);
  const appointmentId = uuid(payload.source_appointment_id);
  const externalAppointmentId = text(payload.external_appointment_id);
  const eventType = text(payload.event_type)?.toLowerCase() ??
    'appointment.status.changed';
  if (!eventId || !appointmentId || !externalAppointmentId) {
    return response({ error: 'Invalid appointment integration event.' }, 400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) {
    return response({ error: 'Supabase service credentials are missing.' }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let data: unknown;
  let error: { code?: string } | null;

  if (eventType === 'appointment.results_available') {
    const summary = sanitizeResultSummary(payload.summary);
    if (!summary) {
      return response({ error: 'Invalid patient result summary.' }, 400);
    }
    const result = await supabase.rpc(
      'apply_dawa_clinician_appointment_result',
      {
        p_event_id: eventId,
        p_appointment_id: appointmentId,
        p_external_appointment_id: externalAppointmentId,
        p_effective_at: optionalTimestamp(payload.effective_at),
        p_patient_safe_message: boundedText(payload.patient_safe_message, 500),
        p_summary: summary,
      },
    );
    data = result.data;
    error = result.error;
  } else if (eventType === 'appointment.status.changed') {
    const status = text(payload.status)?.toLowerCase() ?? null;
    if (!status || !allowedStatuses.has(status)) {
      return response({ error: 'Invalid appointment status event.' }, 400);
    }

    const isRescheduled = status === 'rescheduled';
    const appointmentDate = optionalDate(payload.appointment_date);
    const startTime = optionalTime(payload.start_time);
    const endTime = optionalTime(payload.end_time);
    if (isRescheduled && (!appointmentDate || !startTime || !endTime)) {
      return response({
        error: 'Rescheduled appointments require a valid date and time range.',
      }, 400);
    }

    const result = await supabase.rpc(
      'apply_dawa_clinician_appointment_status',
      {
        p_event_id: eventId,
        p_appointment_id: appointmentId,
        p_external_appointment_id: externalAppointmentId,
        p_status: status,
        p_appointment_date: appointmentDate,
        p_start_time: startTime,
        p_end_time: endTime,
        p_effective_at: optionalTimestamp(payload.effective_at),
        p_patient_safe_message: boundedText(payload.patient_safe_message, 500),
      },
    );
    data = result.data;
    error = result.error;
  } else {
    return response({ error: 'Unsupported appointment integration event.' }, 400);
  }

  if (!error && isRecord(data)) {
    return response(data);
  }

  if (error?.code === 'P0002') {
    return response({
      code: 'APPOINTMENT_NOT_FOUND',
      error: 'The DawaMom appointment was not found.',
      retryable: false,
    }, 404);
  }
  if (error?.code === '23505') {
    return response({
      code: 'SLOT_UNAVAILABLE',
      error: 'That appointment time is no longer available.',
      retryable: false,
    }, 409);
  }
  if (error?.code === '23514' || error?.code === '22023') {
    return response({
      code: eventType === 'appointment.results_available'
        ? 'INVALID_RESULT_SUMMARY'
        : 'INVALID_STATUS_TRANSITION',
      error: eventType === 'appointment.results_available'
        ? 'The patient result summary is not valid for this appointment.'
        : 'The appointment status update is not allowed.',
      retryable: false,
    }, 409);
  }

  console.error('[receive-dawa-clinician-appointment-status] Appointment callback failed.');
  return response({
    code: eventType === 'appointment.results_available'
      ? 'RESULT_SYNC_FAILED'
      : 'STATUS_SYNC_FAILED',
    error: 'The appointment update could not be applied right now.',
    retryable: true,
  }, 500);
});

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function text(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const candidate = String(value).trim();
  return candidate.length === 0 ? null : candidate;
}

function uuid(value: unknown): string | null {
  const candidate = text(value);
  return candidate && uuidPattern.test(candidate) ? candidate.toLowerCase() : null;
}

function optionalDate(value: unknown): string | null {
  const candidate = text(value);
  if (!candidate || !/^\d{4}-\d{2}-\d{2}$/.test(candidate)) return null;
  const parsed = new Date(`${candidate}T00:00:00Z`);
  return !Number.isNaN(parsed.getTime()) &&
      parsed.toISOString().slice(0, 10) === candidate
    ? candidate
    : null;
}

function optionalTime(value: unknown): string | null {
  const candidate = text(value);
  return candidate && /^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/.test(candidate)
    ? candidate.slice(0, 5)
    : null;
}

function optionalTimestamp(value: unknown): string | null {
  const candidate = text(value);
  if (!candidate) return null;
  const parsed = new Date(candidate);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function boundedText(value: unknown, maxLength: number): string | null {
  return text(value)?.slice(0, maxLength) ?? null;
}

function sanitizeResultSummary(value: unknown): JsonRecord | null {
  if (!isRecord(value)) return null;

  const id = uuid(value.id);
  const encounterId = boundedText(value.encounter_id, 240);
  const version = Number(value.version);
  const appointmentDate = optionalDate(value.appointment_date);
  const completedAt = optionalTimestamp(value.completed_at);
  const generatedAt = optionalTimestamp(value.generated_at);
  const overallStatus = text(value.overall_status)?.toLowerCase() ?? null;
  if (!id || !encounterId || !Number.isSafeInteger(version) || version < 1 ||
    !appointmentDate || !completedAt || !generatedAt ||
    !overallStatus || ![
      'routine',
      'follow_up',
      'needs_attention',
      'urgent',
    ].includes(overallStatus)) {
    return null;
  }

  const maternal = isRecord(value.maternal_health) ? value.maternal_health : {};
  const pregnancy = isRecord(value.pregnancy_health)
    ? value.pregnancy_health
    : {};

  return {
    id,
    encounter_id: encounterId,
    version,
    clinician_display_name: boundedText(value.clinician_display_name, 240) ??
      'Your clinician',
    clinic_name: boundedText(value.clinic_name, 240) ?? 'Your clinic',
    appointment_date: appointmentDate,
    completed_at: completedAt,
    overall_status: overallStatus,
    maternal_health: {
      heart_rate: sanitizeMeasurement(maternal.heart_rate),
      blood_pressure: sanitizeMeasurement(maternal.blood_pressure),
      hemoglobin: sanitizeMeasurement(maternal.hemoglobin),
    },
    pregnancy_health: {
      pregnancy_status: sanitizePregnancyStatus(pregnancy.pregnancy_status),
      fetal_heartbeat: sanitizeMeasurement(pregnancy.fetal_heartbeat),
      heartbeat_quality: sanitizeMeasurement(pregnancy.heartbeat_quality),
      fetal_position: sanitizeMeasurement(pregnancy.fetal_position),
      estimated_baby_size: sanitizeMeasurement(pregnancy.estimated_baby_size),
    },
    key_findings: boundedText(value.key_findings, 4000),
    recommendations: boundedText(value.recommendations, 8000),
    follow_up_instructions: boundedText(value.follow_up_instructions, 8000),
    referral_summary: boundedText(value.referral_summary, 8000),
    next_appointment_at: optionalTimestamp(value.next_appointment_at),
    urgent_care_instruction: boundedText(value.urgent_care_instruction, 4000),
    generated_at: generatedAt,
  };
}

function sanitizeMeasurement(value: unknown): JsonRecord {
  if (!isRecord(value)) return {};
  const state = text(value.state)?.toLowerCase() ?? null;
  const interpretation = text(value.interpretation)?.toLowerCase() ?? null;
  const unit = text(value.unit);
  return {
    state: state && [
        'measured',
        'recorded',
        'not_measured',
        'unable_to_obtain',
        'not_applicable',
      ].includes(state)
      ? state
      : null,
    value: boundedText(value.value, 160),
    unit: unit && ['bpm', 'mmHg', 'g/dL', 'cm'].includes(unit) ? unit : null,
    interpretation: interpretation && [
        'normal',
        'low',
        'high',
        'needs_attention',
        'critical',
        'recorded',
      ].includes(interpretation)
      ? interpretation
      : null,
  };
}

function sanitizePregnancyStatus(value: unknown): JsonRecord {
  if (!isRecord(value)) return {};
  const status = text(value.value)?.toLowerCase() ?? null;
  const source = text(value.source)?.toLowerCase() ?? null;
  return {
    state: value.state === 'recorded' ? 'recorded' : null,
    value: status && [
        'pregnant',
        'not_pregnant',
        'not_provided',
        'prefer_not_to_say',
      ].includes(status)
      ? status
      : null,
    source: source && ['patient', 'clinician'].includes(source) ? source : null,
  };
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

function response(
  body: JsonRecord,
  status = 200,
  extraHeaders: HeadersInit = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Access-Control-Allow-Headers':
        'authorization, x-client-info, apikey, content-type, x-dawa-sync-secret',
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
  });
}
