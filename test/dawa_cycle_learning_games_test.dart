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

  test('cycle catalog contains eight purposeful games using five image roles',
      () {
    final games = DawaHealthGameCatalog.cycleGames;
    expect(games, hasLength(8));
    expect(
      games.map((game) => game.visualAssetId).toSet(),
      equals({
        'period_tracking_01',
        'period_tracking_02',
        'period_tracking_03',
        'period_tracking_04',
        'period_tracking_05',
      }),
    );
    for (final game in games) {
      expect(game.questions.length, inInclusiveRange(5, 6));
      expect(game.durationMinutes, inInclusiveRange(3, 4));
      expect(game.relatedActionLabel, isNotEmpty);
      expect(game.relatedActionRoute, startsWith('/'));
      expect(game.rewardCoins, 10);
    }
  });

  testWidgets('cycle games hub adapts from compact grid to large-text list',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    for (final scenario in const [
      (Size(360, 800), 1.0),
      (Size(390, 844), 1.0),
      (Size(412, 915), 1.0),
      (Size(768, 1024), 1.0),
      (Size(390, 844), 1.3),
      (Size(390, 844), 1.5),
    ]) {
      tester.view.physicalSize = scenario.$1;
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scenario.$2),
            ),
            child: child!,
          ),
          home: DawaCycleGamesHubPage(
            repository: DawaLearningRepository(preferences: preferences),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Understand Your Cycle'), findsOneWidget);
      expect(find.text('Cycle Phase Match'), findsOneWidget);
      expect(find.text('Period Products Match'), findsOneWidget);
      expect(find.text('Learn step by step'), findsNothing);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Hub overflowed at ${scenario.$1}, ${scenario.$2}x text',
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('unfinished round survives restart and appears as Continue',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final firstRepository = DawaLearningRepository(preferences: preferences);
    var state = await firstRepository.load();
    state = await firstRepository.saveGameProgress(
      state,
      gameId: DawaHealthGameCatalog.calendarDetectiveId,
      roundIndex: 2,
      correctAnswers: 2,
    );
    expect(
      state
          .gameProgress[DawaHealthGameCatalog.calendarDetectiveId]?.pendingSync,
      isTrue,
    );

    final restarted = DawaLearningRepository(preferences: preferences);
    final restored = await restarted.load();
    expect(
      restored
          .gameProgress[DawaHealthGameCatalog.calendarDetectiveId]?.roundIndex,
      2,
    );

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: DawaCycleGamesHubPage(repository: restarted),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('CONTINUE PLAYING'), findsOneWidget);
    expect(find.text('Calendar Detective'), findsWidgets);
    expect(find.text('Round 3 of 5 • pending sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cycle game gives calm correction and immediate urgent guidance',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    final game = DawaHealthGameCatalog.byId(
      DawaHealthGameCatalog.selfCareOrHelpId,
    );
    await _pumpGame(tester, game, repository);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Contact a clinic'));
    await tester.pumpAndSettle();
    expect(
      find.text('Good try. Here is the safer answer.'),
      findsOneWidget,
    );
    expect(find.textContaining('does not diagnose'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await _pumpGame(tester, game, repository);
    await _answerAndContinue(tester, 'Simple self-care');
    await _answerAndContinue(tester, 'Contact a clinic');

    final urgentWrong = find.widgetWithText(OutlinedButton, 'Simple self-care');
    await tester.ensureVisible(urgentWrong);
    await tester.tap(urgentWrong);
    await tester.pumpAndSettle();

    expect(find.text('Urgent care guidance'), findsOneWidget);
    expect(find.textContaining('Seek urgent care now'), findsOneWidget);
    expect(find.text('I understand • Next round'), findsOneWidget);
    expect(find.textContaining('Score '), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('cycle completion awards points once and clears resumable progress',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    var state = await repository.load();
    state = await repository.saveGameProgress(
      state,
      gameId: DawaHealthGameCatalog.phaseMatchId,
      roundIndex: 3,
      correctAnswers: 3,
    );
    state = await repository.complete(
      state,
      DawaHealthGameCatalog.phaseMatchId,
      rewardCoins: 10,
    );
    state = await repository.clearGameProgress(
      state,
      DawaHealthGameCatalog.phaseMatchId,
    );
    final replay = await repository.complete(
      state,
      DawaHealthGameCatalog.phaseMatchId,
      rewardCoins: 10,
    );

    expect(replay.coins, 190);
    expect(
      replay.completedIds,
      contains(DawaHealthGameCatalog.phaseMatchId),
    );
    expect(
      replay.gameProgress,
      isNot(contains(DawaHealthGameCatalog.phaseMatchId)),
    );
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

Future<void> _answerAndContinue(
  WidgetTester tester,
  String label,
) async {
  final answer = find.widgetWithText(OutlinedButton, label);
  await tester.ensureVisible(answer);
  await tester.tap(answer);
  await tester.pumpAndSettle();
  final next = find.text('Next round');
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}
