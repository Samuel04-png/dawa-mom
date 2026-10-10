-- Dawa Mom source side of the `clinician_risk_alerts` cross-project sync.
--
-- This migration does NOT introduce a second synchronisation architecture. It
-- reuses the existing durable `public.integration_outbox` transport that already
-- carries `patient.upsert`, `patient.archived`, `appointment.created` and
-- `appointment.cancelled` events to Dawa Clinician through the existing
-- `process-dawa-platform-outbox` worker. Only the event vocabulary, the trigger
-- and the worker mapping are extended.
--
-- Purpose:
--   * create the Dawa Mom authoritative `public.clinician_risk_alerts` table when
--     it does not already exist and extend a pre-existing table additively
--   * enqueue INSERT/UPDATE/DELETE risk-alert changes into `integration_outbox`
--     in the same transaction as the change
--   * keep a stable alert identity (`id`) so Dawa Clinician can mirror the row
--     without creating duplicates
--
-- Existing-data impact:
--   Additive-only. `create table if not exists` plus `add column if not exists`,
--   so a pre-existing table keeps every row and every column it already has. No
--   row is deleted, renamed or rewritten by this migration. The one-time backfill
--   at the end only inserts new `integration_outbox` rows.
--
-- RLS impact:
--   RLS stays enabled. Patients read only their own alerts, doctor/admin roles
--   read and manage alerts, and the outbox/ledger stay private (no Flutter-facing
--   policy, existing behaviour preserved).
--
-- Rollback:
--   Disable the new trigger and let the outbox drain, or delete the pending
--   `risk_alert.%` outbox rows. Keep the additive columns and table in place; they
--   are reconciliation evidence.

begin;

-- ---------------------------------------------------------------------------
-- 1. Authoritative source table
-- ---------------------------------------------------------------------------

create table if not exists public.clinician_risk_alerts (
  id uuid primary key default extensions.gen_random_uuid(),
  mother_id uuid not null references public.mothers(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  clinic_id uuid references public.clinics(id) on delete set null,
  alert_type text not null default 'maternal_risk',
  severity text not null default 'moderate',
  status text not null default 'open',
  title text not null,
  summary text,
  details text,
  recommendation text,
  vital_context jsonb not null default '{}'::jsonb,
  provenance text not null default 'dawa_mom',
  detected_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  acknowledged_by uuid,
  resolved_at timestamptz,
  resolved_by uuid,
  dismissed_at timestamptz,
  dismissed_by uuid,
  status_updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  dawa_clinician_alert_id text,
  integration_status text not null default 'pending',
  integration_synced_at timestamptz,
  integration_error_code text,
  constraint clinician_risk_alerts_severity_check check (
    severity in ('low', 'moderate', 'high', 'critical')
  ),
  constraint clinician_risk_alerts_status_check check (
    status in ('open', 'acknowledged', 'resolved', 'dismissed', 'archived')
  ),
  constraint clinician_risk_alerts_integration_status_check check (
    integration_status in ('pending', 'queued', 'synced', 'failed')
  ),
  constraint clinician_risk_alerts_title_check check (length(trim(title)) >= 3),
  constraint clinician_risk_alerts_vital_context_object_check check (
    jsonb_typeof(vital_context) = 'object'
  )
);

-- Extend a pre-existing table without touching existing data. These columns are
-- added as nullable (or defaulted) so the statement stays safe even when the
-- table already holds rows.
alter table public.clinician_risk_alerts
  add column if not exists mother_id uuid,
  add column if not exists doctor_id uuid,
  add column if not exists clinic_id uuid,
  add column if not exists alert_type text default 'maternal_risk',
  add column if not exists severity text default 'moderate',
  add column if not exists status text default 'open',
  add column if not exists title text,
  add column if not exists summary text,
  add column if not exists details text,
  add column if not exists recommendation text,
  add column if not exists vital_context jsonb default '{}'::jsonb,
  add column if not exists provenance text default 'dawa_mom',
  add column if not exists detected_at timestamptz default now(),
  add column if not exists acknowledged_at timestamptz,
  add column if not exists acknowledged_by uuid,
  add column if not exists resolved_at timestamptz,
  add column if not exists resolved_by uuid,
  add column if not exists dismissed_at timestamptz,
  add column if not exists dismissed_by uuid,
  add column if not exists status_updated_at timestamptz default now(),
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now(),
  add column if not exists dawa_clinician_alert_id text,
  add column if not exists integration_status text default 'pending',
  add column if not exists integration_synced_at timestamptz,
  add column if not exists integration_error_code text;

create index if not exists clinician_risk_alerts_mother_idx
  on public.clinician_risk_alerts(mother_id, created_at desc);

create index if not exists clinician_risk_alerts_status_idx
  on public.clinician_risk_alerts(status, severity, created_at desc);

create index if not exists clinician_risk_alerts_pending_sync_idx
  on public.clinician_risk_alerts(integration_status, updated_at)
  where integration_status <> 'synced';

create unique index if not exists clinician_risk_alerts_clinician_id_uidx
  on public.clinician_risk_alerts(dawa_clinician_alert_id)
  where dawa_clinician_alert_id is not null;

drop trigger if exists set_clinician_risk_alerts_updated_at
  on public.clinician_risk_alerts;
create trigger set_clinician_risk_alerts_updated_at
  before update on public.clinician_risk_alerts
  for each row execute function public.set_updated_at();

alter table public.clinician_risk_alerts enable row level security;

drop policy if exists clinician_risk_alerts_select_allowed
  on public.clinician_risk_alerts;
create policy clinician_risk_alerts_select_allowed
  on public.clinician_risk_alerts
  for select
  to authenticated
  using (
    public.is_admin()
    or public.is_doctor()
    or exists (
      select 1
      from public.mothers m
      where m.id = clinician_risk_alerts.mother_id
        and m.profile_id = auth.uid()
    )
  );

drop policy if exists clinician_risk_alerts_clinical_manage
  on public.clinician_risk_alerts;
create policy clinician_risk_alerts_clinical_manage
  on public.clinician_risk_alerts
  for all
  to authenticated
  using (public.is_admin() or public.is_doctor())
  with check (public.is_admin() or public.is_doctor());

grant select, insert, update, delete on public.clinician_risk_alerts
  to service_role;

-- ---------------------------------------------------------------------------
-- 2. Extend the existing outbox vocabulary (no second queue is created)
-- ---------------------------------------------------------------------------

alter table public.integration_outbox
  drop constraint if exists integration_outbox_event_type_check;
alter table public.integration_outbox
  add constraint integration_outbox_event_type_check check (
    event_type in (
      'patient.upsert',
      'patient.archived',
      'appointment.created',
      'appointment.cancelled',
      'risk_alert.upsert',
      'risk_alert.archived'
    )
  );

alter table public.integration_outbox
  drop constraint if exists integration_outbox_aggregate_type_check;
alter table public.integration_outbox
  add constraint integration_outbox_aggregate_type_check check (
    aggregate_type in ('mother', 'appointment', 'risk_alert')
  );

-- ---------------------------------------------------------------------------
-- 3. Sanitised payload builder
-- ---------------------------------------------------------------------------

-- Reads the row through `to_jsonb` so every source column travels to Dawa
-- Clinician even when the source table is a pre-existing schema with extra
-- columns this migration does not know about. Explicit keys are supplied for the
-- fields Dawa Clinician mirrors into typed destination columns. Nulls are kept
-- (no `jsonb_strip_nulls`) so a cleared field such as `resolved_at` can clear the
-- destination value instead of silently retaining a stale one.
--
-- The row is passed in as jsonb rather than re-read by id because an AFTER DELETE
-- trigger runs once the row is already gone.
create or replace function public.build_dawa_mom_risk_alert_sync_payload_from_row(
  p_alert jsonb,
  p_effective_at timestamptz default null,
  p_source_deleted_at timestamptz default null
)
returns jsonb
language plpgsql
immutable
as $$
declare
  row_updated_at timestamptz;
begin
  if p_alert is null or jsonb_typeof(p_alert) <> 'object' then
    raise exception using errcode = '22023', message = 'Risk alert row is required';
  end if;

  row_updated_at := nullif(p_alert ->> 'updated_at', '')::timestamptz;

  return jsonb_build_object(
    'source', 'dawa_mom',
    'source_alert_id', nullif(p_alert ->> 'id', ''),
    'source_mother_id', nullif(p_alert ->> 'mother_id', ''),
    'alert_type', coalesce(nullif(p_alert ->> 'alert_type', ''), 'maternal_risk'),
    'severity', coalesce(nullif(p_alert ->> 'severity', ''), 'moderate'),
    -- Earlier installations used a `unacknowledged` status that the Dawa
    -- Clinician receiver does not accept. Normalise it to `open` (its modern
    -- equivalent) so legacy alerts mirror cleanly without mutating source data.
    'status', case lower(coalesce(nullif(p_alert ->> 'status', ''), ''))
      when '' then 'open'
      when 'unacknowledged' then 'open'
      else p_alert ->> 'status'
    end,
    -- Earlier installations can contain alert rows created before `title` was
    -- mandatory. Preserve those rows in the cross-project sync with a clear,
    -- neutral title rather than permanently failing their backfill event.
    'title', coalesce(
      nullif(trim(coalesce(p_alert ->> 'title', '')), ''),
      'Clinical risk alert'
    ),
    'summary', nullif(trim(coalesce(p_alert ->> 'summary', '')), ''),
    'details', nullif(trim(coalesce(p_alert ->> 'details', '')), ''),
    'recommendation',
      nullif(trim(coalesce(p_alert ->> 'recommendation', '')), ''),
    'vital_context', coalesce(p_alert -> 'vital_context', '{}'::jsonb),
    'provenance', coalesce(nullif(p_alert ->> 'provenance', ''), 'dawa_mom'),
    'detected_at', p_alert -> 'detected_at',
    'acknowledged_at', p_alert -> 'acknowledged_at',
    'resolved_at', p_alert -> 'resolved_at',
    'dismissed_at', p_alert -> 'dismissed_at',
    'source_created_at', p_alert -> 'created_at',
    'source_updated_at', greatest(
      coalesce(row_updated_at, to_timestamp(0)),
      coalesce(p_effective_at, row_updated_at, now())
    ),
    'source_deleted_at', p_source_deleted_at,
    'source_record', p_alert
  );
end;
$$;

create or replace function public.build_dawa_mom_risk_alert_sync_payload(
  p_alert_id uuid,
  p_effective_at timestamptz default null,
  p_source_deleted_at timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  alert_row public.clinician_risk_alerts%rowtype;
begin
  select * into alert_row
  from public.clinician_risk_alerts a
  where a.id = p_alert_id;

  if alert_row.id is null then
    raise exception using errcode = 'P0002', message = 'Risk alert was not found';
  end if;

  return public.build_dawa_mom_risk_alert_sync_payload_from_row(
    to_jsonb(alert_row),
    p_effective_at,
    p_source_deleted_at
  );
end;
$$;

revoke all on function public.build_dawa_mom_risk_alert_sync_payload(
  uuid, timestamptz, timestamptz
) from public, anon, authenticated;
revoke all on function public.build_dawa_mom_risk_alert_sync_payload_from_row(
  jsonb, timestamptz, timestamptz
) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Enqueue trigger
-- ---------------------------------------------------------------------------

create or replace function public.enqueue_dawa_mom_risk_alert_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_at timestamptz;
begin
  -- The worker writes `dawa_clinician_alert_id` back through
  -- `complete_dawa_platform_outbox_event`. That write must never re-enqueue, or a
  -- delivery loop would form. Both this transition flag and the trigger column
  -- list below enforce that independently.
  if coalesce(current_setting('dawa.integration_transition', true), '') = 'allowed' then
    return coalesce(new, old);
  end if;

  if tg_op = 'DELETE' then
    -- A hard delete is mirrored as a soft archive. The delete timestamp becomes
    -- the newest version so the archive is never treated as stale.
    deleted_at := now();

    insert into public.integration_outbox (
      event_type,
      aggregate_type,
      aggregate_id,
      payload
    ) values (
      'risk_alert.archived',
      'risk_alert',
      old.id,
      public.build_dawa_mom_risk_alert_sync_payload_from_row(
        to_jsonb(old),
        deleted_at,
        deleted_at
      )
    );
    return old;
  end if;

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  ) values (
    'risk_alert.upsert',
    'risk_alert',
    new.id,
    public.build_dawa_mom_risk_alert_sync_payload_from_row(
      to_jsonb(new),
      new.updated_at,
      null
    )
  );

  return new;
end;
$$;

revoke all on function public.enqueue_dawa_mom_risk_alert_sync() from public;

drop trigger if exists enqueue_dawa_mom_risk_alert_sync
  on public.clinician_risk_alerts;
-- Only clinical columns are listed. `dawa_clinician_alert_id`,
-- `integration_status`, `integration_synced_at` and `integration_error_code` are
-- deliberately absent so the worker's own write-back cannot re-trigger a sync.
create trigger enqueue_dawa_mom_risk_alert_sync
  after insert or delete or update of mother_id, doctor_id, clinic_id, alert_type,
    severity, status, title, summary, details, recommendation, vital_context,
    provenance, detected_at, acknowledged_at, resolved_at, dismissed_at,
    status_updated_at
  on public.clinician_risk_alerts
  for each row execute function public.enqueue_dawa_mom_risk_alert_sync();

-- Integration mapping columns stay server-managed for non-clinical sessions.
create or replace function public.guard_risk_alert_integration_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
     and auth.uid() is not null
     and not public.is_admin()
     and not public.is_doctor() then
    if old.dawa_clinician_alert_id
         is distinct from new.dawa_clinician_alert_id
       or old.integration_status is distinct from new.integration_status
       or old.integration_synced_at is distinct from new.integration_synced_at
       or old.integration_error_code is distinct from new.integration_error_code then
      raise exception using
        errcode = '42501',
        message = 'Integration mapping fields are server managed';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.guard_risk_alert_integration_fields() from public;

drop trigger if exists guard_risk_alert_integration_fields
  on public.clinician_risk_alerts;
create trigger guard_risk_alert_integration_fields
  before update on public.clinician_risk_alerts
  for each row execute function public.guard_risk_alert_integration_fields();

-- ---------------------------------------------------------------------------
-- 5. Keep risk-alert ordering consistent with existing aggregates
-- ---------------------------------------------------------------------------

-- Same recoverable-lease claim as before. The only change is that `risk_alert`
-- rows are ordered behind their own earlier events exactly like `mother` rows, so
-- an UPDATE cannot overtake the INSERT of the same alert.
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
              o.aggregate_type in ('mother', 'risk_alert')
              and earlier.status not in ('completed', 'permanently_failed')
            )
          )
      )
    order by o.created_at, o.id
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

-- Same completion contract as before, with a `risk_alert` mapping branch added so
-- the destination alert id and the sync outcome are recorded on the source row.
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
  elsif target_event.aggregate_type = 'risk_alert' then
    update public.clinician_risk_alerts a
    set dawa_clinician_alert_id = case
          when p_success then coalesce(nullif(trim(p_destination_id), ''), a.dawa_clinician_alert_id)
          else a.dawa_clinician_alert_id
        end,
        integration_status = case
          when p_success then 'synced'
          when p_permanent then 'failed'
          else 'queued'
        end,
        integration_synced_at = case
          when p_success then now() else a.integration_synced_at
        end,
        integration_error_code = case
          when p_success then null else safe_error_code
        end
    where a.id = target_event.aggregate_id;
  end if;
end;
$$;

-- Re-assert the service-role-only contract for both replaced functions. The
-- original migration already granted these; `create or replace function` keeps
-- existing ACLs, and this keeps the intent explicit and reviewable.
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

-- ---------------------------------------------------------------------------
-- 6. One-time, repeatable-safe backfill of alerts that already exist
-- ---------------------------------------------------------------------------

-- Alerts that were created before this migration have no outbox row and would
-- otherwise never reach Dawa Clinician. The guard makes this statement safe to
-- re-run and safe against a partially deployed earlier attempt: an alert that
-- already has any risk-alert outbox row is skipped rather than queued twice.
insert into public.integration_outbox (
  event_type,
  aggregate_type,
  aggregate_id,
  payload
)
select
  'risk_alert.upsert',
  'risk_alert',
  a.id,
  public.build_dawa_mom_risk_alert_sync_payload(a.id, a.updated_at, null)
from public.clinician_risk_alerts a
where a.mother_id is not null
  and not exists (
    select 1
    from public.integration_outbox o
    where o.aggregate_type = 'risk_alert'
      and o.aggregate_id = a.id
  );

-- Reflect the queued state on the source rows that were just enqueued.
-- `integration_status` is intentionally outside the enqueue trigger column list,
-- so this statement cannot create a new event.
update public.clinician_risk_alerts a
set integration_status = 'queued',
    integration_error_code = null
where a.integration_status <> 'synced'
  and exists (
    select 1
    from public.integration_outbox o
    where o.aggregate_type = 'risk_alert'
      and o.aggregate_id = a.id
      and o.status in ('pending', 'processing', 'retrying')
  );

-- ---------------------------------------------------------------------------
-- 7. Documentation
-- ---------------------------------------------------------------------------

comment on table public.clinician_risk_alerts is
  'Dawa Mom authoritative clinician risk alerts. Changes are mirrored read-only into Dawa Clinician through the existing integration_outbox.';

comment on column public.clinician_risk_alerts.dawa_clinician_alert_id is
  'Stable Dawa Clinician mirror id returned by the receiver. Server-managed.';

comment on function public.build_dawa_mom_risk_alert_sync_payload(
  uuid, timestamptz, timestamptz
) is
  'Builds the sanitised risk-alert synchronisation payload while retaining the full source row for lossless mirroring.';

comment on function public.enqueue_dawa_mom_risk_alert_sync() is
  'Queues risk_alert.upsert / risk_alert.archived events into the existing Dawa platform outbox.';

commit;
