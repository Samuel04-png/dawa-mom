begin;

alter table public.clinics
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

alter table public.doctors
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

alter table public.mothers
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

alter table public.first_encounters
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

alter table public.parities
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

alter table public.encounters
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

alter table public.pregnancy_weeks
  add column if not exists legacy_payload jsonb not null default '{}'::jsonb;

commit;
