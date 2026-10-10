-- Dawa Mom side of the cross-project Dawa platform integration.
--
-- Purpose:
--   * retain stable Dawa Clinician patient/clinic/clinician/appointment mappings
--   * create a private, durable integration outbox with recoverable leases
--   * enqueue only usable mother profiles and committed appointment requests
--   * accept idempotent, validated appointment status callbacks
--   * keep the authoritative clinician directory behind a server-written cache
--
-- Existing-data impact:
--   Additive nullable columns and new private tables/functions/triggers only.
--   Existing clinician cache identifiers are backfilled only when the legacy ID
--   is already a valid UUID. No patient, appointment, encounter, or email job is
--   deleted or rewritten.
--
-- RLS impact:
--   RLS remains enabled. The outbox and receiver ledger intentionally have no
--   Flutter-facing policies. Existing patient appointment policies remain in
--   place; guard triggers additionally protect integration-owned columns.
--
-- Backfill:
--   Existing usable mothers are not automatically enqueued. Use the reviewed
--   backfill tool in dry-run/small-batch mode after receiver deployment.
--
-- Rollback:
--   Disable the worker schedule and rotate the directional secrets. Keep the
--   additive mapping/audit data in place and forward-fix; dropping it would
--   destroy reconciliation evidence and requires explicit approval.

begin;

alter table public.mothers
  add column if not exists dawa_clinician_patient_id text,
  add column if not exists dawa_clinician_synced_at timestamptz,
  add column if not exists dawa_clinician_sync_error_code text;

alter table public.clinics
  add column if not exists dawa_clinician_clinic_id uuid,
  add column if not exists directory_synced_at timestamptz;

alter table public.doctors
  add column if not exists dawa_clinician_clinician_id uuid,
  add column if not exists directory_synced_at timestamptz;

alter table public.appointments
  add column if not exists dawa_clinician_appointment_id text,
  add column if not exists integration_synced_at timestamptz,
  add column if not exists integration_error_code text,
  add column if not exists patient_safe_status_message text,
  add column if not exists email_delivery_status text not null default 'pending';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'appointments_email_delivery_status_check'
      and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_email_delivery_status_check check (
        email_delivery_status in (
          'pending', 'queued', 'sent', 'failed', 'permanently_failed'
        )
      );
  end if;
end $$;

create unique index if not exists mothers_dawa_clinician_patient_id_uidx
  on public.mothers(dawa_clinician_patient_id)
  where dawa_clinician_patient_id is not null;

create unique index if not exists clinics_dawa_clinician_clinic_id_uidx
  on public.clinics(dawa_clinician_clinic_id)
  where dawa_clinician_clinic_id is not null;

create unique index if not exists appointments_dawa_clinician_id_uidx
  on public.appointments(dawa_clinician_appointment_id)
  where dawa_clinician_appointment_id is not null;

-- Preserve a provable pre-existing mapping only when the imported legacy ID is
-- already the UUID contract used by Dawa Clinician. Names are never matched.
with legacy_mapping_candidates as (
  select id, legacy_doctor_id::uuid as external_id
  from public.doctors
  where dawa_clinician_clinician_id is null
    and legacy_doctor_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
), unambiguous_legacy_mappings as (
  select external_id
  from legacy_mapping_candidates
  group by external_id
  having count(*) = 1
)
update public.doctors d
set dawa_clinician_clinician_id = candidate.external_id
from legacy_mapping_candidates candidate
join unambiguous_legacy_mappings unambiguous
  on unambiguous.external_id = candidate.external_id
where d.id = candidate.id
  and not exists (
    select 1
    from public.doctors already_mapped
    where already_mapped.dawa_clinician_clinician_id = candidate.external_id
  );

create unique index if not exists doctors_dawa_clinician_clinician_id_uidx
  on public.doctors(dawa_clinician_clinician_id)
  where dawa_clinician_clinician_id is not null;

create table if not exists public.integration_outbox (
  id uuid primary key default extensions.gen_random_uuid(),
  event_id uuid not null default extensions.gen_random_uuid(),
  event_type text not null,
  aggregate_type text not null,
  aggregate_id uuid not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  processing_started_at timestamptz,
  locked_by text,
  destination_id text,
  last_error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  processed_at timestamptz,
  constraint integration_outbox_event_id_unique unique (event_id),
  constraint integration_outbox_event_type_check check (
    event_type in (
      'patient.upsert',
      'patient.archived',
      'appointment.created',
      'appointment.cancelled'
    )
  ),
  constraint integration_outbox_aggregate_type_check check (
    aggregate_type in ('mother', 'appointment')
  ),
  constraint integration_outbox_status_check check (
    status in (
      'pending',
      'processing',
      'completed',
      'retrying',
      'failed',
      'permanently_failed'
    )
  ),
  constraint integration_outbox_attempt_count_check check (attempt_count >= 0),
  constraint integration_outbox_payload_object_check check (
    jsonb_typeof(payload) = 'object'
  )
);

create index if not exists integration_outbox_ready_idx
  on public.integration_outbox(status, next_attempt_at, created_at)
  where status in ('pending', 'retrying', 'processing');

create index if not exists integration_outbox_aggregate_idx
  on public.integration_outbox(aggregate_type, aggregate_id, created_at desc);

alter table public.integration_outbox enable row level security;
revoke all on table public.integration_outbox from anon, authenticated;

create table if not exists public.processed_integration_events (
  id uuid primary key default extensions.gen_random_uuid(),
  source text not null,
  event_id uuid not null,
  event_type text not null,
  aggregate_id uuid,
  destination_id text,
  result jsonb not null default '{}'::jsonb,
  processed_at timestamptz not null default now(),
  constraint processed_integration_events_source_event_unique
    unique (source, event_id),
  constraint processed_integration_events_result_object_check check (
    jsonb_typeof(result) = 'object'
  )
);

alter table public.processed_integration_events enable row level security;
revoke all on table public.processed_integration_events from anon, authenticated;

create or replace function public.dawa_mom_mother_is_syncable(
  target public.mothers
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    target.profile_id is not null
    and length(trim(coalesce(target.name, ''))) >= 2
    and target.date_of_birth is not null
    and (
      length(regexp_replace(coalesce(target.phone_number, ''), '[^0-9]', '', 'g')) >= 8
      or exists (
        select 1
        from public.profiles p
        where p.id = target.profile_id
          and length(trim(coalesce(p.email, ''))) >= 3
      )
    );
$$;

revoke all on function public.dawa_mom_mother_is_syncable(public.mothers)
  from public, anon, authenticated;

create or replace function public.enqueue_dawa_mom_patient_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_email text;
begin
  if tg_op = 'DELETE' then
    insert into public.integration_outbox (
      event_type,
      aggregate_type,
      aggregate_id,
      payload
    ) values (
      'patient.archived',
      'mother',
      old.id,
      jsonb_strip_nulls(jsonb_build_object(
        'source', 'dawa_mom',
        'source_mother_id', old.id,
        'source_user_id', old.profile_id,
        'source_updated_at', old.updated_at
      ))
    );
    return old;
  end if;

  if tg_op = 'UPDATE' and row(
    old.profile_id,
    old.name,
    old.phone_number,
    old.date_of_birth,
    old.occupation,
    old.address
  ) is not distinct from row(
    new.profile_id,
    new.name,
    new.phone_number,
    new.date_of_birth,
    new.occupation,
    new.address
  ) then
    return new;
  end if;

  if not public.dawa_mom_mother_is_syncable(new) then
    return new;
  end if;

  select p.email into profile_email
  from public.profiles p
  where p.id = new.profile_id;

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  ) values (
    'patient.upsert',
    'mother',
    new.id,
    jsonb_strip_nulls(jsonb_build_object(
      'source', 'dawa_mom',
      'source_mother_id', new.id,
      'source_user_id', new.profile_id,
      'name', nullif(trim(new.name), ''),
      'phone_number', nullif(trim(new.phone_number), ''),
      'email', nullif(lower(trim(profile_email)), ''),
      'date_of_birth', new.date_of_birth,
      'occupation', nullif(trim(new.occupation), ''),
      'address', nullif(trim(new.address), ''),
      'source_updated_at', new.updated_at
    ))
  );

  return new;
end;
$$;

revoke all on function public.enqueue_dawa_mom_patient_sync() from public;

create or replace function public.retry_own_dawa_clinician_patient_sync()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  mother_row public.mothers%rowtype;
  profile_email text;
  existing_event_id uuid;
  created_event_id uuid;
begin
  if auth.uid() is null
     or public.current_app_role() is distinct from 'patient'::public.app_role then
    raise exception using errcode = '42501', message = 'Patient authentication is required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'dawa-mom-patient-retry:' || auth.uid()::text,
    0
  ));

  select * into mother_row
  from public.mothers m
  where m.profile_id = auth.uid()
  limit 1;

  if mother_row.id is null then
    raise exception using errcode = 'P0002', message = 'Mother profile was not found';
  end if;
  if not public.dawa_mom_mother_is_syncable(mother_row) then
    raise exception using errcode = '23514', message = 'Mother profile is not ready to sync';
  end if;

  select o.event_id into existing_event_id
  from public.integration_outbox o
  where o.event_type = 'patient.upsert'
    and o.aggregate_type = 'mother'
    and o.aggregate_id = mother_row.id
    and o.status in ('pending', 'processing', 'retrying')
  order by o.created_at desc
  limit 1;

  if existing_event_id is not null then
    return existing_event_id;
  end if;

  select p.email into profile_email
  from public.profiles p
  where p.id = mother_row.profile_id;

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  ) values (
    'patient.upsert',
    'mother',
    mother_row.id,
    jsonb_strip_nulls(jsonb_build_object(
      'source', 'dawa_mom',
      'source_mother_id', mother_row.id,
      'source_user_id', mother_row.profile_id,
      'name', nullif(trim(mother_row.name), ''),
      'phone_number', nullif(trim(mother_row.phone_number), ''),
      'email', nullif(lower(trim(profile_email)), ''),
      'date_of_birth', mother_row.date_of_birth,
      'occupation', nullif(trim(mother_row.occupation), ''),
      'address', nullif(trim(mother_row.address), ''),
      'source_updated_at', mother_row.updated_at
    ))
  )
  returning event_id into created_event_id;

  return created_event_id;
end;
$$;

revoke all on function public.retry_own_dawa_clinician_patient_sync()
  from public, anon;
grant execute on function public.retry_own_dawa_clinician_patient_sync()
  to authenticated;

drop trigger if exists enqueue_dawa_mom_patient_sync on public.mothers;
create trigger enqueue_dawa_mom_patient_sync
  after insert or delete or update of profile_id, name, phone_number, date_of_birth,
    occupation, address
  on public.mothers
  for each row execute function public.enqueue_dawa_mom_patient_sync();

-- Email is owned by the linked profile rather than the mother row. Enqueue a
-- fresh sanitised patient summary when that approved contact field changes.
create or replace function public.enqueue_dawa_mom_profile_email_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  mother_row public.mothers%rowtype;
begin
  if old.email is not distinct from new.email then
    return new;
  end if;

  select * into mother_row
  from public.mothers m
  where m.profile_id = new.id
  limit 1;

  if mother_row.id is null
     or not public.dawa_mom_mother_is_syncable(mother_row) then
    return new;
  end if;

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  ) values (
    'patient.upsert',
    'mother',
    mother_row.id,
    jsonb_strip_nulls(jsonb_build_object(
      'source', 'dawa_mom',
      'source_mother_id', mother_row.id,
      'source_user_id', mother_row.profile_id,
      'name', nullif(trim(mother_row.name), ''),
      'phone_number', nullif(trim(mother_row.phone_number), ''),
      'email', nullif(lower(trim(new.email)), ''),
      'date_of_birth', mother_row.date_of_birth,
      'occupation', nullif(trim(mother_row.occupation), ''),
      'address', nullif(trim(mother_row.address), ''),
      'source_updated_at', greatest(mother_row.updated_at, new.updated_at)
    ))
  );

  return new;
end;
$$;

revoke all on function public.enqueue_dawa_mom_profile_email_sync()
  from public;

drop trigger if exists enqueue_dawa_mom_profile_email_sync on public.profiles;
create trigger enqueue_dawa_mom_profile_email_sync
  after update of email on public.profiles
  for each row execute function public.enqueue_dawa_mom_profile_email_sync();

create or replace function public.enqueue_dawa_mom_appointment_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_event_type text;
  patient_mapping text;
  clinician_mapping uuid;
  clinic_mapping uuid;
begin
  if tg_op = 'INSERT' then
    target_event_type := 'appointment.created';
  elsif coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
        and auth.uid() is not null
        and public.current_app_role() = 'patient'::public.app_role
        and old.status is distinct from new.status
        and new.status = 'cancelled' then
    target_event_type := 'appointment.cancelled';
  else
    return new;
  end if;

  select m.dawa_clinician_patient_id
    into patient_mapping
  from public.mothers m
  where m.id = new.mother_id;

  select d.dawa_clinician_clinician_id
    into clinician_mapping
  from public.doctors d
  where d.id = new.clinician_id;

  select c.dawa_clinician_clinic_id
    into clinic_mapping
  from public.clinics c
  where c.id = new.clinic_id;

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  ) values (
    target_event_type,
    'appointment',
    new.id,
    jsonb_strip_nulls(jsonb_build_object(
      'source', 'dawa_mom',
      'source_appointment_id', new.id,
      'source_mother_id', new.mother_id,
      'dawa_clinician_patient_id', patient_mapping,
      'dawa_clinician_clinician_id', clinician_mapping,
      'dawa_clinician_clinic_id', clinic_mapping,
      'appointment_date', new.appointment_date,
      'start_time', new.start_time,
      'end_time', new.end_time,
      'appointment_type', new.appointment_type,
      'reason', new.reason,
      'notes', new.notes,
      'status', new.status,
      'created_at', new.created_at,
      'updated_at', new.updated_at
    ))
  );

  return new;
end;
$$;

revoke all on function public.enqueue_dawa_mom_appointment_sync() from public;

drop trigger if exists enqueue_dawa_mom_appointment_sync on public.appointments;
create trigger enqueue_dawa_mom_appointment_sync
  after insert or update of status
  on public.appointments
  for each row execute function public.enqueue_dawa_mom_appointment_sync();

create or replace function public.guard_mother_integration_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
     and auth.uid() is not null
     and public.current_app_role() = 'patient'::public.app_role then
    if old.dawa_clinician_patient_id is distinct from new.dawa_clinician_patient_id
       or old.dawa_clinician_synced_at is distinct from new.dawa_clinician_synced_at
       or old.dawa_clinician_sync_error_code is distinct from new.dawa_clinician_sync_error_code then
      raise exception using
        errcode = '42501',
        message = 'Integration mapping fields are server managed';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists guard_mother_integration_fields on public.mothers;
create trigger guard_mother_integration_fields
  before update on public.mothers
  for each row execute function public.guard_mother_integration_fields();

create or replace function public.guard_mother_integration_fields_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
     and auth.uid() is not null
     and public.current_app_role() = 'patient'::public.app_role
     and (
       new.dawa_clinician_patient_id is not null
       or new.dawa_clinician_synced_at is not null
       or new.dawa_clinician_sync_error_code is not null
     ) then
    raise exception using
      errcode = '42501',
      message = 'Integration mapping fields are server managed';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_mother_integration_fields_on_insert
  on public.mothers;
create trigger guard_mother_integration_fields_on_insert
  before insert on public.mothers
  for each row execute function public.guard_mother_integration_fields_on_insert();

create or replace function public.guard_patient_appointment_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
     and auth.uid() is not null
     and public.current_app_role() = 'patient'::public.app_role then
    if old.patient_id <> auth.uid() then
      raise exception using errcode = '42501', message = 'Appointment is not owned by this patient';
    end if;

    if old.status not in ('pending', 'confirmed', 'rescheduled')
       or new.status <> 'cancelled' then
      raise exception using errcode = '42501', message = 'This appointment cannot be cancelled';
    end if;

    if old.mother_id is distinct from new.mother_id
       or old.patient_id is distinct from new.patient_id
       or old.clinician_id is distinct from new.clinician_id
       or old.clinic_id is distinct from new.clinic_id
       or old.appointment_date is distinct from new.appointment_date
       or old.start_time is distinct from new.start_time
       or old.end_time is distinct from new.end_time
       or old.appointment_type is distinct from new.appointment_type
       or old.reason is distinct from new.reason
       or old.notes is distinct from new.notes
       or old.source is distinct from new.source
       or old.created_by is distinct from new.created_by
       or old.created_at is distinct from new.created_at
       or old.integration_status is distinct from new.integration_status
       or old.external_appointment_id is distinct from new.external_appointment_id
       or old.dawa_clinician_appointment_id is distinct from new.dawa_clinician_appointment_id
       or old.integration_synced_at is distinct from new.integration_synced_at
       or old.integration_error_code is distinct from new.integration_error_code
       or old.patient_safe_status_message is distinct from new.patient_safe_status_message
       or old.email_delivery_status is distinct from new.email_delivery_status then
      raise exception using errcode = '42501', message = 'Patients may only cancel eligible appointments';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.guard_patient_appointment_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
     and auth.uid() is not null
     and public.current_app_role() = 'patient'::public.app_role
     and (
       new.external_appointment_id is not null
       or new.dawa_clinician_appointment_id is not null
       or new.integration_synced_at is not null
       or new.integration_error_code is not null
       or new.patient_safe_status_message is not null
       or new.email_delivery_status <> 'pending'
     ) then
    raise exception using
      errcode = '42501',
      message = 'Appointment integration fields are server managed';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_patient_appointment_insert
  on public.appointments;
create trigger guard_patient_appointment_insert
  before insert on public.appointments
  for each row execute function public.guard_patient_appointment_insert();

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
      (
        o.status in ('pending', 'retrying')
        and o.next_attempt_at <= now()
      ) or (
        o.status = 'processing'
        and o.processing_started_at < now() - interval '10 minutes'
      )
    )
      and not exists (
        select 1
        from public.integration_outbox earlier
        where earlier.aggregate_type = o.aggregate_type
          and earlier.aggregate_id = o.aggregate_id
          and (earlier.created_at, earlier.id) < (o.created_at, o.id)
          and (
            (o.aggregate_type = 'appointment' and earlier.status <> 'completed')
            or (
              o.aggregate_type = 'mother'
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

  safe_error_code := left(nullif(trim(p_error_code), ''), 120);
  final_status := case
    when p_success then 'completed'
    when p_permanent then 'permanently_failed'
    else 'retrying'
  end;

  update public.integration_outbox o
  set status = final_status,
      destination_id = case
        when p_success then coalesce(nullif(trim(p_destination_id), ''), o.destination_id)
        else o.destination_id
      end,
      last_error_code = case when p_success then null else safe_error_code end,
      next_attempt_at = case
        when p_success or p_permanent then o.next_attempt_at
        else coalesce(p_retry_at, now() + interval '15 minutes')
      end,
      processing_started_at = null,
      locked_by = null,
      processed_at = case when p_success or p_permanent then now() else null end,
      updated_at = now()
  where o.id = p_job_id
    and o.status = 'processing'
    and o.locked_by = trim(p_worker_id)
  returning o.* into target_event;

  if target_event.id is null then
    raise exception 'Integration event is not claimed by this worker';
  end if;

  if target_event.aggregate_type = 'mother' then
    update public.mothers m
    set dawa_clinician_patient_id = case
          when p_success then coalesce(nullif(trim(p_destination_id), ''), m.dawa_clinician_patient_id)
          else m.dawa_clinician_patient_id
        end,
        dawa_clinician_synced_at = case when p_success then now() else m.dawa_clinician_synced_at end,
        dawa_clinician_sync_error_code = case when p_success then null else safe_error_code end
    where m.id = target_event.aggregate_id;
  elsif target_event.aggregate_type = 'appointment' then
    update public.appointments a
    set dawa_clinician_appointment_id = case
          when p_success then coalesce(nullif(trim(p_destination_id), ''), a.dawa_clinician_appointment_id)
          else a.dawa_clinician_appointment_id
        end,
        external_appointment_id = case
          when p_success then coalesce(nullif(trim(p_destination_id), ''), a.external_appointment_id)
          else a.external_appointment_id
        end,
        integration_status = case
          when p_success then 'synced'
          when p_permanent then 'failed'
          else 'queued'
        end,
        integration_synced_at = case when p_success then now() else a.integration_synced_at end,
        integration_error_code = case when p_success then null else safe_error_code end
    where a.id = target_event.aggregate_id;
  end if;
end;
$$;

create or replace function public.record_dawa_clinician_patient_mapping(
  p_mother_id uuid,
  p_patient_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform set_config('dawa.integration_transition', 'allowed', true);

  if nullif(trim(p_patient_id), '') is null then
    raise exception using errcode = '22023', message = 'Patient mapping is required';
  end if;

  update public.mothers m
  set dawa_clinician_patient_id = trim(p_patient_id),
      dawa_clinician_synced_at = now(),
      dawa_clinician_sync_error_code = null
  where m.id = p_mother_id;

  if not found then
    raise exception using errcode = 'P0002', message = 'Mother profile was not found';
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
revoke all on function public.record_dawa_clinician_patient_mapping(uuid, text)
  from public, anon, authenticated;
grant execute on function public.record_dawa_clinician_patient_mapping(uuid, text)
  to service_role;

create or replace function public.upsert_dawa_clinician_directory(
  p_clinicians jsonb,
  p_is_full_refresh boolean default false
)
returns table (
  id uuid,
  display_name text,
  professional_title text,
  speciality text,
  clinic_id uuid,
  clinic_name text,
  profile_image_url text,
  is_active boolean,
  is_bookable boolean,
  availability_summary jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  external_clinician_id uuid;
  external_clinic_id uuid;
  local_clinic_id uuid;
begin
  if p_clinicians is null or jsonb_typeof(p_clinicians) <> 'array' then
    raise exception using errcode = '22023', message = 'Clinician directory payload must be an array';
  end if;

  for item in select value from jsonb_array_elements(p_clinicians)
  loop
    begin
      external_clinician_id := (item ->> 'id')::uuid;
      external_clinic_id := (item ->> 'clinic_id')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode = '22023', message = 'Directory identifiers must be UUIDs';
    end;

    if length(trim(coalesce(item ->> 'display_name', ''))) < 2
       or length(trim(coalesce(item ->> 'clinic_name', ''))) < 2 then
      raise exception using errcode = '22023', message = 'Directory display and clinic names are required';
    end if;

    insert into public.clinics (
      name,
      dawa_clinician_clinic_id,
      directory_synced_at
    ) values (
      trim(item ->> 'clinic_name'),
      external_clinic_id,
      now()
    )
    on conflict (dawa_clinician_clinic_id)
      where dawa_clinician_clinic_id is not null
      do update
      set name = excluded.name,
          directory_synced_at = excluded.directory_synced_at,
          updated_at = now()
    returning public.clinics.id into local_clinic_id;

    insert into public.doctors (
      clinic_id,
      name,
      speciality,
      start_time,
      end_time,
      professional_title,
      profile_image_url,
      is_active,
      is_bookable,
      dawa_clinician_clinician_id,
      directory_synced_at
    ) values (
      local_clinic_id,
      trim(item ->> 'display_name'),
      nullif(trim(item ->> 'speciality'), ''),
      coalesce(nullif(trim(item #>> '{availability_summary,start_time}'), ''), '08:00'),
      coalesce(nullif(trim(item #>> '{availability_summary,end_time}'), ''), '16:00'),
      nullif(trim(item ->> 'professional_title'), ''),
      nullif(trim(item ->> 'profile_image_url'), ''),
      coalesce((item ->> 'is_active')::boolean, false),
      coalesce((item ->> 'is_bookable')::boolean, false),
      external_clinician_id,
      now()
    )
    on conflict (dawa_clinician_clinician_id)
      where dawa_clinician_clinician_id is not null
      do update
      set clinic_id = excluded.clinic_id,
          name = excluded.name,
          speciality = excluded.speciality,
          start_time = excluded.start_time,
          end_time = excluded.end_time,
          professional_title = excluded.professional_title,
          profile_image_url = excluded.profile_image_url,
          is_active = excluded.is_active,
          is_bookable = excluded.is_bookable,
          directory_synced_at = excluded.directory_synced_at,
          updated_at = now();
  end loop;

  if p_is_full_refresh then
    update public.doctors d
    set is_active = false,
        is_bookable = false,
        directory_synced_at = now(),
        updated_at = now()
    where d.dawa_clinician_clinician_id is not null
      and not exists (
        select 1
        from jsonb_array_elements(p_clinicians) source_item
        where (source_item ->> 'id')::uuid =
          d.dawa_clinician_clinician_id
      );
  end if;

  return query
  select
    d.id,
    coalesce(nullif(trim(d.name), ''), 'Clinician'),
    d.professional_title,
    d.speciality,
    c.id,
    c.name,
    d.profile_image_url,
    d.is_active,
    d.is_bookable,
    jsonb_build_object(
      'start_time', d.start_time,
      'end_time', d.end_time,
      'slot_minutes', coalesce(
        (
          select (source_item #>> '{availability_summary,slot_minutes}')::integer
          from jsonb_array_elements(p_clinicians) source_item
          where (source_item ->> 'id')::uuid = d.dawa_clinician_clinician_id
          limit 1
        ),
        30
      )
    )
  from public.doctors d
  join public.clinics c on c.id = d.clinic_id
  where d.dawa_clinician_clinician_id in (
    select (source_item ->> 'id')::uuid
    from jsonb_array_elements(p_clinicians) source_item
  )
    and d.is_active
    and d.is_bookable
  order by d.name;
end;
$$;

revoke all on function public.upsert_dawa_clinician_directory(jsonb, boolean)
  from public, anon, authenticated;
grant execute on function public.upsert_dawa_clinician_directory(jsonb, boolean)
  to service_role;

-- The local RPC remains a read-only degraded cache, but only rows proven to
-- originate from the authoritative Dawa Clinician directory are returned.
create or replace function public.get_bookable_clinicians(
  target_clinic_id uuid default null
)
returns table (
  id uuid,
  display_name text,
  professional_title text,
  speciality text,
  clinic_id uuid,
  clinic_name text,
  profile_image_url text,
  is_active boolean,
  is_bookable boolean,
  availability_summary jsonb
)
language sql
stable
security definer
set search_path = public
as $$
  select
    d.id,
    coalesce(nullif(trim(d.name), ''), 'Clinician') as display_name,
    d.professional_title,
    d.speciality,
    d.clinic_id,
    c.name as clinic_name,
    d.profile_image_url,
    d.is_active,
    d.is_bookable,
    jsonb_build_object(
      'start_time', d.start_time,
      'end_time', d.end_time,
      'slot_minutes', 30
    ) as availability_summary
  from public.doctors d
  join public.clinics c on c.id = d.clinic_id
  where auth.uid() is not null
    and d.is_active
    and d.is_bookable
    and d.dawa_clinician_clinician_id is not null
    and c.dawa_clinician_clinic_id is not null
    and (target_clinic_id is null or d.clinic_id = target_clinic_id)
  order by d.name;
$$;

revoke all on function public.get_bookable_clinicians(uuid)
  from public, anon;
grant execute on function public.get_bookable_clinicians(uuid)
  to authenticated;

create or replace function public.apply_dawa_clinician_appointment_status(
  p_event_id uuid,
  p_appointment_id uuid,
  p_external_appointment_id text,
  p_status text,
  p_appointment_date date default null,
  p_start_time time without time zone default null,
  p_end_time time without time zone default null,
  p_effective_at timestamptz default now(),
  p_patient_safe_message text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_result jsonb;
  appointment_row public.appointments%rowtype;
  normalized_status text := lower(trim(coalesce(p_status, '')));
  result_payload jsonb;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_event_id::text, 0));
  perform set_config('dawa.integration_transition', 'allowed', true);

  select e.result into existing_result
  from public.processed_integration_events e
  where e.source = 'dawa_clinician'
    and e.event_id = p_event_id;

  if existing_result is not null then
    return existing_result;
  end if;

  if normalized_status not in (
    'confirmed', 'declined', 'rescheduled', 'completed', 'cancelled'
  ) then
    raise exception using errcode = '22023', message = 'Unsupported appointment status';
  end if;

  if nullif(trim(p_external_appointment_id), '') is null then
    raise exception using errcode = '22023', message = 'External appointment ID is required';
  end if;

  select * into appointment_row
  from public.appointments a
  where a.id = p_appointment_id
  for update;

  if appointment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment was not found';
  end if;

  if appointment_row.dawa_clinician_appointment_id is not null
     and appointment_row.dawa_clinician_appointment_id <> trim(p_external_appointment_id) then
    raise exception using errcode = '23514', message = 'Appointment mapping does not match';
  end if;

  if appointment_row.status <> normalized_status and not (
    (appointment_row.status = 'pending' and normalized_status in ('confirmed', 'declined', 'rescheduled', 'cancelled'))
    or (appointment_row.status = 'confirmed' and normalized_status in ('rescheduled', 'completed', 'cancelled'))
    or (appointment_row.status = 'rescheduled' and normalized_status in ('confirmed', 'completed', 'cancelled'))
  ) then
    raise exception using errcode = '23514', message = 'Invalid appointment status transition';
  end if;

  if normalized_status = 'rescheduled'
     and (p_appointment_date is null or p_start_time is null or p_end_time is null) then
    raise exception using errcode = '22023', message = 'Rescheduled appointments require a date and time range';
  end if;

  if p_start_time is not null and p_end_time is not null and p_end_time <= p_start_time then
    raise exception using errcode = '22023', message = 'Appointment end time must be after start time';
  end if;

  update public.appointments a
  set status = normalized_status,
      appointment_date = case
        when normalized_status = 'rescheduled' then p_appointment_date
        else a.appointment_date
      end,
      start_time = case
        when normalized_status = 'rescheduled' then p_start_time
        else a.start_time
      end,
      end_time = case
        when normalized_status = 'rescheduled' then p_end_time
        else a.end_time
      end,
      dawa_clinician_appointment_id = coalesce(
        a.dawa_clinician_appointment_id,
        nullif(trim(p_external_appointment_id), '')
      ),
      external_appointment_id = coalesce(
        a.external_appointment_id,
        nullif(trim(p_external_appointment_id), '')
      ),
      patient_safe_status_message = case normalized_status
        when 'confirmed' then 'Your appointment has been confirmed.'
        when 'declined' then 'This appointment could not be confirmed. Please choose another time.'
        when 'rescheduled' then 'The clinic proposed a new appointment time.'
        when 'completed' then 'Your appointment is marked complete.'
        when 'cancelled' then 'This appointment was cancelled by the clinic.'
        else null
      end,
      integration_status = 'synced',
      integration_synced_at = coalesce(p_effective_at, now()),
      integration_error_code = null
  where a.id = p_appointment_id
  returning * into appointment_row;

  result_payload := jsonb_build_object(
    'ok', true,
    'event_id', p_event_id,
    'appointment_id', appointment_row.id,
    'external_appointment_id', appointment_row.dawa_clinician_appointment_id,
    'status', appointment_row.status,
    'appointment_date', appointment_row.appointment_date,
    'start_time', appointment_row.start_time,
    'end_time', appointment_row.end_time
  );

  insert into public.processed_integration_events (
    source,
    event_id,
    event_type,
    aggregate_id,
    destination_id,
    result
  ) values (
    'dawa_clinician',
    p_event_id,
    'appointment.status.changed',
    p_appointment_id,
    appointment_row.dawa_clinician_appointment_id,
    result_payload
  );

  return result_payload;
end;
$$;

revoke all on function public.apply_dawa_clinician_appointment_status(
  uuid, uuid, text, text, date, time without time zone,
  time without time zone, timestamptz, text
) from public, anon, authenticated;
grant execute on function public.apply_dawa_clinician_appointment_status(
  uuid, uuid, text, text, date, time without time zone,
  time without time zone, timestamptz, text
) to service_role;

-- Email delivery remains durable but no longer overwrites cross-project sync
-- state. Existing jobs and provider IDs remain untouched.
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
  perform set_config('dawa.integration_transition', 'allowed', true);

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
  set email_delivery_status = case
    when not exists (
      select 1 from public.appointment_email_outbox o
      where o.appointment_id = target_appointment_id
        and o.status <> 'sent'
    ) then 'sent'
    when exists (
      select 1 from public.appointment_email_outbox o
      where o.appointment_id = target_appointment_id
        and o.status = 'permanently_failed'
    ) then 'permanently_failed'
    else 'queued'
  end
  where a.id = target_appointment_id;
end;
$$;

revoke all on function public.complete_appointment_email_job(
  uuid, text, boolean, text, text, text, timestamptz, boolean
) from public, anon, authenticated;
grant execute on function public.complete_appointment_email_job(
  uuid, text, boolean, text, text, text, timestamptz, boolean
) to service_role;

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'appointments'
  ) then
    alter publication supabase_realtime add table public.appointments;
  end if;
end $$;

comment on table public.integration_outbox is
  'Private durable queue for Dawa Mom patient and appointment delivery. Payloads are sanitised and Flutter roles have no access.';
comment on table public.processed_integration_events is
  'Private idempotency ledger for inbound Dawa Clinician callbacks.';
comment on column public.mothers.dawa_clinician_patient_id is
  'Server-managed mapping to the native Dawa Clinician patient record.';
comment on column public.doctors.dawa_clinician_clinician_id is
  'Stable public integration UUID from the authoritative Dawa Clinician directory.';
comment on column public.clinics.dawa_clinician_clinic_id is
  'Stable public integration UUID from the authoritative Dawa Clinician directory.';
comment on column public.appointments.email_delivery_status is
  'Email-only delivery state, intentionally separate from cross-project integration_status.';

notify pgrst, 'reload schema';

commit;
