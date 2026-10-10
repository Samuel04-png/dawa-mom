import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202610090001_add_care_plan_items.sql',
  );
  final worker = File(
    'supabase/functions/process-dawa-platform-outbox/index.ts',
  );

  test('care plan is owner-scoped and clinician access uses assignment', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('create table if not exists public.care_plan_items'));
    expect(
        sql, contains('patient_id uuid not null references public.profiles'));
    expect(sql, contains('mother_id uuid not null references public.mothers'));
    expect(
        sql,
        contains(
            'alter table public.care_plan_items enable row level security'));
    expect(sql, contains('patient_id = auth.uid()'));
    expect(sql, contains('public.owns_mother(mother_id)'));
    expect(sql, contains('public.doctor_assigned_to_mother(mother_id)'));
    expect(
        sql,
        isNot(contains(
            'care_plan_items_select_allowed\n  on public.care_plan_items\n  for select\n  to authenticated\n  using (true)')));
  });

  test('care items have traceable lifecycle, source, and duplicate protection',
      () {
    final sql = migration.readAsStringSync();

    expect(sql,
        contains("'recommended', 'due', 'scheduled', 'completed', 'overdue'"));
    expect(sql, contains("'cancelled', 'dismissed'"));
    expect(sql, contains('source_record_id text'));
    expect(sql, contains('created_by uuid references public.profiles'));
    expect(sql, contains('care_plan_items_source_record_uidx'));
    expect(sql, contains('care_plan_items_appointment_uidx'));
    expect(sql, contains('guard_care_plan_item_transition'));
    expect(sql, contains('mark_overdue_care_plan_items'));
  });

  test('appointment-linked care items are generated once and mirror lifecycle',
      () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('sync_appointment_care_plan_item'));
    expect(sql, contains("when 'completed' then 'completed'"));
    expect(sql,
        contains("when 'cancelled', 'declined', 'missed' then 'cancelled'"));
    expect(sql, contains("'appointment', new.id::text"));
    expect(
        sql,
        contains(
            'on conflict (appointment_id) where appointment_id is not null'));
  });

  test(
      'care-item sync extends the existing durable outbox without client secrets',
      () {
    final sql = migration.readAsStringSync();
    final source = worker.readAsStringSync();

    expect(sql, contains("'care_item.upsert', 'care_item.archived'"));
    expect(
        sql,
        contains(
            "aggregate_type in ('mother', 'appointment', 'risk_alert', 'care_item')"));
    expect(sql, contains('build_dawa_mom_care_item_sync_payload_from_row'));
    expect(sql, contains('enqueue_dawa_mom_care_item_sync'));
    expect(sql, contains('to service_role'));
    expect(source, contains('DAWA_CLINICIAN_CARE_ITEM_URL'));
    expect(source, contains('CARE_ITEM_ENDPOINT_NOT_CONFIGURED'));
    expect(source, contains("job.event_type === 'care_item.archived'"));
    expect(source, contains('loadCareItemPayload'));
  });

  test('patient cancellation records delivery state separately from status',
      () {
    final sql = File(
      'supabase/migrations/202610090002_track_cancellation_sync_state.sql',
    ).readAsStringSync();

    expect(sql, contains("new.status = 'cancelled'"));
    expect(sql, contains("new.integration_status := 'queued'"));
    expect(sql, contains('z_mark_patient_cancellation_pending_sync'));
  });
}
