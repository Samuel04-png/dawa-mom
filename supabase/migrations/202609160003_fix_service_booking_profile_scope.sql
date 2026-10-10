-- Resolve PL/pgSQL variable/column name ambiguity in the service booking RPC.

begin;

create or replace function public.book_dawa_mom_appointment(
  p_clinic_id uuid,
  p_clinician_id uuid,
  p_appointment_date date,
  p_start_time time without time zone,
  p_end_time time without time zone,
  p_appointment_type text,
  p_reason text,
  p_notes text,
  p_idempotency_key uuid,
  p_service_id uuid
)
returns public.appointments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile_id uuid := auth.uid();
  v_mother_id uuid;
  selected_service public.service_catalog%rowtype;
  existing public.appointments;
  result_row public.appointments;
  local_now timestamp without time zone := timezone('Africa/Lusaka', now());
begin
  if v_profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;
  if p_idempotency_key is null then
    raise exception using errcode = '23514', message = 'An idempotency key is required';
  end if;

  select * into existing
  from public.appointments
  where patient_id = v_profile_id
    and client_idempotency_key = p_idempotency_key;
  if found then return existing; end if;

  select * into selected_service
  from public.service_catalog
  where id = coalesce(
    p_service_id,
    (select id from public.service_catalog
     where external_service_id = 'dawa-mom-general-consultation'
       and is_active limit 1)
  );
  if selected_service.id is null or not selected_service.is_active then
    raise exception using errcode = '23514', message = 'Service is not available';
  end if;
  if p_appointment_date is null or p_start_time is null or p_end_time is null
     or p_end_time <= p_start_time
     or (p_appointment_date + p_start_time) <= local_now then
    raise exception using errcode = '23514', message = 'Appointment time is invalid';
  end if;
  if length(trim(coalesce(p_appointment_type, ''))) < 2
     or length(trim(coalesce(p_appointment_type, ''))) > 80
     or length(coalesce(p_reason, '')) > 500
     or length(coalesce(p_notes, '')) > 1000 then
    raise exception using errcode = '23514', message = 'Appointment details are invalid';
  end if;

  select mother_row.id into v_mother_id
  from public.mothers mother_row
  where mother_row.profile_id = v_profile_id;
  if v_mother_id is null then
    raise exception using errcode = '23514', message = 'A health profile is required';
  end if;
  if not exists (
    select 1 from public.doctors
    where doctors.id = p_clinician_id
      and doctors.clinic_id = p_clinic_id
      and doctors.is_active and doctors.is_bookable
  ) then
    raise exception using errcode = '23514', message = 'Clinician is not bookable at this clinic';
  end if;

  begin
    insert into public.appointments (
      mother_id, patient_id, clinician_id, clinic_id, appointment_date,
      start_time, end_time, appointment_type, reason, notes, status, source,
      created_by, integration_status, client_idempotency_key, service_id,
      external_service_id_snapshot, service_name_snapshot, is_paid_snapshot,
      price_snapshot, currency_snapshot
    ) values (
      v_mother_id, v_profile_id, p_clinician_id, p_clinic_id, p_appointment_date,
      p_start_time, p_end_time, trim(p_appointment_type),
      nullif(trim(coalesce(p_reason, '')), ''),
      nullif(trim(coalesce(p_notes, '')), ''), 'pending', 'dawa_mom',
      v_profile_id, 'pending', p_idempotency_key, selected_service.id,
      selected_service.external_service_id, selected_service.name,
      selected_service.is_paid, selected_service.price, selected_service.currency
    ) returning * into result_row;
  exception when unique_violation then
    select * into existing from public.appointments
    where patient_id = v_profile_id and client_idempotency_key = p_idempotency_key;
    if found then return existing; end if;
    raise exception using errcode = '23505', message = 'The selected appointment time is no longer available';
  end;
  return result_row;
end;
$$;

revoke all on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid
) from public, anon;
grant execute on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid
) to authenticated;

commit;
