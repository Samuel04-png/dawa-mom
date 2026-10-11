import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_quest_pages.dart';
import 'package:dawa_mom/features/rewards/presentation/dawa_rewards_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a locally cached voucher is not treated as an authoritative claim',
      () async {
    SharedPreferences.setMockInitialValues({
      'dawa_reward_free_scan_voucher': 'DAWA12345678',
      'dawa_learning_coins': 40,
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    final state = await repository.load();
    final redemption = await repository.loadRedemption(state: state);

    expect(redemption, isNull);
  });

  testWidgets('reward center shows balance, earning paths and achievements',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'dawa_learning_coins': 215,
      'dawa_learning_completed': [
        'game-myth-match',
        'myth-vs-fact',
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    await _pumpRewards(tester, preferences);

    expect(find.text('215 Dawa points'), findsOneWidget);
    expect(find.text('Play a health game'), findsOneWidget);
    expect(find.text('Game changer'), findsOneWidget);
    expect(find.text('2 healthy actions completed'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Reward activity'), findsOneWidget);
    expect(find.text('Myth Match'), findsOneWidget);
    expect(find.text('+10 pts'), findsOneWidget);
  });

  testWidgets('an unverified cached voucher is not presented as active',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'dawa_reward_free_scan_voucher': 'SCANABC12345',
      'dawa_learning_coins': 30,
    });
    final preferences = await SharedPreferences.getInstance();
    await _pumpRewards(tester, preferences);

    expect(find.text('Your active voucher'), findsNothing);
    expect(find.text('SCANABC12345'), findsNothing);
    expect(find.byTooltip('Copy voucher code'), findsNothing);
  });

  testWidgets('core release keeps an unverified reward unavailable for claim',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: const DawaRewardsPage(
          previewState: DawaLearningState(coins: 1000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Redeem voucher'), findsNothing);
    expect(find.text('View voucher'), findsNothing);
    expect(
      find.textContaining('Clinic reward redemption is not available yet'),
      findsOneWidget,
    );
  });

  testWidgets('direct learning reward flow cannot expose voucher claiming',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final dialog = showDawaRewardDialog(
      pageContext,
      repository: repository,
      state: const DawaLearningState(coins: 1000),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rewards are being prepared'), findsOneWidget);
    expect(find.text('Redeem now'), findsNothing);
    expect(find.text('Clinic scan voucher'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await dialog, isNull);
  });
}

Future<void> _pumpRewards(
  WidgetTester tester,
  SharedPreferences preferences,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DawaTheme.light(),
      home: DawaRewardsPage(
        repository: DawaLearningRepository(preferences: preferences),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}
