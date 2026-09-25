import 'dart:async';

import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Care defaults to Upcoming and renders real appointment data',
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
      await _pumpCare(
        tester,
        DawaCarePage(
          initialAppointments: [appointment],
          initialClinics: const [
            ClinicOption(
              id: 'clinic-1',
              name: 'Kabulonga Clinic',
              address: 'Lusaka',
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Your next visit'), findsOneWidget);
      expect(find.text('Dr Jane Banda'), findsOneWidget);
      expect(find.text('Kabulonga Clinic'), findsOneWidget);
      expect(find.text('Quick actions'), findsNothing);
      expect(find.text('3 of 5'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('care-tab-upcoming')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Care sections preserve the selected tab and show real content',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final completed = _appointment(
      id: 'completed-1',
      status: 'completed',
      date: DateTime.now().subtract(const Duration(days: 8)),
    );
    await _pumpCare(
      tester,
      DawaCarePage(
        initialAppointments: [_appointment(), completed],
        initialClinics: const [
          ClinicOption(
            id: 'clinic-1',
            name: 'Kabulonga Clinic',
            address: 'Lusaka',
            distanceKm: 2.4,
            isOpen: true,
            services: ['Antenatal care', 'General care'],
            isPreferred: true,
          ),
          ClinicOption(
            id: 'clinic-2',
            name: 'Chilenje Clinic',
            address: 'Chilenje',
            distanceKm: 4.8,
            services: ['Cervical screening'],
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const ValueKey('care-tab-clinics')));
    await tester.pumpAndSettle();
    expect(find.text('Find care near you'), findsOneWidget);
    expect(find.text('Nearest'), findsOneWidget);
    expect(find.text('Antenatal'), findsOneWidget);
    expect(find.text('Cervical'), findsOneWidget);
    expect(find.text('Preferred'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('care-tab-history')));
    await tester.pumpAndSettle();
    expect(find.text('Your previous care'), findsOneWidget);
    expect(find.text('View summary'), findsOneWidget);
    expect(find.textContaining('Dr Jane Banda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care empty Upcoming has one booking action and clinic browse',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await _pumpCare(
      tester,
      const DawaCarePage(
        initialAppointments: [],
        initialClinics: [
          ClinicOption(id: 'clinic-1', name: 'Kabulonga Clinic'),
        ],
      ),
    );

    expect(find.text('No upcoming appointments'), findsOneWidget);
    expect(find.text('Book appointment'), findsOneWidget);
    expect(find.text('Browse clinics'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);
    await tester.tap(find.text('Browse clinics'));
    await tester.pumpAndSettle();
    expect(find.text('Find care near you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care cancellation waits for repository confirmation',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = _ControlledAppointmentRepository();
    await _pumpCare(
      tester,
      DawaCarePage(
        repository: repository,
        initialAppointments: [_appointment()],
        initialClinics: const [],
      ),
    );

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel appointment'));
    await tester.pump();
    expect(find.text('Please wait'), findsOneWidget);
    expect(find.text('Your next visit'), findsOneWidget);

    repository.completeCancellation();
    await tester.pumpAndSettle();
    expect(find.text('No upcoming appointments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCare(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DawaTheme.light(),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Appointment _appointment({
  String id = 'appointment-1',
  String status = 'confirmed',
  DateTime? date,
}) =>
    Appointment(
      id: id,
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: date ?? DateTime.now().add(const Duration(days: 7)),
      startTime: '09:00',
      endTime: '09:30',
      appointmentType: 'maternal_health',
      status: status,
      source: 'dawa_mom',
      createdAt: DateTime.now(),
      integrationStatus: 'synced',
      clinicianName: 'Dr Jane Banda',
      clinicName: 'Kabulonga Clinic',
      clinicAddress: 'Lusaka',
    );

class _ControlledAppointmentRepository extends AppointmentRepository {
  _ControlledAppointmentRepository()
      : super(
          client: SupabaseClient(
            'http://127.0.0.1:54321',
            'care-test-anon-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final _cancellation = Completer<Appointment>();

  @override
  Future<Appointment> cancelAppointment(String id) => _cancellation.future;

  void completeCancellation() {
    _cancellation.complete(
      _appointment(
        id: 'appointment-1',
        status: 'cancelled',
        date: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  }
}
