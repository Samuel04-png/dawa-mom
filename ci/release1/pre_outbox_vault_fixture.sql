-- CI-only fixture. This file is copied into the disposable migration workspace
-- immediately before 202607180001_schedule_dawa_platform_outbox.sql. It is not
-- a production migration and contains no deployable credential.
select vault.create_secret(
  'ci-release1-placeholder-not-a-production-secret',
  'dawa_mom_worker_secret',
  'Release 1 disposable migration validation only'
);
