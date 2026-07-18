-- Schedule the Dawa Mom durable integration outbox worker.
--
-- The worker token is provisioned separately in Supabase Vault under
-- `dawa_mom_worker_secret`. No credential is stored in this migration.

begin;

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

do $$
declare
  existing_job_id bigint;
begin
  if not exists (
    select 1
    from vault.secrets
    where name = 'dawa_mom_worker_secret'
  ) then
    raise exception 'Vault secret dawa_mom_worker_secret is required before scheduling';
  end if;

  for existing_job_id in
    select jobid
    from cron.job
    where jobname = 'dawa-mom-platform-outbox-every-minute'
  loop
    perform cron.unschedule(existing_job_id);
  end loop;

  perform cron.schedule(
    'dawa-mom-platform-outbox-every-minute',
    '* * * * *',
    $schedule$
      select net.http_post(
        url := 'https://himbfndvsuwiudtzjojh.supabase.co/functions/v1/process-dawa-platform-outbox',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-dawa-worker-secret', (
            select decrypted_secret
            from vault.decrypted_secrets
            where name = 'dawa_mom_worker_secret'
            limit 1
          )
        ),
        body := '{}'::jsonb
      );
    $schedule$
  );
end $$;

commit;
