// Deterministic local launch-review captures. Run with:
// flutter test tool/launch_review_capture_test.dart --update-goldens

import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/data/appointment_repository.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/notifications/dawa_notifications_page.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:dawa_mom/features/profile/profile_completion_page.dart';
import 'package:dawa_mom/features/rewards/presentation/dawa_rewards_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _capture = ValueKey('launch-review-capture');
final _offlineClient = SupabaseClient(
  'http://127.0.0.1:54321',
  'launch-review-anon-key',
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

  testWidgets('captures refined profile', (tester) async {
    await _pump(
      tester,
      ProfileCompletionPage(repository: _IncompleteProfileRepository()),
    );
    await _golden(tester, 'profile.png');
  });

  testWidgets('captures reward progression', (tester) async {
    await _pump(
      tester,
      const DawaRewardsPage(
        previewState: DawaLearningState(
          coins: 820,
          balanceVerified: true,
          completedIds: {'myth-vs-fact', 'game-myth-match'},
        ),
      ),
    );
    await _golden(tester, 'rewards-progression.png');
  });

  testWidgets('captures an unlocked voucher wallet', (tester) async {
    const state = DawaLearningState(coins: 0, balanceVerified: true);
    const redemption = DawaRewardRedemption(
      state: state,
      rewardCode: 'free_scan_voucher',
      voucherCode: 'DAWA-OLD-REF',
      claimReference: 'DAWA-9K4M2R8T6Q1A',
      claimId: '3e8d5a06-3348-4e87-9a30-7e4d69c7ce83',
      qrPayload:
          'dawa-mom://voucher/3e8d5a06-3348-4e87-9a30-7e4d69c7ce83?ref=DAWA-9K4M2R8T6Q1A',
      alreadyRedeemed: false,
    );
    await _pump(
      tester,
      const DawaRewardsPage(
        previewState: state,
        previewRedemption: redemption,
      ),
    );
    await _golden(tester, 'voucher-wallet.png');
  });

  testWidgets('captures notification state', (tester) async {
    await _pump(tester, DawaNotificationsPage(repository: _Notifications()));
    await _golden(tester, 'notifications.png');
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _capture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DawaTheme.light(),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _golden(WidgetTester tester, String file) => expectLater(
      find.byKey(_capture),
      matchesGoldenFile('../docs/launch-captures/$file'),
    );

class _IncompleteProfileRepository extends HealthProfileRepository {
  _IncompleteProfileRepository() : super(client: _offlineClient);

  @override
  Future<HealthProfileSnapshot> load() async => const HealthProfileSnapshot(
        profile: {'display_name': 'Chipo'},
        mother: {'pregnancy_status': 'not_pregnant'},
        pregnancy: null,
        periodSettings: null,
      );
}

class _Notifications extends DawaNotificationsRepository {
  _Notifications()
      : super(
          appointments: AppointmentRepository(client: _offlineClient),
          client: _offlineClient,
        );

  @override
  Future<(List<DawaNotificationItem>, Set<String>)> load() async => (
        [
          DawaNotificationItem(
            id: 'visit',
            category: DawaNotificationCategory.appointments,
            title: 'Visit reminder',
            body: 'You have an upcoming visit. Open Care to review it.',
            // Future fixture dates deliberately keep relative labels stable
            // (`Now` / `Today`) without exposing real notification timing.
            createdAt: DateTime.now().add(const Duration(hours: 2)),
            icon: Icons.calendar_month_rounded,
            color: DawaColors.green,
          ),
          DawaNotificationItem(
            id: 'reward',
            category: DawaNotificationCategory.rewards,
            title: 'Reward update',
            body: 'Your Dawa Points balance changed.',
            createdAt: DateTime.now().add(const Duration(hours: 1)),
            icon: Icons.workspace_premium_rounded,
            color: DawaColors.warning,
          ),
        ],
        <String>{'reward'},
      );

  @override
  Future<Set<String>> markRead(Set<String> read, String id) async =>
      {...read, id};

  @override
  Future<Set<String>> markAllRead(
          Set<String> read, Iterable<String> ids) async =>
      {...read, ...ids};
}
