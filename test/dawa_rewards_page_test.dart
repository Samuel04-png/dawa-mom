import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/rewards/presentation/dawa_rewards_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stored voucher can be reopened without another debit', () async {
    SharedPreferences.setMockInitialValues({
      'dawa_reward_free_scan_voucher': 'DAWA12345678',
      'dawa_learning_coins': 40,
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    final state = await repository.load();
    final redemption = await repository.loadRedemption(state: state);

    expect(redemption, isNotNull);
    expect(redemption!.voucherCode, 'DAWA12345678');
    expect(redemption.alreadyRedeemed, isTrue);
    expect(redemption.state.coins, 40);
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

    expect(find.text('215'), findsOneWidget);
    expect(find.text('Play a health game'), findsOneWidget);
    expect(find.text('Game changer'), findsOneWidget);
    expect(find.text('2 healthy actions completed'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Reward activity'), findsOneWidget);
    expect(find.text('Myth Match'), findsOneWidget);
    expect(find.text('+10 pts'), findsOneWidget);
  });

  testWidgets('active voucher is visible and copyable', (tester) async {
    SharedPreferences.setMockInitialValues({
      'dawa_reward_free_scan_voucher': 'SCANABC12345',
      'dawa_learning_coins': 30,
    });
    final preferences = await SharedPreferences.getInstance();
    await _pumpRewards(tester, preferences);

    expect(find.text('Your active voucher'), findsOneWidget);
    expect(find.text('SCANABC12345'), findsOneWidget);
    expect(find.byTooltip('Copy voucher code'), findsOneWidget);
    expect(find.text('View voucher'), findsOneWidget);
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
