-- Follow-up to the already-deployed 202609240001 risk-alert sync migration.
--
-- This migration deliberately does not rewrite historical outbox jobs or change
-- source alert rows. It hardens payload construction for new updates/deletes;
-- operators can review any existing permanently-failed jobs before deciding
-- whether to replay them.

begin;

create or replace function public.build_dawa_mom_risk_alert_sync_payload_from_row(
  p_alert jsonb,
  p_effective_at timestamptz default null,
  p_source_deleted_at timestamptz default null
)
returns jsonb
language plpgsql
stable
as $$
declare
  row_updated_at timestamptz;
  normalized_severity text;
  normalized_status text;
begin
  if p_alert is null or jsonb_typeof(p_alert) <> 'object' then
    raise exception using errcode = '22023', message = 'Risk alert row is required';
  end if;

  -- Pre-sync installations can carry a text `updated_at` value. A malformed
  -- historical value must not block a fresh clinical update or DELETE trigger.
  begin
    row_updated_at := nullif(p_alert ->> 'updated_at', '')::timestamptz;
  exception
    when invalid_datetime_format or datetime_field_overflow then
      row_updated_at := null;
  end;

  normalized_severity := lower(trim(coalesce(p_alert ->> 'severity', '')));
  if normalized_severity not in ('low', 'moderate', 'high', 'critical') then
    normalized_severity := 'moderate';
  end if;

  normalized_status := lower(trim(coalesce(p_alert ->> 'status', '')));
  if normalized_status in ('', 'unacknowledged') then
    normalized_status := 'open';
  elsif normalized_status not in (
    'open', 'acknowledged', 'resolved', 'dismissed', 'archived'
  ) then
    normalized_status := 'open';
  end if;

  return jsonb_build_object(
    'source', 'dawa_mom',
    'source_alert_id', nullif(p_alert ->> 'id', ''),
    'source_mother_id', nullif(p_alert ->> 'mother_id', ''),
    'alert_type', coalesce(nullif(p_alert ->> 'alert_type', ''), 'maternal_risk'),
    'severity', normalized_severity,
    'status', normalized_status,
    'title', coalesce(
      nullif(trim(coalesce(p_alert ->> 'title', '')), ''),
      'Clinical risk alert'
    ),
    'summary', nullif(trim(coalesce(p_alert ->> 'summary', '')), ''),
    'details', nullif(trim(coalesce(p_alert ->> 'details', '')), ''),
    'recommendation',
      nullif(trim(coalesce(p_alert ->> 'recommendation', '')), ''),
    'vital_context', case
      when jsonb_typeof(p_alert -> 'vital_context') = 'object'
        then p_alert -> 'vital_context'
      else '{}'::jsonb
    end,
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

revoke all on function public.build_dawa_mom_risk_alert_sync_payload_from_row(
  jsonb, timestamptz, timestamptz
) from public, anon, authenticated;

comment on function public.build_dawa_mom_risk_alert_sync_payload_from_row(
  jsonb, timestamptz, timestamptz
) is 'Builds a canonical Dawa Mom risk-alert payload for the durable clinician sync outbox.';

commit;
