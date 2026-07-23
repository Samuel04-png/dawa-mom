import 'package:dawa_mom/features/appointments/data/dawa_appointment_reminder_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('appointment reminder persists all delivery preferences', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaAppointmentReminderRepository(
      preferences: preferences,
    );
    const value = DawaAppointmentReminder(
      appointmentId: 'appointment-1',
      daysBefore: 2,
      appNotification: false,
      smsNotification: true,
      emailNotification: true,
    );

    await repository.save(value);
    final restored = await repository.load('appointment-1');

    expect(restored.daysBefore, 2);
    expect(restored.appNotification, isFalse);
    expect(restored.smsNotification, isTrue);
    expect(restored.emailNotification, isTrue);
  });

  test('an enabled reminder always retains at least one delivery channel',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaAppointmentReminderRepository(
      preferences: preferences,
    );
    const invalid = DawaAppointmentReminder(
      appointmentId: 'appointment-2',
      appNotification: false,
      smsNotification: false,
      emailNotification: false,
    );

    final saved = await repository.save(invalid);

    expect(saved.appNotification, isTrue);
  });
}
