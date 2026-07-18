import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import {
  createClient,
  type SupabaseClient,
} from 'npm:@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type JsonRecord = Record<string, unknown>;
type SupabaseAdmin = SupabaseClient<any, 'public', any>;
type DirectoryRequest = {
  action?: 'list' | 'availability';
  clinic_id?: string;
  clinician_id?: string;
  date?: string;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const authorization = req.headers.get('Authorization');
  if (!authorization) {
    return jsonResponse({ error: 'Missing Authorization header' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
    return jsonResponse({ error: 'Dawa Mom function environment is not configured' }, 500);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse({ error: 'Invalid or expired session' }, 401);
  }

  let body: DirectoryRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const action = body.action ?? 'list';
  if (action !== 'list' && action !== 'availability') {
    return jsonResponse({ error: 'Unsupported directory action' }, 400);
  }
  if (action === 'availability' && (!body.clinician_id || !body.date)) {
    return jsonResponse({ error: 'clinician_id and date are required' }, 400);
  }

  const externalUrl = Deno.env.get('DAWA_CLINICIAN_DIRECTORY_URL');
  const externalToken = Deno.env.get('DAWA_CLINICIAN_DIRECTORY_TOKEN');
  if (!externalUrl || !externalToken) {
    return jsonResponse({
      code: 'DIRECTORY_NOT_CONFIGURED',
      error: 'The authoritative clinician directory is not connected yet',
    }, 503);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const mapped = await resolveExternalMappings(adminClient, body);
    const response = await fetch(externalUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-dawa-directory-secret': externalToken,
      },
      body: JSON.stringify({
        action,
        clinic_id: mapped.externalClinicId,
        clinician_id: mapped.externalClinicianId,
        date: body.date ?? null,
        source: 'dawa_mom',
      }),
    });

    if (!response.ok) {
      return jsonResponse({
        code: response.status === 404
          ? 'CLINICIAN_NOT_BOOKABLE'
          : 'DIRECTORY_UPSTREAM_ERROR',
        error: response.status === 409
          ? 'That appointment time is no longer available'
          : 'The clinician directory is temporarily unavailable',
        retryable: response.status >= 500 || response.status === 409,
      }, response.status >= 500 ? 502 : response.status);
    }

    const payload = await response.json();
    if (!isRecord(payload)) {
      throw new Error('Directory response must be an object.');
    }

    if (action === 'availability') {
      const slots = sanitizeSlots(payload.slots);
      return new Response(JSON.stringify({
        clinician_id: body.clinician_id,
        clinic_id: body.clinic_id ?? null,
        date: body.date,
        timezone: payload.timezone === 'Africa/Lusaka'
          ? 'Africa/Lusaka'
          : 'Africa/Lusaka',
        slots,
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const safeClinicians = sanitizeClinicians(payload.clinicians);
    const { data: localClinicians, error: cacheError } = await adminClient.rpc(
      'upsert_dawa_clinician_directory',
      {
        p_clinicians: safeClinicians,
        p_is_full_refresh: !body.clinic_id,
      },
    );
    if (cacheError) throw cacheError;

    return new Response(JSON.stringify({ clinicians: localClinicians ?? [] }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch {
    console.error('[clinician-directory] Authoritative directory request failed.');
    return jsonResponse({
      code: 'DIRECTORY_UPSTREAM_UNREACHABLE',
      error: 'The clinician directory is temporarily unavailable',
      retryable: true,
    }, 502);
  }
});

async function resolveExternalMappings(
  adminClient: SupabaseAdmin,
  body: DirectoryRequest,
): Promise<{
  externalClinicId: string | null;
  externalClinicianId: string | null;
}> {
  let externalClinicId: string | null = null;
  let externalClinicianId: string | null = null;

  if (body.clinic_id) {
    if (!uuidPattern.test(body.clinic_id)) {
      throw new Error('Local clinic ID must be a UUID.');
    }
    const { data, error } = await adminClient
      .from('clinics')
      .select('dawa_clinician_clinic_id')
      .eq('id', body.clinic_id)
      .maybeSingle();
    if (error) throw error;
    externalClinicId = data?.dawa_clinician_clinic_id ?? null;
    if (!externalClinicId) {
      throw new Error('Clinic has no authoritative mapping.');
    }
  }

  if (body.clinician_id) {
    if (!uuidPattern.test(body.clinician_id)) {
      throw new Error('Local clinician ID must be a UUID.');
    }
    const { data, error } = await adminClient
      .from('doctors')
      .select('dawa_clinician_clinician_id,clinic_id')
      .eq('id', body.clinician_id)
      .maybeSingle();
    if (error) throw error;
    externalClinicianId = data?.dawa_clinician_clinician_id ?? null;
    if (!externalClinicianId) {
      throw new Error('Clinician has no authoritative mapping.');
    }
  }

  return { externalClinicId, externalClinicianId };
}

function sanitizeClinicians(value: unknown): JsonRecord[] {
  if (!Array.isArray(value)) {
    throw new Error('Directory clinicians must be an array.');
  }
  return value.map((candidate) => {
    if (!isRecord(candidate)) throw new Error('Invalid clinician row.');
    const id = requiredUuid(candidate.id);
    const clinicId = requiredUuid(candidate.clinic_id);
    const displayName = requiredText(candidate.display_name);
    const clinicName = requiredText(candidate.clinic_name);
    const availability = isRecord(candidate.availability_summary)
      ? candidate.availability_summary
      : {};
    return {
      id,
      display_name: displayName,
      professional_title: optionalText(candidate.professional_title),
      speciality: optionalText(candidate.speciality),
      clinic_id: clinicId,
      clinic_name: clinicName,
      profile_image_url: optionalText(candidate.profile_image_url),
      is_active: candidate.is_active === true,
      is_bookable: candidate.is_bookable === true,
      availability_summary: {
        start_time: requiredTime(availability.start_time, '08:00'),
        end_time: requiredTime(availability.end_time, '16:00'),
        slot_minutes: clampSlotMinutes(availability.slot_minutes),
      },
    };
  }).filter((item) => item.is_active && item.is_bookable);
}

function sanitizeSlots(value: unknown): JsonRecord[] {
  if (!Array.isArray(value)) throw new Error('Directory slots must be an array.');
  return value.map((candidate) => {
    if (!isRecord(candidate)) throw new Error('Invalid availability slot.');
    return {
      start_time: requiredTime(candidate.start_time),
      end_time: requiredTime(candidate.end_time),
      is_available: candidate.is_available === true,
    };
  });
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function requiredUuid(value: unknown): string {
  const candidate = requiredText(value);
  if (!uuidPattern.test(candidate)) throw new Error('Directory ID must be a UUID.');
  return candidate.toLowerCase();
}

function requiredText(value: unknown): string {
  const candidate = optionalText(value);
  if (!candidate) throw new Error('Required directory field is missing.');
  return candidate;
}

function optionalText(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const candidate = String(value).trim();
  return candidate.length === 0 ? null : candidate;
}

function requiredTime(value: unknown, fallback?: string): string {
  const candidate = optionalText(value) ?? fallback;
  if (!candidate || !/^([01]\d|2[0-3]):[0-5]\d$/.test(candidate)) {
    throw new Error('Invalid directory time.');
  }
  return candidate;
}

function clampSlotMinutes(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 5 && parsed <= 240
    ? Math.round(parsed)
    : 30;
}
