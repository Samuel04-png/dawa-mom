-- Keep clinician confirmation and payment method as separate authoritative states.

begin;

alter table public.appointments
  add column if not exists payment_method text not null default 'online';

alter table public.appointments
  drop constraint if exists appointments_payment_method_check;
alter table public.appointments
  add constraint appointments_payment_method_check
  check (payment_method in ('online', 'cash'));

-- Add a cash-aware overload. The existing 10-argument online RPC remains
-- available to older installed clients and continues to use the safe default.
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
  p_service_id uuid,
  p_payment_method text
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
  normalized_payment_method text := lower(trim(coalesce(p_payment_method, 'online')));
  local_now timestamp without time zone := timezone('Africa/Lusaka', now());
begin
  if v_profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;
  if p_idempotency_key is null then
    raise exception using errcode = '23514', message = 'An idempotency key is required';
  end if;
  if normalized_payment_method not in ('online', 'cash') then
    raise exception using errcode = '22023', message = 'Invalid payment method';
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
      price_snapshot, currency_snapshot, payment_method
    ) values (
      v_mother_id, v_profile_id, p_clinician_id, p_clinic_id, p_appointment_date,
      p_start_time, p_end_time, trim(p_appointment_type),
      nullif(trim(coalesce(p_reason, '')), ''),
      nullif(trim(coalesce(p_notes, '')), ''), 'pending', 'dawa_mom',
      v_profile_id, 'pending', p_idempotency_key, selected_service.id,
      selected_service.external_service_id, selected_service.name,
      selected_service.is_paid, selected_service.price, selected_service.currency,
      normalized_payment_method
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
  text, text, text, uuid, uuid, text
) from public, anon;
grant execute on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid, text
) to authenticated;

create or replace function public.enqueue_dawa_mom_appointment_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.is_paid_snapshot and new.payment_method = 'online' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    insert into public.integration_outbox (
      event_type, aggregate_type, aggregate_id, payload
    ) values (
      'appointment.created', 'appointment', new.id,
      jsonb_strip_nulls(jsonb_build_object(
        'source', 'dawa_mom',
        'source_appointment_id', new.id,
        'source_mother_id', new.mother_id,
        'dawa_clinician_patient_id', (select mother.dawa_clinician_patient_id from public.mothers mother where mother.id = new.mother_id),
        'dawa_clinician_clinician_id', (select doctor.dawa_clinician_clinician_id from public.doctors doctor where doctor.id = new.clinician_id),
        'dawa_clinician_clinic_id', (select clinic.dawa_clinician_clinic_id from public.clinics clinic where clinic.id = new.clinic_id),
        'appointment_date', new.appointment_date,
        'start_time', new.start_time,
        'end_time', new.end_time,
        'appointment_type', new.appointment_type,
        'reason', new.reason,
        'notes', new.notes,
        'status', new.status,
        'service_id', new.service_id,
        'external_service_id', new.external_service_id_snapshot,
        'price', new.price_snapshot,
        'currency', new.currency_snapshot,
        'payment_method', new.payment_method,
        'payment_status', case when new.payment_method = 'cash' then 'pay_at_clinic' else 'not_required' end,
        'created_at', new.created_at,
        'updated_at', new.updated_at
      ))
    );
  elsif coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
        and auth.uid() is not null
        and public.current_app_role() = 'patient'::public.app_role
        and old.status is distinct from new.status
        and new.status = 'cancelled' then
    insert into public.integration_outbox (
      event_type, aggregate_type, aggregate_id, payload
    ) values (
      'appointment.cancelled', 'appointment', new.id,
      jsonb_build_object('source', 'dawa_mom', 'source_appointment_id', new.id)
    );
  end if;
  return new;
end;
$$;

create or replace function public.enqueue_appointment_email_jobs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_paid_snapshot and new.payment_method = 'online' then
    return new;
  end if;
  insert into public.appointment_email_outbox (
    appointment_id, recipient_kind, template_key
  ) values
    (new.id, 'patient', 'appointment_requested'),
    (new.id, 'clinician', 'appointment_requested')
  on conflict (appointment_id, recipient_kind, template_key) do nothing;
  return new;
end;
$$;

notify pgrst, 'reload schema';

commit;
