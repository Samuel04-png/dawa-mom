begin;

create table if not exists public.firebase_auth_migration_credentials (
  firebase_uid text primary key,
  profile_id uuid unique references public.profiles(id) on delete cascade,
  email text not null unique,
  password_hash text not null,
  salt text not null,
  disabled boolean not null default false,
  migrated_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.firebase_auth_migration_config (
  id boolean primary key default true,
  algorithm text not null default 'SCRYPT',
  base64_signer_key text not null,
  base64_salt_separator text not null,
  rounds integer not null,
  mem_cost integer not null,
  created_at timestamptz not null default now(),
  constraint firebase_auth_migration_config_singleton check (id)
);

alter table public.firebase_auth_migration_credentials enable row level security;
alter table public.firebase_auth_migration_config enable row level security;

commit;
