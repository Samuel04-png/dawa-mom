import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/games/domain/dawa_health_game.dart';
import 'package:dawa_mom/features/games/presentation/dawa_games_pages.dart';
import 'package:dawa_mom/features/games/services/dawa_game_feedback.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('game catalog uses unique ids, routes and positive rewards', () {
    expect(
      DawaHealthGameCatalog.games.map((game) => game.id).toSet().length,
      DawaHealthGameCatalog.games.length,
    );
    expect(
      DawaHealthGameCatalog.games.map((game) => game.route).toSet().length,
      DawaHealthGameCatalog.games.length,
    );
    for (final game in DawaHealthGameCatalog.games) {
      expect(game.questions.length, greaterThanOrEqualTo(5));
      expect(game.rewardCoins, greaterThan(0));
      expect(game.passingScore, greaterThan(0));
    }
  });

  testWidgets('passing Myth Match awards points once and allows replay',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    final game = DawaHealthGameCatalog.byId(
      DawaHealthGameCatalog.mythMatchId,
    );
    await _pumpGame(tester, game, repository);

    final answers = [
      'Fact',
      'Myth',
      'Myth',
      'Fact',
      'Myth',
    ];
    for (var index = 0; index < answers.length; index++) {
      final answer = find.widgetWithText(OutlinedButton, answers[index]);
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(find.text('That’s right!'), findsOneWidget);
      final action = find.text(
        index == answers.length - 1 ? 'Finish game' : 'Next question',
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    expect(find.text('Game complete!'), findsOneWidget);
    expect(find.text('+10 points'), findsOneWidget);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();

    final state = await repository.load();
    expect(state.completedIds, contains(DawaHealthGameCatalog.mythMatchId));
    expect(state.coins, 190);
    expect(find.textContaining('Cervical screening can find'), findsOneWidget);
  });

  testWidgets('a score below the pass mark earns no reward', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    final game = DawaHealthGameCatalog.byId(
      DawaHealthGameCatalog.nutritionSortId,
    );
    await _pumpGame(tester, game, repository);

    for (var index = 0; index < game.questions.length; index++) {
      final question = game.questions[index];
      final wrongLabel = question.correctAnswer == DawaGameAnswer.first
          ? question.secondLabel
          : question.firstLabel;
      final answer = find.widgetWithText(OutlinedButton, wrongLabel);
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(find.text('Not quite'), findsOneWidget);
      final action = find.text(
        index == game.questions.length - 1 ? 'Finish game' : 'Next question',
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    expect(find.text('Almost there'), findsOneWidget);
    final state = await repository.load();
    expect(
      state.completedIds,
      isNot(contains(DawaHealthGameCatalog.nutritionSortId)),
    );
    expect(state.coins, 180);
  });

  testWidgets('games hub explains rewards and urgent-care boundary',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: DawaGamesHubPage(
          repository: DawaLearningRepository(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Myth Match'), findsOneWidget);
    expect(find.text('Plate Builder'), findsOneWidget);
    expect(find.textContaining('seek urgent care'), findsOneWidget);

    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('How health games work'), findsOneWidget);
    expect(find.text('Collect the reward once'), findsOneWidget);
  });
}

Future<void> _pumpGame(
  WidgetTester tester,
  DawaHealthGame game,
  DawaLearningRepository repository,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DawaTheme.light(),
      home: DawaHealthGamePage(
        game: game,
        repository: repository,
        feedback: const DawaSilentGameFeedback(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
