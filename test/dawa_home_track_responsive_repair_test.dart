import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/components/responsive/responsive_home_dashboard.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/period_tracker/presentation/dawa_cycle_tracker_page.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _sizes = <Size>[
  Size(320, 568),
  Size(360, 800),
  Size(390, 844),
  Size(412, 915),
  Size(768, 1024),
];

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

final _client = SupabaseClient(
  'http://localhost:54321',
  'local-anon-key-for-widget-tests',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

Map<String, dynamic> _periodSettings() => <String, dynamic>{
      'averageCycleLength': 28,
      'periodLength': 5,
      'isRegular': true,
      'lastPeriodStart': _dateOnly(
        DateTime.now().subtract(const Duration(days: 23)),
      ),
    };

List<PeriodRecord> _periodHistory() => List<PeriodRecord>.generate(
      4,
      (index) => PeriodRecord(
        startDate: _dateOnly(
          DateTime.now().subtract(Duration(days: 23 + (index * 28))),
        ),
        endDate: _dateOnly(
          DateTime.now().subtract(Duration(days: 19 + (index * 28))),
        ),
      ),
    );

HealthProfileSnapshot _healthProfile() {
  final dueDate = DateTime.now().add(const Duration(days: 112));
  return HealthProfileSnapshot(
    profile: const <String, dynamic>{
      'email': 'chipo@example.test',
      'display_name': 'Chipo Banda',
      'phone_number': '+260 97 000 0000',
    },
    mother: const <String, dynamic>{
      'name': 'Chipo Banda',
      'pregnancy_status': 'pregnant',
      'date_of_birth': '1994-03-17',
      'address': 'Lusaka, Zambia',
    },
    pregnancy: <String, dynamic>{
      'estimated_due_date': dueDate.toIso8601String(),
    },
    periodSettings: _periodSettings(),
  );
}

HealthProfileSnapshot _cycleHealthProfile() => HealthProfileSnapshot(
      profile: const <String, dynamic>{
        'email': 'chipo@example.test',
        'display_name': 'Chipo Banda',
        'phone_number': '+260 97 000 0000',
      },
      mother: const <String, dynamic>{
        'name': 'Chipo Banda',
        'pregnancy_status': 'not_pregnant',
        'date_of_birth': '1994-03-17',
        'address': 'Lusaka, Zambia',
      },
      pregnancy: null,
      periodSettings: _periodSettings(),
    );

Appointment _appointment() => Appointment(
      id: 'appointment-1',
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
      clinicianName: 'Midwife Mulenga',
      clinicName: 'Kalingalinga Clinic',
      clinicAddress: 'Lusaka, Zambia',
    );

Widget _shell({
  required int index,
  required Widget child,
  double textScale = 1,
}) =>
    MaterialApp(
      theme: DawaTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: DawaMomResponsiveShell(
            currentIndex: index,
            destinations: _destinations,
            onDestinationSelected: (_) {},
            onLogout: () async {},
            child: child,
          ),
        ),
      ),
    );

void _expectNoOverlap(WidgetTester tester, Finder first, Finder second) {
  expect(
    tester.getRect(first).overlaps(tester.getRect(second)),
    isFalse,
  );
}

Future<void> _scrollToEnd(WidgetTester tester) async {
  final scrollable = find.byType(SingleChildScrollView).first;
  await tester.fling(scrollable, const Offset(0, -2400), 2400);
  await tester.pumpAndSettle();
}

void _expectAboveNavigation(
  WidgetTester tester,
  Finder target,
  Size size,
) {
  final bottom = tester.getBottomRight(target).dy;
  if (size.width < DawaBreakpoints.mobile) {
    final navigationTop =
        tester.getTopLeft(find.byType(BottomNavigationBar)).dy;
    expect(bottom, lessThanOrEqualTo(navigationTop));
  } else {
    expect(bottom, lessThanOrEqualTo(size.height));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Home keeps reserved hero regions and exposes final content at all target sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in _sizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _shell(
          index: 0,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _FakeAppointmentRepository(),
            healthProfileRepository: _FakeHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Home failed at $size');
      final hero = find.byKey(const ValueKey('home-current-journey-hero'));
      expect(hero, findsOneWidget);
      expect(find.text('Ask\nRudo'), findsOneWidget);
      expect(find.textContaining('Dawa Rewards'), findsOneWidget);
      expect(find.textContaining('Kalingalinga Clinic'), findsOneWidget);

      final heroTitle = find.descendant(
        of: hero,
        matching: find.text('Week 24'),
      );
      final heroArtwork = find.descendant(
        of: hero,
        matching: find.byType(Image),
      );
      _expectNoOverlap(tester, heroTitle, heroArtwork);

      await _scrollToEnd(tester);
      final finalAction = find.text('Read more');
      expect(finalAction, findsOneWidget);
      _expectAboveNavigation(tester, finalAction, size);
      expect(tester.takeException(), isNull,
          reason: 'Home scroll failed at $size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Home remains usable at larger patient text sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    for (final scale in const [1.3, 1.5]) {
      await tester.pumpWidget(
        _shell(
          index: 0,
          textScale: scale,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _FakeAppointmentRepository(),
            healthProfileRepository: _FakeHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final failure = tester.takeException();
      if (failure != null) _debugOverflowingFlexes(tester);
      expect(
        failure,
        isNull,
        reason: 'Home failed at ${scale}x text',
      );
      expect(find.byKey(const ValueKey('rudo-launcher')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'cycle Home keeps its image compact and shows cycle day only once',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _shell(
          index: 0,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _FakeAppointmentRepository(),
            healthProfileRepository: _FakeCycleHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hero = find.byKey(const ValueKey('home-current-journey-hero'));
      final image = find.byKey(const ValueKey('home-journey-thumbnail'));
      expect(hero, findsOneWidget);
      expect(image, findsOneWidget);
      expect(tester.getSize(hero).height, lessThanOrEqualTo(420));
      if (size.width < 370) {
        expect(tester.getSize(image).height, lessThanOrEqualTo(130));
      } else if (size.width < 600) {
        expect(tester.getSize(image).width, inInclusiveRange(104, 124));
        expect(tester.getSize(image).height, lessThanOrEqualTo(124));
      } else {
        expect(
          tester.getSize(image).width,
          lessThanOrEqualTo(size.width * .35),
        );
      }
      expect(find.textContaining('Cycle day'), findsOneWidget);
      expect(find.text('Today’s check-in'), findsOneWidget);
      expect(find.text('View cycle'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('cycle Home supports 1.3x and 1.5x text without a large image',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    for (final scale in const [1.3, 1.5]) {
      await tester.pumpWidget(
        _shell(
          index: 0,
          textScale: scale,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _FakeAppointmentRepository(),
            healthProfileRepository: _FakeCycleHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = find.byKey(const ValueKey('home-journey-thumbnail'));
      expect(tester.getSize(image).height, lessThanOrEqualTo(130));
      expect(find.text('View cycle'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '${scale}x text');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('cycle Home promotes an unfinished cycle game', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _FakeAppointmentRepository(),
          healthProfileRepository: _FakeCycleHealthProfileRepository(),
          periodTrackerService: _FakePeriodTrackerService(),
          learningRepository: _FakeCycleProgressLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue cycle game'), findsOneWidget);
    expect(find.textContaining('Cycle day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Track stays overflow-free and keeps logging and final controls accessible',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in _sizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _shell(
          index: 1,
          child: DawaCycleTrackerPage(
            service: _FakePeriodTrackerService(),
            profileRepository: _FakeHealthProfileRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final trackException = tester.takeException();
      expect(trackException, isNull, reason: 'Track failed at $size');
      expect(find.text('Estimated fertile window'), findsWidgets);
      expect(find.text('Day 24'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cycle-log-today-action')),
        findsOneWidget,
      );

      await _scrollToEnd(tester);
      final settings = find.text('Cycle settings and history');
      expect(settings, findsOneWidget);
      _expectAboveNavigation(tester, settings, size);
      final fab = find.byKey(const ValueKey('cycle-log-today-action'));
      _expectNoOverlap(tester, settings, fab);
      expect(tester.takeException(), isNull,
          reason: 'Track scroll failed at $size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Track saves a one-tap period start for today', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final service = _FakePeriodTrackerService();

    await tester.pumpWidget(
      _shell(
        index: 1,
        child: DawaCycleTrackerPage(
          service: service,
          profileRepository: _FakeHealthProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final startAction = find.byKey(const ValueKey('period-start-action'));
    await tester.ensureVisible(startAction);
    await tester.pumpAndSettle();
    await tester.tap(startAction);
    await tester.pumpAndSettle();

    expect(service.lastSavedStart, _dateOnly(DateTime.now()));
    expect(find.text('Period start saved for today.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _debugOverflowingFlexes(WidgetTester tester) {
  for (final element in tester.allElements) {
    final renderObject = element.renderObject;
    if (renderObject is! RenderFlex || !renderObject.hasSize) continue;
    final flexRect =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    var outside = false;
    renderObject.visitChildren((child) {
      if (child is! RenderBox || !child.hasSize) return;
      final childRect = child.localToGlobal(Offset.zero) & child.size;
      if (childRect.left < flexRect.left - .1 ||
          childRect.right > flexRect.right + .1 ||
          childRect.top < flexRect.top - .1 ||
          childRect.bottom > flexRect.bottom + .1) {
        outside = true;
      }
    });
    if (!outside) continue;
    debugPrint(
      'Home overflow candidate ${element.widget.runtimeType} '
      '${renderObject.direction} $flexRect',
    );
    if (element.widget case Row(children: final widgets)) {
      debugPrint(
        '  widgets: ${widgets.map((widget) {
          if (widget is Text) return 'Text(${widget.data})';
          return widget.runtimeType.toString();
        }).join(', ')}',
      );
    }
  }
}

class _FakeAppointmentRepository extends AppointmentRepository {
  _FakeAppointmentRepository() : super(client: _client);

  @override
  Future<List<Appointment>> getAppointments() async => <Appointment>[
        _appointment(),
      ];
}

class _FakeHealthProfileRepository extends HealthProfileRepository {
  _FakeHealthProfileRepository() : super(client: _client);

  @override
  Future<HealthProfileSnapshot> load() async => _healthProfile();
}

class _FakeCycleHealthProfileRepository extends _FakeHealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => _cycleHealthProfile();
}

class _FakePeriodTrackerService extends PeriodTrackerService {
  DateTime? lastSavedStart;

  @override
  Future<Map<String, dynamic>?> loadUserSettings() async => _periodSettings();

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async => _periodHistory();

  @override
  Future<void> savePeriodRecord({
    required DateTime startDate,
    DateTime? endDate,
    DateTime? replacingStartDate,
  }) async {
    lastSavedStart = _dateOnly(startDate);
  }
}

class _FakeLearningRepository extends DawaLearningRepository {
  @override
  Future<DawaLearningState> load() async => const DawaLearningState(
        coins: 720,
        streak: 5,
        completedIds: <String>{'screening-checkpoint'},
      );
}

class _FakeCycleProgressLearningRepository extends DawaLearningRepository {
  @override
  Future<DawaLearningState> load() async => DawaLearningState(
        coins: 720,
        streak: 5,
        gameProgress: {
          'cycle-game-calendar-detective': DawaGameProgress(
            gameId: 'cycle-game-calendar-detective',
            roundIndex: 2,
            correctAnswers: 2,
            updatedAt: DateTime.utc(2026, 7, 28),
            pendingSync: true,
          ),
        },
      );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
