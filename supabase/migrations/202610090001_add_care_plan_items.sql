-- Server-owned, patient-safe care-plan foundation shared by Dawa Mom and
-- Dawa Clinician. This migration deliberately contains no clinical decision
-- rules: it stores care that an approved source has already created.
--
-- Existing-data impact:
--   Additive table, indexes, functions and triggers only. Existing appointments
--   are represented once as scheduled care items without changing appointment
--   status or clinical data.
--
-- Rollback:
--   Disable the enqueue and appointment triggers first. Keep rows and outbox
--   evidence for reconciliation; removing them would discard care history.

begin;

create table if not exists public.care_plan_items (
  id uuid primary key default extensions.gen_random_uuid(),
  -- `mother_id` is the established clinical patient identity. `patient_id`
  -- retains the auth/profile identity used by Dawa Mom ownership policies.
  mother_id uuid not null references public.mothers(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  care_type text not null,
  title text not null,
  description text,
  status text not null default 'recommended',
  priority text not null default 'routine',
  due_at timestamptz,
  scheduled_at timestamptz,
  completed_at timestamptz,
  source text not null,
  source_record_id text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  dawa_clinician_care_item_id text,
  integration_status text not null default 'pending',
  integration_synced_at timestamptz,
  integration_error_code text,
  constraint care_plan_items_type_check check (
    care_type in (
      'anc_visit', 'appointment', 'screening', 'screening_followup',
      'postpartum_visit', 'vaccination', 'learning', 'care_instruction',
      'callback', 'clinical_followup', 'other'
    )
  ),
  constraint care_plan_items_status_check check (
    status in (
      'recommended', 'due', 'scheduled', 'completed', 'overdue',
      'cancelled', 'dismissed'
    )
  ),
  constraint care_plan_items_priority_check check (
    priority in ('routine', 'standard', 'high', 'urgent')
  ),
  constraint care_plan_items_source_check check (
    source in (
      'appointment', 'clinician', 'pregnancy', 'encounter', 'screening',
      'learning', 'system', 'migration'
    )
  ),
  constraint care_plan_items_title_check check (length(trim(title)) >= 3),
  constraint care_plan_items_description_check check (
    description is null or length(description) <= 4000
  ),
  constraint care_plan_items_completed_at_check check (
    status <> 'completed' or completed_at is not null
  ),
  constraint care_plan_items_integration_status_check check (
    integration_status in ('pending', 'queued', 'synced', 'failed')
  )
);

create index if not exists care_plan_items_mother_status_due_idx
  on public.care_plan_items(mother_id, status, due_at, created_at desc);
create index if not exists care_plan_items_patient_status_due_idx
  on public.care_plan_items(patient_id, status, due_at, created_at desc);
create index if not exists care_plan_items_clinic_status_idx
  on public.care_plan_items(clinic_id, status, due_at)
  where clinic_id is not null;
create unique index if not exists care_plan_items_appointment_uidx
  on public.care_plan_items(appointment_id)
  where appointment_id is not null;
create unique index if not exists care_plan_items_source_record_uidx
  on public.care_plan_items(mother_id, source, source_record_id)
  where source_record_id is not null;
create unique index if not exists care_plan_items_clinician_id_uidx
  on public.care_plan_items(dawa_clinician_care_item_id)
  where dawa_clinician_care_item_id is not null;
create index if not exists care_plan_items_pending_sync_idx
  on public.care_plan_items(integration_status, updated_at)
  where integration_status <> 'synced';

drop trigger if exists set_care_plan_items_updated_at on public.care_plan_items;
create trigger set_care_plan_items_updated_at
  before update on public.care_plan_items
  for each row execute function public.set_updated_at();

-- A care item must always retain the ownership pair used throughout Dawa Mom.
-- Authenticated patients are read-only here: dismissal/completion is a future
-- server-confirmed workflow, rather than an optimistic client mutation.
create or replace function public.guard_care_plan_item_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  expected_patient_id uuid;
  bypass boolean := coalesce(
    current_setting('dawa.care_plan_transition', true), ''
  ) = 'allowed';
begin
  if tg_op <> 'DELETE' then
    select m.profile_id into expected_patient_id
    from public.mothers m
    where m.id = new.mother_id;

    if expected_patient_id is null or new.patient_id <> expected_patient_id then
      raise exception using
        errcode = '23514',
        message = 'Care item patient profile does not match the mother profile';
    end if;
  end if;

  if bypass or auth.uid() is null or public.is_admin() then
    return coalesce(new, old);
  end if;

  if public.current_app_role() = 'patient'::public.app_role then
    raise exception using
      errcode = '42501',
      message = 'Patients cannot change server-owned care items';
  end if;

  if public.is_doctor() then
    if tg_op = 'INSERT' then
      if new.created_by is distinct from auth.uid()
         or new.source <> 'clinician' then
        raise exception using
          errcode = '42501',
          message = 'Clinician-created care items must retain clinician provenance';
      end if;
    elsif old.created_by is distinct from new.created_by
       or old.source is distinct from new.source
       or old.mother_id is distinct from new.mother_id
       or old.patient_id is distinct from new.patient_id
       or old.appointment_id is distinct from new.appointment_id
       or old.source_record_id is distinct from new.source_record_id
       or old.dawa_clinician_care_item_id is distinct from new.dawa_clinician_care_item_id
       or old.integration_status is distinct from new.integration_status
       or old.integration_synced_at is distinct from new.integration_synced_at
       or old.integration_error_code is distinct from new.integration_error_code then
      raise exception using
        errcode = '42501',
        message = 'Care item provenance and integration fields are server managed';
    end if;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists guard_care_plan_item_write on public.care_plan_items;
create trigger guard_care_plan_item_write
  before insert or update or delete on public.care_plan_items
  for each row execute function public.guard_care_plan_item_write();

-- Explicitly reject impossible lifecycle reversals. The worker/service role can
-- use the scoped transition flag when applying a trusted external update.
create or replace function public.guard_care_plan_item_transition()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  if old.status in ('completed', 'cancelled', 'dismissed')
     and coalesce(current_setting('dawa.care_plan_transition', true), '') <> 'allowed' then
    raise exception using
      errcode = '23514',
      message = 'A terminal care item cannot be reopened without a server transition';
  end if;

  if new.status = 'completed' and new.completed_at is null then
    new.completed_at := now();
  elsif new.status <> 'completed' and old.status <> 'completed' then
    new.completed_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_care_plan_item_transition on public.care_plan_items;
create trigger guard_care_plan_item_transition
  before update of status, completed_at on public.care_plan_items
  for each row execute function public.guard_care_plan_item_transition();

alter table public.care_plan_items enable row level security;
revoke all on table public.care_plan_items from anon;
grant select, insert, update, delete on public.care_plan_items
  to authenticated, service_role;

create policy care_plan_items_select_allowed
  on public.care_plan_items
  for select
  to authenticated
  using (
    public.is_admin()
    or (
      public.is_doctor()
      and public.doctor_assigned_to_mother(mother_id)
    )
    or (
      patient_id = auth.uid()
      and public.owns_mother(mother_id)
    )
  );

create policy care_plan_items_clinician_insert
  on public.care_plan_items
  for insert
  to authenticated
  with check (
    public.is_admin()
    or (
      public.is_doctor()
      and public.doctor_assigned_to_mother(mother_id)
      and source = 'clinician'
      and created_by = auth.uid()
    )
  );

create policy care_plan_items_clinician_update
  on public.care_plan_items
  for update
  to authenticated
  using (
    public.is_admin()
    or (
      public.is_doctor()
      and public.doctor_assigned_to_mother(mother_id)
    )
  )
  with check (
    public.is_admin()
    or (
      public.is_doctor()
      and public.doctor_assigned_to_mother(mother_id)
    )
  );

create policy care_plan_items_clinician_delete
  on public.care_plan_items
  for delete
  to authenticated
  using (
    public.is_admin()
    or (
      public.is_doctor()
      and public.doctor_assigned_to_mother(mother_id)
    )
  );

-- Appointment booking is an approved product workflow, so it is the first and
-- only automatic recommendation source. It creates one linked item, not a
-- clinical recommendation, and mirrors appointment lifecycle truthfully.
create or replace function public.sync_appointment_care_plan_item()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  item_status text;
  item_completed_at timestamptz;
  item_due_at timestamptz;
  item_title text;
begin
  perform set_config('dawa.care_plan_transition', 'allowed', true);

  item_status := case new.status
    when 'completed' then 'completed'
    when 'cancelled', 'declined', 'missed' then 'cancelled'
    else 'scheduled'
  end;
  item_completed_at := case when item_status = 'completed' then now() else null end;
  item_due_at := (new.appointment_date + new.start_time) at time zone 'Africa/Lusaka';
  item_title := initcap(replace(new.appointment_type, '_', ' ')) || ' appointment';

  insert into public.care_plan_items (
    mother_id, patient_id, clinic_id, appointment_id, care_type, title,
    status, priority, due_at, scheduled_at, completed_at, source,
    source_record_id, created_by
  ) values (
    new.mother_id, new.patient_id, new.clinic_id, new.id, 'appointment',
    item_title, item_status, 'standard', item_due_at, item_due_at,
    item_completed_at, 'appointment', new.id::text, null
  )
  on conflict (appointment_id) where appointment_id is not null do update
  set clinic_id = excluded.clinic_id,
      title = excluded.title,
      status = excluded.status,
      due_at = excluded.due_at,
      scheduled_at = excluded.scheduled_at,
      completed_at = excluded.completed_at;

  return new;
end;
$$;

drop trigger if exists sync_appointment_care_plan_item on public.appointments;
create trigger sync_appointment_care_plan_item
  after insert or update of status, appointment_date, start_time,
    appointment_type, clinic_id on public.appointments
  for each row execute function public.sync_appointment_care_plan_item();

-- Date-based state maintenance is intentionally service-role-only. A scheduler
-- may call it; Flutter never marks care overdue merely because a device clock
-- says so. Appointment items are excluded because a missed visit must be
-- confirmed by its appointment lifecycle, not inferred from time passing.
create or replace function public.mark_overdue_care_plan_items(
  p_limit integer default 500
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  changed_count integer;
begin
  perform set_config('dawa.care_plan_transition', 'allowed', true);
  with candidates as (
    select id
    from public.care_plan_items
    where appointment_id is null
      and status in ('recommended', 'due')
      and due_at is not null
      and due_at < now()
    order by due_at
    limit greatest(1, least(coalesce(p_limit, 500), 5000))
    for update skip locked
  )
  update public.care_plan_items item
  set status = 'overdue'
  from candidates
  where item.id = candidates.id;
  get diagnostics changed_count = row_count;
  return changed_count;
end;
$$;

revoke all on function public.mark_overdue_care_plan_items(integer)
  from public, anon, authenticated;
grant execute on function public.mark_overdue_care_plan_items(integer)
  to service_role;

-- Reuse, rather than replace, the durable Dawa Clinician integration outbox.
alter table public.integration_outbox
  drop constraint if exists integration_outbox_event_type_check;
alter table public.integration_outbox
  add constraint integration_outbox_event_type_check check (
    event_type in (
      'patient.upsert', 'patient.archived',
      'appointment.created', 'appointment.cancelled',
      'risk_alert.upsert', 'risk_alert.archived',
      'care_item.upsert', 'care_item.archived'
    )
  );

alter table public.integration_outbox
  drop constraint if exists integration_outbox_aggregate_type_check;
alter table public.integration_outbox
  add constraint integration_outbox_aggregate_type_check check (
    aggregate_type in ('mother', 'appointment', 'risk_alert', 'care_item')
  );

create or replace function public.build_dawa_mom_care_item_sync_payload_from_row(
  p_item jsonb,
  p_effective_at timestamptz default null,
  p_source_deleted_at timestamptz default null
)
returns jsonb
language plpgsql
stable
set search_path = public
as $$
declare
  source_updated_at timestamptz;
  patient_mapping text;
begin
  if p_item is null or jsonb_typeof(p_item) <> 'object' then
    raise exception using errcode = '22023', message = 'Care item row is required';
  end if;
  source_updated_at := nullif(p_item ->> 'updated_at', '')::timestamptz;
  select m.dawa_clinician_patient_id into patient_mapping
  from public.mothers m
  where m.id = nullif(p_item ->> 'mother_id', '')::uuid;

  return jsonb_build_object(
    'source', 'dawa_mom',
    'source_care_item_id', p_item ->> 'id',
    'source_mother_id', p_item ->> 'mother_id',
    'dawa_clinician_patient_id', patient_mapping,
    'care_type', p_item ->> 'care_type',
    'title', p_item ->> 'title',
    'description', p_item ->> 'description',
    'status', p_item ->> 'status',
    'priority', p_item ->> 'priority',
    'due_at', p_item -> 'due_at',
    'scheduled_at', p_item -> 'scheduled_at',
    'completed_at', p_item -> 'completed_at',
    'source_type', p_item ->> 'source',
    'source_record_id', p_item ->> 'source_record_id',
    'source_appointment_id', p_item ->> 'appointment_id',
    'source_clinic_id', p_item ->> 'clinic_id',
    'created_by', p_item ->> 'created_by',
    'source_created_at', p_item -> 'created_at',
    'source_updated_at', greatest(
      coalesce(source_updated_at, to_timestamp(0)),
      coalesce(p_effective_at, source_updated_at, now())
    ),
    'source_deleted_at', p_source_deleted_at,
    'source_record', p_item
  );
end;
$$;

create or replace function public.enqueue_dawa_mom_care_item_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  effective_at timestamptz;
begin
  if coalesce(current_setting('dawa.integration_transition', true), '') = 'allowed' then
    return coalesce(new, old);
  end if;
  effective_at := case when tg_op = 'DELETE' then now() else new.updated_at end;
  insert into public.integration_outbox (
    event_type, aggregate_type, aggregate_id, payload
  ) values (
    case when tg_op = 'DELETE' then 'care_item.archived' else 'care_item.upsert' end,
    'care_item',
    coalesce(new.id, old.id),
    public.build_dawa_mom_care_item_sync_payload_from_row(
      to_jsonb(coalesce(new, old)),
      effective_at,
      case when tg_op = 'DELETE' then effective_at else null end
    )
  );
  return coalesce(new, old);
end;
$$;

drop trigger if exists enqueue_dawa_mom_care_item_sync on public.care_plan_items;
create trigger enqueue_dawa_mom_care_item_sync
  after insert or delete or update of mother_id, patient_id, clinic_id,
    appointment_id, care_type, title, description, status, priority, due_at,
    scheduled_at, completed_at, source, source_record_id, created_by
  on public.care_plan_items
  for each row execute function public.enqueue_dawa_mom_care_item_sync();

create or replace function public.claim_dawa_platform_outbox_events(
  p_limit integer,
  p_worker_id text
)
returns setof public.integration_outbox
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
    from public.integration_outbox o
    where (
      (o.status in ('pending', 'retrying') and o.next_attempt_at <= now())
      or (o.status = 'processing' and o.processing_started_at < now() - interval '10 minutes')
    ) and not exists (
      select 1
      from public.integration_outbox earlier
      where earlier.aggregate_type = o.aggregate_type
        and earlier.aggregate_id = o.aggregate_id
        and (earlier.created_at, earlier.id) < (o.created_at, o.id)
        and (
          (o.aggregate_type = 'appointment' and earlier.status <> 'completed')
          or (
            o.aggregate_type in ('mother', 'risk_alert', 'care_item')
            and earlier.status not in ('completed', 'permanently_failed')
          )
        )
    )
    order by o.next_attempt_at, o.created_at
    for update skip locked
    limit greatest(1, least(coalesce(p_limit, 10), 50))
  )
  update public.integration_outbox o
  set status = 'processing',
      attempt_count = o.attempt_count + 1,
      processing_started_at = now(),
      locked_by = trim(p_worker_id),
      updated_at = now()
  from candidates c
  where o.id = c.id
  returning o.*;
end;
$$;

create or replace function public.complete_dawa_platform_outbox_event(
  p_job_id uuid,
  p_worker_id text,
  p_success boolean,
  p_destination_id text default null,
  p_error_code text default null,
  p_retry_at timestamptz default null,
  p_permanent boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_event public.integration_outbox%rowtype;
  final_status text;
  safe_error_code text;
begin
  perform set_config('dawa.integration_transition', 'allowed', true);
  final_status := case
    when p_success then 'completed'
    when p_permanent then 'permanently_failed'
    else 'retrying'
  end;
  safe_error_code := left(nullif(trim(p_error_code), ''), 120);
  update public.integration_outbox o
  set status = final_status,
      destination_id = case when p_success then coalesce(nullif(trim(p_destination_id), ''), o.destination_id) else o.destination_id end,
      last_error_code = case when p_success then null else safe_error_code end,
      next_attempt_at = case when p_success or p_permanent then o.next_attempt_at else coalesce(p_retry_at, now() + interval '15 minutes') end,
      processing_started_at = null,
      locked_by = null,
      processed_at = case when p_success or p_permanent then now() else null end,
      updated_at = now()
  where o.id = p_job_id and o.status = 'processing' and o.locked_by = trim(p_worker_id)
  returning o.* into target_event;
  if target_event.id is null then
    raise exception 'Integration event is not claimed by this worker';
  end if;

  if target_event.aggregate_type = 'care_item' then
    perform set_config('dawa.care_plan_transition', 'allowed', true);
    update public.care_plan_items item
    set dawa_clinician_care_item_id = case
          when p_success then coalesce(nullif(trim(p_destination_id), ''), item.dawa_clinician_care_item_id)
          else item.dawa_clinician_care_item_id
        end,
        integration_status = case
          when p_success then 'synced'
          when p_permanent then 'failed'
          else 'queued'
        end,
        integration_synced_at = case when p_success then now() else item.integration_synced_at end,
        integration_error_code = case when p_success then null else safe_error_code end
    where item.id = target_event.aggregate_id;
  elsif target_event.aggregate_type = 'mother' then
    update public.mothers m
    set dawa_clinician_patient_id = case when p_success then coalesce(nullif(trim(p_destination_id), ''), m.dawa_clinician_patient_id) else m.dawa_clinician_patient_id end,
        dawa_clinician_synced_at = case when p_success then now() else m.dawa_clinician_synced_at end,
        dawa_clinician_sync_error_code = case when p_success then null else safe_error_code end
    where m.id = target_event.aggregate_id;
  elsif target_event.aggregate_type = 'appointment' then
    update public.appointments a
    set dawa_clinician_appointment_id = case when p_success then coalesce(nullif(trim(p_destination_id), ''), a.dawa_clinician_appointment_id) else a.dawa_clinician_appointment_id end,
        external_appointment_id = case when p_success then coalesce(nullif(trim(p_destination_id), ''), a.external_appointment_id) else a.external_appointment_id end,
        integration_status = case when p_success then 'synced' when p_permanent then 'failed' else 'queued' end,
        integration_synced_at = case when p_success then now() else a.integration_synced_at end,
        integration_error_code = case when p_success then null else safe_error_code end
    where a.id = target_event.aggregate_id;
  elsif target_event.aggregate_type = 'risk_alert' then
    update public.clinician_risk_alerts a
    set dawa_clinician_alert_id = case when p_success then coalesce(nullif(trim(p_destination_id), ''), a.dawa_clinician_alert_id) else a.dawa_clinician_alert_id end,
        integration_status = case when p_success then 'synced' when p_permanent then 'failed' else 'queued' end,
        integration_synced_at = case when p_success then now() else a.integration_synced_at end,
        integration_error_code = case when p_success then null else safe_error_code end
    where a.id = target_event.aggregate_id;
  end if;
end;
$$;

revoke all on function public.claim_dawa_platform_outbox_events(integer, text)
  from public, anon, authenticated;
revoke all on function public.complete_dawa_platform_outbox_event(
  uuid, text, boolean, text, text, timestamptz, boolean
) from public, anon, authenticated;
grant execute on function public.claim_dawa_platform_outbox_events(integer, text)
  to service_role;
grant execute on function public.complete_dawa_platform_outbox_event(
  uuid, text, boolean, text, text, timestamptz, boolean
) to service_role;

-- Queue a repeatable-safe backfill for existing appointments. Generic care
-- recommendations are intentionally not generated here.
insert into public.care_plan_items (
  mother_id, patient_id, clinic_id, appointment_id, care_type, title, status,
  priority, due_at, scheduled_at, completed_at, source, source_record_id
)
select
  a.mother_id,
  a.patient_id,
  a.clinic_id,
  a.id,
  'appointment',
  initcap(replace(a.appointment_type, '_', ' ')) || ' appointment',
  case
    when a.status = 'completed' then 'completed'
    when a.status in ('cancelled', 'declined', 'missed') then 'cancelled'
    else 'scheduled'
  end,
  'standard',
  (a.appointment_date + a.start_time) at time zone 'Africa/Lusaka',
  (a.appointment_date + a.start_time) at time zone 'Africa/Lusaka',
  case when a.status = 'completed' then coalesce(a.updated_at, now()) else null end,
  'appointment',
  a.id::text
from public.appointments a
on conflict (appointment_id) where appointment_id is not null do nothing;

comment on table public.care_plan_items is
  'Server-owned patient care-plan items. These coordinate approved care work; they do not diagnose or generate medical recommendations.';
comment on column public.care_plan_items.source_record_id is
  'Stable source-system identifier retained for traceability and duplicate prevention.';
comment on function public.mark_overdue_care_plan_items(integer) is
  'Service-role-only date lifecycle maintenance. Schedule only after operational review.';

commit;
