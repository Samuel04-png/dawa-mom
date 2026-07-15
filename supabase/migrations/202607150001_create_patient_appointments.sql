-- Separate patient appointment requests from clinician-owned clinical encounters.
-- Dawa Mom patients write only appointment lifecycle data; clinical encounter
-- data remains in public.encounters.

begin;

alter table public.doctors
  add column if not exists professional_title text,
  add column if not exists profile_image_url text,
  add column if not exists is_active boolean not null default true,
  add column if not exists is_bookable boolean not null default true;

-- Link imported clinician rows to the canonical clinic when the legacy name is
-- an unambiguous case-insensitive match. Unmatched rows remain unavailable for
-- booking until their clinic relationship is repaired.
update public.doctors d
set clinic_id = c.id
from public.clinics c
where d.clinic_id is null
  and d.clinic_name_legacy is not null
  and lower(trim(d.clinic_name_legacy)) = lower(trim(c.name));

create table if not exists public.appointments (
  id uuid primary key default extensions.gen_random_uuid(),
  mother_id uuid not null references public.mothers(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  clinician_id uuid not null references public.doctors(id) on delete restrict,
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  appointment_date date not null,
  start_time time without time zone not null,
  end_time time without time zone not null,
  appointment_type text not null default 'maternal_health',
  reason text,
  notes text,
  status text not null default 'pending',
  source text not null default 'dawa_mom',
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  integration_status text not null default 'pending',
  external_appointment_id text,
  constraint appointments_time_order_check check (end_time > start_time),
  constraint appointments_status_check check (
    status in (
      'pending',
      'confirmed',
      'declined',
      'rescheduled',
      'completed',
      'cancelled',
      'missed'
    )
  ),
  constraint appointments_source_check check (length(trim(source)) > 0),
  constraint appointments_integration_status_check check (
    integration_status in ('pending', 'queued', 'sent', 'synced', 'failed')
  )
);

create index if not exists appointments_mother_date_idx
  on public.appointments(mother_id, appointment_date, start_time);

create index if not exists appointments_patient_date_idx
  on public.appointments(patient_id, appointment_date, start_time);

create index if not exists appointments_clinician_date_idx
  on public.appointments(clinician_id, appointment_date, start_time);

create index if not exists appointments_integration_status_idx
  on public.appointments(integration_status, created_at)
  where integration_status <> 'synced';

create unique index if not exists appointments_clinician_slot_unique
  on public.appointments(clinician_id, appointment_date, start_time)
  where status not in ('cancelled', 'declined');

create unique index if not exists appointments_mother_slot_unique
  on public.appointments(mother_id, appointment_date, start_time)
  where status not in ('cancelled', 'declined');

-- Preserve valid legacy appointment rows that were stored in encounters. Rows
-- without a canonical clinician/clinic link or a parseable 24-hour time remain
-- in encounters for manual review rather than risking an incorrect booking.
insert into public.appointments (
  id,
  mother_id,
  patient_id,
  clinician_id,
  clinic_id,
  appointment_date,
  start_time,
  end_time,
  appointment_type,
  reason,
  status,
  source,
  created_by,
  created_at,
  updated_at,
  integration_status
)
select
  e.id,
  e.mother_id,
  m.profile_id,
  e.doctor_id,
  coalesce(e.clinic_id, d.clinic_id),
  e.appointment_date,
  e.appointment_time::time,
  e.appointment_time::time + interval '30 minutes',
  'maternal_health',
  e.comment,
  case lower(e.status)
    when 'scheduled' then 'pending'
    when 'canceled' then 'cancelled'
    when 'cancelled' then 'cancelled'
    when 'completed' then 'completed'
    else 'pending'
  end,
  'dawa_mom_legacy',
  m.profile_id,
  e.created_at,
  e.updated_at,
  'pending'
from public.encounters e
join public.mothers m on m.id = e.mother_id
join public.doctors d on d.id = e.doctor_id
where e.appointment_date is not null
  and e.appointment_time ~ '^(?:[01]?[0-9]|2[0-3]):[0-5][0-9]$'
  and coalesce(e.clinic_id, d.clinic_id) is not null
on conflict do nothing;

create or replace function public.validate_appointment_relationships()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.mothers m
    where m.id = new.mother_id
      and m.profile_id = new.patient_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'Appointment patient profile does not match the mother profile';
  end if;

  if not exists (
    select 1
    from public.doctors d
    where d.id = new.clinician_id
      and d.clinic_id = new.clinic_id
      and d.is_active
      and d.is_bookable
  ) then
    raise exception using
      errcode = '23514',
      message = 'Selected clinician is not bookable at the selected clinic';
  end if;

  return new;
end;
$$;

create or replace function public.guard_patient_appointment_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
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
       or old.external_appointment_id is distinct from new.external_appointment_id then
      raise exception using errcode = '42501', message = 'Patients may only cancel eligible appointments';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists validate_appointment_relationships on public.appointments;
create trigger validate_appointment_relationships
  before insert or update of mother_id, patient_id, clinician_id, clinic_id
  on public.appointments
  for each row execute function public.validate_appointment_relationships();

drop trigger if exists guard_patient_appointment_update on public.appointments;
create trigger guard_patient_appointment_update
  before update on public.appointments
  for each row execute function public.guard_patient_appointment_update();

drop trigger if exists set_appointments_updated_at on public.appointments;
create trigger set_appointments_updated_at
  before update on public.appointments
  for each row execute function public.set_updated_at();

alter table public.appointments enable row level security;

drop policy if exists appointments_select_owner on public.appointments;
create policy appointments_select_owner
  on public.appointments
  for select
  to authenticated
  using (
    patient_id = auth.uid()
    and public.owns_mother(mother_id)
  );

comment on policy appointments_select_owner on public.appointments is
  'Authenticated patients may read only appointments linked to their own profile and mother row.';

drop policy if exists appointments_insert_owner on public.appointments;
create policy appointments_insert_owner
  on public.appointments
  for insert
  to authenticated
  with check (
    patient_id = auth.uid()
    and created_by = auth.uid()
    and public.owns_mother(mother_id)
    and status = 'pending'
    and source = 'dawa_mom'
    and integration_status = 'pending'
  );

comment on policy appointments_insert_owner on public.appointments is
  'Authenticated patients may create pending Dawa Mom appointment requests only for their own mother profile.';

drop policy if exists appointments_cancel_owner on public.appointments;
create policy appointments_cancel_owner
  on public.appointments
  for update
  to authenticated
  using (
    patient_id = auth.uid()
    and public.owns_mother(mother_id)
    and status in ('pending', 'confirmed', 'rescheduled')
  )
  with check (
    patient_id = auth.uid()
    and public.owns_mother(mother_id)
    and status = 'cancelled'
  );

comment on policy appointments_cancel_owner on public.appointments is
  'Authenticated patients may cancel an eligible owned appointment; a trigger prevents changes to every other field.';

drop policy if exists appointments_admin_read on public.appointments;
create policy appointments_admin_read
  on public.appointments
  for select
  to authenticated
  using (public.is_admin());

comment on policy appointments_admin_read on public.appointments is
  'Authenticated Dawa Mom admins may read all appointment requests for support and integration monitoring.';

-- Patients use the narrow RPC below. Direct doctor rows remain available only
-- to the clinician represented by the row or to an admin.
drop policy if exists doctors_read_authenticated on public.doctors;
drop policy if exists doctors_select_self_or_admin on public.doctors;
create policy doctors_select_self_or_admin
  on public.doctors
  for select
  to authenticated
  using (public.is_admin() or public.doctor_owns_doctor(id));

comment on policy doctors_select_self_or_admin on public.doctors is
  'Prevents patient clients from reading private clinician columns; booking clients use get_bookable_clinicians instead.';

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
    and (target_clinic_id is null or d.clinic_id = target_clinic_id)
  order by d.name;
$$;

revoke all on function public.get_bookable_clinicians(uuid) from public;
revoke all on function public.get_bookable_clinicians(uuid) from anon;
grant execute on function public.get_bookable_clinicians(uuid) to authenticated;

create or replace function public.get_clinician_booked_slots(
  target_clinician_id uuid,
  target_date date
)
returns table (start_time time without time zone, end_time time without time zone)
language sql
stable
security definer
set search_path = public
as $$
  select a.start_time, a.end_time
  from public.appointments a
  where auth.uid() is not null
    and a.clinician_id = target_clinician_id
    and a.appointment_date = target_date
    and a.status not in ('cancelled', 'declined')
  order by a.start_time;
$$;

revoke all on function public.get_clinician_booked_slots(uuid, date) from public;
revoke all on function public.get_clinician_booked_slots(uuid, date) from anon;
grant execute on function public.get_clinician_booked_slots(uuid, date) to authenticated;

comment on table public.appointments is
  'Patient appointment requests created by Dawa Mom. Clinical observations belong in encounters, not this table.';
comment on column public.appointments.patient_id is
  'Supabase profile/auth UUID retained alongside mother_id for ownership and downstream patient mapping.';
comment on column public.appointments.source is
  'Originating product. Dawa Mom patient-created rows use dawa_mom.';
comment on column public.appointments.integration_status is
  'Server-side delivery state for the later Dawa Clinician integration phase.';
comment on function public.get_bookable_clinicians(uuid) is
  'Returns only public booking-directory fields from Dawa Mom temporary clinician cache rows.';
comment on function public.get_clinician_booked_slots(uuid, date) is
  'Returns occupied times without exposing another patient or appointment details.';

notify pgrst, 'reload schema';

commit;
