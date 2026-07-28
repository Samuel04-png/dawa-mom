-- Durable, owner-scoped in-app notifications.
-- External push/SMS/email delivery remains behind separately configured
-- server adapters; this table never stores provider credentials.

begin;

create table if not exists public.notifications (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  category text not null,
  template_key text not null,
  title text not null,
  body text not null,
  public_title text not null default 'Dawa Mom',
  public_body text not null default 'A new update is available in Dawa Mom.',
  route text,
  source_type text,
  source_id uuid,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  archived_at timestamptz,
  constraint notifications_category_check check (
    category in (
      'appointments',
      'cycle',
      'pregnancy',
      'learning',
      'rewards',
      'check_ins',
      'account'
    )
  ),
  constraint notifications_title_length_check check (
    length(title) between 1 and 120
    and length(body) between 1 and 500
    and length(public_title) between 1 and 120
    and length(public_body) between 1 and 240
  ),
  constraint notifications_source_template_unique unique (
    profile_id,
    source_type,
    source_id,
    template_key
  )
);

create index if not exists notifications_owner_created_idx
  on public.notifications(profile_id, created_at desc);
create index if not exists notifications_owner_unread_idx
  on public.notifications(profile_id, created_at desc)
  where read_at is null and archived_at is null;
create index if not exists notifications_owner_category_idx
  on public.notifications(profile_id, category, created_at desc)
  where archived_at is null;

alter table public.notifications enable row level security;

drop policy if exists notifications_select_owner on public.notifications;
create policy notifications_select_owner
  on public.notifications
  for select
  to authenticated
  using (profile_id = auth.uid());

drop policy if exists notifications_update_owner on public.notifications;
create policy notifications_update_owner
  on public.notifications
  for update
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

revoke all on table public.notifications from anon, authenticated;
grant select on table public.notifications to authenticated;
grant update (read_at, archived_at) on table public.notifications
  to authenticated;

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
    v_body := 'Your appointment request is being reviewed. Open Dawa Mom for the latest status.';
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
      'Open Dawa Mom to review your appointment update.'
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
    'Dawa Mom appointment update',
    'Open Dawa Mom to review an appointment update.',
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

drop trigger if exists create_appointment_notification
  on public.appointments;
create trigger create_appointment_notification
  after insert or update of status
  on public.appointments
  for each row execute function public.create_appointment_notification();

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

comment on table public.notifications is
  'Owner-scoped, privacy-safe in-app notifications created by trusted database and Edge Function workflows.';
comment on column public.notifications.public_body is
  'Generic wording safe for an external lock-screen preview.';

commit;
