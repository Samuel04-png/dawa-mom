-- Run this after applying migrations/202605040001_initial_schema.sql.
-- It returns quick checks for the tables, auth trigger, and RLS policies the app needs.

select
  c.relname as table_name,
  c.relrowsecurity as row_security_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in (
    'profiles',
    'clinics',
    'doctors',
    'mothers',
    'first_encounters',
    'parities',
    'encounters',
    'appointments',
    'pregnancy_weeks',
    'period_tracker_settings',
    'period_tracker_entries',
    'chat_sessions',
    'chat_messages',
    'legacy_firebase_refs'
  )
order by table_name;

select
  trigger_name,
  event_object_schema,
  event_object_table
from information_schema.triggers
where trigger_name in (
    'on_auth_user_created',
    'prevent_profile_role_self_change',
    'prevent_patient_clinical_encounter_write',
    'validate_appointment_relationships',
    'guard_patient_appointment_update',
    'set_appointments_updated_at'
)
order by trigger_name;

select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

select
  policyname,
  cmd,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'encounters'
  and policyname = 'encounters_insert_patient_appointment';

select
  policyname,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'appointments'
order by policyname;

select
  proname as function_name
from pg_proc
join pg_namespace on pg_namespace.oid = pg_proc.pronamespace
where nspname = 'public'
  and proname in (
    'handle_new_auth_user',
    'current_app_role',
    'is_admin',
    'doctor_assigned_to_mother',
    'owns_chat_session',
    'prevent_patient_clinical_encounter_write',
    'validate_appointment_relationships',
    'guard_patient_appointment_update',
    'get_bookable_clinicians',
    'get_clinician_booked_slots'
  )
order by proname;
