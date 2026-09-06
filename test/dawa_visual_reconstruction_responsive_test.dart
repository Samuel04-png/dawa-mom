import 'package:dawa_mom/design_system/dawa_components.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/appointments/data/dawa_appointment_reminder_repository.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_appointment_reminder_sheet.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_booking_success_dialog.dart';
import 'package:dawa_mom/features/appointments/presentation/dawa_care_page.dart';
import 'package:dawa_mom/features/games/presentation/dawa_games_pages.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learning_detail_pages.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_quest_pages.dart';
import 'package:dawa_mom/features/notifications/dawa_notifications_page.dart';
import 'package:dawa_mom/features/period_tracker/presentation/dawa_cycle_tracker_page.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:dawa_mom/features/rewards/presentation/dawa_rewards_page.dart';
import 'package:dawa_mom/features/settings/dawa_mom_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _requiredSizes = <Size>[
  Size(360, 800),
  Size(390, 844),
  Size(412, 915),
  Size(768, 1024),
];

final _offlineSupabase = SupabaseClient(
  'http://127.0.0.1:54321',
  'responsive-test-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

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

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'dawa_learning_coins': 215,
      'dawa_learning_streak': 4,
      'dawa_learning_completed': <String>['myth-vs-fact'],
    });
  });

  testWidgets(
      'Care, Learn, article, guide, quests, games, rewards, profile and notifications render at every required size',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in _requiredSizes) {
      tester.view.physicalSize = size;
      final preferences = await SharedPreferences.getInstance();
      final learning = DawaLearningRepository(preferences: preferences);
      final pages = <(String, Widget)>[
        (
          'Care',
          DawaCarePage(
            initialAppointments: [_appointment()],
            initialClinics: const [
              ClinicOption(
                id: 'clinic-1',
                name: 'Kalingalinga Clinic',
                address: 'Lusaka, Zambia',
              ),
            ],
          ),
        ),
        ('Learn', DawaLearnPage(repository: learning)),
        ('Article', DawaArticlePage(repository: learning)),
        (
          'Pregnancy guide',
          DawaPregnancyGuideDetailPage(
            guideId: 'clinic-visit',
            repository: learning,
          ),
        ),
        ('Quest hub', DawaQuestHubPage(repository: learning)),
        ('Quest module', const DawaQuestModulePage()),
        ('Quest complete', DawaQuestCompletePage(repository: learning)),
        ('Games', DawaGamesHubPage(repository: learning)),
        ('Rewards', DawaRewardsPage(repository: learning)),
        (
          'Profile',
          DawaMomSettingsPage(
            profileRepository: _FakeHealthProfileRepository(),
          ),
        ),
        (
          'Notifications',
          DawaNotificationsPage(
            repository: _FakeNotificationsRepository(),
          ),
        ),
      ];

      for (final (name, page) in pages) {
        await _pump(tester, page);
        final failure = tester.takeException();
        if (failure != null) {
          _debugOverflowingFlexes(tester);
          debugPrint(
            '$name failed at $size:\n'
            '${failure is FlutterError ? failure.toStringDeep() : failure}',
          );
        }
        expect(
          failure,
          isNull,
          reason: '$name failed at $size',
        );
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('illustrated article hero never overlaps and metadata wraps',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in _requiredSizes) {
      tester.view.physicalSize = size;
      final preferences = await SharedPreferences.getInstance();
      await _pump(
        tester,
        DawaArticlePage(
          repository: DawaLearningRepository(preferences: preferences),
        ),
      );

      final hero = find.byType(DawaIllustratedHeroCard);
      final title = find.text('Cervical cancer awareness');
      final art = find.descendant(of: hero, matching: find.byType(Image));
      expect(hero, findsOneWidget);
      expect(title, findsOneWidget);
      expect(art, findsOneWidget);
      expect(
        tester.getRect(title).overlaps(tester.getRect(art)),
        isFalse,
        reason: 'Article hero regions overlapped at $size',
      );
      expect(find.text('Save article'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Article failed at $size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('learning categories scroll to the final Audio chip',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final preferences = await SharedPreferences.getInstance();

    await _pump(
      tester,
      DawaLearnPage(
        repository: DawaLearningRepository(preferences: preferences),
      ),
    );
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsOneWidget);
    await tester.drag(horizontal, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Audio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('critical screens survive increased text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    for (final scale in const [1.3, 1.6]) {
      final preferences = await SharedPreferences.getInstance();
      final pages = <Widget>[
        DawaCarePage(
          initialAppointments: [_appointment()],
          initialClinics: const [
            ClinicOption(
              id: 'clinic-1',
              name: 'Kalingalinga Clinic',
              address: 'Lusaka, Zambia',
            ),
          ],
        ),
        DawaLearnPage(
          repository: DawaLearningRepository(preferences: preferences),
        ),
        DawaArticlePage(
          repository: DawaLearningRepository(preferences: preferences),
        ),
        DawaNotificationsPage(
          repository: _FakeNotificationsRepository(),
        ),
        DawaMomSettingsPage(
          profileRepository: _FakeHealthProfileRepository(),
        ),
      ];
      for (final page in pages) {
        await _pump(tester, page, textScale: scale);
        final failure = tester.takeException();
        if (failure != null) {
          _debugOverflowingFlexes(tester);
          debugPrint(
            '${page.runtimeType} failed at ${scale}x text:\n'
            '${failure is FlutterError ? failure.toStringDeep() : failure}',
          );
        }
        expect(
          failure,
          isNull,
          reason: '${page.runtimeType} failed at ${scale}x text',
        );
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('care and check-in overlays remain usable at every required size',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in _requiredSizes) {
      tester.view.physicalSize = size;
      final preferences = await SharedPreferences.getInstance();
      final appointment = _appointment();
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: Wrap(
                children: [
                  TextButton(
                    onPressed: () =>
                        showDawaBookingSuccessDialog(context, appointment),
                    child: const Text('Open booking'),
                  ),
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DawaAppointmentReminderSheet(
                        appointment: appointment,
                        repository: DawaAppointmentReminderRepository(
                          preferences: preferences,
                          client: _offlineSupabase,
                        ),
                      ),
                    ),
                    child: const Text('Open reminder'),
                  ),
                  TextButton(
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
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open booking'));
      await tester.pumpAndSettle();
      expect(find.text('Appointment confirmed!'), findsOneWidget);
      expect(find.text('Set a reminder'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Booking confirmation failed at $size',
      );
      await tester.tap(find.text('Done for now'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Save reminder'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Appointment reminder failed at $size',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open check-in'));
      await tester.pumpAndSettle();
      expect(find.text('Save log'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Daily check-in failed at $size',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    }
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
    final ancestors = <String>[];
    element.visitAncestorElements((ancestor) {
      if (ancestors.length < 5)
        ancestors.add(ancestor.widget.runtimeType.toString());
      return ancestors.length < 5;
    });
    debugPrint(
      'Overflow candidate ${element.widget.runtimeType} '
      '${renderObject.direction} $flexRect inside ${ancestors.join(' ← ')}',
    );
    if (element.widget case Row(children: final widgets)) {
      debugPrint(
        '  widgets: ${widgets.map((widget) {
          if (widget is Text) return 'Text(${widget.data})';
          return widget.runtimeType.toString();
        }).join(', ')}',
      );
    }
    renderObject.visitChildren((child) {
      if (child is! RenderBox || !child.hasSize) return;
      final childRect = child.localToGlobal(Offset.zero) & child.size;
      debugPrint('  ${child.runtimeType}: $childRect');
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DawaTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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
      clinicianTitle: 'Registered midwife',
      clinicName: 'Kalingalinga Clinic',
      clinicAddress: 'Lusaka, Zambia',
    );

class _FakeHealthProfileRepository implements HealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => const HealthProfileSnapshot(
        profile: {
          'display_name': 'Chipo Banda',
          'email': 'chipo@example.test',
          'phone_number': '+260 97 000 0000',
        },
        mother: {
          'name': 'Chipo Banda',
          'phone_number': '+260 97 000 0000',
          'date_of_birth': '1995-01-01',
          'address': 'Lusaka, Zambia',
          'pregnancy_status': 'not_pregnant',
        },
        pregnancy: null,
        periodSettings: {
          'lastPeriodStart': null,
          'averageCycleLength': 28,
          'periodLength': 5,
          'isRegular': true,
        },
      );

  @override
  Future<void> retryPatientSync() async {}

  @override
  Future<void> savePregnancyInformation({
    required String status,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
  }) async {}
}

class _FakeNotificationsRepository extends DawaNotificationsRepository {
  _FakeNotificationsRepository()
      : super(
          appointments: AppointmentRepository(client: _offlineSupabase),
          client: _offlineSupabase,
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
