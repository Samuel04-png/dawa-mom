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
  created_at?: string | null;
  updated_at?: string | null;
};

type Args = {
  dryRun: boolean;
  batchSize: number;
  startAfter: string | null;
  maxRecords: number | null;
};

const defaultEndpoint =
  'https://eatliepvwrviogsnqavu.supabase.co/functions/v1/sync-dawa-mom-patient';

const args = parseArgs(Deno.args);
const momUrl = requiredEnv('DAWA_MOM_SUPABASE_URL').replace(/\/+$/, '');
const momServiceRoleKey = requiredEnv('DAWA_MOM_SERVICE_ROLE_KEY');
const syncSecret = requiredEnv('DAWA_SYNC_SECRET');
const syncEndpoint = Deno.env.get('DAWA_CLINICIAN_SYNC_ENDPOINT') ??
  defaultEndpoint;

let cursor = args.startAfter;
let processed = 0;
const failedIds: string[] = [];

while (args.maxRecords == null || processed < args.maxRecords) {
  const remaining = args.maxRecords == null
    ? args.batchSize
    : Math.min(args.batchSize, args.maxRecords - processed);
  if (remaining <= 0) {
    break;
  }

  const rows = await fetchMotherBatch(cursor, remaining);
  if (rows.length === 0) {
    break;
  }

  for (const row of rows) {
    cursor = row.id;
    processed += 1;

    const payload = {
      type: 'INSERT',
      schema: 'public',
      table: 'mothers',
      record: toWebhookRecord(row),
      old_record: null,
    };

    if (args.dryRun) {
      console.log(`[dry-run] would backfill mother ${row.id}`);
      continue;
    }

    try {
      const response = await fetch(syncEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-dawa-sync-secret': syncSecret,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        failedIds.push(row.id);
        console.error(
          `Backfill failed for mother ${row.id}: HTTP ${response.status}`,
        );
        continue;
      }

      console.log(`Backfilled mother ${row.id}`);
    } catch (error) {
      failedIds.push(row.id);
      console.error(`Backfill failed for mother ${row.id}: ${error}`);
    }
  }

  console.log(`Batch complete. Last processed source id: ${cursor}`);
}

console.log(`Processed ${processed} mother rows.`);
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
      'created_at',
      'updated_at',
    ].join(','),
  );
  url.searchParams.set('order', 'id.asc');
  url.searchParams.set('limit', String(limit));
  if (startAfter) {
    url.searchParams.set('id', `gt.${startAfter}`);
  }

  const response = await fetch(url, {
    headers: {
      apikey: momServiceRoleKey,
      Authorization: `Bearer ${momServiceRoleKey}`,
    },
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Could not read Dawa Mom mothers: HTTP ${response.status} ${text}`,
    );
  }

  return await response.json() as MotherRow[];
}

function toWebhookRecord(row: MotherRow): Record<string, unknown> {
  return {
    id: row.id,
    user_id: row.user_id ?? row.profile_id ?? null,
    mother_id: row.legacy_mother_id ?? row.id,
    name: row.name ?? null,
    phone_number: row.phone_number ?? null,
    date_of_birth: row.date_of_birth ?? null,
    occupation: row.occupation ?? null,
    address: row.address ?? null,
    created_at: row.created_at ?? null,
    updated_at: row.updated_at ?? null,
  };
}

function parseArgs(rawArgs: string[]): Args {
  const parsed: Args = {
    dryRun: false,
    batchSize: 100,
    startAfter: null,
    maxRecords: null,
  };

  for (const arg of rawArgs) {
    if (arg === '--dry-run') {
      parsed.dryRun = true;
      continue;
    }
    if (arg.startsWith('--batch-size=')) {
      parsed.batchSize = positiveInt(arg.slice('--batch-size='.length));
      continue;
    }
    if (arg.startsWith('--start-after=')) {
      parsed.startAfter = arg.slice('--start-after='.length) || null;
      continue;
    }
    if (arg.startsWith('--max=')) {
      parsed.maxRecords = positiveInt(arg.slice('--max='.length));
      continue;
    }
    throw new Error(`Unknown argument: ${arg}`);
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

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}
