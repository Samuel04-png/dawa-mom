import 'dart:async';

import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/components/responsive/responsive_home_dashboard.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/care_plan/data/dawa_care_plan_repository.dart';
import 'package:dawa_mom/features/care_plan/domain/dawa_care_item.dart';
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
  Size(400, 793),
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

Map<String, dynamic> _safeCycleSettings() => <String, dynamic>{
      'averageCycleLength': 28,
      'periodLength': 5,
      'isRegular': true,
      'lastPeriodStart': _dateOnly(
        DateTime.now().subtract(const Duration(days: 14)),
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

List<PeriodRecord> _safeCycleHistory() => <PeriodRecord>[
      PeriodRecord(
        startDate: _dateOnly(DateTime.now().subtract(const Duration(days: 14))),
        endDate: _dateOnly(DateTime.now().subtract(const Duration(days: 10))),
      ),
      PeriodRecord(
        startDate: _dateOnly(DateTime.now().subtract(const Duration(days: 42))),
        endDate: _dateOnly(DateTime.now().subtract(const Duration(days: 38))),
      ),
    ];

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

HealthProfileSnapshot _safeCycleHealthProfile() => HealthProfileSnapshot(
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
      periodSettings: _safeCycleSettings(),
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

Appointment _appointmentTomorrow() => Appointment(
      id: 'appointment-tomorrow',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime.now().add(const Duration(days: 1)),
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
      'Home keeps the adaptive featured surface and exposes final content at all target sizes',
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
      final featured =
          find.byKey(const ValueKey('home-adaptive-featured-card'));
      expect(featured, findsOneWidget);
      expect(find.byKey(const ValueKey('home-featured-appointment')),
          findsOneWidget);
      expect(find.textContaining('Dawa Points'), findsOneWidget);
      expect(find.text('Your next visit'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);

      await _scrollToEnd(tester);
      final finalAction = find.byKey(const ValueKey('home-daily-tip'));
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

  testWidgets('Home uses balanced two-by-two quick actions on narrow screens',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(320, 568),
      Size(360, 800),
      Size(393, 852),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _shell(
          index: 0,
          textScale: 1.3,
          child: DawaMomResponsiveDashboard(
            onOpenRudo: () {},
            appointmentRepository: _NoAppointmentRepository(),
            healthProfileRepository: _FakeCycleHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cycle = find.bySemanticsLabel('Open cycle calendar');
      final feeling = find.bySemanticsLabel('How I feel today');
      final book = find.bySemanticsLabel('Book a visit');
      final learn = find.bySemanticsLabel('Open learning');
      expect(cycle, findsOneWidget);
      expect(feeling, findsOneWidget);
      expect(book, findsOneWidget);
      expect(learn, findsOneWidget);

      final cycleRect = tester.getRect(cycle);
      final feelingRect = tester.getRect(feeling);
      final bookRect = tester.getRect(book);
      final learnRect = tester.getRect(learn);
      expect(cycleRect.right, lessThanOrEqualTo(feelingRect.left),
          reason: 'top quick actions are not two columns at $size');
      expect(bookRect.right, lessThanOrEqualTo(learnRect.left),
          reason: 'bottom quick actions are not two columns at $size');
      expect(bookRect.top, greaterThan(cycleRect.bottom),
          reason: 'quick-action rows overlap at $size');
      expect(cycleRect.height, greaterThanOrEqualTo(92),
          reason: 'quick action is too small at $size');

      await _scrollToEnd(tester);
      _expectAboveNavigation(
        tester,
        find.byKey(const ValueKey('home-daily-tip')),
        size,
      );
      expect(tester.takeException(), isNull,
          reason: 'Home failed at $size with large text');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'cycle Home keeps a compact ring preview and shows cycle day only once',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(320, 568),
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
            appointmentRepository: _NoAppointmentRepository(),
            healthProfileRepository: _FakeCycleHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final featured =
          find.byKey(const ValueKey('home-adaptive-featured-card'));
      final cycleCard = find.byKey(const ValueKey('home-featured-cycle'));
      expect(featured, findsOneWidget);
      expect(cycleCard, findsOneWidget);
      expect(tester.getSize(cycleCard).height, lessThanOrEqualTo(330));
      expect(
        find.descendant(
          of: cycleCard,
          matching: find.byKey(const ValueKey('home-cycle-preview-ring')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: cycleCard,
          matching: find.byKey(const ValueKey('home-cycle-date-strip')),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Cycle day '), findsOneWidget);
      expect(find.text('How I feel'), findsOneWidget);
      expect(find.text('View cycle'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'cycle feature removes the redundant greeting and keeps its ring in bounds',
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
            appointmentRepository: _NoAppointmentRepository(),
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

      expect(find.text('YOUR CYCLE'), findsOneWidget);
      expect(find.textContaining('Cycle day '), findsOneWidget);

      final card = find.byKey(const ValueKey('home-featured-cycle'));
      final ring = find.descendant(
        of: card,
        matching: find.byKey(const ValueKey('home-cycle-preview-ring')),
      );
      final cardBox = tester.getRect(card);
      final ringBox = tester.getRect(ring);
      expect(ringBox.right, lessThanOrEqualTo(cardBox.right + 1),
          reason: 'ring pushed off right edge at $size');
      expect(ringBox.width, greaterThanOrEqualTo(128),
          reason: 'ring is no longer a strong cycle anchor at $size');
      expect(ringBox.width, lessThanOrEqualTo(172),
          reason: 'ring no longer fits its Home summary role at $size');

      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('cycle Home supports 1.3x and 1.5x text with a compact ring',
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
            appointmentRepository: _NoAppointmentRepository(),
            healthProfileRepository: _FakeCycleHealthProfileRepository(),
            periodTrackerService: _FakePeriodTrackerService(),
            learningRepository: _FakeLearningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ring = find.descendant(
        of: find.byKey(const ValueKey('home-featured-cycle')),
        matching: find.byKey(const ValueKey('home-cycle-preview-ring')),
      );
      expect(tester.getSize(ring).height, lessThanOrEqualTo(172));
      expect(find.text('View cycle'), findsOneWidget);
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

      final title = find.text('Add your details');
      final action = find.text('Add');
      expect(title, findsOneWidget, reason: 'title missing at $size');
      expect(action, findsOneWidget, reason: 'action missing at $size');

      // Bring the compact action into view, then ensure it remains readable
      // without colliding with the instruction at any supported width.
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();

      final titleRect = tester.getRect(title);
      final actionRect = tester.getRect(action);
      expect(actionRect.overlaps(titleRect), isFalse,
          reason: 'action overlaps instruction at $size');
      expect(titleRect.width, greaterThan(140),
          reason: 'instruction was crushed to a sliver at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('cycle Home keeps Track as the primary cycle action',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _NoAppointmentRepository(),
          healthProfileRepository: _FakeCycleHealthProfileRepository(),
          periodTrackerService: _FakePeriodTrackerService(),
          learningRepository: _FakeCycleProgressLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-featured-cycle')), findsOneWidget);
    expect(find.text('View cycle'), findsOneWidget);
    expect(find.textContaining('Cycle day '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home uses one real appointment priority before daily check-in',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _TomorrowAppointmentRepository(),
          healthProfileRepository: _SafeCycleHealthProfileRepository(),
          periodTrackerService: _SafeCyclePeriodTrackerService(),
          learningRepository: _FakeLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-featured-appointment')),
        findsOneWidget);
    expect(find.text('Your visit is tomorrow'), findsOneWidget);
    expect(find.text('Quick check-in'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home prioritizes a server-owned due care item', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _NoAppointmentRepository(),
          carePlanRepository: _FakeCarePlanRepository(
            DawaCarePlanSnapshot(
              isCached: false,
              items: [
                DawaCareItem(
                  id: 'care-urgent',
                  motherId: 'mother-1',
                  patientId: 'patient-1',
                  type: 'clinical_followup',
                  title: 'Return to clinic',
                  status: DawaCareItemStatus.due,
                  priority: DawaCareItemPriority.high,
                  source: 'clinician',
                  createdAt: DateTime(2026, 10, 9),
                  updatedAt: DateTime(2026, 10, 9),
                ),
              ],
            ),
          ),
          healthProfileRepository: _SafeCycleHealthProfileRepository(),
          periodTrackerService: _SafeCyclePeriodTrackerService(),
          learningRepository: _FakeLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-featured-care')), findsOneWidget);
    expect(find.text('Care needs attention'), findsOneWidget);
    expect(find.text('Open care'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home hides its daily check-in nudge after a real log exists',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _NoAppointmentRepository(),
          healthProfileRepository: _SafeCycleHealthProfileRepository(),
          periodTrackerService: _LoggedTodayPeriodTrackerService(),
          learningRepository: _FakeLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-priority-nudge')), findsNothing);
    expect(find.text('Quick check-in'), findsNothing);
    // The quick action remains available so a mother can change today's log.
    expect(find.text('How I feel'), findsOneWidget);
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
    expect(find.text('Points unavailable'), findsOneWidget);
    expect(find.text('Book visit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home does not raise a global warning for care-only failure',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _FakeAppointmentRepository(),
          carePlanRepository: _FailingCarePlanRepository(),
          healthProfileRepository: _FakeHealthProfileRepository(),
          periodTrackerService: _FakePeriodTrackerService(),
          learningRepository: _FakeLearningRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Some updates are unavailable.'), findsNothing);
    expect(find.byKey(const ValueKey('home-featured-appointment')),
        findsOneWidget);
    expect(find.text('Your next visit'), findsOneWidget);
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
      _expectAboveNavigation(tester, fab, size);
      _expectNoOverlap(
        tester,
        fab,
        find.byKey(const ValueKey('rudo-launcher')),
      );
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
    expect(find.text('Period started'), findsOneWidget);
    expect(find.textContaining("We'll update your cycle from"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track logs the day selected in the cycle ring', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final service = _FakePeriodTrackerService();
    final selected =
        _dateOnly(DateTime.now().subtract(const Duration(days: 2)));

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
    await tester.tap(
      find.byKey(
        ValueKey(
            'cycle-week-day-${PeriodTrackerService.formatDateId(selected)}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('period-start-action')));
    await tester.pumpAndSettle();

    expect(service.lastSavedStart, selected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track ends the active period through the persistence service',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final service = _ActivePeriodTrackerService();

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

    final endAction = find.byKey(const ValueKey('period-end-action'));
    await tester.ensureVisible(endAction);
    await tester.tap(endAction);
    await tester.pumpAndSettle();

    expect(service.lastUpdatedStart,
        _dateOnly(DateTime.now().subtract(const Duration(days: 2))));
    expect(service.lastUpdatedEnd, _dateOnly(DateTime.now()));
    expect(find.text('Period ended'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track reports a write failure without claiming success',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 1,
        child: DawaCycleTrackerPage(
          service: _FailingPeriodTrackerService(),
          profileRepository: _FakeHealthProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('period-start-action')));
    await tester.pumpAndSettle();

    expect(find.text('Your period could not be saved. Please try again.'),
        findsOneWidget);
    expect(find.text('Period started'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track retains a confirmed save when the refresh fails',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 1,
        child: DawaCycleTrackerPage(
          service: _FakePeriodTrackerService(),
          profileRepository: _RefreshFailingHealthProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('period-start-action')));
    await tester.pumpAndSettle();

    expect(find.text('Period saved'), findsOneWidget);
    expect(
      find.text(
          'Your period was saved. We could not refresh the cycle view yet.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cycle-ring-hero')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Track ignores repeated period taps while a write is pending',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final service = _DelayedPeriodTrackerService();

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
    final action = find.byKey(const ValueKey('period-start-action'));
    await tester.tap(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();

    expect(service.saveCalls, 1);
    service.completeSave();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pregnancy setup replaces empty metrics with useful benefits',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _shell(
        index: 1,
        child: DawaCycleTrackerPage(
          service: _FakePeriodTrackerService(),
          profileRepository: _FakeCycleHealthProfileRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('track-mode-1')));
    await tester.pumpAndSettle();

    expect(find.text('Set up pregnancy tracking'), findsOneWidget);
    expect(
      find.text(
          'Add a last period or due date to see guidance for your stage.'),
      findsOneWidget,
    );
    expect(find.text('Not set'), findsNothing);
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

class _TomorrowAppointmentRepository extends _FakeAppointmentRepository {
  @override
  Future<List<Appointment>> getAppointments() async => <Appointment>[
        _appointmentTomorrow(),
      ];
}

class _NoAppointmentRepository extends _FakeAppointmentRepository {
  @override
  Future<List<Appointment>> getAppointments() async => const <Appointment>[];
}

class _FailingAppointmentRepository extends AppointmentRepository {
  _FailingAppointmentRepository() : super(client: _client);

  @override
  Future<List<Appointment>> getAppointments() async =>
      throw Exception('offline');
}

class _FakeCarePlanRepository extends DawaCarePlanRepository {
  _FakeCarePlanRepository(this.snapshot);

  final DawaCarePlanSnapshot snapshot;

  @override
  Future<DawaCarePlanSnapshot> load() async => snapshot;
}

class _FailingCarePlanRepository extends DawaCarePlanRepository {
  @override
  Future<DawaCarePlanSnapshot> load() async => throw Exception('offline');
}

class _FakeHealthProfileRepository extends HealthProfileRepository {
  _FakeHealthProfileRepository() : super(client: _client);

  @override
  Future<HealthProfileSnapshot> load() async => _healthProfile();
}

class _RefreshFailingHealthProfileRepository
    extends _FakeHealthProfileRepository {
  var _loads = 0;

  @override
  Future<HealthProfileSnapshot> load() async {
    _loads++;
    if (_loads == 1) return _healthProfile();
    throw StateError('refresh unavailable');
  }
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

class _SafeCycleHealthProfileRepository extends _FakeHealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => _safeCycleHealthProfile();
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

class _ActivePeriodTrackerService extends PeriodTrackerService {
  DateTime? lastUpdatedStart;
  DateTime? lastUpdatedEnd;

  DateTime get _start =>
      _dateOnly(DateTime.now().subtract(const Duration(days: 2)));

  @override
  Future<Map<String, dynamic>?> loadUserSettings() async => <String, dynamic>{
        'averageCycleLength': 28,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': _start,
      };

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async => <PeriodRecord>[
        PeriodRecord(startDate: _start),
      ];

  @override
  Future<void> updatePeriodRecord({
    required DateTime originalStartDate,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    lastUpdatedStart = _dateOnly(startDate);
    lastUpdatedEnd = endDate == null ? null : _dateOnly(endDate);
  }
}

class _FailingPeriodTrackerService extends _FakePeriodTrackerService {
  @override
  Future<void> savePeriodRecord({
    required DateTime startDate,
    DateTime? endDate,
    DateTime? replacingStartDate,
  }) =>
      throw const PeriodTrackerPersistenceException(
        message: 'Your period could not be saved. Please try again.',
        operation: 'save_period_record',
        stage: 'entry_upsert',
        writeConfirmed: false,
        code: '42501',
      );
}

class _DelayedPeriodTrackerService extends _FakePeriodTrackerService {
  final Completer<void> _saveCompleter = Completer<void>();
  var saveCalls = 0;

  @override
  Future<void> savePeriodRecord({
    required DateTime startDate,
    DateTime? endDate,
    DateTime? replacingStartDate,
  }) {
    saveCalls++;
    return _saveCompleter.future;
  }

  void completeSave() => _saveCompleter.complete();
}

class _SafeCyclePeriodTrackerService extends _FakePeriodTrackerService {
  @override
  Future<Map<String, dynamic>?> loadUserSettings() async =>
      _safeCycleSettings();

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async => _safeCycleHistory();
}

class _LoggedTodayPeriodTrackerService extends _SafeCyclePeriodTrackerService {
  @override
  Future<Map<String, dynamic>?> loadDailyData(DateTime date) async =>
      const <String, dynamic>{
        'symptoms': <String>[],
        'notes': <String>['Pain: 1/10', 'Overall feeling: Good'],
      };
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
