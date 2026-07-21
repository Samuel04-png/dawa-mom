import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final resultMigration = File(
    'supabase/migrations/202607210001_receive_appointment_results.sql',
  );
  final pregnancyMigration = File(
    'supabase/migrations/202607210002_sync_patient_pregnancy_state.sql',
  );
  final receiver = File(
    'supabase/functions/receive-dawa-clinician-appointment-status/index.ts',
  );

  test('result summaries are owner-readable and server-write-only', () {
    final sql = resultMigration.readAsStringSync();

    expect(sql,
        contains('appointment_result_summaries enable row level security'));
    expect(sql, contains('appointment_results_select_owner'));
    expect(
      sql,
      contains(
        'revoke insert, update, delete on table public.appointment_result_summaries',
      ),
    );
    expect(sql, contains('to service_role'));
    expect(sql, isNot(contains('disable row level security')));
  });

  test('receiver allowlists patient fields and rejects private notes', () {
    final source = receiver.readAsStringSync();

    expect(source, contains("eventType === 'appointment.results_available'"));
    expect(source, contains('sanitizeResultSummary'));
    expect(source, contains('sanitizeMeasurement'));
    expect(source, contains('x-dawa-sync-secret'));
    expect(source, isNot(contains('clinician_only_notes')));
    expect(source, isNot(contains('assessment_payload')));
  });

  test('result delivery is idempotent and only accepts newer versions', () {
    final sql = resultMigration.readAsStringSync();

    expect(sql, contains('pg_advisory_xact_lock'));
    expect(sql, contains('processed_integration_events'));
    expect(sql, contains('on conflict (appointment_id)'));
    expect(
      sql,
      contains('appointment_result_summaries.version < excluded.version'),
    );
    expect(sql, contains("'appointment.results_available'"));
  });

  test('pregnancy migration preserves patient provenance and backfills safely',
      () {
    final sql = pregnancyMigration.readAsStringSync();

    expect(sql, contains("'provenance', 'patient'"));
    expect(sql, contains('build_dawa_mom_patient_sync_payload'));
    expect(sql, contains('jsonb_typeof(o.payload -> \'pregnancy\')'));
    expect(sql, contains("o.status in ('pending', 'processing', 'retrying')"));
    expect(sql, isNot(contains('delete from public.integration_outbox')));
  });
}
