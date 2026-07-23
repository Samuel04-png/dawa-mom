import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('care hub renders real supplied appointment data responsively',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final appointment = _appointment();

    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1024, 768),
      Size(1366, 900),
      Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: DawaCarePage(
            initialAppointments: [appointment],
            initialClinics: const [
              ClinicOption(
                id: 'clinic-1',
                name: 'Kabulonga Clinic',
                address: 'Lusaka',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Your care'), findsOneWidget);
      expect(find.text('Dr Jane Banda'), findsWidgets);
      expect(find.text('Kabulonga Clinic'), findsWidgets);
    }
  });
}

Appointment _appointment() => Appointment(
      id: 'appointment-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime.now().add(const Duration(days: 7)),
      startTime: '09:00',
      endTime: '09:30',
      appointmentType: 'maternal_health',
      status: 'confirmed',
      source: 'dawa_mom',
      createdAt: DateTime.now(),
      integrationStatus: 'synced',
      clinicianName: 'Dr Jane Banda',
      clinicName: 'Kabulonga Clinic',
      clinicAddress: 'Lusaka',
    );
