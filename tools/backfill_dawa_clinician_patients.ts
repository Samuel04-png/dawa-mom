export {};

type MotherRow = {
  id: string;
  user_id?: string | null;
  profile_id?: string | null;
  legacy_mother_id?: string | null;
  name?: string | null;
  phone_number?: string | null;
  date_of_birth?: string | null;
  occupation?: string | null;
  address?: string | null;
  email?: string | null;
  dawa_clinician_patient_id?: string | null;
  dawa_clinician_synced_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

type Args = {
  execute: boolean;
  batchSize: number;
  startAfter: string | null;
  maxRecords: number | null;
  motherId: string | null;
};

const defaultEndpoint =
  'https://eatliepvwrviogsnqavu.supabase.co/functions/v1/sync-dawa-mom-patient';

const args = parseArgs(Deno.args);
const momUrl = requiredEnv('DAWA_MOM_SUPABASE_URL').replace(/\/+$/, '');
const momServiceRoleKey = requiredEnv('DAWA_MOM_SERVICE_ROLE_KEY');
const syncSecret = args.execute ? requiredEnv('DAWA_CLINICIAN_SYNC_SECRET') : '';
const configuredSyncEndpoint = Deno.env.get('DAWA_CLINICIAN_PATIENT_SYNC_URL') ??
  Deno.env.get('DAWA_CLINICIAN_SYNC_ENDPOINT');
if (args.execute && !configuredSyncEndpoint) {
  throw new Error(
    'DAWA_CLINICIAN_PATIENT_SYNC_URL is required with --execute so the destination is explicit.',
  );
}
const syncEndpoint = configuredSyncEndpoint ?? defaultEndpoint;

let cursor = args.startAfter;
let processed = 0;
let mapped = 0;
let skipped = 0;
const failedIds: string[] = [];

while (args.maxRecords == null || processed < args.maxRecords) {
  const remaining = args.maxRecords == null
    ? args.batchSize
    : Math.min(args.batchSize, args.maxRecords - processed);
  if (remaining <= 0) break;

  const rows = await fetchMotherBatch(cursor, remaining);
  if (rows.length === 0) break;

  for (const row of rows) {
    cursor = row.id;
    processed += 1;

    if (!needsSync(row)) {
      skipped += 1;
      console.log(`[skip] mother ${row.id} mapping is current`);
      continue;
    }

    if (!isUsable(row)) {
      skipped += 1;
      console.log(`[skip] mother ${row.id} does not have a usable profile`);
      continue;
    }

    const eventId = await deterministicEventId(row);
    const record = toSyncRecord(row);
    if (!args.execute) {
      console.log(
        `[dry-run] would sync mother ${row.id} with event ${eventId}`,
      );
      continue;
    }

    try {
      const response = await fetch(syncEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-dawa-sync-secret': syncSecret,
        },
        body: JSON.stringify({
          event_id: eventId,
          event_type: 'patient.upsert',
          type: 'UPDATE',
          schema: 'public',
          table: 'mothers',
          record,
        }),
      });

      let result: Record<string, unknown> = {};
      try {
        const parsed = await response.json();
        if (isRecord(parsed)) result = parsed;
      } catch {
        // Do not print raw upstream responses or patient payloads.
      }

      const patientId = text(result.patient_id);
      if (!response.ok || !patientId) {
        failedIds.push(row.id);
        console.error(
          `Backfill failed for mother ${row.id}: HTTP ${response.status}`,
        );
        continue;
      }

      await storeMapping(row.id, patientId);
      mapped += 1;
      console.log(`Backfilled mother ${row.id}`);
    } catch {
      failedIds.push(row.id);
      console.error(`Backfill failed for mother ${row.id}: network error`);
    }
  }

  console.log(`Batch complete. Last processed source id: ${cursor}`);
  if (args.motherId) break;
}

console.log(
  `${args.execute ? 'Processed' : 'Dry-run inspected'} ${processed} rows; ` +
    `${mapped} mapped; ${skipped} skipped; ${failedIds.length} failed.`,
);
if (failedIds.length > 0) {
  console.error(`Failed source ids for retry: ${failedIds.join(', ')}`);
  Deno.exitCode = 1;
}

async function fetchMotherBatch(
  startAfter: string | null,
  limit: number,
): Promise<MotherRow[]> {
  const url = new URL(`${momUrl}/rest/v1/mothers`);
  url.searchParams.set(
    'select',
    [
      'id',
      'user_id',
      'profile_id',
      'legacy_mother_id',
      'name',
      'phone_number',
      'date_of_birth',
      'occupation',
      'address',
      'dawa_clinician_patient_id',
      'dawa_clinician_synced_at',
      'created_at',
      'updated_at',
    ].join(','),
  );
  url.searchParams.set('order', 'id.asc');
  url.searchParams.set('limit', String(limit));

  if (args.motherId) {
    url.searchParams.set('id', `eq.${args.motherId}`);
  } else if (startAfter) {
    url.searchParams.set('id', `gt.${startAfter}`);
  }

  const response = await fetch(url, {
    headers: serviceHeaders(),
  });
  if (!response.ok) {
    throw new Error(`Could not read Dawa Mom mothers: HTTP ${response.status}`);
  }

  const rows = await response.json() as MotherRow[];
  const profileIds = [...new Set(
    rows
      .map((row) => row.profile_id ?? row.user_id ?? null)
      .filter((id): id is string => Boolean(id)),
  )];
  if (profileIds.length === 0) return rows;

  const profilesUrl = new URL(`${momUrl}/rest/v1/profiles`);
  profilesUrl.searchParams.set('select', 'id,email');
  profilesUrl.searchParams.set('id', `in.(${profileIds.join(',')})`);
  const profilesResponse = await fetch(profilesUrl, { headers: serviceHeaders() });
  if (!profilesResponse.ok) {
    throw new Error(`Could not read Dawa Mom profiles: HTTP ${profilesResponse.status}`);
  }
  const profiles = await profilesResponse.json() as Array<{
    id: string;
    email?: string | null;
  }>;
  const emails = new Map(profiles.map((profile) => [profile.id, profile.email]));
  return rows.map((row) => ({
    ...row,
    email: emails.get(row.profile_id ?? row.user_id ?? '') ?? null,
  }));
}

function needsSync(row: MotherRow): boolean {
  if (!row.dawa_clinician_patient_id) return true;
  const updated = Date.parse(row.updated_at ?? '');
  const synced = Date.parse(row.dawa_clinician_synced_at ?? '');
  return Number.isFinite(updated) && (!Number.isFinite(synced) || updated > synced);
}

function isUsable(row: MotherRow): boolean {
  const digits = (row.phone_number ?? '').replaceAll(/\D/g, '');
  const hasEmail = (row.email?.trim().length ?? 0) >= 3;
  return Boolean(
    row.id && (row.profile_id || row.user_id) &&
      (row.name?.trim().length ?? 0) >= 2 && row.date_of_birth &&
      (digits.length >= 8 || hasEmail),
  );
}

function toSyncRecord(row: MotherRow): Record<string, unknown> {
  return {
    id: row.id,
    source_mother_id: row.id,
    source_user_id: row.user_id ?? row.profile_id ?? null,
    mother_id: row.legacy_mother_id ?? row.id,
    name: row.name ?? null,
    phone_number: row.phone_number ?? null,
    email: row.email ?? null,
    date_of_birth: row.date_of_birth ?? null,
    occupation: row.occupation ?? null,
    address: row.address ?? null,
    created_at: row.created_at ?? null,
    updated_at: row.updated_at ?? null,
    source_updated_at: row.updated_at ?? null,
  };
}

async function storeMapping(motherId: string, patientId: string): Promise<void> {
  const response = await fetch(
    `${momUrl}/rest/v1/rpc/record_dawa_clinician_patient_mapping`,
    {
      method: 'POST',
      headers: { ...serviceHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({
        p_mother_id: motherId,
        p_patient_id: patientId,
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`Could not store mapping: HTTP ${response.status}`);
  }
}

async function deterministicEventId(row: MotherRow): Promise<string> {
  const version = row.updated_at ?? row.created_at ?? 'unversioned';
  const bytes = new Uint8Array(
    await crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode(`dawa_mom:patient.backfill:${row.id}:${version}`),
    ),
  ).slice(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = [...bytes].map((value) => value.toString(16).padStart(2, '0'))
    .join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function parseArgs(rawArgs: string[]): Args {
  const parsed: Args = {
    execute: false,
    batchSize: 100,
    startAfter: null,
    maxRecords: null,
    motherId: null,
  };

  for (const arg of rawArgs) {
    if (arg === '--execute') {
      parsed.execute = true;
    } else if (arg === '--dry-run') {
      parsed.execute = false;
    } else if (arg.startsWith('--batch-size=')) {
      parsed.batchSize = positiveInt(arg.slice('--batch-size='.length));
    } else if (arg.startsWith('--start-after=')) {
      parsed.startAfter = arg.slice('--start-after='.length) || null;
    } else if (arg.startsWith('--max=')) {
      parsed.maxRecords = positiveInt(arg.slice('--max='.length));
    } else if (arg.startsWith('--mother-id=')) {
      parsed.motherId = requiredUuid(arg.slice('--mother-id='.length));
      parsed.maxRecords = 1;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return parsed;
}

function positiveInt(value: string): number {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`Expected a positive integer, received: ${value}`);
  }
  return parsed;
}

function requiredUuid(value: string): string {
  const candidate = value.trim();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(candidate)) {
    throw new Error('mother-id must be a UUID');
  }
  return candidate.toLowerCase();
}

function serviceHeaders(): Record<string, string> {
  return {
    apikey: momServiceRoleKey,
    Authorization: `Bearer ${momServiceRoleKey}`,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function text(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const candidate = String(value).trim();
  return candidate.length === 0 ? null : candidate;
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
