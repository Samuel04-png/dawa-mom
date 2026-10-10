// Manual visual-QA target for Batch 2. It exercises the real responsive Home
// dashboard with local repository fixtures and no backend writes.
// Run: flutter run -d web-server -t test/support/home_batch2_capture_app.dart
import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/components/responsive/responsive_home_dashboard.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/care_plan/data/dawa_care_plan_repository.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() => runApp(const _HomeBatchTwoCaptureApp());

final _client = SupabaseClient(
  'http://localhost:54321',
  'local-anon-key-for-home-capture',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

enum _PreviewState { period, pregnancy, appointment, general }

class _HomeBatchTwoCaptureApp extends StatelessWidget {
  const _HomeBatchTwoCaptureApp();

  @override
  Widget build(BuildContext context) {
    final state = switch (Uri.base.queryParameters['state']) {
      'pregnancy' => _PreviewState.pregnancy,
      'appointment' => _PreviewState.appointment,
      'general' => _PreviewState.general,
      _ => _PreviewState.period,
    };
    return MaterialApp(
      theme: DawaTheme.light(),
      home: DawaMomResponsiveShell(
        currentIndex: 0,
        destinations: const [
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
        ],
        onDestinationSelected: (_) {},
        onLogout: () async {},
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _PreviewAppointments(state),
          carePlanRepository: _PreviewCarePlan(),
          healthProfileRepository: _PreviewProfile(state),
          periodTrackerService: _PreviewPeriods(state),
          learningRepository: _PreviewLearning(),
        ),
      ),
    );
  }
}

class _PreviewAppointments extends AppointmentRepository {
  _PreviewAppointments(this.state) : super(client: _client);

  final _PreviewState state;

  @override
  Future<List<Appointment>> getAppointments() async =>
      state == _PreviewState.appointment
          ? [
              Appointment(
                id: 'visit-1',
                motherId: 'mother-1',
                patientId: 'patient-1',
                clinicianId: 'clinician-1',
                clinicId: 'clinic-1',
                date: DateTime.now().add(const Duration(days: 5)),
                startTime: '10:00',
                endTime: '10:30',
                appointmentType: 'antenatal_checkup',
                status: 'confirmed',
                source: 'dawa_mom',
                createdAt: DateTime.now(),
                integrationStatus: 'confirmed',
                clinicName: 'Kalingalinga Clinic',
              ),
            ]
          : const [];
}

class _PreviewCarePlan extends DawaCarePlanRepository {
  @override
  Future<DawaCarePlanSnapshot> load() async =>
      const DawaCarePlanSnapshot(items: [], isCached: false);
}

class _PreviewProfile extends HealthProfileRepository {
  _PreviewProfile(this.state) : super(client: _client);

  final _PreviewState state;

  @override
  Future<HealthProfileSnapshot> load() async {
    final now = DateTime.now();
    final pregnant = state == _PreviewState.pregnancy;
    final general = state == _PreviewState.general;
    final periodStart = state == _PreviewState.period
        ? DateTime(now.year, now.month, now.day - 2)
        : DateTime(now.year, now.month, now.day - 14);
    return HealthProfileSnapshot(
      profile: const {
        'id': 'home-preview',
        'email': 'chipo@example.test',
        'display_name': 'Chipo Banda',
        'phone_number': '+260970000000',
      },
      mother: {
        'name': 'Chipo Banda',
        'date_of_birth': '1994-03-17',
        'address': 'Lusaka',
        'pregnancy_status': pregnant ? 'pregnant' : 'not_pregnant',
      },
      pregnancy: pregnant
          ? {
              'estimated_due_date':
                  now.add(const Duration(days: 120)).toIso8601String(),
            }
          : null,
      periodSettings: general
          ? {'lastPeriodStart': periodStart}
          : {
              'averageCycleLength': 28,
              'periodLength': 5,
              'isRegular': true,
              'lastPeriodStart': periodStart,
            },
    );
  }
}

class _PreviewPeriods extends PeriodTrackerService {
  _PreviewPeriods(this.state);

  final _PreviewState state;

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async {
    final now = DateTime.now();
    if (state == _PreviewState.general) return const [];
    final start = state == _PreviewState.period
        ? DateTime(now.year, now.month, now.day - 2)
        : DateTime(now.year, now.month, now.day - 14);
    return [
      PeriodRecord(
        startDate: start,
        endDate: state == _PreviewState.period
            ? null
            : DateTime(now.year, now.month, now.day - 10),
      ),
      if (state != _PreviewState.period)
        PeriodRecord(
          startDate: DateTime(now.year, now.month - 1, now.day - 14),
          endDate: DateTime(now.year, now.month - 1, now.day - 10),
        ),
    ];
  }

  @override
  Future<Map<String, dynamic>?> loadDailyData(DateTime date) async => null;
}

class _PreviewLearning extends DawaLearningRepository {
  @override
  Future<DawaLearningState> load() async => const DawaLearningState(
        coins: 720,
        streak: 5,
        completedIds: {'screening-checkpoint'},
      );
}
