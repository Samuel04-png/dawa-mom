begin;

create table if not exists public.legacy_orphan_records (
  id uuid primary key default extensions.gen_random_uuid(),
  firebase_ref text not null unique,
  source_collection text not null,
  reason text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.legacy_orphan_records enable row level security;

drop policy if exists legacy_orphan_records_admin_manage on public.legacy_orphan_records;
create policy legacy_orphan_records_admin_manage
  on public.legacy_orphan_records
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

commit;
