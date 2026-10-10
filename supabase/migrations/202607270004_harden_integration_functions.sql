-- Resolve integration-function lint findings while preserving the existing
-- service-role-only contract and patient-safe fallback wording.

begin;

alter function public.patient_safe_result_measurement(jsonb, text)
  stable;

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
  safe_status_message text := left(
    nullif(
      regexp_replace(
        trim(coalesce(p_patient_safe_message, '')),
        '[[:cntrl:]]+',
        ' ',
        'g'
      ),
      ''
    ),
    500
  );
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
    raise exception using
      errcode = '22023',
      message = 'Unsupported appointment status';
  end if;

  if nullif(trim(p_external_appointment_id), '') is null then
    raise exception using
      errcode = '22023',
      message = 'External appointment ID is required';
  end if;

  select * into appointment_row
  from public.appointments a
  where a.id = p_appointment_id
  for update;

  if appointment_row.id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Appointment was not found';
  end if;

  if appointment_row.dawa_clinician_appointment_id is not null
     and appointment_row.dawa_clinician_appointment_id
       <> trim(p_external_appointment_id) then
    raise exception using
      errcode = '23514',
      message = 'Appointment mapping does not match';
  end if;

  if appointment_row.status <> normalized_status and not (
    (
      appointment_row.status = 'pending'
      and normalized_status in (
        'confirmed', 'declined', 'rescheduled', 'cancelled'
      )
    )
    or (
      appointment_row.status = 'confirmed'
      and normalized_status in ('rescheduled', 'completed', 'cancelled')
    )
    or (
      appointment_row.status = 'rescheduled'
      and normalized_status in ('confirmed', 'completed', 'cancelled')
    )
  ) then
    raise exception using
      errcode = '23514',
      message = 'Invalid appointment status transition';
  end if;

  if normalized_status = 'rescheduled'
     and (
       p_appointment_date is null
       or p_start_time is null
       or p_end_time is null
     ) then
    raise exception using
      errcode = '22023',
      message = 'Rescheduled appointments require a date and time range';
  end if;

  if p_start_time is not null
     and p_end_time is not null
     and p_end_time <= p_start_time then
    raise exception using
      errcode = '22023',
      message = 'Appointment end time must be after start time';
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
      patient_safe_status_message = coalesce(
        safe_status_message,
        case normalized_status
          when 'confirmed' then 'Your appointment has been confirmed.'
          when 'declined' then
            'This appointment could not be confirmed. Please choose another time.'
          when 'rescheduled' then
            'The clinic proposed a new appointment time.'
          when 'completed' then 'Your appointment is marked complete.'
          when 'cancelled' then
            'This appointment was cancelled by the clinic.'
          else null
        end
      ),
      integration_status = 'synced',
      integration_synced_at = coalesce(p_effective_at, now()),
      integration_error_code = null
  where a.id = p_appointment_id
  returning * into appointment_row;

  result_payload := jsonb_build_object(
    'ok', true,
    'event_id', p_event_id,
    'appointment_id', appointment_row.id,
    'external_appointment_id',
      appointment_row.dawa_clinician_appointment_id,
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
  uuid,
  uuid,
  text,
  text,
  date,
  time without time zone,
  time without time zone,
  timestamptz,
  text
) from public, anon, authenticated;

grant execute on function public.apply_dawa_clinician_appointment_status(
  uuid,
  uuid,
  text,
  text,
  date,
  time without time zone,
  time without time zone,
  timestamptz,
  text
) to service_role;

comment on function public.apply_dawa_clinician_appointment_status(
  uuid,
  uuid,
  text,
  text,
  date,
  time without time zone,
  time without time zone,
  timestamptz,
  text
) is
  'Idempotently applies trusted Dawa Clinician status events and stores bounded patient-safe wording.';

commit;
