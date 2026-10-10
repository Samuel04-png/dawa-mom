-- Read-only/post-migration verification for
-- 202610090001_add_care_plan_items.sql. Run in a non-production environment
-- before enabling a scheduler for mark_overdue_care_plan_items.

select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'care_plan_items'
order by ordinal_position;

select conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.care_plan_items'::regclass
order by conname;

select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'care_plan_items'
order by policyname;

select routine_name, security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'sync_appointment_care_plan_item',
    'mark_overdue_care_plan_items',
    'build_dawa_mom_care_item_sync_payload_from_row'
  )
order by routine_name;

select event_object_table, trigger_name, event_manipulation, action_statement
from information_schema.triggers
where event_object_schema = 'public'
  and event_object_table in ('appointments', 'care_plan_items')
order by event_object_table, trigger_name;

select event_type, aggregate_type, count(*)
from public.integration_outbox
where aggregate_type = 'care_item'
group by event_type, aggregate_type;

-- Manual policy checks (use disposable fixture identities only):
-- 1. As patient A, select care_plan_items: only A's mother/profile pair appears.
-- 2. As patient A, insert/update/delete care_plan_items: all operations fail.
-- 3. As patient B, select patient A's item: no row appears.
-- 4. As an assigned doctor, insert a source='clinician' item with
--    created_by=auth.uid(): succeeds; an unassigned doctor is denied.
-- 5. Insert/update an appointment: exactly one appointment-linked item exists;
--    complete/cancel the appointment and confirm the item mirrors the state.
-- 6. As service_role in a fixture database, call
--    mark_overdue_care_plan_items(100); only non-appointment due/recommended
--    items with elapsed due_at become overdue.
