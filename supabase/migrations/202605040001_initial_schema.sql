-- DawaMom initial Supabase schema.
-- This migration is a local draft for the Firebase to Supabase migration.
-- Apply it only after a Supabase project is created and reviewed by the team.

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

do $$
begin
  create type public.app_role as enum ('patient', 'doctor', 'admin');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  firebase_uid text unique,
  email text,
  display_name text,
  photo_url text,
  phone_number text,
  role public.app_role not null default 'patient',
  requested_role public.app_role not null default 'patient',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_requested_role_not_admin check (requested_role <> 'admin'::public.app_role)
);

create table if not exists public.clinics (
  id uuid primary key default extensions.gen_random_uuid(),
  firebase_ref text unique,
  name text not null,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  clinic_id uuid references public.clinics(id) on delete set null,
  firebase_ref text unique,
  legacy_doctor_id text,
  name text,
  phone_number text,
  speciality text,
  start_time text,
  end_time text,
  clinic_name_legacy text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mothers (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  firebase_ref text unique,
  legacy_mother_id text,
  name text,
  phone_number text,
  date_of_birth date,
  occupation text,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.first_encounters (
  id uuid primary key default extensions.gen_random_uuid(),
  firebase_ref text unique,
  mother_id uuid not null references public.mothers(id) on delete cascade,
  gravidity text,
  lnmp date,
  estimated_due_date date,
  hiv_status text,
  last_vl text,
  diabetes_mellitus text,
  hypertension text,
  cardiac_disease text,
  perceiving_foetal_movement text,
  sign_of_imminent_eclampsia text[] not null default '{}',
  signs_of_anaemia text[] not null default '{}',
  symptoms_of_uti text[] not null default '{}',
  draining_any_liquor text,
  herbs_taken text,
  any_allergies text,
  side_effect text,
  menstruation_regular text,
  cacx text,
  cd4 text,
  epilepsy text,
  asthma text,
  tb text,
  sickle_cell text,
  cacx_date_of_screen date,
  booked_date date,
  parity integer,
  duration_of_menstruation text,
  have_you_booked text,
  drug_taken text[] not null default '{}',
  age_of_menarche text,
  sti text[] not null default '{}',
  anc_dates date[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mothers
  add column if not exists first_encounter_id uuid references public.first_encounters(id) on delete set null;

create table if not exists public.parities (
  id uuid primary key default extensions.gen_random_uuid(),
  firebase_ref text unique,
  first_encounter_id uuid not null references public.first_encounters(id) on delete cascade,
  weight text,
  state text,
  mode_of_delivery text,
  complications text[] not null default '{}',
  year_of_birth text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.encounters (
  id uuid primary key default extensions.gen_random_uuid(),
  firebase_ref text unique,
  mother_id uuid not null references public.mothers(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  clinic_id uuid references public.clinics(id) on delete set null,
  bp text,
  pulse integer,
  next_visit date,
  comment text,
  us_obstetrics text,
  leucocytes_esterase text,
  nitrates text,
  urologobulin text,
  protein text,
  ph text,
  blood text,
  ketones text,
  bilirubin text,
  glucose text,
  color text,
  clarity text,
  odor text,
  casts text,
  refer_for_anemia text,
  appointment_date date,
  hemocheck integer,
  specific_gravity text,
  heart_beat integer,
  heart_beat_quality text,
  womb_position text,
  estimated_baby_size integer,
  foetal_hemocheck integer,
  status text not null default 'scheduled',
  is_instant boolean not null default false,
  appointment_time text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pregnancy_weeks (
  id bigserial primary key,
  firebase_ref text unique,
  week text not null,
  week_plan text,
  tips text,
  body_changes text,
  general_info text,
  baby_development text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.period_tracker_settings (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  average_cycle_length integer not null default 28,
  period_length integer not null default 5,
  is_regular boolean not null default true,
  last_period_start date,
  updated_at timestamptz not null default now(),
  constraint period_tracker_settings_cycle_length_check check (average_cycle_length between 15 and 60),
  constraint period_tracker_settings_period_length_check check (period_length between 1 and 15)
);

create table if not exists public.period_tracker_entries (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  entry_date date not null,
  symptoms text[] not null default '{}',
  notes text[] not null default '{}',
  sexual_activity jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, entry_date)
);

create table if not exists public.chat_sessions (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  redis_session_key text unique,
  firebase_ref text unique,
  phone_number text,
  user_name text,
  session_state jsonb not null default '{}'::jsonb,
  last_message text,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default extensions.gen_random_uuid(),
  session_id uuid not null references public.chat_sessions(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system', 'agent')),
  client_message_id text,
  source text not null default 'app',
  content text not null,
  payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.legacy_firebase_refs (
  firebase_path text primary key,
  table_name text not null,
  record_id text not null,
  created_at timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists doctors_clinic_id_idx on public.doctors(clinic_id);
create index if not exists mothers_profile_id_idx on public.mothers(profile_id);
create index if not exists first_encounters_mother_id_idx on public.first_encounters(mother_id);
create index if not exists parities_first_encounter_id_idx on public.parities(first_encounter_id);
create index if not exists encounters_mother_date_idx on public.encounters(mother_id, appointment_date);
create index if not exists encounters_doctor_date_idx on public.encounters(doctor_id, appointment_date);
create index if not exists period_tracker_entries_profile_date_idx on public.period_tracker_entries(profile_id, entry_date);
create index if not exists chat_sessions_profile_id_idx on public.chat_sessions(profile_id);
create index if not exists chat_messages_session_created_at_idx on public.chat_messages(session_id, created_at);

create unique index if not exists chat_messages_session_client_message_unique
  on public.chat_messages(session_id, client_message_id)
  where client_message_id is not null;

create unique index if not exists encounters_doctor_slot_unique
  on public.encounters(doctor_id, appointment_date, appointment_time)
  where doctor_id is not null
    and appointment_date is not null
    and appointment_time is not null
    and lower(status) not in ('canceled', 'cancelled');

create unique index if not exists encounters_mother_slot_unique
  on public.encounters(mother_id, appointment_date, appointment_time)
  where appointment_date is not null
    and appointment_time is not null
    and lower(status) not in ('canceled', 'cancelled');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    display_name,
    phone_number,
    requested_role,
    role
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'name'),
    new.phone,
    case
      when new.raw_user_meta_data->>'requested_role' in ('patient', 'doctor')
        then (new.raw_user_meta_data->>'requested_role')::public.app_role
      else 'patient'::public.app_role
    end,
    'patient'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create or replace function public.current_app_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_app_role() = 'admin'::public.app_role, false)
$$;

create or replace function public.is_doctor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_app_role() = 'doctor'::public.app_role, false)
$$;

create or replace function public.owns_mother(target_mother_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.mothers m
    where m.id = target_mother_id
      and m.profile_id = auth.uid()
  )
$$;

create or replace function public.doctor_owns_doctor(target_doctor_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.doctors d
    where d.id = target_doctor_id
      and d.profile_id = auth.uid()
  )
$$;

create or replace function public.doctor_assigned_to_mother(target_mother_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.encounters e
    join public.doctors d on d.id = e.doctor_id
    where e.mother_id = target_mother_id
      and d.profile_id = auth.uid()
  )
$$;

create or replace function public.doctor_assigned_to_profile(target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.mothers m
    join public.encounters e on e.mother_id = m.id
    join public.doctors d on d.id = e.doctor_id
    where m.profile_id = target_profile_id
      and d.profile_id = auth.uid()
  )
$$;

create or replace function public.can_access_first_encounter(target_first_encounter_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.first_encounters fe
    where fe.id = target_first_encounter_id
      and (
        public.is_admin()
        or public.owns_mother(fe.mother_id)
        or public.doctor_assigned_to_mother(fe.mother_id)
      )
  )
$$;

create or replace function public.can_write_first_encounter(target_first_encounter_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.first_encounters fe
    where fe.id = target_first_encounter_id
      and public.doctor_assigned_to_mother(fe.mother_id)
  )
$$;

create or replace function public.owns_chat_session(target_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.chat_sessions s
    where s.id = target_session_id
      and s.profile_id = auth.uid()
  )
$$;

create or replace function public.can_read_chat_session(target_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.chat_sessions s
    where s.id = target_session_id
      and (
        public.is_admin()
        or s.profile_id = auth.uid()
        or public.doctor_assigned_to_profile(s.profile_id)
      )
  )
$$;

create or replace function public.is_patient_appointment_status(target_status text)
returns boolean
language sql
stable
as $$
  select lower(coalesce(target_status, '')) in ('scheduled', 'canceled', 'cancelled')
$$;

create or replace function public.encounter_has_clinical_data(target public.encounters)
returns boolean
language sql
stable
as $$
  select target.bp is not null
    or target.pulse is not null
    or target.next_visit is not null
    or target.comment is not null
    or target.us_obstetrics is not null
    or target.leucocytes_esterase is not null
    or target.nitrates is not null
    or target.urologobulin is not null
    or target.protein is not null
    or target.ph is not null
    or target.blood is not null
    or target.ketones is not null
    or target.bilirubin is not null
    or target.glucose is not null
    or target.color is not null
    or target.clarity is not null
    or target.odor is not null
    or target.casts is not null
    or target.refer_for_anemia is not null
    or target.hemocheck is not null
    or target.specific_gravity is not null
    or target.heart_beat is not null
    or target.heart_beat_quality is not null
    or target.womb_position is not null
    or target.estimated_baby_size is not null
    or target.foetal_hemocheck is not null
$$;

create or replace function public.prevent_patient_clinical_encounter_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_app_role() = 'patient'::public.app_role then
    if not public.is_patient_appointment_status(new.status) then
      raise exception 'Patients can only schedule or cancel appointments';
    end if;

    if tg_op = 'INSERT' then
      if public.encounter_has_clinical_data(new) then
        raise exception 'Patients cannot create clinical encounter data';
      end if;
    elsif tg_op = 'UPDATE' then
      if old.mother_id is distinct from new.mother_id then
        raise exception 'Patients cannot reassign encounter ownership';
      end if;

      if not public.is_patient_appointment_status(old.status) then
        raise exception 'Patients cannot update clinical encounter state';
      end if;

      if public.encounter_has_clinical_data(old)
         or public.encounter_has_clinical_data(new) then
        raise exception 'Patients cannot edit clinical encounter data';
      end if;
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.prevent_profile_role_self_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
     and old.role is distinct from new.role
     and not public.is_admin() then
    raise exception 'Only admins can change profile roles';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_profile_role_self_change on public.profiles;
create trigger prevent_profile_role_self_change
  before update of role on public.profiles
  for each row execute function public.prevent_profile_role_self_change();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists set_clinics_updated_at on public.clinics;
create trigger set_clinics_updated_at
  before update on public.clinics
  for each row execute function public.set_updated_at();

drop trigger if exists set_doctors_updated_at on public.doctors;
create trigger set_doctors_updated_at
  before update on public.doctors
  for each row execute function public.set_updated_at();

drop trigger if exists set_mothers_updated_at on public.mothers;
create trigger set_mothers_updated_at
  before update on public.mothers
  for each row execute function public.set_updated_at();

drop trigger if exists set_first_encounters_updated_at on public.first_encounters;
create trigger set_first_encounters_updated_at
  before update on public.first_encounters
  for each row execute function public.set_updated_at();

drop trigger if exists set_parities_updated_at on public.parities;
create trigger set_parities_updated_at
  before update on public.parities
  for each row execute function public.set_updated_at();

drop trigger if exists set_encounters_updated_at on public.encounters;
create trigger set_encounters_updated_at
  before update on public.encounters
  for each row execute function public.set_updated_at();

drop trigger if exists prevent_patient_clinical_encounter_write on public.encounters;
create trigger prevent_patient_clinical_encounter_write
  before insert or update on public.encounters
  for each row execute function public.prevent_patient_clinical_encounter_write();

drop trigger if exists set_pregnancy_weeks_updated_at on public.pregnancy_weeks;
create trigger set_pregnancy_weeks_updated_at
  before update on public.pregnancy_weeks
  for each row execute function public.set_updated_at();

drop trigger if exists set_period_tracker_settings_updated_at on public.period_tracker_settings;
create trigger set_period_tracker_settings_updated_at
  before update on public.period_tracker_settings
  for each row execute function public.set_updated_at();

drop trigger if exists set_period_tracker_entries_updated_at on public.period_tracker_entries;
create trigger set_period_tracker_entries_updated_at
  before update on public.period_tracker_entries
  for each row execute function public.set_updated_at();

drop trigger if exists set_chat_sessions_updated_at on public.chat_sessions;
create trigger set_chat_sessions_updated_at
  before update on public.chat_sessions
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.clinics enable row level security;
alter table public.doctors enable row level security;
alter table public.mothers enable row level security;
alter table public.first_encounters enable row level security;
alter table public.parities enable row level security;
alter table public.encounters enable row level security;
alter table public.pregnancy_weeks enable row level security;
alter table public.period_tracker_settings enable row level security;
alter table public.period_tracker_entries enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;
alter table public.legacy_firebase_refs enable row level security;

create policy profiles_select_own_or_admin
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid() or public.is_admin());

create policy profiles_insert_own_patient
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid() and role = 'patient'::public.app_role);

create policy profiles_update_own_or_admin
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

create policy clinics_read_authenticated
  on public.clinics
  for select
  to authenticated
  using (true);

create policy clinics_admin_manage
  on public.clinics
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy doctors_read_authenticated
  on public.doctors
  for select
  to authenticated
  using (true);

create policy doctors_admin_insert
  on public.doctors
  for insert
  to authenticated
  with check (public.is_admin());

create policy doctors_update_own_or_admin
  on public.doctors
  for update
  to authenticated
  using (public.is_admin() or public.doctor_owns_doctor(id))
  with check (public.is_admin() or public.doctor_owns_doctor(id));

create policy doctors_admin_delete
  on public.doctors
  for delete
  to authenticated
  using (public.is_admin());

create policy mothers_select_owner_doctor_or_admin
  on public.mothers
  for select
  to authenticated
  using (
    public.is_admin()
    or profile_id = auth.uid()
    or public.doctor_assigned_to_mother(id)
  );

create policy mothers_insert_owner_or_admin
  on public.mothers
  for insert
  to authenticated
  with check (public.is_admin() or profile_id = auth.uid());

create policy mothers_update_owner_or_admin
  on public.mothers
  for update
  to authenticated
  using (public.is_admin() or profile_id = auth.uid())
  with check (public.is_admin() or profile_id = auth.uid());

create policy mothers_admin_delete
  on public.mothers
  for delete
  to authenticated
  using (public.is_admin());

create policy first_encounters_select_allowed
  on public.first_encounters
  for select
  to authenticated
  using (
    public.is_admin()
    or public.owns_mother(mother_id)
    or public.doctor_assigned_to_mother(mother_id)
  );

create policy first_encounters_insert_allowed
  on public.first_encounters
  for insert
  to authenticated
  with check (public.doctor_assigned_to_mother(mother_id));

create policy first_encounters_update_allowed
  on public.first_encounters
  for update
  to authenticated
  using (public.doctor_assigned_to_mother(mother_id))
  with check (public.doctor_assigned_to_mother(mother_id));

create policy first_encounters_delete_doctor_assigned
  on public.first_encounters
  for delete
  to authenticated
  using (public.doctor_assigned_to_mother(mother_id));

create policy parities_select_allowed
  on public.parities
  for select
  to authenticated
  using (public.can_access_first_encounter(first_encounter_id));

create policy parities_insert_allowed
  on public.parities
  for insert
  to authenticated
  with check (public.can_write_first_encounter(first_encounter_id));

create policy parities_update_allowed
  on public.parities
  for update
  to authenticated
  using (public.can_write_first_encounter(first_encounter_id))
  with check (public.can_write_first_encounter(first_encounter_id));

create policy parities_delete_doctor_assigned
  on public.parities
  for delete
  to authenticated
  using (public.can_write_first_encounter(first_encounter_id));

create policy encounters_select_allowed
  on public.encounters
  for select
  to authenticated
  using (
    public.is_admin()
    or public.owns_mother(mother_id)
    or public.doctor_owns_doctor(doctor_id)
  );

create policy encounters_insert_patient_appointment
  on public.encounters
  for insert
  to authenticated
  with check (
    public.owns_mother(mother_id)
    and public.is_patient_appointment_status(status)
  );

create policy encounters_insert_doctor_assigned
  on public.encounters
  for insert
  to authenticated
  with check (
    public.doctor_owns_doctor(doctor_id)
    and public.doctor_assigned_to_mother(mother_id)
  );

create policy encounters_update_patient_appointment
  on public.encounters
  for update
  to authenticated
  using (
    public.owns_mother(mother_id)
    and public.is_patient_appointment_status(status)
  )
  with check (
    public.owns_mother(mother_id)
    and public.is_patient_appointment_status(status)
  );

create policy encounters_update_doctor_assigned
  on public.encounters
  for update
  to authenticated
  using (public.doctor_owns_doctor(doctor_id))
  with check (public.doctor_owns_doctor(doctor_id));

create policy encounters_delete_doctor_assigned
  on public.encounters
  for delete
  to authenticated
  using (public.doctor_owns_doctor(doctor_id));

create policy pregnancy_weeks_read_authenticated
  on public.pregnancy_weeks
  for select
  to authenticated
  using (true);

create policy pregnancy_weeks_admin_manage
  on public.pregnancy_weeks
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy period_tracker_settings_owner_or_admin
  on public.period_tracker_settings
  for all
  to authenticated
  using (public.is_admin() or profile_id = auth.uid())
  with check (public.is_admin() or profile_id = auth.uid());

create policy period_tracker_entries_owner_or_admin
  on public.period_tracker_entries
  for all
  to authenticated
  using (public.is_admin() or profile_id = auth.uid())
  with check (public.is_admin() or profile_id = auth.uid());

create policy chat_sessions_select_allowed
  on public.chat_sessions
  for select
  to authenticated
  using (
    public.is_admin()
    or profile_id = auth.uid()
    or public.doctor_assigned_to_profile(profile_id)
  );

create policy chat_sessions_insert_owner
  on public.chat_sessions
  for insert
  to authenticated
  with check (profile_id = auth.uid());

create policy chat_sessions_update_owner
  on public.chat_sessions
  for update
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy chat_messages_select_allowed
  on public.chat_messages
  for select
  to authenticated
  using (public.can_read_chat_session(session_id));

create policy chat_messages_insert_owner
  on public.chat_messages
  for insert
  to authenticated
  with check (public.owns_chat_session(session_id));

create policy legacy_firebase_refs_admin_manage
  on public.legacy_firebase_refs
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

comment on table public.profiles is 'Supabase Auth profile mirror. One row per auth.users user.';
comment on column public.profiles.requested_role is 'Self-selected account type at signup. Admin role is never self-requestable; admins manually promote profiles.';
comment on table public.mothers is 'Patient profile data. profile_id is unique so every patient has a separate login and cannot share the old hardcoded mother reference.';
comment on table public.doctors is 'Doctor profile and scheduling metadata. Doctors log into the same app through profiles.role = doctor.';
comment on table public.encounters is 'Appointments and clinical encounter data. Patients can schedule/cancel appointment fields only; assigned doctors manage clinical fields; admins can read through app RLS.';
comment on table public.chat_sessions is 'Durable chat history mirror. JSON session_state supports migration away from Redis/Upstash while Supabase stores long term history.';
comment on column public.chat_messages.payload is 'Original JSON chat payload for Redis/Upstash-shaped message history migration and audit.';
comment on table public.legacy_firebase_refs is 'Mapping table for Firebase document paths to Supabase row ids during phased migration.';

commit;
