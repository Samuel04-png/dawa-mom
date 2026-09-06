import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202607150003_appointment_email_outbox.sql',
  );
  final worker = File(
    'supabase/functions/process-appointment-emails/index.ts',
  );

  test('migration creates two idempotent server-only outbox jobs', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('appointment_email_outbox'));
    expect(sql, contains("(new.id, 'patient', 'appointment_requested')"));
    expect(sql, contains("(new.id, 'clinician', 'appointment_requested')"));
    expect(
        sql, contains('unique (appointment_id, recipient_kind, template_key)'));
    expect(sql, contains('for update skip locked'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('to service_role'));
    expect(sql, isNot(contains('RESEND_API_KEY=')));
  });

  test('worker resolves recipients server-side and uses stable idempotency',
      () {
    final source = worker.readAsStringSync();

    expect(source, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(source, contains('auth.admin.getUserById'));
    expect(source, contains('DAWA_CLINICIAN_EMAIL_RESOLVER_URL'));
    expect(source, contains('Idempotency-Key'));
    expect(source, contains('job.id'));
    expect(source, contains('pending until the clinic confirms'));
    expect(source, isNot(contains('flutter')));
  });

  test('Flutter sources contain no email provider secret', () {
    final matches = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => file.readAsStringSync().contains('RESEND_API_KEY'));

    expect(matches, isEmpty);
  });
}
