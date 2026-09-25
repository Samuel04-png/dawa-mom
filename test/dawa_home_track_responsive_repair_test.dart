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
  Size(430, 932),
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

HealthProfileSnapshot _incompleteHealthProfile() {
  final base = _healthProfile();

  // Only the personal section is incomplete. profile/contact data, pregnancy
  // and period settings all stay valid so the banner reports exactly one
  // missing step: "Next step: add your name and date of birth."
  return HealthProfileSnapshot(
    profile: <String, dynamic>{
      'email': base.profile['email'],
      'phone_number': base.profile['phone_number'],
      // display_name is removed on purpose: it feeds `name`, which would
      // otherwise make `personalComplete` true.
    },
    mother: <String, dynamic>{
      'pregnancy_status': 'pregnant',
      'address': base.mother['address'],
      // name and date_of_birth are intentionally omitted.
    },
    pregnancy: base.pregnancy,
    periodSettings: base.periodSettings,
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
      expect(find.byKey(const ValueKey('home-current-journey-hero')),
          findsOneWidget);
      expect(find.textContaining('Dawa Points'), findsOneWidget);
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
      Size(400, 793),
      Size(412, 915),
      Size(430, 932),
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
      // Hero is compact (content-sized) rather than a tall fixed-height card.
      expect(tester.getSize(hero).height, lessThanOrEqualTo(330));
      if (size.width < 370) {
        // Stacked treatment: a short full-width image band above the copy.
        expect(tester.getSize(image).height, lessThanOrEqualTo(130));
      } else if (size.width < 600) {
        // Side treatment: the portrait keeps a responsive slice on the right,
        // meaningfully larger than the old sliver that used to fall off-screen.
        expect(tester.getSize(image).width, inInclusiveRange(120, 180));
      } else {
        expect(
          tester.getSize(image).width,
          lessThanOrEqualTo(size.width * .4),
        );
      }
      expect(find.textContaining('Day '), findsOneWidget);
      expect(find.text('How I feel\ntoday'), findsOneWidget);
      expect(find.text('View my cycle'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'cycle hero removes the redundant greeting and keeps artwork visible',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(400, 793),
      Size(430, 932),
      Size(768, 1024),
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

      // Redundant greeting is gone.
      expect(
        find.textContaining(RegExp('Good (morning|afternoon|evening)')),
        findsNothing,
        reason: 'greeting should be removed at $size',
      );

      // Card begins directly with the cycle copy.
      expect(find.text('Your cycle today'), findsOneWidget);
      expect(find.textContaining('Day '), findsOneWidget);

      // The side portrait stays inside the hero card (no long, negative offset
      // that pushed almost the whole illustration off-screen).
      final hero = find.byKey(const ValueKey('home-current-journey-hero'));
      final image = find.byKey(const ValueKey('home-journey-thumbnail'));
      final heroBox = tester.getRect(hero);
      final imageBox = tester.getRect(image);
      expect(imageBox.right, lessThanOrEqualTo(heroBox.right + 1),
          reason: 'image pushed off right edge at $size');
      expect(imageBox.width, greaterThanOrEqualTo(heroBox.width * .28),
          reason: 'illustration sliver too small at $size');

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
      expect(find.text('View my cycle'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '${scale}x text');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'profile completion banner stays tidy and tappable at every target width',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(320, 568),
      Size(360, 800),
      Size(390, 844),
      Size(400, 793),
      Size(430, 932),
      Size(768, 1024),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _shell(
          index: 0,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _FakeAppointmentRepository(),
            healthProfileRepository: _FakeIncompleteHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'profile banner failed at $size');

      final title = find.text('Complete your health profile');
      final subtitle = find.text('Next step: add your name and date of birth.');
      final action = find.text('Continue');
      expect(title, findsOneWidget, reason: 'title missing at $size');
      expect(subtitle, findsOneWidget, reason: 'subtitle missing at $size');
      expect(action, findsOneWidget, reason: 'Continue missing at $size');

      // Bring the banner fully into view, then confirm nothing overlaps and
      // the compact trailing action still triggers navigation/tap.
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();

      final titleRect = tester.getRect(title);
      final subtitleRect = tester.getRect(subtitle);
      final actionRect = tester.getRect(action);
      expect(titleRect.bottom, lessThanOrEqualTo(subtitleRect.top),
          reason: 'title collapsed into subtitle at $size');
      // The trailing action may sit on its own row (stacked narrow layout) or
      // at the right of the text row (wider layout); in both cases its painted
      // rectangle must not overlap the copy.
      expect(actionRect.overlaps(subtitleRect), isFalse,
          reason: 'action overlaps subtitle at $size');
      expect(actionRect.overlaps(titleRect), isFalse,
          reason: 'action overlaps title at $size');
      expect(titleRect.overlaps(subtitleRect), isFalse,
          reason: 'title overlaps subtitle at $size');

      if (size.width < 500) {
        // Phones stack the action below the copy so neither text field is
        // squeezed into an unreadable column.
        expect(actionRect.top, greaterThanOrEqualTo(subtitleRect.bottom),
            reason: 'Continue not below copy at $size');
      } else {
        // Tablet uses the intentional side-by-side layout.
        expect(actionRect.left, greaterThanOrEqualTo(subtitleRect.right),
            reason: 'Continue not trailing copy at $size');
      }
      // The copy must never be crushed into a thin column next to the action.
      expect(titleRect.width, greaterThan(140),
          reason: 'title crushed to a sliver at $size');
      expect(subtitleRect.width, greaterThan(150),
          reason: 'subtitle crushed at $size');

      // The trailing action must be wired for tap (production routes to the
      // profile completion flow via GoRouter, which the plain harness lacks),
      // so verify the button is enabled rather than triggering navigation.
      final button = tester.widget<TextButton>(
        find.ancestor(of: action, matching: find.byType(TextButton)),
      );
      expect(button.enabled, isTrue, reason: 'Continue disabled at $size');
      expect(button.onPressed, isNotNull, reason: 'Continue unbound at $size');
      expect(
        tester
            .getSize(find.ancestor(
              of: action,
              matching: find.byType(TextButton),
            ))
            .height,
        greaterThanOrEqualTo(48),
        reason: 'Continue touch target is smaller than 48px at $size',
      );
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
    expect(find.textContaining('Day '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home keeps healthy sections useful when repositories fail',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _FailingAppointmentRepository(),
          healthProfileRepository: _FakeHealthProfileRepository(),
          periodTrackerService: _FakePeriodTrackerService(),
          learningRepository: _FailingLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week 24'), findsOneWidget);
    expect(find.text('Some updates are unavailable.'), findsOneWidget);
    expect(find.text('Visits unavailable'), findsOneWidget);
    expect(find.text('Points unavailable'), findsOneWidget);
    expect(find.text('Book a\nvisit'), findsOneWidget);
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

class _FailingAppointmentRepository extends AppointmentRepository {
  _FailingAppointmentRepository() : super(client: _client);

  @override
  Future<List<Appointment>> getAppointments() async =>
      throw Exception('offline');
}

class _FakeHealthProfileRepository extends HealthProfileRepository {
  _FakeHealthProfileRepository() : super(client: _client);

  @override
  Future<HealthProfileSnapshot> load() async => _healthProfile();
}

class _FakeIncompleteHealthProfileRepository
    extends _FakeHealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => _incompleteHealthProfile();
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

class _FailingLearningRepository extends DawaLearningRepository {
  @override
  Future<DawaLearningState> load() async => throw Exception('offline');
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
