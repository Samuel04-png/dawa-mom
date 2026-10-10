-- Keep the public product name as the single word "DawaMom".
-- This migration is additive so already-applied migration history remains
-- immutable.

begin;

alter table public.notifications
  alter column public_title set default 'DawaMom',
  alter column public_body
    set default 'A new update is available in DawaMom.';

update public.notifications
set
  title = replace(title, 'Dawa Mom', 'DawaMom'),
  body = replace(body, 'Dawa Mom', 'DawaMom'),
  public_title = replace(public_title, 'Dawa Mom', 'DawaMom'),
  public_body = replace(public_body, 'Dawa Mom', 'DawaMom')
where
  title like '%Dawa Mom%'
  or body like '%Dawa Mom%'
  or public_title like '%Dawa Mom%'
  or public_body like '%Dawa Mom%';

create or replace function public.create_appointment_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_template_key text;
  v_title text;
  v_body text;
begin
  if tg_op = 'INSERT' then
    v_template_key := 'appointment_requested';
    v_title := 'Appointment request sent';
    v_body := 'Your appointment request is being reviewed. Open DawaMom for the latest status.';
  elsif old.status is not distinct from new.status then
    return new;
  else
    v_template_key := 'appointment_status_' || new.status;
    v_title := case new.status
      when 'confirmed' then 'Appointment confirmed'
      when 'cancelled' then 'Appointment cancelled'
      when 'completed' then 'Appointment completed'
      when 'missed' then 'Appointment follow-up'
      when 'rescheduled' then 'Appointment changed'
      when 'declined' then 'Appointment update'
      else 'Appointment status updated'
    end;
    v_body := coalesce(
      nullif(trim(new.patient_safe_status_message), ''),
      'Open DawaMom to review your appointment update.'
    );
  end if;

  insert into public.notifications (
    profile_id,
    category,
    template_key,
    title,
    body,
    public_title,
    public_body,
    route,
    source_type,
    source_id
  )
  values (
    new.patient_id,
    'appointments',
    v_template_key,
    v_title,
    v_body,
    'DawaMom appointment update',
    'Open DawaMom to review an appointment update.',
    '/appointmentDetails?appointmentId=' || new.id::text,
    'appointment',
    new.id
  )
  on conflict (
    profile_id,
    source_type,
    source_id,
    template_key
  ) do nothing;

  return new;
end;
$$;

revoke all on function public.create_appointment_notification()
  from public, anon, authenticated;

comment on function public.create_appointment_notification() is
  'Creates privacy-safe appointment notifications using the DawaMom product name.';

commit;
