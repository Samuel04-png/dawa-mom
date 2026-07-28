-- Make the final Dawa Mom booking write server-authoritative and idempotent.
-- Authoritative Dawa Clinician availability remains an upstream dependency;
-- this transaction protects the Dawa Mom appointment aggregate and local slot
-- conflicts without claiming an external confirmation.

begin;

alter table public.appointments
  add column if not exists client_idempotency_key uuid;

update public.appointments
set client_idempotency_key = id
where client_idempotency_key is null;

alter table public.appointments
  alter column client_idempotency_key set not null;

create unique index if not exists appointments_patient_idempotency_uidx
  on public.appointments(patient_id, client_idempotency_key);

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
       or old.email_delivery_status is distinct from new.email_delivery_status
       or old.client_idempotency_key is distinct from new.client_idempotency_key then
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
       or new.client_idempotency_key is null
     ) then
    raise exception using
      errcode = '42501',
      message = 'Appointment integration fields are server managed';
  end if;
  return new;
end;
$$;

create or replace function public.book_dawa_mom_appointment(
  p_clinic_id uuid,
  p_clinician_id uuid,
  p_appointment_date date,
  p_start_time time without time zone,
  p_end_time time without time zone,
  p_appointment_type text,
  p_reason text,
  p_notes text,
  p_idempotency_key uuid
)
returns public.appointments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile_id uuid := auth.uid();
  v_mother_id uuid;
  v_existing public.appointments;
  v_result public.appointments;
  v_local_now timestamp without time zone :=
    timezone('Africa/Lusaka', now());
begin
  if v_profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;
  if p_idempotency_key is null then
    raise exception using errcode = '23514', message = 'An idempotency key is required';
  end if;

  select appointment.*
    into v_existing
  from public.appointments appointment
  where appointment.patient_id = v_profile_id
    and appointment.client_idempotency_key = p_idempotency_key;
  if found then
    return v_existing;
  end if;

  if p_appointment_date is null
     or p_start_time is null
     or p_end_time is null
     or p_end_time <= p_start_time
     or (p_appointment_date + p_start_time) <= v_local_now then
    raise exception using errcode = '23514', message = 'Appointment time is invalid';
  end if;
  if length(trim(coalesce(p_appointment_type, ''))) < 2
     or length(trim(coalesce(p_appointment_type, ''))) > 80
     or length(coalesce(p_reason, '')) > 500
     or length(coalesce(p_notes, '')) > 1000 then
    raise exception using errcode = '23514', message = 'Appointment details are invalid';
  end if;

  select mother.id
    into v_mother_id
  from public.mothers mother
  where mother.profile_id = v_profile_id;
  if v_mother_id is null then
    raise exception using errcode = '23514', message = 'A health profile is required';
  end if;

  if not exists (
    select 1
    from public.doctors clinician
    where clinician.id = p_clinician_id
      and clinician.clinic_id = p_clinic_id
      and clinician.is_active
      and clinician.is_bookable
  ) then
    raise exception using errcode = '23514', message = 'Clinician is not bookable at this clinic';
  end if;

  begin
    insert into public.appointments (
      mother_id,
      patient_id,
      clinician_id,
      clinic_id,
      appointment_date,
      start_time,
      end_time,
      appointment_type,
      reason,
      notes,
      status,
      source,
      created_by,
      integration_status,
      client_idempotency_key
    )
    values (
      v_mother_id,
      v_profile_id,
      p_clinician_id,
      p_clinic_id,
      p_appointment_date,
      p_start_time,
      p_end_time,
      trim(p_appointment_type),
      nullif(trim(coalesce(p_reason, '')), ''),
      nullif(trim(coalesce(p_notes, '')), ''),
      'pending',
      'dawa_mom',
      v_profile_id,
      'pending',
      p_idempotency_key
    )
    returning * into v_result;
  exception
    when unique_violation then
      select appointment.*
        into v_existing
      from public.appointments appointment
      where appointment.patient_id = v_profile_id
        and appointment.client_idempotency_key = p_idempotency_key;
      if found then
        return v_existing;
      end if;
      raise exception using
        errcode = '23505',
        message = 'The selected appointment time is no longer available';
  end;

  return v_result;
end;
$$;

revoke all on function public.book_dawa_mom_appointment(
  uuid,
  uuid,
  date,
  time without time zone,
  time without time zone,
  text,
  text,
  text,
  uuid
) from public, anon;
grant execute on function public.book_dawa_mom_appointment(
  uuid,
  uuid,
  date,
  time without time zone,
  time without time zone,
  text,
  text,
  text,
  uuid
) to authenticated;

comment on column public.appointments.client_idempotency_key is
  'Client-generated UUID reused across retries so one user action creates at most one appointment.';
comment on function public.book_dawa_mom_appointment(
  uuid,
  uuid,
  date,
  time without time zone,
  time without time zone,
  text,
  text,
  text,
  uuid
) is
  'Atomically validates and creates one owner-scoped pending Dawa Mom appointment, or returns the prior result for the same idempotency key.';

commit;
