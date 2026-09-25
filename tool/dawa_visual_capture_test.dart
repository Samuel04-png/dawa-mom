import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/components/responsive/responsive_home_dashboard.dart';
import 'package:dawa_mom/design_system/dawa_components.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/design_system/dawa_page_scaffold.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/data/dawa_appointment_reminder_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_appointment_reminder_sheet.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_booking_success_dialog.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:dawa_mom/features/auth/dawa_auth_pages.dart';
import 'package:dawa_mom/features/games/domain/dawa_health_game.dart';
import 'package:dawa_mom/features/games/presentation/dawa_games_pages.dart';
import 'package:dawa_mom/features/games/services/dawa_game_feedback.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learning_detail_pages.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_library_page.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_quest_pages.dart';
import 'package:dawa_mom/features/notifications/dawa_notification_preferences_page.dart';
import 'package:dawa_mom/features/notifications/dawa_notifications_page.dart';
import 'package:dawa_mom/features/onboarding/dawa_main_app_tour.dart';
import 'package:dawa_mom/features/onboarding/dawa_onboarding_page.dart';
import 'package:dawa_mom/features/period_tracker/presentation/dawa_cycle_tracker_page.dart';
import 'package:dawa_mom/features/preferences/dawa_language_sheet.dart';
import 'package:dawa_mom/features/preferences/dawa_user_preferences_repository.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:dawa_mom/features/profile/profile_completion_page.dart';
import 'package:dawa_mom/features/rewards/presentation/dawa_rewards_page.dart';
import 'package:dawa_mom/features/settings/dawa_mom_settings_page.dart';
import 'package:dawa_mom/navbar/appointments/appointment_details/appointment_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _captureKey = ValueKey('visual-capture');

const _captureSizes = <String, Size>{
  '360x800': Size(360, 800),
  '390x844': Size(390, 844),
  '412x915': Size(412, 915),
  'tablet-portrait': Size(768, 1024),
};

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

final _offlineClient = SupabaseClient(
  'http://127.0.0.1:54321',
  'visual-capture-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

const _captureClinics = <ClinicOption>[
  ClinicOption(
    id: 'clinic-1',
    name: 'Kalingalinga Clinic',
    address: 'Lusaka, Zambia',
    distanceKm: 2.4,
    isOpen: true,
    services: ['Antenatal care', 'General care'],
    openingHours: 'Mon–Fri, 08:00–16:00',
    isPreferred: true,
    languages: ['English', 'Nyanja'],
  ),
  ClinicOption(
    id: 'clinic-2',
    name: 'Chilenje Level One Hospital',
    address: 'Chilenje, Lusaka',
    distanceKm: 4.8,
    services: ['Cervical screening', 'Maternal health'],
    openingHours: 'Mon–Sat, 08:00–17:00',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
    await loader.load();
  });

  setUp(() {
    _resetCapturePreferences();
  });

  testWidgets('capture entry and onboarding screens', (tester) async {
    await _captureMatrix(
      tester,
      'welcome.png',
      () => const DawaWelcomePage(),
    );
    await _captureMatrix(
      tester,
      'registration.png',
      () => const DawaRegistrationPage(),
    );
    await _captureMatrix(
      tester,
      'onboarding-track.png',
      () => const DawaOnboardingPage(),
    );
  });

  testWidgets('capture sign-in and recovery screens', (tester) async {
    await _captureMatrix(
      tester,
      'sign-in.png',
      () => const DawaLoginPage(),
    );
    await _captureMatrix(
      tester,
      'password-recovery.png',
      () => const DawaPasswordRecoveryPage(),
    );
  });

  testWidgets('capture Home and Track with responsive navigation',
      (tester) async {
    await _captureMatrix(
      tester,
      'home.png',
      () => _shell(
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
    await _captureMatrix(
      tester,
      'home-cycle.png',
      () => _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _FakeAppointmentRepository(),
          healthProfileRepository: _FakeCycleHealthProfileRepository(),
          periodTrackerService: _FakeCurrentPeriodTrackerService(),
          learningRepository: _FakeLearningRepository(),
        ),
      ),
    );
    await _captureMatrix(
      tester,
      'track.png',
      () => _shell(
        index: 1,
        child: DawaCycleTrackerPage(
          service: _FakePeriodTrackerService(),
          profileRepository: _FakeHealthProfileRepository(),
        ),
      ),
    );
    await _captureMatrix(
      tester,
      'rudo-chat.png',
      () => _shell(
        index: 0,
        child: DawaMomResponsiveDashboard(
          onOpenRudo: () {},
          appointmentRepository: _FakeAppointmentRepository(),
          healthProfileRepository: _FakeHealthProfileRepository(),
          periodTrackerService: _FakePeriodTrackerService(),
          learningRepository: _FakeLearningRepository(),
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.byKey(const ValueKey('rudo-launcher')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('capture three in-app coach tour steps', (tester) async {
    await _captureMatrix(
      tester,
      'tour-home-journey.png',
      () => const _TourCaptureHost(),
    );
    await _captureMatrix(
      tester,
      'tour-track.png',
      () => const _TourCaptureHost(),
      afterPump: (tester) async {
        await tester.tap(find.byKey(const ValueKey('tour-next')));
        await tester.pumpAndSettle();
      },
    );
    await _captureMatrix(
      tester,
      'tour-rewards.png',
      () => const _TourCaptureHost(),
      afterPump: (tester) async {
        for (var index = 0; index < 4; index++) {
          await tester.tap(find.byKey(const ValueKey('tour-next')));
          await tester.pumpAndSettle();
        }
      },
    );
  });

  testWidgets('capture Care and Learning hubs', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await _captureMatrix(
      tester,
      'care-upcoming.png',
      () => _shell(
        index: 2,
        child: DawaCarePage(
          initialAppointments: [_appointment(), _pastAppointment()],
          initialClinics: _captureClinics,
        ),
      ),
      afterPump: _jumpPageToTop,
    );
    await _captureMatrix(
      tester,
      'care-clinics.png',
      () => _shell(
        index: 2,
        child: DawaCarePage(
          initialAppointments: [_appointment(), _pastAppointment()],
          initialClinics: _captureClinics,
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.byKey(const ValueKey('care-tab-clinics')));
        await tester.pumpAndSettle();
        await _jumpPageToTop(tester);
      },
    );
    await _captureMatrix(
      tester,
      'care-history.png',
      () => _shell(
        index: 2,
        child: DawaCarePage(
          initialAppointments: [_appointment(), _pastAppointment()],
          initialClinics: _captureClinics,
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.byKey(const ValueKey('care-tab-history')));
        await tester.pumpAndSettle();
        await _jumpPageToTop(tester);
      },
    );
    await _captureMatrix(
      tester,
      'care-no-appointment.png',
      () => _shell(
        index: 2,
        child: const DawaCarePage(
          initialAppointments: [],
          initialClinics: _captureClinics,
        ),
      ),
      afterPump: _jumpPageToTop,
    );
    await _captureMatrix(
      tester,
      'learn.png',
      () => _shell(
        index: 3,
        child: DawaLearnPage(
          repository: DawaLearningRepository(preferences: prefs),
        ),
      ),
      beforePump: (_) async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setStringList('dawa_learning_completed', [
          'myth-vs-fact',
          'screening-checkpoint',
          'pregnancy-basics',
        ]);
      },
    );
    await _captureMatrix(
      tester,
      'learn-cards.png',
      () => _shell(
        index: 3,
        child: DawaLearnPage(
          repository: DawaLearningRepository(preferences: prefs),
        ),
      ),
      afterPump: (tester) async {
        await tester.ensureVisible(
          find.text('Foods to eat in your second trimester'),
        );
        await tester.pumpAndSettle();
      },
    );
    await _captureMatrix(
      tester,
      'learn-pregnancy-basics-card.png',
      () => _shell(
        index: 3,
        child: DawaLearnPage(
          repository: _FakeLearningRepository(),
        ),
      ),
      afterPump: (tester) async {
        await tester.ensureVisible(find.text('Pregnancy basics').last);
        await tester.pumpAndSettle();
        await _jumpPageBy(tester, 110);
      },
    );
  });

  testWidgets('capture appointment details and care overlays', (tester) async {
    await _captureMatrix(
      tester,
      'appointment-details.png',
      () => Scaffold(
        backgroundColor: DawaColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DawaAppHeader(
                  title: 'Appointment details',
                  onBack: () {},
                ),
              ),
              Expanded(
                child: AppointmentDetailsContent(
                  appointment: _appointment(),
                  cancelling: false,
                  onCancel: () {},
                  onRefresh: () async {},
                  resultLoading: false,
                  resultError: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _captureMatrix(
      tester,
      'appointment-booked-modal.png',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () =>
                  showDawaBookingSuccessDialog(context, _appointment()),
              child: const Text('Show booking confirmation'),
            ),
          ),
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.text('Show booking confirmation'));
        await tester.pumpAndSettle();
      },
    );
    await _captureMatrix(
      tester,
      'appointment-reminder-sheet.png',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DawaAppointmentReminderSheet(
                  appointment: _appointment(),
                  repository: _FakeAppointmentReminderRepository(),
                ),
              ),
              child: const Text('Open reminder'),
            ),
          ),
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.text('Open reminder'));
        await tester.pumpAndSettle();
      },
    );
    await _captureMatrix(
      tester,
      'daily-check-in-sheet.png',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showDawaDailyCheckInSheet(
                context,
                date: DateTime(2026, 7, 23),
                existing: null,
                onSave: ({
                  required symptoms,
                  required pain,
                  required feeling,
                  required note,
                }) async {},
              ),
              child: const Text('Open check-in'),
            ),
          ),
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.text('Open check-in'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('capture Learning details and Mother’s Path', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    DawaLearningRepository learning() =>
        DawaLearningRepository(preferences: prefs);
    await _captureMatrix(
      tester,
      'cervical-article.png',
      () => DawaArticlePage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'pregnancy-guide.png',
      () => DawaPregnancyGuideDetailPage(
        guideId: 'clinic-visit',
        repository: learning(),
      ),
    );
    await _captureMatrix(
      tester,
      'pregnancy-guides.png',
      () => DawaPregnancyGuidesPage(
        profileRepository: _FakeHealthProfileRepository(),
        learningRepository: learning(),
      ),
    );
    await _captureMatrix(
      tester,
      'audio-lesson.png',
      () => DawaAudioLessonPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'library.png',
      () => DawaLibraryPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'myth-fact.png',
      () => DawaMythFactPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'quest-hub.png',
      () => DawaQuestHubPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'quest-module.png',
      () => const DawaQuestModulePage(),
    );
    await _captureMatrix(
      tester,
      'clinic-lesson.png',
      () => const DawaClinicLessonPage(),
    );
    await _captureMatrix(
      tester,
      'quest-checkpoint.png',
      () => DawaQuestCheckpointPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'quest-complete.png',
      () => DawaQuestCompletePage(repository: learning()),
      beforePump: (_) async {
        await prefs.setStringList('dawa_learning_completed', [
          'myth-vs-fact',
          'screening-checkpoint',
        ]);
        await prefs.setInt('dawa_learning_coins', 720);
        await prefs.remove('dawa_learning_pending_completions');
      },
    );
  });

  testWidgets('capture games and rewards', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    DawaLearningRepository learning() =>
        DawaLearningRepository(preferences: prefs);
    await _captureMatrix(
      tester,
      'games-hub.png',
      () => DawaGamesHubPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'cycle-games-hub.png',
      () => DawaCycleGamesHubPage(repository: learning()),
    );
    await _captureMatrix(
      tester,
      'myth-match-game.png',
      () => DawaHealthGamePage(
        game: DawaHealthGameCatalog.games.first,
        repository: learning(),
        feedback: const DawaSilentGameFeedback(),
      ),
    );
    await _captureMatrix(
      tester,
      'rewards-center.png',
      () => DawaRewardsPage(repository: learning()),
    );
  });

  testWidgets('capture Profile and Notifications', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await _captureMatrix(
      tester,
      'profile.png',
      () => _shell(
        index: 4,
        child: DawaMomSettingsPage(
          profileRepository: _FakeHealthProfileRepository(),
        ),
      ),
    );
    await _captureMatrix(
      tester,
      'profile-account.png',
      () => _shell(
        index: 4,
        child: DawaMomSettingsPage(
          profileRepository: _FakeHealthProfileRepository(),
        ),
      ),
      afterPump: (tester) async {
        await tester.ensureVisible(
          find.byKey(const ValueKey('profile-logout')),
        );
        await tester.pumpAndSettle();
      },
    );
    await _captureMatrix(
      tester,
      'profile-completion.png',
      () => ProfileCompletionPage(
        repository: _FakeIncompleteHealthProfileRepository(),
      ),
    );
    await _captureMatrix(
      tester,
      'notifications.png',
      () => DawaNotificationsPage(
        repository: _FakeNotificationsRepository(),
      ),
    );
    await _captureMatrix(
      tester,
      'notification-preferences.png',
      () => DawaNotificationPreferencesPage(
        repository: DawaUserPreferencesRepository(
          preferences: prefs,
          client: _offlineClient,
        ),
      ),
    );
  });

  testWidgets('capture language and completion modals', (tester) async {
    await _captureMatrix(
      tester,
      'language-sheet.png',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showDawaLanguageSheet(
                context,
                initialValue: const DawaUserPreferences(),
              ),
              child: const Text('Open language'),
            ),
          ),
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.text('Open language'));
        await tester.pumpAndSettle();
      },
    );
    await _captureMatrix(
      tester,
      'game-complete-modal.png',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => DawaGameCompletionDialog(
                  title: 'Game complete!',
                  message:
                      'You earned 10 Dawa points for completing Myth Match.',
                  asset: DawaArtwork.banaCelebrate,
                  primaryLabel: 'Play again',
                  secondaryLabel: 'View rewards',
                  passed: true,
                  score: 5,
                  total: 5,
                  rewardCoins: 10,
                  onSecondary: () {},
                ),
              ),
              child: const Text('Finish game'),
            ),
          ),
        ),
      ),
      afterPump: (tester) async {
        await tester.tap(find.text('Finish game'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('capture reward redemption modal', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await _captureMatrix(
      tester,
      'reward-redemption-modal.png',
      () {
        final repository = DawaLearningRepository(preferences: prefs);
        return Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDawaRewardDialog(
                  context,
                  repository: repository,
                  state: const DawaLearningState(coins: 1200),
                ),
                child: const Text('Open reward'),
              ),
            ),
          ),
        );
      },
      afterPump: (tester) async {
        await tester.tap(find.text('Open reward'));
        await tester.pumpAndSettle();
      },
    );
  });
}

Future<void> _captureMatrix(
  WidgetTester tester,
  String name,
  Widget Function() builder, {
  Future<void> Function(WidgetTester tester)? beforePump,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  for (final entry in _captureSizes.entries) {
    _resetCapturePreferences();
    if (beforePump != null) await beforePump(tester);
    await _pump(tester, builder(), size: entry.value);
    if (afterPump != null) await afterPump(tester);
    await _precacheImages(tester);
    expect(
      tester.takeException(),
      isNull,
      reason: '$name failed at ${entry.value}',
    );
    await _capture(tester, '${entry.key}/$name');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }
}

void _resetCapturePreferences() {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'dawa_learning_coins': 720,
    'dawa_learning_streak': 5,
    'dawa_learning_completed': <String>[
      'myth-vs-fact',
      'screening-checkpoint',
    ],
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DawaTheme.light(),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _precacheImages(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _precacheImages(WidgetTester tester) async {
  final imageProviders = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(_captureKey));
    for (final provider in imageProviders) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _jumpPageToTop(WidgetTester tester) async {
  final scrollable = _pageVerticalScroll();
  if (scrollable == null) return;
  final state = tester.state<ScrollableState>(
    find
        .descendant(
          of: scrollable,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  state.position.jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> _jumpPageBy(WidgetTester tester, double delta) async {
  final scrollable = _pageVerticalScroll();
  if (scrollable == null) return;
  final state = tester.state<ScrollableState>(
    find
        .descendant(
          of: scrollable,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  state.position.jumpTo(
    (state.position.pixels + delta).clamp(
      state.position.minScrollExtent,
      state.position.maxScrollExtent,
    ),
  );
  await tester.pumpAndSettle();
}

Finder? _pageVerticalScroll() {
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is SingleChildScrollView &&
        widget.scrollDirection == Axis.vertical,
  );
  final scaffold = find.byType(DawaPageScaffold);
  if (scaffold.evaluate().isNotEmpty) {
    final insidePage = find.descendant(
      of: scaffold.first,
      matching: vertical,
    );
    if (insidePage.evaluate().isNotEmpty) return insidePage.first;
  }
  return vertical.evaluate().isEmpty ? null : vertical.first;
}

Future<void> _capture(WidgetTester tester, String name) => expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile(
        '../dawa implemented screems/$name',
      ),
    );

Widget _shell({
  required int index,
  required Widget child,
}) =>
    DawaMomResponsiveShell(
      currentIndex: index,
      destinations: _destinations,
      onDestinationSelected: (_) {},
      onLogout: () async {},
      rudoChatBuilder: (_, controller) =>
          _RudoCapturePanel(controller: controller),
      child: child,
    );

class _TourCaptureHost extends StatefulWidget {
  const _TourCaptureHost();

  @override
  State<_TourCaptureHost> createState() => _TourCaptureHostState();
}

class _TourCaptureHostState extends State<_TourCaptureHost> {
  late final DawaMainAppTourController _controller;
  int _index = 0;
  final _journeyKey = GlobalKey();
  final _rewardsKey = GlobalKey();
  final _notificationsKey = GlobalKey();
  late final _navigationKeys =
      List<GlobalKey>.generate(5, (index) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _controller = DawaMainAppTourController(
      service: MainAppTourService(userIdOverride: 'visual-tour-member'),
      onStepChanged: (step) {
        if (!mounted) return;
        setState(() => _index = dawaMainAppTourTabFor(step.target));
      },
    )..addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DawaMomResponsiveDashboard(
        onOpenRudo: () {},
        appointmentRepository: _FakeAppointmentRepository(),
        healthProfileRepository: _FakeHealthProfileRepository(),
        periodTrackerService: _FakePeriodTrackerService(),
        learningRepository: _FakeLearningRepository(),
        journeyTourKey: _journeyKey,
        rewardsTourKey: _rewardsKey,
        notificationsTourKey: _notificationsKey,
      ),
      const ColoredBox(
        color: DawaColors.canvas,
        child: Center(child: Text('Track your daily wellbeing')),
      ),
      const ColoredBox(
        color: DawaColors.canvas,
        child: Center(child: Text('Care and appointments')),
      ),
      const ColoredBox(
        color: DawaColors.canvas,
        child: Center(child: Text('Learn in small steps')),
      ),
      const ColoredBox(
        color: DawaColors.canvas,
        child: Center(child: Text('Your profile')),
      ),
    ];
    final shell = DawaMomResponsiveShell(
      currentIndex: _index,
      destinations: _destinations,
      navigationTargetKeys: _navigationKeys,
      onDestinationSelected: (_) {},
      onLogout: () async {},
      child: pages[_index],
    );
    return DawaMainAppTourScope(
      onReplay: () => _controller.start(replay: true),
      child: Stack(
        children: [
          Positioned.fill(child: shell),
          if (_controller.active)
            Positioned.fill(
              child: DawaMainAppTourOverlay(
                controller: _controller,
                targetKeys: {
                  DawaMainAppTourTarget.homeJourney: _journeyKey,
                  DawaMainAppTourTarget.track: _navigationKeys[1],
                  DawaMainAppTourTarget.care: _navigationKeys[2],
                  DawaMainAppTourTarget.learn: _navigationKeys[3],
                  DawaMainAppTourTarget.rewards: _rewardsKey,
                  DawaMainAppTourTarget.notifications: _notificationsKey,
                  DawaMainAppTourTarget.profile: _navigationKeys[4],
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RudoCapturePanel extends StatelessWidget {
  const _RudoCapturePanel({required this.controller});

  final RudoAssistantController controller;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: DawaColors.canvas,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                color: DawaColors.surface,
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/female-doctor.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rudo',
                            style: TextStyle(
                              color: DawaColors.primaryDark,
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Here to help',
                            style: TextStyle(
                              color: DawaColors.muted,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: controller.close,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DawaColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DawaColors.line),
                        ),
                        child: const Text(
                          'Hi, I’m Rudo. What would you like help with today?',
                          style: TextStyle(
                            color: DawaColors.ink,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    suffixIcon: IconButton(
                      tooltip: 'Send',
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
      clinicianName: 'Midwife Mulenga',
      clinicianTitle: 'Registered midwife',
      clinicName: 'Kalingalinga Clinic',
      clinicAddress: 'Lusaka, Zambia',
    );

Appointment _pastAppointment() => Appointment(
      id: 'appointment-completed-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime.now().subtract(const Duration(days: 8)),
      startTime: '11:00',
      endTime: '11:30',
      appointmentType: 'antenatal_care',
      status: 'completed',
      source: 'dawa_mom',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      integrationStatus: 'synced',
      clinicianName: 'Midwife Mulenga',
      clinicianTitle: 'Registered midwife',
      clinicName: 'Kalingalinga Clinic',
      clinicAddress: 'Lusaka, Zambia',
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
      'phone_number': '+260 97 000 0000',
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
        'phone_number': '+260 97 000 0000',
        'pregnancy_status': 'not_pregnant',
        'date_of_birth': '1994-03-17',
        'address': 'Lusaka, Zambia',
      },
      pregnancy: null,
      periodSettings: <String, dynamic>{
        'averageCycleLength': 32,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': _dateOnly(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
    );

class _FakeAppointmentRepository extends AppointmentRepository {
  _FakeAppointmentRepository() : super(client: _offlineClient);

  @override
  Future<List<Appointment>> getAppointments() async => [_appointment()];
}

class _FakeHealthProfileRepository implements HealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => _healthProfile();

  @override
  Future<void> retryPatientSync() async {}

  @override
  Future<void> savePregnancyInformation({
    required String status,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
  }) async {}
}

class _FakeIncompleteHealthProfileRepository
    extends _FakeHealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => HealthProfileSnapshot(
        profile: const <String, dynamic>{
          'email': 'chipo@example.test',
          'display_name': 'Chipo Banda',
        },
        mother: const <String, dynamic>{
          'name': 'Chipo Banda',
          'date_of_birth': '1994-03-17',
          'pregnancy_status': 'not_provided',
        },
        pregnancy: null,
        periodSettings: null,
      );
}

class _FakeCycleHealthProfileRepository extends _FakeHealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => _cycleHealthProfile();
}

class _FakePeriodTrackerService extends PeriodTrackerService {
  @override
  Future<Map<String, dynamic>?> loadUserSettings() async => _periodSettings();

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async => _periodHistory();
}

class _FakeCurrentPeriodTrackerService extends PeriodTrackerService {
  @override
  Future<Map<String, dynamic>?> loadUserSettings() async =>
      _cycleHealthProfile().periodSettings;

  @override
  Future<List<PeriodRecord>> loadPeriodHistory() async => [
        PeriodRecord(
          startDate: _dateOnly(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          endDate: null,
        ),
      ];
}

class _FakeLearningRepository extends DawaLearningRepository {
  @override
  Future<DawaLearningState> load() async => const DawaLearningState(
        coins: 720,
        streak: 5,
        completedIds: <String>{
          'screening-checkpoint',
          'pregnancy-basics',
        },
      );
}

class _FakeAppointmentReminderRepository
    extends DawaAppointmentReminderRepository {
  @override
  Future<DawaAppointmentReminder> load(String appointmentId) async =>
      DawaAppointmentReminder(
        appointmentId: appointmentId,
        enabled: true,
        daysBefore: 1,
        appNotification: true,
      );

  @override
  Future<DawaAppointmentReminder> save(
    DawaAppointmentReminder value,
  ) async =>
      value;
}

class _FakeNotificationsRepository extends DawaNotificationsRepository {
  _FakeNotificationsRepository()
      : super(
          appointments: AppointmentRepository(client: _offlineClient),
          client: _offlineClient,
        );

  @override
  Future<(List<DawaNotificationItem>, Set<String>)> load() async => (
        [
          DawaNotificationItem(
            id: 'appointment',
            category: DawaNotificationCategory.appointments,
            title: 'Appointment reminder',
            body:
                'Your antenatal check-up at Kalingalinga Clinic is tomorrow at 10:00 AM.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            icon: Icons.calendar_month_rounded,
            color: DawaColors.green,
          ),
          DawaNotificationItem(
            id: 'lesson',
            category: DawaNotificationCategory.learning,
            title: 'New lesson available',
            body: 'Cervical health: what to expect during screening.',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            icon: Icons.menu_book_rounded,
            color: DawaColors.primary,
          ),
        ],
        <String>{'lesson'},
      );

  @override
  Future<Set<String>> markRead(Set<String> read, String id) async =>
      {...read, id};

  @override
  Future<Set<String>> markAllRead(
    Set<String> read,
    Iterable<String> ids,
  ) async =>
      {...read, ...ids};
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
