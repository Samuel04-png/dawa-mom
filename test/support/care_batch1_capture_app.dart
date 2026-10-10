// Manual visual-QA target for Care Batch 1.
// Run: flutter run -d web-server -t test/support/care_batch1_capture_app.dart
// States: empty, confirmed, pending, clinics-minimal, clinics-full.
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _CareBatchOneCaptureApp());

class _CareBatchOneCaptureApp extends StatelessWidget {
  const _CareBatchOneCaptureApp();

  @override
  Widget build(BuildContext context) {
    final state = Uri.base.queryParameters['state'] ?? 'empty';
    final clinics = switch (state) {
      'clinics-full' => _fullClinics,
      _ => _minimalClinics,
    };
    final appointments = switch (state) {
      'confirmed' => [_appointment(status: 'confirmed')],
      'pending' => [_appointment(status: 'pending')],
      _ => const <Appointment>[],
    };
    final clinicSection = state.startsWith('clinics');

    return MaterialApp(
      theme: DawaTheme.light(),
      home: DawaMomResponsiveShell(
        currentIndex: 2,
        destinations: _destinations,
        onDestinationSelected: (_) {},
        onLogout: () async {},
        child: DawaCarePage(
          initialAppointments: appointments,
          initialClinics: clinics,
          initialCareItems: const [],
          initialSectionIndex: clinicSection ? 1 : 0,
        ),
      ),
    );
  }
}

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

const _minimalClinics = <ClinicOption>[
  ClinicOption(id: 'clinic-minimal', name: 'Kabulonga Clinic'),
];

const _fullClinics = <ClinicOption>[
  ClinicOption(
    id: 'clinic-full',
    name: 'Kabulonga Clinic',
    address: 'Kabulonga, Lusaka',
    distanceKm: 2.4,
    isOpen: true,
    isPreferred: true,
    services: ['Antenatal care', 'General care'],
    openingHours: 'Mon–Fri, 08:00–17:00',
  ),
];

Appointment _appointment({required String status}) => Appointment(
      id: 'appointment-$status',
      motherId: 'preview-mother',
      patientId: 'preview-patient',
      clinicianId: 'preview-clinician',
      clinicId: 'clinic-minimal',
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
