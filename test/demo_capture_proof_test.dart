import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/components/responsive/responsive_home_dashboard.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/care_plan/data/dawa_care_plan_repository.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/period_tracker/presentation/dawa_cycle_tracker_page.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _client = SupabaseClient(
  'http://127.0.0.1:54321',
  'local-anon-key-for-demo-capture',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

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
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('captures week 22 pregnancy home at iPhone 16 viewport',
      (tester) async {
    _configureMobileViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DawaTheme.light(),
        home: _shell(
          index: 0,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _PreviewAppointments(),
            healthProfileRepository: _PreviewProfile(pregnant: true),
            periodTrackerService: _PreviewPeriods(active: false),
            learningRepository: _PreviewLearning(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
    );

    expect(find.text('Week 22'), findsOneWidget);
    expect(find.textContaining('2nd trimester'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(DawaMomResponsiveDashboard),
      matchesGoldenFile(
        '../demo_assets/raw/dawa_mom/pregnancy/week22_home.png',
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
    );
  });

  testWidgets('captures cycle overview at iPhone 16 viewport', (tester) async {
    _configureMobileViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DawaTheme.light(),
        home: _shell(
          index: 1,
          child: DawaCycleTrackerPage(
            service: _PreviewPeriods(active: false),
            profileRepository: _PreviewProfile(pregnant: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
    );

    expect(find.text('YOUR CYCLE TODAY'), findsOneWidget);
    expect(find.text('Estimated fertile window'), findsWidgets);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(DawaCycleTrackerPage),
      matchesGoldenFile(
        '../demo_assets/raw/dawa_mom/cycle/cycle_tracking_overview.png',
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
    );
  });
}

void _configureMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _shell({required int index, required Widget child}) =>
    DawaMomResponsiveShell(
      currentIndex: index,
      destinations: _destinations,
      onDestinationSelected: (_) {},
      onLogout: () async {},
      child: child,
    );

class _PreviewAppointments extends AppointmentRepository {
  _PreviewAppointments() : super(client: _client);

  @override
  Future<List<Appointment>> getAppointments() async => const [];
}

class _PreviewProfile extends HealthProfileRepository {
  _PreviewProfile({required this.pregnant}) : super(client: _client);

  final bool pregnant;

  @override
  Future<HealthProfileSnapshot> load() async {
    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 120));
    return HealthProfileSnapshot(
      profile: const {
        'email': 'chipo@example.test',
        'display_name': 'Chipo Banda',
        'phone_number': '+260 97 000 0000',
      },
      mother: {
        'name': 'Chipo Banda',
        'date_of_birth': '1994-03-17',
        'address': 'Lusaka, Zambia',
        'pregnancy_status': pregnant ? 'pregnant' : 'not_pregnant',
      },
      pregnancy: pregnant
          ? {'estimated_due_date': dueDate.toIso8601String()}
          : null,
      periodSettings: _periodSettings(now),
    );
  }
}

class _PreviewPeriods extends PeriodTrackerService {
  _PreviewPeriods({required this.active});

  final bool active;

  @override
  Future<Map<String, dynamic>?> loadUserSettings() async =>
      _periodSettings(DateTime.now());

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async {
    final today = DateTime.now();
    final latestStart = _dateOnly(
      today.subtract(Duration(days: active ? 2 : 14)),
    );
    final olderStart = _dateOnly(today.subtract(const Duration(days: 42)));
    return [
      PeriodRecord(
        startDate: latestStart,
        endDate: active ? null : _dateOnly(today.subtract(
          Duration(days: active ? 0 : 10),
        )),
      ),
      if (!active)
        PeriodRecord(
          startDate: olderStart,
          endDate: _dateOnly(today.subtract(const Duration(days: 38))),
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
        completedIds: {},
      );
}

Map<String, dynamic> _periodSettings(DateTime now) => {
      'averageCycleLength': 28,
      'periodLength': 5,
      'isRegular': true,
      'lastPeriodStart': _dateOnly(
        now.subtract(Duration(days: 14)),
      ),
    };

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
