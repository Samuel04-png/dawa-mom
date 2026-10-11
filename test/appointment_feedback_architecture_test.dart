import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final feedback = File(
    'lib/features/feedback/dawa_feedback_effects.dart',
  ).readAsStringSync();
  final carePage = File(
    'lib/features/appointments/presentation/dawa_care_page.dart',
  ).readAsStringSync();
  final legacyAppointments = File(
    'lib/navbar/appointments/encounters/encounters_widget.dart',
  ).readAsStringSync();
  final responsiveHome = File(
    'lib/components/responsive/responsive_home_dashboard.dart',
  ).readAsStringSync();
  final upcomingAppointment = File(
    'lib/components/responsive/upcoming_appointment_section.dart',
  ).readAsStringSync();
  final legacyHome =
      File('lib/navbar/home/home_widget.dart').readAsStringSync();

  test('appointment feedback uses a registered local sound asset', () {
    expect(
      File('assets/audios/sounds/notification_05.mp3').existsSync(),
      isTrue,
    );
    expect(feedback, contains('AudioCache(prefix: \'\')'));
    expect(
      feedback,
      contains("'assets/audios/sounds/notification_05.mp3'"),
    );
    expect(feedback, contains('preferences.soundEffectsEnabled'));
    expect(feedback, contains('AssetSource(assetPath)'));
  });

  test('only completed booking states request appointment sound feedback', () {
    const careCompletionGate =
        '!appointment.requiresOnlinePayment || result.paymentSucceeded';
    const legacyCompletionGate =
        '!result.appointment.requiresOnlinePayment || result.paymentSucceeded';
    expect(carePage, contains(careCompletionGate));
    expect(carePage, contains('DawaFeedbackEffects.appointmentBooked()'));
    expect(legacyAppointments, contains(legacyCompletionGate));
    expect(
      legacyAppointments,
      contains('DawaFeedbackEffects.appointmentBooked()'),
    );
    expect(
        responsiveHome, contains('result.appointment.requiresOnlinePayment'));
    expect(responsiveHome, contains('result.paymentSucceeded'));
    expect(responsiveHome, contains('DawaFeedbackEffects.appointmentBooked()'));
    expect(upcomingAppointment, contains(legacyCompletionGate));
    expect(
      upcomingAppointment,
      contains('DawaFeedbackEffects.appointmentBooked()'),
    );
    expect(legacyHome, contains('DawaFeedbackEffects.appointmentBooked()'));
  });

  test('only a real clinic confirmation receives a status sound', () {
    expect(carePage, contains("if (status == 'confirmed')"));
    expect(carePage, contains('DawaFeedbackEffects.appointmentConfirmed()'));
  });
}
