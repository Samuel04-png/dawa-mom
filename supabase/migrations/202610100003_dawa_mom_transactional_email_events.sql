-- Additive, private transactional-email event queue.
-- Deployment gate: requires a verified Resend sender, RESEND_API_KEY and the
-- worker secret before any Edge Function or scheduler is enabled.

begin;

create table if not exists public.dawa_mom_email_outbox (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  event_key text not null,
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
  constraint dawa_mom_email_outbox_event_check check (event_key in (
    'welcome', 'reward_unlocked', 'voucher_claimed'
  )),
  constraint dawa_mom_email_outbox_status_check check (
    status in ('pending', 'retrying', 'processing', 'sent', 'permanently_failed')
  ),
  constraint dawa_mom_email_outbox_attempt_check check (attempt_count >= 0),
  unique (profile_id, event_key)
);

create index if not exists dawa_mom_email_outbox_ready_idx
  on public.dawa_mom_email_outbox(status, next_attempt_at, created_at)
  where status in ('pending', 'retrying', 'processing');

alter table public.dawa_mom_email_outbox enable row level security;
revoke all on table public.dawa_mom_email_outbox from anon, authenticated;

create or replace function public.enqueue_dawa_mom_welcome_email()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.dawa_mom_email_outbox(profile_id, event_key)
  values (new.id, 'welcome')
  on conflict (profile_id, event_key) do nothing;
  return new;
end;
$$;

drop trigger if exists enqueue_dawa_mom_welcome_email on public.profiles;
create trigger enqueue_dawa_mom_welcome_email
after insert on public.profiles
for each row execute function public.enqueue_dawa_mom_welcome_email();

create or replace function public.enqueue_dawa_mom_voucher_emails()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'claimed' then
    insert into public.dawa_mom_email_outbox(profile_id, event_key)
    values (new.profile_id, 'voucher_claimed')
    on conflict (profile_id, event_key) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists enqueue_dawa_mom_voucher_emails
  on public.dawa_mom_reward_redemptions;
create trigger enqueue_dawa_mom_voucher_emails
after insert on public.dawa_mom_reward_redemptions
for each row execute function public.enqueue_dawa_mom_voucher_emails();

-- The existing, server-owned 1,000-point reward threshold is the only
-- eligibility event handled here. This trigger cannot be reached through a
-- Flutter balance update because clients do not have coin-balance write
-- permission.
create or replace function public.enqueue_dawa_mom_reward_unlocked_email()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.coin_balance < 1000 and new.coin_balance >= 1000 then
    insert into public.dawa_mom_email_outbox(profile_id, event_key)
    values (new.profile_id, 'reward_unlocked')
    on conflict (profile_id, event_key) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists enqueue_dawa_mom_reward_unlocked_email
  on public.dawa_mom_learning_state;
create trigger enqueue_dawa_mom_reward_unlocked_email
after update of coin_balance on public.dawa_mom_learning_state
for each row execute function public.enqueue_dawa_mom_reward_unlocked_email();

-- Appointment requests retain their existing appointment_email_outbox. This
-- trigger adds only patient-facing confirmed/cancelled lifecycle messages.
create or replace function public.enqueue_appointment_lifecycle_email()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.status is distinct from new.status
     and new.status in ('confirmed', 'cancelled') then
    insert into public.appointment_email_outbox(
      appointment_id, recipient_kind, template_key
    ) values (
      new.id, 'patient', 'appointment_' || new.status
    ) on conflict (appointment_id, recipient_kind, template_key) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists enqueue_appointment_lifecycle_email on public.appointments;
create trigger enqueue_appointment_lifecycle_email
after update of status on public.appointments
for each row execute function public.enqueue_appointment_lifecycle_email();

-- A trusted scheduler may enqueue a reminder only for an active, confirmed
-- appointment whose owner opted into email. No scheduler is created here.
create or replace function public.enqueue_due_dawa_mom_appointment_reminders(
  p_today date default current_date
)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_count integer;
begin
  insert into public.appointment_email_outbox(
    appointment_id, recipient_kind, template_key
  )
  select reminder.appointment_id, 'patient', 'appointment_reminder'
  from public.dawa_mom_appointment_reminders reminder
  join public.appointments appointment on appointment.id = reminder.appointment_id
  where reminder.enabled
    and reminder.email_notification
    and appointment.status in ('confirmed', 'rescheduled')
    and appointment.appointment_date = p_today + reminder.days_before
  on conflict (appointment_id, recipient_kind, template_key) do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.claim_dawa_mom_email_jobs(
  p_limit integer,
  p_worker_id text
)
returns setof public.dawa_mom_email_outbox
language plpgsql security definer set search_path = public as $$
begin
  if p_worker_id is null or length(trim(p_worker_id)) < 8 then
    raise exception 'A valid worker id is required';
  end if;
  return query
  with candidates as (
    select id from public.dawa_mom_email_outbox
    where (status in ('pending', 'retrying') and next_attempt_at <= now())
       or (status = 'processing' and locked_at < now() - interval '10 minutes')
    order by next_attempt_at, created_at
    for update skip locked
    limit greatest(1, least(coalesce(p_limit, 10), 50))
  )
  update public.dawa_mom_email_outbox queue
  set status = 'processing', attempt_count = queue.attempt_count + 1,
      locked_at = now(), locked_by = trim(p_worker_id), updated_at = now()
  from candidates
  where queue.id = candidates.id
  returning queue.*;
end;
$$;

create or replace function public.complete_dawa_mom_email_job(
  p_job_id uuid, p_worker_id text, p_success boolean,
  p_provider_message_id text default null, p_error text default null,
  p_retry_at timestamptz default null, p_permanent boolean default false
)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.dawa_mom_email_outbox
  set status = case when p_success then 'sent' when p_permanent then 'permanently_failed' else 'retrying' end,
      provider_message_id = case when p_success then nullif(trim(p_provider_message_id), '') else provider_message_id end,
      last_error = case when p_success then null else left(coalesce(nullif(trim(p_error), ''), 'Delivery failed'), 2000) end,
      next_attempt_at = case when p_success or p_permanent then next_attempt_at else coalesce(p_retry_at, now() + interval '15 minutes') end,
      sent_at = case when p_success then now() else sent_at end,
      locked_at = null, locked_by = null, updated_at = now()
  where id = p_job_id and status = 'processing' and locked_by = trim(p_worker_id);
  if not found then raise exception 'Email job is not claimed by this worker'; end if;
end;
$$;

revoke all on function public.enqueue_due_dawa_mom_appointment_reminders(date)
  from public, anon, authenticated;
revoke all on function public.claim_dawa_mom_email_jobs(integer, text)
  from public, anon, authenticated;
revoke all on function public.complete_dawa_mom_email_job(uuid, text, boolean, text, text, timestamptz, boolean)
  from public, anon, authenticated;
grant execute on function public.claim_dawa_mom_email_jobs(integer, text) to service_role;
grant execute on function public.complete_dawa_mom_email_job(uuid, text, boolean, text, text, timestamptz, boolean) to service_role;

comment on table public.dawa_mom_email_outbox is
  'Private, idempotent transactional email queue. Flutter never accesses recipient addresses or delivery state.';

notify pgrst, 'reload schema';

commit;
