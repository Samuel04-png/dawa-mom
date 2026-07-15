-- Durable, server-only delivery queue for appointment email notifications.
-- The booking transaction only writes queue rows; network delivery is handled
-- asynchronously by process-appointment-emails.

begin;

create table if not exists public.appointment_email_outbox (
  id uuid primary key default extensions.gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  recipient_kind text not null,
  template_key text not null default 'appointment_requested',
  recipient_email text,
  status text not null default 'pending',
  attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  locked_at timestamptz,
  locked_by text,
  provider_message_id text,
  last_error text,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointment_email_outbox_recipient_check
    check (recipient_kind in ('patient', 'clinician')),
  constraint appointment_email_outbox_status_check
    check (status in ('pending', 'retrying', 'processing', 'sent', 'permanently_failed')),
  constraint appointment_email_outbox_attempt_check check (attempt_count >= 0),
  constraint appointment_email_outbox_email_check check (
    recipient_email is null
    or recipient_email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  ),
  unique (appointment_id, recipient_kind, template_key)
);

create index if not exists appointment_email_outbox_ready_idx
  on public.appointment_email_outbox(status, next_attempt_at, created_at)
  where status in ('pending', 'retrying', 'processing');

alter table public.appointment_email_outbox enable row level security;

-- Deliberately no client-facing policies. The service-role worker bypasses RLS;
-- patients and clinicians never receive queue data or recipient addresses.
revoke all on table public.appointment_email_outbox from anon, authenticated;

create or replace function public.enqueue_appointment_email_jobs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.appointment_email_outbox (
    appointment_id,
    recipient_kind,
    template_key
  ) values
    (new.id, 'patient', 'appointment_requested'),
    (new.id, 'clinician', 'appointment_requested')
  on conflict (appointment_id, recipient_kind, template_key) do nothing;

  return new;
end;
$$;

revoke all on function public.enqueue_appointment_email_jobs() from public;

drop trigger if exists enqueue_appointment_email_jobs on public.appointments;
create trigger enqueue_appointment_email_jobs
  after insert on public.appointments
  for each row execute function public.enqueue_appointment_email_jobs();

create or replace function public.claim_appointment_email_jobs(
  p_limit integer,
  p_worker_id text
)
returns setof public.appointment_email_outbox
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_worker_id is null or length(trim(p_worker_id)) < 8 then
    raise exception 'A valid worker id is required';
  end if;

  return query
  with candidates as (
    select o.id
    from public.appointment_email_outbox o
    where (
      o.status in ('pending', 'retrying')
      and o.next_attempt_at <= now()
    ) or (
      o.status = 'processing'
      and o.locked_at < now() - interval '10 minutes'
    )
    order by o.next_attempt_at, o.created_at
    for update skip locked
    limit greatest(1, least(coalesce(p_limit, 10), 50))
  )
  update public.appointment_email_outbox o
  set status = 'processing',
      attempt_count = o.attempt_count + 1,
      locked_at = now(),
      locked_by = trim(p_worker_id),
      updated_at = now()
  from candidates c
  where o.id = c.id
  returning o.*;
end;
$$;

create or replace function public.complete_appointment_email_job(
  p_job_id uuid,
  p_worker_id text,
  p_success boolean,
  p_recipient_email text default null,
  p_provider_message_id text default null,
  p_error text default null,
  p_retry_at timestamptz default null,
  p_permanent boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_appointment_id uuid;
begin
  update public.appointment_email_outbox o
  set status = case
        when p_success then 'sent'
        when p_permanent then 'permanently_failed'
        else 'retrying'
      end,
      recipient_email = case
        when p_recipient_email is null then o.recipient_email
        else lower(trim(p_recipient_email))
      end,
      provider_message_id = case
        when p_success then nullif(trim(p_provider_message_id), '')
        else o.provider_message_id
      end,
      last_error = case
        when p_success then null
        else left(coalesce(nullif(trim(p_error), ''), 'Delivery failed'), 2000)
      end,
      next_attempt_at = case
        when p_success or p_permanent then o.next_attempt_at
        else coalesce(p_retry_at, now() + interval '15 minutes')
      end,
      sent_at = case when p_success then now() else o.sent_at end,
      locked_at = null,
      locked_by = null,
      updated_at = now()
  where o.id = p_job_id
    and o.status = 'processing'
    and o.locked_by = trim(p_worker_id)
  returning o.appointment_id into target_appointment_id;

  if target_appointment_id is null then
    raise exception 'Email job is not claimed by this worker';
  end if;

  update public.appointments a
  set integration_status = case
    when not exists (
      select 1 from public.appointment_email_outbox o
      where o.appointment_id = target_appointment_id
        and o.status <> 'sent'
    ) then 'sent'
    when exists (
      select 1 from public.appointment_email_outbox o
      where o.appointment_id = target_appointment_id
        and o.status = 'permanently_failed'
    ) then 'failed'
    else 'queued'
  end
  where a.id = target_appointment_id;
end;
$$;

revoke all on function public.claim_appointment_email_jobs(integer, text)
  from public, anon, authenticated;
revoke all on function public.complete_appointment_email_job(
  uuid, text, boolean, text, text, text, timestamptz, boolean
) from public, anon, authenticated;
grant execute on function public.claim_appointment_email_jobs(integer, text)
  to service_role;
grant execute on function public.complete_appointment_email_job(
  uuid, text, boolean, text, text, text, timestamptz, boolean
) to service_role;

comment on table public.appointment_email_outbox is
  'Private durable queue for patient confirmations and clinician notifications. No Flutter client access.';
comment on column public.appointment_email_outbox.recipient_email is
  'Resolved only by the service-role worker from trusted profile/auth or clinician directory sources.';
comment on function public.claim_appointment_email_jobs(integer, text) is
  'Claims ready jobs using row locks and SKIP LOCKED; stale leases are recoverable after ten minutes.';

notify pgrst, 'reload schema';

commit;
