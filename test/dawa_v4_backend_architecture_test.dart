import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appointment booking is atomic and idempotent in Supabase', () {
    final sql = File(
      'supabase/migrations/'
      '202607270002_idempotent_appointment_booking.sql',
    ).readAsStringSync();
    final repository = File(
      'lib/features/appointments/data/appointment_repository.dart',
    ).readAsStringSync();

    expect(sql, contains('client_idempotency_key'));
    expect(sql, contains('appointments_patient_idempotency_uidx'));
    expect(sql, contains('book_dawa_mom_appointment'));
    expect(sql, contains('security definer'));
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('unique_violation'));
    expect(sql.trimRight(), endsWith('commit;'));
    expect(repository, contains("'book_dawa_mom_appointment'"));
    expect(repository, contains("'p_idempotency_key': requestId"));
  });

  test('in-app notifications are owner scoped and privacy safe', () {
    final sql = File(
      'supabase/migrations/'
      '202607270003_add_in_app_notifications.sql',
    ).readAsStringSync();
    final preferencesSql = File(
      'supabase/migrations/'
      '202607270001_expand_notification_preferences.sql',
    ).readAsStringSync();
    final client = File(
      'lib/features/notifications/dawa_notifications_page.dart',
    ).readAsStringSync();

    expect(sql, contains('public.notifications enable row level security'));
    expect(sql, contains('profile_id = auth.uid()'));
    expect(preferencesSql, contains('private_lock_screen'));
    expect(sql, contains('public_body'));
    expect(sql, contains('create_appointment_notification'));
    expect(sql, contains('supabase_realtime'));
    expect(client, contains("table: 'notifications'"));
    expect(client, contains("column: 'profile_id'"));
    expect(client, contains('onPostgresChanges'));
    expect(sql.trimRight(), endsWith('commit;'));
  });

  test('integration functions use their safety contract without lint debt', () {
    final sql = File(
      'supabase/migrations/'
      '202607270004_harden_integration_functions.sql',
    ).readAsStringSync();

    expect(sql, contains('patient_safe_result_measurement(jsonb, text)'));
    expect(sql, contains('stable;'));
    expect(sql, contains('safe_status_message text'));
    expect(sql, contains('p_patient_safe_message'));
    expect(sql, contains('regexp_replace'));
    expect(sql, contains('to service_role'));
    expect(sql.trimRight(), endsWith('commit;'));
  });
}
