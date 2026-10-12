// Generates the fixed, full-resolution Care Batch 1 review captures.
// Run: flutter test tool/care_batch1_review_capture_test.dart --update-goldens
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _captureKey = ValueKey('care-batch1-review');
const _captureSize = Size(393, 852);

const _destinations = <DawaMomShellDestination>[
  DawaMomShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  DawaMomShellDestination(
    label: 'Track',
    icon: Icons.sync_outlined,
    selectedIcon: Icons.sync_rounded,
  ),
  DawaMomShellDestination(
    label: 'Care',
    icon: Icons.health_and_safety_outlined,
    selectedIcon: Icons.health_and_safety_rounded,
  ),
  DawaMomShellDestination(
    label: 'Learn',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  DawaMomShellDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    final poppins = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
    await poppins.load();
  });

  for (final state in _states) {
    testWidgets('captures ${state.fileName}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = _captureSize;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: DawaTheme.light(),
            home: DawaMomResponsiveShell(
              currentIndex: 2,
              destinations: _destinations,
              onDestinationSelected: (_) {},
              onLogout: () async {},
              child: DawaCarePage(
                initialAppointments: state.appointments,
                initialClinics: state.clinics,
                initialCareItems: const [],
                initialSectionIndex: state.clinicsSection ? 1 : 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_captureKey),
        matchesGoldenFile(
          '../dawa implemented screems/batch1-review/${state.fileName}',
        ),
      );
    });
  }
}

final _states = <_CaptureState>[
  const _CaptureState(
    fileName: 'upcoming-empty-393x852.png',
    appointments: [],
    clinics: [ClinicOption(id: 'clinic-minimal', name: 'Kabulonga Clinic')],
  ),
  _CaptureState(
    fileName: 'upcoming-confirmed-393x852.png',
    appointments: [_appointment('confirmed')],
    clinics: const [],
  ),
  _CaptureState(
    fileName: 'upcoming-pending-393x852.png',
    appointments: [_appointment('pending')],
    clinics: const [],
  ),
  const _CaptureState(
    fileName: 'clinics-minimal-393x852.png',
    appointments: [],
    clinics: [ClinicOption(id: 'clinic-minimal', name: 'Kabulonga Clinic')],
    clinicsSection: true,
  ),
  const _CaptureState(
    fileName: 'clinics-rich-393x852.png',
    appointments: [],
    clinics: [
      ClinicOption(
        id: 'clinic-rich',
        name: 'Kabulonga Clinic',
        address: 'Kabulonga, Lusaka',
        distanceKm: 2.4,
        isOpen: true,
        isPreferred: true,
        services: ['Antenatal care', 'General care'],
        openingHours: 'Mon–Fri, 08:00–17:00',
      ),
    ],
    clinicsSection: true,
  ),
];

class _CaptureState {
  const _CaptureState({
    required this.fileName,
    required this.appointments,
    required this.clinics,
    this.clinicsSection = false,
  });

  final String fileName;
  final List<Appointment> appointments;
  final List<ClinicOption> clinics;
  final bool clinicsSection;
}

Appointment _appointment(String status) => Appointment(
      id: 'appointment-$status',
      motherId: 'capture-mother',
      patientId: 'capture-patient',
      clinicianId: 'capture-clinician',
      clinicId: 'clinic-rich',
      date: DateTime(2026, 10, 16),
      startTime: '09:00',
      endTime: '09:30',
      appointmentType: 'maternal_health',
      status: status,
      source: 'dawa_mom',
      createdAt: DateTime(2026, 10, 10),
      integrationStatus: 'synced',
      clinicianName: 'Dr Jane Banda',
      clinicName: 'Kabulonga Clinic',
      clinicAddress: 'Kabulonga, Lusaka',
    );
