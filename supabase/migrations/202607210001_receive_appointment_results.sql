-- Patient-owned storage and idempotent receiver RPC for Dawa Clinician
-- appointment-result summaries. Only a strict patient-safe allowlist is stored.

begin;

create table if not exists public.appointment_result_summaries (
  id uuid primary key,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  external_appointment_id text not null,
  external_encounter_id text not null,
  version integer not null default 1,
  clinician_display_name text not null,
  clinic_name text not null,
  appointment_date date not null,
  completed_at timestamptz not null,
  overall_status text not null,
  maternal_summary jsonb not null default '{}'::jsonb,
  pregnancy_summary jsonb not null default '{}'::jsonb,
  key_findings text,
  recommendations text,
  follow_up_instructions text,
  referral_summary text,
  next_appointment_at timestamptz,
  urgent_care_instruction text,
  generated_at timestamptz not null,
  received_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointment_result_summaries_appointment_unique unique (appointment_id),
  constraint appointment_result_summaries_version_check check (version > 0),
  constraint appointment_result_summaries_status_check check (
    overall_status in ('routine', 'follow_up', 'needs_attention', 'urgent')
  ),
  constraint appointment_result_summaries_maternal_object_check check (
    jsonb_typeof(maternal_summary) = 'object'
  ),
  constraint appointment_result_summaries_pregnancy_object_check check (
    jsonb_typeof(pregnancy_summary) = 'object'
  )
);

create index if not exists appointment_result_summaries_completed_idx
  on public.appointment_result_summaries(appointment_id, completed_at desc);

alter table public.appointments
  add column if not exists result_summary_id uuid
    references public.appointment_result_summaries(id) on delete set null,
  add column if not exists result_received_at timestamptz;

alter table public.appointment_result_summaries enable row level security;
revoke all on table public.appointment_result_summaries from anon;
revoke insert, update, delete on table public.appointment_result_summaries
  from authenticated;

drop policy if exists appointment_results_select_owner
  on public.appointment_result_summaries;
create policy appointment_results_select_owner
  on public.appointment_result_summaries
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.appointments a
      where a.id = appointment_id
        and a.patient_id = auth.uid()
        and public.owns_mother(a.mother_id)
    )
  );

drop policy if exists appointment_results_admin_read
  on public.appointment_result_summaries;
create policy appointment_results_admin_read
  on public.appointment_result_summaries
  for select
  to authenticated
  using (public.is_admin());

create or replace function public.patient_safe_result_measurement(
  p_section jsonb,
  p_key text
)
returns jsonb
language plpgsql
immutable
set search_path = public
as $$
declare
  source_value jsonb := p_section -> p_key;
  safe_state text;
  safe_interpretation text;
  safe_unit text;
begin
  if source_value is null or jsonb_typeof(source_value) <> 'object' then
    return '{}'::jsonb;
  end if;

  safe_state := source_value ->> 'state';
  if safe_state not in (
    'measured', 'recorded', 'not_measured', 'unable_to_obtain',
    'not_applicable'
  ) then
    safe_state := null;
  end if;

  safe_interpretation := source_value ->> 'interpretation';
  if safe_interpretation not in (
    'normal', 'low', 'high', 'needs_attention', 'critical', 'recorded'
  ) then
    safe_interpretation := null;
  end if;

  safe_unit := source_value ->> 'unit';
  if safe_unit not in ('bpm', 'mmHg', 'g/dL', 'cm') then
    safe_unit := null;
  end if;

  return jsonb_strip_nulls(jsonb_build_object(
    'state', safe_state,
    'value', left(nullif(trim(source_value ->> 'value'), ''), 160),
    'unit', safe_unit,
    'interpretation', safe_interpretation
  ));
end;
$$;

create or replace function public.apply_dawa_clinician_appointment_result(
  p_event_id uuid,
  p_appointment_id uuid,
  p_external_appointment_id text,
  p_effective_at timestamptz,
  p_patient_safe_message text,
  p_summary jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_result jsonb;
  appointment_row public.appointments%rowtype;
  summary_row public.appointment_result_summaries%rowtype;
  existing_summary public.appointment_result_summaries%rowtype;
  summary_id uuid;
  summary_version integer;
  overall_status text;
  source_maternal jsonb;
  source_pregnancy jsonb;
  safe_maternal jsonb;
  safe_pregnancy jsonb;
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

  if p_summary is null or jsonb_typeof(p_summary) <> 'object' then
    raise exception using errcode = '22023', message = 'Result summary must be an object';
  end if;
  if nullif(trim(p_external_appointment_id), '') is null then
    raise exception using errcode = '22023', message = 'External appointment ID is required';
  end if;

  begin
    summary_id := (p_summary ->> 'id')::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '22023', message = 'Result summary ID is invalid';
  end;

  if coalesce(p_summary ->> 'version', '') !~ '^[1-9][0-9]{0,8}$' then
    raise exception using errcode = '22023', message = 'Result summary version is invalid';
  end if;
  summary_version := (p_summary ->> 'version')::integer;
  overall_status := p_summary ->> 'overall_status';
  if overall_status is null or overall_status not in (
    'routine', 'follow_up', 'needs_attention', 'urgent'
  ) then
    raise exception using errcode = '22023', message = 'Result summary status is invalid';
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
  if lower(appointment_row.status) not in ('confirmed', 'rescheduled', 'completed') then
    raise exception using errcode = '23514', message = 'Appointment is not ready for a result';
  end if;

  select * into existing_summary
  from public.appointment_result_summaries s
  where s.appointment_id = appointment_row.id
  for update;

  if existing_summary.id is not null and existing_summary.id <> summary_id then
    raise exception using errcode = '23514', message = 'Result summary mapping does not match';
  end if;

  source_maternal := case
    when jsonb_typeof(p_summary -> 'maternal_health') = 'object'
      then p_summary -> 'maternal_health'
    else '{}'::jsonb
  end;
  source_pregnancy := case
    when jsonb_typeof(p_summary -> 'pregnancy_health') = 'object'
      then p_summary -> 'pregnancy_health'
    else '{}'::jsonb
  end;

  safe_maternal := jsonb_build_object(
    'heart_rate', public.patient_safe_result_measurement(source_maternal, 'heart_rate'),
    'blood_pressure', public.patient_safe_result_measurement(source_maternal, 'blood_pressure'),
    'hemoglobin', public.patient_safe_result_measurement(source_maternal, 'hemoglobin')
  );
  safe_pregnancy := jsonb_build_object(
    'pregnancy_status', jsonb_strip_nulls(jsonb_build_object(
      'state', case
        when source_pregnancy #>> '{pregnancy_status,state}' = 'recorded'
          then 'recorded' else null end,
      'value', case
        when source_pregnancy #>> '{pregnancy_status,value}' in (
          'pregnant', 'not_pregnant', 'not_provided', 'prefer_not_to_say'
        ) then source_pregnancy #>> '{pregnancy_status,value}' else null end,
      'source', case
        when source_pregnancy #>> '{pregnancy_status,source}' in (
          'patient', 'clinician'
        ) then source_pregnancy #>> '{pregnancy_status,source}' else null end
    )),
    'fetal_heartbeat', public.patient_safe_result_measurement(source_pregnancy, 'fetal_heartbeat'),
    'heartbeat_quality', public.patient_safe_result_measurement(source_pregnancy, 'heartbeat_quality'),
    'fetal_position', public.patient_safe_result_measurement(source_pregnancy, 'fetal_position'),
    'estimated_baby_size', public.patient_safe_result_measurement(source_pregnancy, 'estimated_baby_size')
  );

  if existing_summary.id is null or summary_version > existing_summary.version then
    insert into public.appointment_result_summaries (
      id,
      appointment_id,
      external_appointment_id,
      external_encounter_id,
      version,
      clinician_display_name,
      clinic_name,
      appointment_date,
      completed_at,
      overall_status,
      maternal_summary,
      pregnancy_summary,
      key_findings,
      recommendations,
      follow_up_instructions,
      referral_summary,
      next_appointment_at,
      urgent_care_instruction,
      generated_at
    ) values (
      summary_id,
      appointment_row.id,
      trim(p_external_appointment_id),
      left(trim(coalesce(p_summary ->> 'encounter_id', '')), 240),
      summary_version,
      left(trim(coalesce(p_summary ->> 'clinician_display_name', 'Your clinician')), 240),
      left(trim(coalesce(p_summary ->> 'clinic_name', 'Your clinic')), 240),
      coalesce((p_summary ->> 'appointment_date')::date, appointment_row.appointment_date),
      coalesce((p_summary ->> 'completed_at')::timestamptz, p_effective_at, now()),
      overall_status,
      safe_maternal,
      safe_pregnancy,
      left(nullif(trim(p_summary ->> 'key_findings'), ''), 4000),
      left(nullif(trim(p_summary ->> 'recommendations'), ''), 8000),
      left(nullif(trim(p_summary ->> 'follow_up_instructions'), ''), 8000),
      left(nullif(trim(p_summary ->> 'referral_summary'), ''), 8000),
      case
        when coalesce(p_summary ->> 'next_appointment_at', '') = '' then null
        else (p_summary ->> 'next_appointment_at')::timestamptz
      end,
      left(nullif(trim(p_summary ->> 'urgent_care_instruction'), ''), 4000),
      coalesce((p_summary ->> 'generated_at')::timestamptz, now())
    )
    on conflict (appointment_id)
    do update set
      external_appointment_id = excluded.external_appointment_id,
      external_encounter_id = excluded.external_encounter_id,
      version = excluded.version,
      clinician_display_name = excluded.clinician_display_name,
      clinic_name = excluded.clinic_name,
      appointment_date = excluded.appointment_date,
      completed_at = excluded.completed_at,
      overall_status = excluded.overall_status,
      maternal_summary = excluded.maternal_summary,
      pregnancy_summary = excluded.pregnancy_summary,
      key_findings = excluded.key_findings,
      recommendations = excluded.recommendations,
      follow_up_instructions = excluded.follow_up_instructions,
      referral_summary = excluded.referral_summary,
      next_appointment_at = excluded.next_appointment_at,
      urgent_care_instruction = excluded.urgent_care_instruction,
      generated_at = excluded.generated_at,
      received_at = now(),
      updated_at = now()
    where public.appointment_result_summaries.version < excluded.version
    returning * into summary_row;
  end if;

  if summary_row.id is null then
    select * into summary_row
    from public.appointment_result_summaries s
    where s.appointment_id = appointment_row.id;
  end if;

  update public.appointments a
  set status = 'completed',
      dawa_clinician_appointment_id = coalesce(
        a.dawa_clinician_appointment_id,
        trim(p_external_appointment_id)
      ),
      external_appointment_id = coalesce(
        a.external_appointment_id,
        trim(p_external_appointment_id)
      ),
      patient_safe_status_message = coalesce(
        left(nullif(trim(p_patient_safe_message), ''), 500),
        'Your appointment is complete and your care summary is available.'
      ),
      result_summary_id = summary_row.id,
      result_received_at = now(),
      integration_status = 'synced',
      integration_synced_at = coalesce(p_effective_at, now()),
      integration_error_code = null
  where a.id = appointment_row.id
  returning * into appointment_row;

  result_payload := jsonb_build_object(
    'ok', true,
    'event_id', p_event_id,
    'appointment_id', appointment_row.id,
    'external_appointment_id', appointment_row.dawa_clinician_appointment_id,
    'summary_id', summary_row.id,
    'summary_version', summary_row.version,
    'status', appointment_row.status
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
    'appointment.results_available',
    appointment_row.id,
    summary_row.id::text,
    result_payload
  );

  return result_payload;
end;
$$;

revoke all on function public.patient_safe_result_measurement(jsonb, text)
  from public, anon, authenticated;
revoke all on function public.apply_dawa_clinician_appointment_result(
  uuid, uuid, text, timestamptz, text, jsonb
) from public, anon, authenticated;
grant execute on function public.apply_dawa_clinician_appointment_result(
  uuid, uuid, text, timestamptz, text, jsonb
) to service_role;

comment on table public.appointment_result_summaries is
  'Patient-readable allowlisted summaries received from Dawa Clinician; never a copy of the private encounter.';

commit;
