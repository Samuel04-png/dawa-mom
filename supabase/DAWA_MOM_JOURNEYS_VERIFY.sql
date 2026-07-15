-- Read-only verification for 202607150002_complete_dawa_mom_user_journeys.sql.

select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'profiles' and column_name in (
      'has_completed_app_walkthrough',
      'app_walkthrough_completed_at',
      'period_setup_skipped_at'
    ))
    or (table_name = 'mothers' and column_name = 'pregnancy_status')
    or (table_name = 'period_tracker_entries' and column_name in (
      'is_period_start',
      'period_end_date'
    ))
  )
order by table_name, ordinal_position;

select routine_name, security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'upsert_patient_health_profile',
    'delete_current_user'
  )
order by routine_name;

select schemaname, tablename, policyname, roles, cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles',
    'mothers',
    'period_tracker_settings',
    'period_tracker_entries'
  )
order by tablename, policyname;
