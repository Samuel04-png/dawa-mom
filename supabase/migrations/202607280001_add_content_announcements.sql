-- Scheduled, registry-backed in-app content announcements.
-- External lock-screen notifications deliberately remain generic and do not
-- read from this table.

begin;

create table if not exists public.content_announcements (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique,
  title text not null,
  body text not null,
  asset_id text not null,
  deep_link text not null,
  journey_contexts text[] not null default array['general']::text[],
  required_profile_states text[] not null default array[]::text[],
  placements text[] not null default array['home']::text[],
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  min_app_version text,
  max_app_version text,
  priority integer not null default 0,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint content_announcements_copy_length_check check (
    length(trim(slug)) between 1 and 80
    and length(trim(title)) between 1 and 120
    and length(trim(body)) between 1 and 500
    and length(trim(asset_id)) between 1 and 100
  ),
  constraint content_announcements_asset_id_check check (
    asset_id ~ '^[a-z0-9_]+_[0-9]{2}$'
  ),
  constraint content_announcements_deep_link_check check (
    left(deep_link, 1) = '/'
    and left(deep_link, 2) <> '//'
    and position('://' in deep_link) = 0
    and length(deep_link) <= 300
  ),
  constraint content_announcements_dates_check check (
    ends_at is null or ends_at > starts_at
  ),
  constraint content_announcements_journey_check check (
    journey_contexts <@ array[
      'general', 'cycle', 'pregnancy', 'postpartum'
    ]::text[]
  ),
  constraint content_announcements_placements_check check (
    placements <@ array[
      'home', 'learn', 'track', 'care', 'notification'
    ]::text[]
  )
);

create index if not exists content_announcements_active_idx
  on public.content_announcements(enabled, starts_at, ends_at, priority desc);

create index if not exists content_announcements_journeys_idx
  on public.content_announcements using gin(journey_contexts);

alter table public.content_announcements enable row level security;
alter table public.content_announcements force row level security;

drop policy if exists content_announcements_read_published
  on public.content_announcements;
create policy content_announcements_read_published
  on public.content_announcements
  for select
  to authenticated
  using (
    enabled
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  );

revoke all on table public.content_announcements from anon, authenticated;
grant select on table public.content_announcements to authenticated;

create or replace function public.set_content_announcement_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_content_announcement_updated_at()
  from public, anon, authenticated;

drop trigger if exists set_content_announcement_updated_at
  on public.content_announcements;
create trigger set_content_announcement_updated_at
  before update on public.content_announcements
  for each row execute function public.set_content_announcement_updated_at();

comment on table public.content_announcements is
  'Server-scheduled in-app content using allowlisted registry asset IDs and local deep links. Writes are service-role/admin only.';
comment on column public.content_announcements.required_profile_states is
  'Optional coarse states such as profile_incomplete; never store a diagnosis or patient identifier here.';
comment on column public.content_announcements.deep_link is
  'Validated again against the app route allowlist before rendering.';

commit;
