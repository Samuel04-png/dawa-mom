# Release 1 disposable migration validation

`tool/ci/release1_migration_validation.sh` creates a temporary Supabase
workspace, applies the checked-in baseline through `202609240002`, seeds
synthetic legacy appointment/payment rows, and then incrementally applies only:

1. the checked-in migration chain through `202609240002`;
2. `202610090002_track_cancellation_sync_state.sql`; and
3. `202610100001_secure_paid_appointment_lifecycle.sql`.

It excludes `202610090001_add_care_plan_items.sql` and both Release 2
migrations by construction. The incremental application tests
`202610100001`'s real legacy-row backfill, not only new bookings. It starts
only a local Docker stack and carries no Supabase access token, project ref,
database URL, provider credential, or real patient data.

`202607180001_schedule_dawa_platform_outbox.sql` correctly requires the
`dawa_mom_worker_secret` in Vault. The runner injects a named, non-production
placeholder as a temporary `202607170002` fixture so that the historical chain
can run unchanged. The fixture is never placed in `supabase/migrations`,
deployed, or used as an application secret.

## Important baseline limitation

`202609170001_recovered_remote_history.sql` deliberately contains no schema
SQL because the corresponding remote migration was applied before this
repository snapshot existed. Therefore the checked-in migration chain is a
**structural baseline**, not proof that every historical production object or
record is represented.

Do not call a passing workflow production-equivalent. Before production
approval, an authorized operator must provide a sanitized, schema-only baseline
from a non-production/staging environment that has been reconciled against the
connected project’s read-only schema inventory. That baseline must contain no
patient, payment, access-token, or provider data. The same SQL test file must
then run against it in isolated CI.

The protected `release/1-core-backend` branch may contain the immutable
Release 1 files `202610090002` and `202610100001` without Care Plan only after
migration-owner approval. It must not rename migrations, run migration repair,
mark Care Plan applied, or manually execute production SQL. The non-contiguous
history must be an explicit, reviewed release-scope record.
