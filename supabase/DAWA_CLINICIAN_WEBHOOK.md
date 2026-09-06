# Dawa Mom to Dawa Clinician sync

This repository is the Dawa Mom source project (`himbfndvsuwiudtzjojh`). The
destination is the separate Dawa Clinician project (`eatliepvwrviogsnqavu`).
Flutter must only call Dawa Mom. Cross-project calls are server-to-server.

## Durable path

After migration `202607170001_add_dawa_platform_sync.sql` is applied, committed
mother and appointment changes create private `integration_outbox` events in the
same transaction. The `process-dawa-platform-outbox` Edge Function claims those
events with recoverable leases, calls the appropriate Dawa Clinician receiver,
and stores the returned stable mapping.

The older Dashboard database webhook is supported only during a rolling deploy.
Once the outbox worker has passed the single-user and small-batch checks, disable
the `sync_mothers_to_dawa_clinician` webhook to avoid maintaining two delivery
paths. Receiver idempotency protects a short overlap, but overlap is not the
steady-state design.

## Server-only configuration

Dawa Mom Edge Function environment:

- `DAWA_CLINICIAN_PATIENT_SYNC_URL`
- `DAWA_CLINICIAN_APPOINTMENT_URL`
- `DAWA_CLINICIAN_DIRECTORY_URL`
- `DAWA_CLINICIAN_DIRECTORY_TOKEN`
- `DAWA_CLINICIAN_SYNC_SECRET`
- `DAWA_MOM_SYNC_SECRET`
- optional `DAWA_MOM_WORKER_SECRET`

Never store their values in Flutter, checked-in files, public environment files,
or browser-visible configuration.

## Backfill

`tools/backfill_dawa_clinician_patients.ts` is dry-run by default. It selects
only usable profiles, supports deterministic replay, and writes the destination
patient mapping back to Dawa Mom only with explicit `--execute`.

Required for a live dry run:

- `DAWA_MOM_SUPABASE_URL`
- `DAWA_MOM_SERVICE_ROLE_KEY`

Also required for execution:

- `DAWA_CLINICIAN_SYNC_SECRET`
- `DAWA_CLINICIAN_PATIENT_SYNC_URL` (explicit destination; there is no execute
  fallback)

Examples:

```sh
deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts \
  --dry-run --max=25 --batch-size=10

deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts \
  --dry-run --mother-id=<dawa-mom-mother-uuid>

deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts \
  --execute --mother-id=<reviewed-test-mother-uuid>

deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts \
  --execute --max=25 --batch-size=10 --start-after=<last-source-uuid>

# Full remaining set: only after explicit approval and successful small-batch
# reconciliation.
deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts \
  --execute --batch-size=100 --start-after=<last-source-uuid>
```

Do not run an unrestricted production backfill until one-user and small-batch
reconciliation have passed. The tool logs source IDs and safe status only; it
does not log complete patient records or secrets.

See `../../docs/integration/05-deployment-and-verification.md` in the shared
workspace for the cross-project rollout and rollback sequence.
