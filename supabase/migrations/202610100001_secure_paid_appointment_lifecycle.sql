-- A paid online appointment is a private reservation until the provider
-- verifies payment. Clinic scheduling is released only by that verification.

begin;

alter table public.appointments
  add column if not exists payment_state text not null default 'not_required';

alter table public.appointments
  drop constraint if exists appointments_payment_state_check;
alter table public.appointments
  add constraint appointments_payment_state_check check (
    payment_state in (
      'not_required', 'pay_at_clinic', 'not_started', 'pending',
      'processing', 'successful', 'failed', 'cancelled', 'expired',
      'reconciliation_required'
    )
  );

alter table public.payments
  drop constraint if exists payments_status_check;
alter table public.payments
  add constraint payments_status_check check (
    status in (
      'created', 'pending', 'processing', 'successful', 'failed',
      'cancelled', 'expired', 'reconciliation_required'
    )
  );

drop index if exists public.payments_one_active_per_appointment_uidx;
create unique index payments_one_active_per_appointment_uidx
  on public.payments(appointment_id)
  where status in (
    'created', 'pending', 'processing', 'successful',
    'reconciliation_required'
  );

-- Preserve completed/confirmed legacy paid appointments. For other existing
-- rows, take the newest provider record as the source of truth; a paid online
-- row without a provider record is deliberately hidden until reconciled.
update public.appointments appointment
set payment_state = coalesce(
  (
    select payment.status
    from public.payments payment
    where payment.appointment_id = appointment.id
    order by payment.created_at desc
    limit 1
  ),
  case
    when appointment.status in ('confirmed', 'rescheduled', 'completed') then 'successful'
    else 'not_started'
  end
)
where appointment.is_paid_snapshot
  and appointment.payment_method = 'online';

-- Patient sessions may still only cancel their own appointment. Secure
-- payment functions explicitly set this transaction-local flag before moving
-- the private payment reservation through its server-owned lifecycle.
create or replace function public.guard_patient_appointment_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
     and public.current_app_role() = 'patient'::public.app_role
     and coalesce(current_setting('dawa.payment_transition', true), '') <> 'allowed' then
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
       or old.payment_state is distinct from new.payment_state then
      raise exception using errcode = '42501', message = 'Patients may only cancel eligible appointments';
    end if;
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
      price_snapshot, currency_snapshot, payment_method, payment_state
    ) values (
      v_mother_id, v_profile_id, p_clinician_id, p_clinic_id, p_appointment_date,
      p_start_time, p_end_time, trim(p_appointment_type),
      nullif(trim(coalesce(p_reason, '')), ''),
      nullif(trim(coalesce(p_notes, '')), ''), 'pending', 'dawa_mom',
      v_profile_id, 'pending', p_idempotency_key, selected_service.id,
      selected_service.external_service_id, selected_service.name,
      selected_service.is_paid, selected_service.price, selected_service.currency,
      normalized_payment_method,
      case
        when not selected_service.is_paid then 'not_required'
        when normalized_payment_method = 'cash' then 'pay_at_clinic'
        else 'not_started'
      end
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

-- Older installed clients still send the pre-payment-method, 10-argument
-- overload. Route those calls through the secure lifecycle implementation so
-- a paid online appointment starts as `not_started`, never as the column's
-- generic `not_required` default.
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
language sql
security definer
set search_path = public, pg_temp
as $$
  select public.book_dawa_mom_appointment(
    p_clinic_id,
    p_clinician_id,
    p_appointment_date,
    p_start_time,
    p_end_time,
    p_appointment_type,
    p_reason,
    p_notes,
    p_idempotency_key,
    p_service_id,
    'online'
  );
$$;

revoke all on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid
) from public, anon;
grant execute on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid
) to authenticated;

create or replace function public.create_lipila_payment(
  p_appointment_id uuid,
  p_phone_number text
)
returns public.payments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  profile_id uuid := auth.uid();
  appointment_row public.appointments%rowtype;
  existing public.payments;
  normalized_phone text := regexp_replace(coalesce(p_phone_number, ''), '[^0-9+]', '', 'g');
  payment_row public.payments;
begin
  if profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;
  normalized_phone := regexp_replace(normalized_phone, '^00', '');
  if normalized_phone like '0%' then normalized_phone := '260' || substr(normalized_phone, 2); end if;
  if normalized_phone !~ '^260[0-9]{9}$' then
    raise exception using errcode = '22023', message = 'A valid Zambian mobile number is required';
  end if;

  select * into appointment_row
  from public.appointments
  where id = p_appointment_id and patient_id = profile_id
  for update;
  if appointment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment was not found';
  end if;
  if not appointment_row.is_paid_snapshot or appointment_row.price_snapshot <= 0
     or appointment_row.payment_method <> 'online' then
    raise exception using errcode = '23514', message = 'This appointment does not require online payment';
  end if;
  if appointment_row.status in ('cancelled', 'declined', 'completed', 'missed')
     or appointment_row.payment_state = 'reconciliation_required' then
    raise exception using errcode = '23514', message = 'This appointment cannot be paid';
  end if;
  perform set_config('dawa.payment_transition', 'allowed', true);

  select * into existing from public.payments
  where appointment_id = appointment_row.id
    and status in ('created', 'pending', 'processing', 'successful', 'reconciliation_required')
  order by created_at desc limit 1;
  if found then
    update public.appointments
    set payment_state = case
      when existing.status = 'created' then 'pending'
      else existing.status
    end
    where id = appointment_row.id;
    return existing;
  end if;

  insert into public.payments (
    user_id, appointment_id, service_id, external_service_id,
    amount, currency, phone_number, status, reference_id
  ) values (
    profile_id, appointment_row.id, appointment_row.service_id,
    appointment_row.external_service_id_snapshot, appointment_row.price_snapshot,
    appointment_row.currency_snapshot, normalized_phone, 'created',
    'dawa-' || replace(gen_random_uuid()::text, '-', '')
  ) returning * into payment_row;

  update public.appointments
  set payment_state = 'pending'
  where id = appointment_row.id;
  return payment_row;
end;
$$;

revoke all on function public.create_lipila_payment(uuid, text) from public, anon;
grant execute on function public.create_lipila_payment(uuid, text) to authenticated;

-- Atomically record the provider event and move both the payment ledger and
-- its private appointment reservation. An event cannot be marked duplicate
-- before its state transition has committed.
create or replace function public.apply_lipila_payment_status(
  p_payment_id uuid,
  p_webhook_id text,
  p_event_type text,
  p_status text,
  p_payload jsonb,
  p_provider_identifier text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  payment_row public.payments%rowtype;
  appointment_row public.appointments%rowtype;
  normalized_status text := lower(trim(coalesce(p_status, '')));
  inserted_event_id uuid;
begin
  if p_payment_id is null or nullif(trim(coalesce(p_webhook_id, '')), '') is null
     or nullif(trim(coalesce(p_event_type, '')), '') is null
     or jsonb_typeof(coalesce(p_payload, '{}'::jsonb)) <> 'object' then
    raise exception using errcode = '22023', message = 'Invalid payment update';
  end if;
  if normalized_status not in ('pending', 'processing', 'successful', 'failed', 'cancelled', 'expired') then
    raise exception using errcode = '22023', message = 'Invalid payment status';
  end if;
  perform set_config('dawa.payment_transition', 'allowed', true);

  select * into payment_row from public.payments where id = p_payment_id for update;
  if payment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Payment was not found';
  end if;

  insert into public.payment_events (
    payment_id, webhook_id, event_type, payload
  ) values (
    payment_row.id, p_webhook_id, p_event_type, p_payload
  ) on conflict (provider, webhook_id) do nothing
  returning id into inserted_event_id;
  if inserted_event_id is null then
    return jsonb_build_object('ok', true, 'duplicate', true, 'status', payment_row.status);
  end if;

  select * into appointment_row
  from public.appointments where id = payment_row.appointment_id for update;
  if appointment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment was not found';
  end if;

  if payment_row.status = 'successful' and normalized_status <> 'successful' then
    return jsonb_build_object('ok', true, 'terminal', true, 'status', payment_row.status);
  end if;
  if payment_row.status in ('failed', 'cancelled', 'expired') and normalized_status = 'successful' then
    update public.payments
    set status = 'reconciliation_required', updated_at = now(),
        provider_identifier = coalesce(nullif(trim(p_provider_identifier), ''), provider_identifier)
    where id = payment_row.id;
    update public.appointments
    set payment_state = 'reconciliation_required'
    where id = appointment_row.id;
    return jsonb_build_object('ok', true, 'reconciliation_required', true);
  end if;
  if payment_row.status in ('failed', 'cancelled', 'expired', 'reconciliation_required') then
    return jsonb_build_object('ok', true, 'terminal', true, 'status', payment_row.status);
  end if;

  update public.payments
  set status = normalized_status,
      updated_at = now(),
      provider_identifier = coalesce(nullif(trim(p_provider_identifier), ''), provider_identifier),
      paid_at = case when normalized_status = 'successful' then now() else paid_at end,
      failed_at = case when normalized_status in ('failed', 'cancelled', 'expired') then now() else failed_at end
  where id = payment_row.id;

  if normalized_status = 'successful' then
    update public.appointments
    set payment_state = 'successful'
    where id = appointment_row.id;
    perform public.release_paid_appointment_workflow(payment_row.id, p_webhook_id);
  elsif normalized_status in ('failed', 'cancelled', 'expired') then
    update public.appointments
    set payment_state = normalized_status,
        status = case when status = 'pending' then 'cancelled' else status end
    where id = appointment_row.id;
  else
    update public.appointments
    set payment_state = normalized_status
    where id = appointment_row.id;
  end if;

  return jsonb_build_object('ok', true, 'status', normalized_status);
end;
$$;

revoke all on function public.apply_lipila_payment_status(
  uuid, text, text, text, jsonb, text
) from public, anon, authenticated;
grant execute on function public.apply_lipila_payment_status(
  uuid, text, text, text, jsonb, text
) to service_role;

notify pgrst, 'reload schema';

commit;
