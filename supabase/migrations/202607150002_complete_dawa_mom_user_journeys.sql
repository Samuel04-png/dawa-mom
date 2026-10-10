-- Complete Dawa Mom profile, period tracking, walkthrough, and account journeys.
-- Existing clinical and cycle records are preserved; RLS remains enabled.

begin;

alter table public.profiles
  add column if not exists has_completed_app_walkthrough boolean not null default false,
  add column if not exists app_walkthrough_completed_at timestamptz,
  add column if not exists period_setup_skipped_at timestamptz;

alter table public.mothers
  add column if not exists pregnancy_status text not null default 'not_provided';

alter table public.mothers
  drop constraint if exists mothers_pregnancy_status_check;

alter table public.mothers
  add constraint mothers_pregnancy_status_check check (
    pregnancy_status in ('not_provided', 'pregnant', 'not_pregnant', 'prefer_not_to_say')
  );

update public.mothers m
set pregnancy_status = 'pregnant'
where pregnancy_status = 'not_provided'
  and exists (
    select 1
    from public.first_encounters f
    where f.mother_id = m.id
  );

alter table public.period_tracker_entries
  add column if not exists is_period_start boolean not null default false,
  add column if not exists period_end_date date;

alter table public.period_tracker_entries
  drop constraint if exists period_tracker_entries_period_end_check;

alter table public.period_tracker_entries
  add constraint period_tracker_entries_period_end_check check (
    period_end_date is null or period_end_date >= entry_date
  );

create index if not exists period_tracker_entries_period_history_idx
  on public.period_tracker_entries(profile_id, entry_date desc)
  where is_period_start;

-- Promote the existing latest-period value into the existing entries store so
-- current users immediately gain history without losing their predictions.
insert into public.period_tracker_entries (
  profile_id,
  entry_date,
  is_period_start
)
select
  settings.profile_id,
  settings.last_period_start,
  true
from public.period_tracker_settings settings
where settings.last_period_start is not null
on conflict (profile_id, entry_date) do update
set is_period_start = true;

create or replace function public.upsert_patient_health_profile(
  p_pregnancy_status text,
  p_lnmp date default null,
  p_estimated_due_date date default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_profile_id uuid := auth.uid();
  target_mother_id uuid;
  target_encounter_id uuid;
begin
  if target_profile_id is null then
    raise exception 'Authentication is required';
  end if;

  if p_pregnancy_status not in (
    'not_provided',
    'pregnant',
    'not_pregnant',
    'prefer_not_to_say'
  ) then
    raise exception 'Unsupported pregnancy status';
  end if;

  select id, first_encounter_id
  into target_mother_id, target_encounter_id
  from public.mothers
  where profile_id = target_profile_id;

  if target_mother_id is null then
    raise exception 'Complete your personal profile first';
  end if;

  update public.mothers
  set pregnancy_status = p_pregnancy_status
  where id = target_mother_id;

  if p_pregnancy_status <> 'pregnant' then
    return target_encounter_id;
  end if;

  if p_lnmp is not null and p_lnmp > current_date then
    raise exception 'Last menstrual period cannot be in the future';
  end if;

  if p_estimated_due_date is not null and p_estimated_due_date < current_date then
    raise exception 'Estimated due date cannot be in the past';
  end if;

  if target_encounter_id is null then
    select id
    into target_encounter_id
    from public.first_encounters
    where mother_id = target_mother_id
    order by created_at
    limit 1;
  end if;

  if target_encounter_id is null then
    insert into public.first_encounters (
      mother_id,
      lnmp,
      estimated_due_date
    )
    values (
      target_mother_id,
      p_lnmp,
      p_estimated_due_date
    )
    returning id into target_encounter_id;
  else
    update public.first_encounters
    set
      lnmp = p_lnmp,
      estimated_due_date = p_estimated_due_date
    where id = target_encounter_id
      and mother_id = target_mother_id;
  end if;

  update public.mothers
  set first_encounter_id = target_encounter_id
  where id = target_mother_id;

  return target_encounter_id;
end;
$$;

revoke all on function public.upsert_patient_health_profile(text, date, date) from public;
grant execute on function public.upsert_patient_health_profile(text, date, date) to authenticated;

-- Account deletion is intentionally server-side. The function can delete only
-- auth.uid(); profile, maternal, appointment, and tracker rows cascade safely.
create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target_user_id uuid := auth.uid();
begin
  if target_user_id is null then
    raise exception 'Authentication is required';
  end if;

  delete from auth.users where id = target_user_id;
end;
$$;

revoke all on function public.delete_current_user() from public;
grant execute on function public.delete_current_user() to authenticated;

commit;
