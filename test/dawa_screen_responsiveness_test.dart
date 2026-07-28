import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/auth/dawa_auth_pages.dart';
import 'package:dawa_mom/features/games/domain/dawa_health_game.dart';
import 'package:dawa_mom/features/games/presentation/dawa_games_pages.dart';
import 'package:dawa_mom/features/games/services/dawa_game_feedback.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:dawa_mom/features/onboarding/dawa_onboarding_page.dart';
import 'package:dawa_mom/features/rewards/presentation/dawa_rewards_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizes = [
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(768, 1024),
    Size(1024, 768),
    Size(1366, 900),
    Size(1440, 900),
  ];

  testWidgets('welcome screen renders at every required product breakpoint',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in sizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: const DawaWelcomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('DawaMom'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('learning hub renders at every required product breakpoint',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in sizes) {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: DawaLearnPage(
            repository: DawaLearningRepository(preferences: preferences),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Cervical cancer awareness'), findsOneWidget);
      expect(find.text('Audio lessons in your language'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('onboarding remains polished and overflow-free on target devices',
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
        MaterialApp(
          theme: DawaTheme.light(),
          home: const DawaOnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book a visit with ease'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(const ValueKey('skip-onboarding')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Failed at $size');

      for (final title in const [
        'Health answers you can trust',
        'Know your cycle',
        'Learn, play and earn',
      ]) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: '$title failed at $size');
      }
      expect(find.text('Get started'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'games, game play and rewards render at every required breakpoint',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in sizes) {
      SharedPreferences.setMockInitialValues({
        'dawa_learning_coins': 205,
        'dawa_learning_completed': ['game-myth-match'],
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = DawaLearningRepository(preferences: preferences);
      tester.view.physicalSize = size;

      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: DawaGamesHubPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Games hub failed at $size');
      expect(find.text('Myth Match'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: DawaHealthGamePage(
            game: DawaHealthGameCatalog.games.first,
            repository: repository,
            feedback: const DawaSilentGameFeedback(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Game play failed at $size');
      expect(find.text('Myth Match'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: DawaRewardsPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Rewards failed at $size');
      expect(find.text('Dawa Rewards'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    }
  });
}
