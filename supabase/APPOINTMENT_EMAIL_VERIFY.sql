-- Read-only verification for the appointment email pipeline.
-- Run in the linked Supabase SQL editor after migration 202607150003.

select
  to_regclass('public.appointment_email_outbox') as outbox_table,
  exists (
    select 1
    from pg_trigger
    where tgname = 'enqueue_appointment_email_jobs'
      and not tgisinternal
  ) as enqueue_trigger_installed;

select
  relrowsecurity as rls_enabled,
  relforcerowsecurity as rls_forced
from pg_class
where oid = 'public.appointment_email_outbox'::regclass;

select policyname, roles, cmd
from pg_policies
where schemaname = 'public'
  and tablename = 'appointment_email_outbox';

select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'claim_appointment_email_jobs',
    'complete_appointment_email_job',
    'enqueue_appointment_email_jobs'
  )
order by p.proname;

select status, recipient_kind, count(*)
from public.appointment_email_outbox
group by status, recipient_kind
order by status, recipient_kind;
