import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202607170001_add_dawa_platform_sync.sql',
  );
  final worker = File(
    'supabase/functions/process-dawa-platform-outbox/index.ts',
  );
  final statusReceiver = File(
    'supabase/functions/receive-dawa-clinician-appointment-status/index.ts',
  );

  test('cross-project delivery is durable, idempotent, and server-only', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('create table if not exists public.integration_outbox'));
    expect(sql, contains('for update skip locked'));
    expect(sql, contains('processed_integration_events_source_event_unique'));
    expect(sql, contains('pg_advisory_xact_lock'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('to service_role'));
    expect(sql, contains('dawa_clinician_patient_id'));
    expect(sql, contains("'patient.archived'"));
    expect(sql, contains('dawa_clinician_appointment_id'));
    expect(sql, contains('email_delivery_status'));
    expect(sql, contains('retry_own_dawa_clinician_patient_sync'));
    expect(sql, contains('enqueue_dawa_mom_profile_email_sync'));
    expect(sql, contains('record_dawa_clinician_patient_mapping'));
    expect(
      sql,
      contains("o.aggregate_type = 'mother'"),
      reason: 'patient updates must be delivered in source order per mother',
    );
  });

  test('worker sends only mapped records to explicit clinician endpoints', () {
    final source = worker.readAsStringSync();

    expect(source, contains('DAWA_CLINICIAN_PATIENT_SYNC_URL'));
    expect(source, contains('DAWA_CLINICIAN_APPOINTMENT_URL'));
    expect(source, contains('x-dawa-sync-secret'));
    expect(source, contains('PATIENT_NOT_SYNCED'));
    expect(source, contains('DIRECTORY_MAPPING_MISSING'));
    expect(source, contains('retryDelayMs'));
  });

  test('status callback validates mappings and permitted states', () {
    final source = statusReceiver.readAsStringSync();

    expect(source, contains('DAWA_MOM_SYNC_SECRET'));
    expect(source, contains('allowedStatuses'));
    expect(source, contains('apply_dawa_clinician_appointment_status'));
    expect(source, contains('source_appointment_id'));
    expect(source, contains('external_appointment_id'));
  });

  test('Flutter client does not contain integration server credentials', () {
    final forbidden = <String>[
      'SUPABASE_SERVICE_ROLE_KEY',
      'DAWA_CLINICIAN_SYNC_SECRET',
      'DAWA_MOM_SYNC_SECRET',
    ];
    final dartSources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final source in dartSources) {
      final text = source.readAsStringSync();
      for (final secretName in forbidden) {
        expect(text, isNot(contains(secretName)),
            reason: '${source.path} must not reference $secretName');
      }
    }
  });
}
