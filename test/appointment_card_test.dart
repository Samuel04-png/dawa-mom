import 'package:dawa_mom/components/responsive/upcoming_appointment_section.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _appointment = Appointment(
  id: 'appointment-1',
  motherId: 'mother-1',
  patientId: 'patient-1',
  clinicianId: 'clinician-1',
  clinicId: 'clinic-1',
  date: DateTime(2099, 7, 20),
  startTime: '09:00',
  endTime: '09:30',
  appointmentType: 'maternal_health',
  status: 'confirmed',
  source: 'dawa_mom',
  createdAt: DateTime(2026, 7, 15),
  integrationStatus: 'delivered',
  clinicianName: 'Dr Jane',
  clinicName: 'Dawa Clinic',
);

Widget _host({required VoidCallback onOpen, VoidCallback? onCancel}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 620,
          child: UpcomingAppointmentCard(
            appointment: _appointment,
            compact: false,
            onOpen: onOpen,
            onCancel: onCancel,
          ),
        ),
      ),
    );

void main() {
  testWidgets('appointment card opens details and displays status',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(_host(onOpen: () => opened++));

    expect(find.text('Confirmed'), findsOneWidget);
    await tester.tap(find.text('Dr Jane'));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('appointment overflow exposes only working actions',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _host(onOpen: () => opened++, onCancel: () {}),
    );

    await tester.tap(find.byTooltip('Appointment actions'));
    await tester.pumpAndSettle();

    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Cancel appointment'), findsOneWidget);
    expect(find.text('Reschedule appointment'), findsNothing);

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });
}
