-- Extend the existing patient outbox contract with an explicit, provenance-
-- preserving pregnancy state and source dates. The nested pregnancy object
-- intentionally retains null dates so a change to not-pregnant/not-provided
-- can clear stale source dates in Dawa Clinician.

begin;

create or replace function public.build_dawa_mom_patient_sync_payload(
  p_mother_id uuid,
  p_source_updated_at timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  mother_row public.mothers%rowtype;
  first_encounter_row public.first_encounters%rowtype;
  profile_email text;
  safe_pregnancy_status text;
  pregnancy_updated_at timestamptz;
begin
  select * into mother_row
  from public.mothers m
  where m.id = p_mother_id;

  if mother_row.id is null then
    raise exception using errcode = 'P0002', message = 'Mother profile was not found';
  end if;

  select p.email into profile_email
  from public.profiles p
  where p.id = mother_row.profile_id;

  select * into first_encounter_row
  from public.first_encounters f
  where f.id = mother_row.first_encounter_id
     or f.mother_id = mother_row.id
  order by
    case when f.id = mother_row.first_encounter_id then 0 else 1 end,
    f.updated_at desc
  limit 1;

  safe_pregnancy_status := case
    when mother_row.pregnancy_status in (
      'pregnant', 'not_pregnant', 'not_provided', 'prefer_not_to_say'
    ) then mother_row.pregnancy_status
    else 'not_provided'
  end;
  pregnancy_updated_at := greatest(
    mother_row.updated_at,
    first_encounter_row.updated_at,
    p_source_updated_at
  );

  return jsonb_strip_nulls(jsonb_build_object(
    'source', 'dawa_mom',
    'source_mother_id', mother_row.id,
    'source_user_id', mother_row.profile_id,
    'name', nullif(trim(mother_row.name), ''),
    'phone_number', nullif(trim(mother_row.phone_number), ''),
    'email', nullif(lower(trim(profile_email)), ''),
    'date_of_birth', mother_row.date_of_birth,
    'occupation', nullif(trim(mother_row.occupation), ''),
    'address', nullif(trim(mother_row.address), ''),
    'source_updated_at', greatest(
      mother_row.updated_at,
      first_encounter_row.updated_at,
      p_source_updated_at
    ),
    'pregnancy', jsonb_build_object(
      'status', safe_pregnancy_status,
      'lnmp', case when safe_pregnancy_status = 'pregnant'
        then first_encounter_row.lnmp else null end,
      'estimated_due_date', case when safe_pregnancy_status = 'pregnant'
        then first_encounter_row.estimated_due_date else null end,
      'provenance', 'patient',
      'updated_at', pregnancy_updated_at
    )
  ));
end;
$$;

create or replace function public.enqueue_dawa_mom_patient_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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
    old.address,
    old.pregnancy_status,
    old.first_encounter_id
  ) is not distinct from row(
    new.profile_id,
    new.name,
    new.phone_number,
    new.date_of_birth,
    new.occupation,
    new.address,
    new.pregnancy_status,
    new.first_encounter_id
  ) then
    return new;
  end if;

  if not public.dawa_mom_mother_is_syncable(new) then
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
    new.id,
    public.build_dawa_mom_patient_sync_payload(new.id, new.updated_at)
  );

  return new;
end;
$$;

drop trigger if exists enqueue_dawa_mom_patient_sync on public.mothers;
create trigger enqueue_dawa_mom_patient_sync
  after insert or delete or update of profile_id, name, phone_number,
    date_of_birth, occupation, address, pregnancy_status, first_encounter_id
  on public.mothers
  for each row execute function public.enqueue_dawa_mom_patient_sync();

create or replace function public.enqueue_dawa_mom_first_encounter_patient_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_mother_id uuid;
  target_updated_at timestamptz;
  mother_row public.mothers%rowtype;
begin
  if tg_op = 'DELETE' then
    target_mother_id := old.mother_id;
    target_updated_at := coalesce(old.updated_at, now());
  else
    target_mother_id := new.mother_id;
    target_updated_at := coalesce(new.updated_at, now());
  end if;

  select * into mother_row
  from public.mothers m
  where m.id = target_mother_id;

  if mother_row.id is null
     or not public.dawa_mom_mother_is_syncable(mother_row) then
    if tg_op = 'DELETE' then return old; end if;
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
    public.build_dawa_mom_patient_sync_payload(
      mother_row.id,
      target_updated_at
    )
  );

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists enqueue_dawa_mom_first_encounter_patient_sync
  on public.first_encounters;
create trigger enqueue_dawa_mom_first_encounter_patient_sync
  after insert or delete or update of lnmp, estimated_due_date, mother_id
  on public.first_encounters
  for each row execute function public.enqueue_dawa_mom_first_encounter_patient_sync();

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
    public.build_dawa_mom_patient_sync_payload(mother_row.id, new.updated_at)
  );

  return new;
end;
$$;

create or replace function public.retry_own_dawa_clinician_patient_sync()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  mother_row public.mothers%rowtype;
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

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  ) values (
    'patient.upsert',
    'mother',
    mother_row.id,
    public.build_dawa_mom_patient_sync_payload(mother_row.id, now())
  )
  returning event_id into created_event_id;

  return created_event_id;
end;
$$;

revoke all on function public.build_dawa_mom_patient_sync_payload(uuid, timestamptz)
  from public, anon, authenticated;
revoke all on function public.enqueue_dawa_mom_first_encounter_patient_sync()
  from public;
revoke all on function public.enqueue_dawa_mom_patient_sync()
  from public;
revoke all on function public.enqueue_dawa_mom_profile_email_sync()
  from public;
revoke all on function public.retry_own_dawa_clinician_patient_sync()
  from public, anon;
grant execute on function public.retry_own_dawa_clinician_patient_sync()
  to authenticated;

-- Queue an idempotent one-time backfill for every already-syncable mother.
-- Existing active events that already contain this contract are not duplicated.
insert into public.integration_outbox (
  event_type,
  aggregate_type,
  aggregate_id,
  payload
)
select
  'patient.upsert',
  'mother',
  m.id,
  public.build_dawa_mom_patient_sync_payload(m.id, now())
from public.mothers m
where public.dawa_mom_mother_is_syncable(m)
  and not exists (
    select 1
    from public.integration_outbox o
    where o.event_type = 'patient.upsert'
      and o.aggregate_type = 'mother'
      and o.aggregate_id = m.id
      and o.status in ('pending', 'processing', 'retrying')
      and jsonb_typeof(o.payload -> 'pregnancy') = 'object'
  );

commit;
