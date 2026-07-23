import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redesign migration preserves owner scoping and server-side rewards',
      () {
    final sql = File(
      'supabase/migrations/'
      '202607230001_add_dawa_mom_learning_and_preferences.sql',
    ).readAsStringSync();

    expect(sql, contains('enable row level security'));
    expect(sql, contains('profile_id = auth.uid()'));
    expect(sql, contains('redeem_dawa_mom_reward'));
    expect(sql, contains('complete_dawa_mom_learning_item'));
    expect(sql, contains('dawa_mom_appointment_reminders'));
    expect(sql, contains('appointment.patient_id = auth.uid()'));
    expect(sql.trimRight(), endsWith('commit;'));
  });

  test('Flutter contains no service-role secret for redesign persistence', () {
    final dart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(dart, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    expect(dart, isNot(contains('service_role')));
  });
}
