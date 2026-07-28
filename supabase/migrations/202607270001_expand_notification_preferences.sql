-- Privacy-safe notification timing and summary preferences.
-- Delivery providers remain server-side and are not enabled by this migration.

begin;

alter table public.dawa_mom_user_preferences
  add column if not exists weekly_summary boolean not null default false,
  add column if not exists quiet_hours_enabled boolean not null default true,
  add column if not exists quiet_hours_start time without time zone
    not null default '21:00',
  add column if not exists quiet_hours_end time without time zone
    not null default '07:00',
  add column if not exists private_lock_screen boolean not null default true;

comment on column public.dawa_mom_user_preferences.weekly_summary is
  'User consent for one non-sensitive weekly in-app summary.';
comment on column public.dawa_mom_user_preferences.quiet_hours_enabled is
  'Suppress non-transactional notifications during the configured window.';
comment on column public.dawa_mom_user_preferences.private_lock_screen is
  'Use generic external notification wording without health details.';

commit;
