-- Versioned completion state for the optional in-app coach tour.
--
-- Existing members who already completed the original product walkthrough are
-- backfilled to version 1 so this new coach tour is reserved for new accounts
-- and explicit replays. Existing profile RLS policies continue to protect
-- these user-owned columns.

alter table public.profiles
  add column if not exists main_app_tour_completed_version integer
    not null default 0,
  add column if not exists main_app_tour_completed_at timestamptz;

update public.profiles
set
  main_app_tour_completed_version = 1,
  main_app_tour_completed_at =
    coalesce(app_walkthrough_completed_at, timezone('utc', now()))
where
  has_completed_app_walkthrough is true
  and main_app_tour_completed_version < 1;

comment on column public.profiles.main_app_tour_completed_version is
  'Latest version of the optional main-app coach tour completed by this user.';

comment on column public.profiles.main_app_tour_completed_at is
  'UTC completion time for the latest completed main-app coach tour.';
