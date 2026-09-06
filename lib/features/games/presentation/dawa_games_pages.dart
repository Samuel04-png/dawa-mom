import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/services/voice_service.dart';
import '../domain/dawa_health_game.dart';
import '../services/dawa_game_feedback.dart';

class DawaGamesHubPage extends StatefulWidget {
  const DawaGamesHubPage({super.key, this.repository});

  static const routeName = 'HealthGames';
  static const routePath = '/learn/games';

  final DawaLearningRepository? repository;

  @override
  State<DawaGamesHubPage> createState() => _DawaGamesHubPageState();
}

class _DawaGamesHubPageState extends State<DawaGamesHubPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  void _showHowItWorks() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DawaBottomSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DawaIconBadge(
                  icon: Icons.sports_esports_rounded,
                  color: DawaColors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      Text('How health games work', style: context.dawaTitle),
                ),
                IconButton(
                  tooltip: 'Close game guide',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _GameRule(
              number: '1',
              title: 'Choose an answer',
              description:
                  'Every card gives immediate feedback and a short explanation.',
            ),
            const _GameRule(
              number: '2',
              title: 'Score 80% or higher',
              description:
                  'You can retry as often as you like. Replaying never removes points.',
            ),
            const _GameRule(
              number: '3',
              title: 'Collect the reward once',
              description:
                  'Each completed game awards 10 points once, even across devices.',
            ),
            const SizedBox(height: 10),
            Text(
              'Games help you learn. They do not replace care from a trained health worker.',
              style: context.dawaCaption,
            ),
            const SizedBox(height: 18),
            DawaPrimaryButton(
              label: 'Let’s play',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Health games',
              onBack: context.pop,
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/settings'),
            ),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const DawaLearningState();
                final completed = DawaHealthGameCatalog.games
                    .where((game) => state.completedIds.contains(game.id))
                    .length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GamesHero(
                      completed: completed,
                      total: DawaHealthGameCatalog.games.length,
                      coins: state.coins,
                    ),
                    const SizedBox(height: 16),
                    DawaSectionHeader(
                      title: 'Choose a game',
                      subtitle: 'Short, supportive practice you can replay',
                      actionLabel: 'How it works',
                      onAction: _showHowItWorks,
                    ),
                    const SizedBox(height: 10),
                    DawaResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 2,
                      children: [
                        for (final game in DawaHealthGameCatalog.games)
                          _GameCard(
                            game: game,
                            completed: state.completedIds.contains(game.id),
                            onTap: () async {
                              await context.push(game.route);
                              if (mounted) {
                                setState(() => _state = _repository.load());
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DawaCard(
                      color: DawaColors.softPink,
                      borderColor: DawaColors.pink.withValues(alpha: .25),
                      child: Row(
                        children: [
                          const DawaIconBadge(
                            icon: Icons.health_and_safety_rounded,
                            color: DawaColors.pink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'If you have severe pain, heavy bleeding, trouble breathing, fainting, or pregnancy danger signs, seek urgent care instead of playing.',
                              style: context.dawaCaption.copyWith(
                                color: DawaColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class DawaCycleGamesHubPage extends StatefulWidget {
  const DawaCycleGamesHubPage({super.key, this.repository});

  final DawaLearningRepository? repository;

  @override
  State<DawaCycleGamesHubPage> createState() => _DawaCycleGamesHubPageState();
}

class _DawaCycleGamesHubPageState extends State<DawaCycleGamesHubPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  Future<void> _openGame(DawaHealthGame game) async {
    await context.push(game.route);
    if (mounted) setState(() => _state = _repository.load());
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Understand Your Cycle',
              eyebrow: 'QUICK LEARNING GAMES',
              onBack: context.pop,
              onNotifications: () => context.push('/notifications'),
            ),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const DawaLoadingSkeleton(
                    layout: DawaSkeletonLayout.content,
                    label: 'Loading cycle games',
                  );
                }
                final state = snapshot.data!;
                final games = DawaHealthGameCatalog.cycleGames;
                final completed = games
                    .where((game) => state.completedIds.contains(game.id))
                    .length;
                final active = state.gameProgress.values
                    .where(
                      (progress) =>
                          games.any((game) => game.id == progress.gameId) &&
                          !state.completedIds.contains(progress.gameId),
                    )
                    .toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final continuing = active.firstOrNull;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CycleGamesIntro(
                      completed: completed,
                      total: games.length,
                      pointsAvailable: games
                          .where(
                            (game) => !state.completedIds.contains(game.id),
                          )
                          .fold(0, (sum, game) => sum + game.rewardCoins),
                    ),
                    if (continuing != null) ...[
                      const SizedBox(height: DawaSpacing.sm),
                      _ContinueCycleGameCard(
                        game: DawaHealthGameCatalog.byId(continuing.gameId),
                        progress: continuing,
                        onTap: () => _openGame(
                          DawaHealthGameCatalog.byId(continuing.gameId),
                        ),
                      ),
                    ],
                    const SizedBox(height: DawaSpacing.md),
                    const DawaSectionHeader(
                      title: 'Choose a quick game',
                      subtitle:
                          'No timers • tap-based answers • explanations after every round',
                    ),
                    const SizedBox(height: DawaSpacing.sm),
                    _CycleGameLayout(
                      games: games,
                      state: state,
                      onOpen: _openGame,
                    ),
                    const SizedBox(height: DawaSpacing.md),
                    DawaCard(
                      color: DawaColors.softGreen,
                      borderColor: DawaColors.green.withValues(alpha: .25),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DawaIconBadge(
                            icon: Icons.health_and_safety_outlined,
                            color: DawaColors.green,
                          ),
                          const SizedBox(width: DawaSpacing.sm),
                          Expanded(
                            child: Text(
                              'Games support learning and do not diagnose a condition. Urgent safety guidance always comes before points.',
                              style: context.dawaCaption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _CycleGamesIntro extends StatelessWidget {
  const _CycleGamesIntro({
    required this.completed,
    required this.total,
    required this.pointsAvailable,
  });

  final int completed;
  final int total;
  final int pointsAvailable;

  @override
  Widget build(BuildContext context) => DawaCard(
        featured: true,
        padding: const EdgeInsets.all(14),
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .18),
        semanticLabel:
            '$completed of $total cycle games complete. $pointsAvailable points available.',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 76,
              child: DawaContextualImage(
                assetId: 'period_tracking_01',
                variant: DawaImageVariant.compactThumbnail,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn through quick games and simple challenges',
                    style: context.dawaSectionTitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Learn what cycle days, symptoms and period estimates mean through short games.',
                    style: context.dawaCaption,
                  ),
                  const SizedBox(height: 8),
                  DawaProgressBar(
                    value: total == 0 ? 0 : completed / total,
                    semanticLabel: '$completed of $total cycle games completed',
                    color: DawaColors.green,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        '$completed of $total complete',
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.greenDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$pointsAvailable points available',
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ContinueCycleGameCard extends StatelessWidget {
  const _ContinueCycleGameCard({
    required this.game,
    required this.progress,
    required this.onTap,
  });

  final DawaHealthGame game;
  final DawaGameProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final round = (progress.roundIndex + 1).clamp(1, game.questions.length);
    return DawaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      semanticLabel:
          'Continue ${game.title}, round $round of ${game.questions.length}.',
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: DawaContextualImage(
              assetId: game.visualAssetId,
              variant: DawaImageVariant.cardSideImage,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTINUE PLAYING',
                  style: context.dawaCaption.copyWith(
                    color: DawaColors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(game.title, style: context.dawaSectionTitle),
                const SizedBox(height: 5),
                DawaProgressBar(
                  value: progress.roundIndex / game.questions.length,
                  semanticLabel: 'Round $round of ${game.questions.length}',
                  color: DawaColors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Round $round of ${game.questions.length}'
                  '${progress.pendingSync ? ' • pending sync' : ''}',
                  style: context.dawaCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.play_circle_fill_rounded,
            color: DawaColors.primary,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _CycleGameLayout extends StatelessWidget {
  const _CycleGameLayout({
    required this.games,
    required this.state,
    required this.onOpen,
  });

  final List<DawaHealthGame> games;
  final DawaLearningState state;
  final ValueChanged<DawaHealthGame> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final useGrid = constraints.maxWidth >= 328 && textScale <= 1.2;
          if (!useGrid) {
            return Column(
              children: [
                for (var index = 0; index < games.length; index++) ...[
                  _CycleGameListCard(
                    game: games[index],
                    completed: state.completedIds.contains(games[index].id),
                    progress: state.gameProgress[games[index].id],
                    onTap: () => onOpen(games[index]),
                  ),
                  if (index < games.length - 1)
                    const SizedBox(height: DawaSpacing.sm),
                ],
              ],
            );
          }
          final columns = constraints.maxWidth >= 720 ? 3 : 2;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final game in games)
                SizedBox(
                  width: width,
                  child: _CycleGameGridCard(
                    game: game,
                    completed: state.completedIds.contains(game.id),
                    progress: state.gameProgress[game.id],
                    onTap: () => onOpen(game),
                  ),
                ),
            ],
          );
        },
      );
}

class _CycleGameGridCard extends StatelessWidget {
  const _CycleGameGridCard({
    required this.game,
    required this.completed,
    required this.progress,
    required this.onTap,
  });

  final DawaHealthGame game;
  final bool completed;
  final DawaGameProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        semanticLabel:
            '${game.title}. ${completed ? 'Completed' : progress != null ? 'In progress' : 'Not started'}. ${game.durationMinutes} minutes.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DawaContextualImage(
              assetId: game.visualAssetId,
              variant: DawaImageVariant.moduleThumbnail,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DawaRadii.medium),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaSectionTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    game.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaCaption,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      DawaStatusPill(
                        label: '${game.durationMinutes} min',
                        icon: Icons.schedule_rounded,
                        color: DawaColors.primary,
                      ),
                      DawaStatusPill(
                        label: completed
                            ? 'Replay'
                            : progress != null
                                ? 'Continue'
                                : 'Play',
                        icon: completed
                            ? Icons.check_circle_outline_rounded
                            : progress != null
                                ? Icons.play_arrow_rounded
                                : Icons.play_arrow_rounded,
                        color: completed
                            ? DawaColors.green
                            : progress != null
                                ? DawaColors.primary
                                : DawaColors.primary,
                      ),
                      Text(
                        '+${game.rewardCoins} pts',
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CycleGameListCard extends StatelessWidget {
  const _CycleGameListCard({
    required this.game,
    required this.completed,
    required this.progress,
    required this.onTap,
  });

  final DawaHealthGame game;
  final bool completed;
  final DawaGameProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        semanticLabel:
            '${game.title}. ${completed ? 'Completed' : progress != null ? 'In progress' : 'Not started'}.',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 88,
              child: DawaContextualImage(
                assetId: game.visualAssetId,
                variant: DawaImageVariant.cardSideImage,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title, style: context.dawaSectionTitle),
                  const SizedBox(height: 3),
                  Text(
                    game.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaCaption,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${game.durationMinutes} min • '
                    '${completed ? 'Replay' : progress != null ? 'Continue round ${progress!.roundIndex + 1}' : 'Play • +${game.rewardCoins} points'}',
                    style: context.dawaCaption.copyWith(
                      color:
                          completed ? DawaColors.greenDark : DawaColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DawaColors.primary,
            ),
          ],
        ),
      );
}

class DawaHealthGamePage extends StatefulWidget {
  const DawaHealthGamePage({
    super.key,
    required this.game,
    this.repository,
    this.feedback,
  });

  static const routeName = 'HealthGame';
  static const routePath = '/learn/games/:gameId';

  final DawaHealthGame game;
  final DawaLearningRepository? repository;
  final DawaGameFeedback? feedback;

  @override
  State<DawaHealthGamePage> createState() => _DawaHealthGamePageState();
}

class _DawaHealthGamePageState extends State<DawaHealthGamePage> {
  late final DawaLearningRepository _repository;
  late final DawaGameFeedback _feedback;
  late Future<DawaLearningState> _state;
  VoiceService? _voiceService;
  var _questionIndex = 0;
  var _score = 0;
  DawaGameAnswer? _answer;
  var _busy = false;

  DawaGameQuestion get _question => widget.game.questions[_questionIndex];

  bool get _isCorrect => _answer == _question.correctAnswer;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _feedback = widget.feedback ?? DawaGameFeedbackService();
    _state = _repository.load();
    unawaited(_restoreProgress());
  }

  @override
  void dispose() {
    unawaited(_feedback.dispose());
    final voice = _voiceService;
    if (voice != null) unawaited(voice.dispose());
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final state = await _state;
    final progress = state.gameProgress[widget.game.id];
    if (!mounted ||
        progress == null ||
        state.completedIds.contains(widget.game.id)) {
      return;
    }
    setState(() {
      _questionIndex =
          progress.roundIndex.clamp(0, widget.game.questions.length - 1);
      _score = progress.correctAnswers.clamp(0, widget.game.questions.length);
    });
  }

  void _speakInstructions() {
    final question = _question;
    final answerLabels =
        question.answers.map((answer) => answer.$2).join('. Or ');
    final text =
        '${widget.game.instructions} ${question.prompt} Choose: $answerLabels.';
    final voice = _voiceService ??= VoiceService();
    unawaited(
      voice.speakText(
        text,
        Localizations.localeOf(context).languageCode,
      ),
    );
  }

  void _select(DawaGameAnswer answer) {
    if (_answer != null || _busy) return;
    final correct = answer == _question.correctAnswer;
    setState(() {
      _answer = answer;
      if (correct) _score += 1;
    });
    unawaited(correct ? _feedback.correct() : _feedback.wrong());
  }

  Future<void> _continue() async {
    if (_answer == null || _busy) return;
    if (_questionIndex < widget.game.questions.length - 1) {
      setState(() => _busy = true);
      final current = await _state;
      final next = await _repository.saveGameProgress(
        current,
        gameId: widget.game.id,
        roundIndex: _questionIndex + 1,
        correctAnswers: _score,
      );
      if (!mounted) return;
      setState(() {
        _state = Future.value(next);
        _questionIndex += 1;
        _answer = null;
        _busy = false;
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    final passed = _score >= widget.game.passingScore;
    if (!passed) {
      final replay = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DawaGameCompletionDialog(
          title: 'Almost there',
          message:
              'You scored $_score of ${widget.game.questions.length}. Review the explanations and try once more.',
          asset: DawaArtwork.banaReassure,
          visualAssetId: widget.game.visualAssetId,
          primaryLabel: 'Try again',
          passed: false,
          score: _score,
          total: widget.game.questions.length,
        ),
      );
      if (replay == true) await _reset();
      return;
    }

    setState(() => _busy = true);
    final current = await _state;
    final alreadyCompleted = current.completedIds.contains(widget.game.id);
    var next = await _repository.complete(
      current,
      widget.game.id,
      rewardCoins: widget.game.rewardCoins,
    );
    next = await _repository.clearGameProgress(next, widget.game.id);
    if (!mounted) return;
    setState(() {
      _state = Future.value(next);
      _busy = false;
    });
    await _feedback.completed();
    if (!mounted) return;
    final pageContext = context;
    final replay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DawaGameCompletionDialog(
        title: alreadyCompleted ? 'Brilliant replay!' : 'Game complete!',
        message: alreadyCompleted
            ? 'Your knowledge is getting stronger. You already collected this game’s reward.'
            : widget.game.activity == DawaGameActivity.kitBuilder
                ? 'Your period-kit checklist is saved. You also earned ${widget.game.rewardCoins} Dawa points.'
                : 'You earned ${widget.game.rewardCoins} Dawa points for completing ${widget.game.title}.',
        asset: DawaArtwork.banaCelebrate,
        visualAssetId: widget.game.completionAssetId,
        primaryLabel: 'Play again',
        secondaryLabel: widget.game.relatedActionLabel,
        passed: true,
        score: _score,
        total: widget.game.questions.length,
        rewardCoins: alreadyCompleted ? 0 : widget.game.rewardCoins,
        onSecondary: () {
          Navigator.pop(dialogContext, false);
          pageContext.push(widget.game.relatedActionRoute);
        },
      ),
    );
    if (replay == true) await _reset();
  }

  Future<void> _reset() async {
    final current = await _state;
    final next = await _repository.clearGameProgress(current, widget.game.id);
    if (!mounted) return;
    setState(() {
      _state = Future.value(next);
      _questionIndex = 0;
      _score = 0;
      _answer = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: widget.game.title,
              eyebrow: widget.game.eyebrow,
              onBack: context.pop,
            ),
            Row(
              children: [
                Expanded(
                  child: DawaProgressBar(
                    value: (_questionIndex + 1) / widget.game.questions.length,
                    semanticLabel:
                        'Question ${_questionIndex + 1} of ${widget.game.questions.length}',
                    color: DawaColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_questionIndex + 1}/${widget.game.questions.length}',
                  style: context.dawaCaption.copyWith(
                    color: DawaColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DawaCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.volume_up_outlined,
                    color: DawaColors.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.game.instructions,
                      style: context.dawaCaption,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Listen to instructions',
                    onPressed: _speakInstructions,
                    icon: const Icon(Icons.play_arrow_rounded),
                    color: DawaColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _QuestionCard(
                key: ValueKey(_questionIndex),
                game: widget.game,
                question: _question,
                onListen: _speakInstructions,
              ),
            ),
            const SizedBox(height: 14),
            _AnswerChoices(
              question: _question,
              selectedAnswer: _answer,
              onSelect: _select,
            ),
            AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _answer == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Semantics(
                        liveRegion: true,
                        container: true,
                        label:
                            '${_question.urgentGuidance ? 'Urgent care guidance' : _isCorrect ? 'Correct' : widget.game.isCycleGame ? 'Good try' : 'Not quite'}. ${_question.explanation}',
                        child: DawaCard(
                          color: _question.urgentGuidance
                              ? DawaColors.softPink
                              : _isCorrect
                                  ? DawaColors.softGreen
                                  : DawaColors.softBlue,
                          borderColor: (_question.urgentGuidance
                                  ? DawaColors.pink
                                  : _isCorrect
                                      ? DawaColors.green
                                      : DawaColors.primary)
                              .withValues(alpha: .35),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DawaIconBadge(
                                icon: _isCorrect
                                    ? _question.urgentGuidance
                                        ? Icons.emergency_rounded
                                        : Icons.check_rounded
                                    : _question.urgentGuidance
                                        ? Icons.emergency_rounded
                                        : Icons.lightbulb_outline_rounded,
                                color: _question.urgentGuidance
                                    ? DawaColors.pink
                                    : _isCorrect
                                        ? DawaColors.green
                                        : DawaColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isCorrect
                                          ? _question.urgentGuidance
                                              ? 'Urgent care guidance'
                                              : 'That’s right!'
                                          : _question.urgentGuidance
                                              ? 'Urgent care guidance'
                                              : widget.game.isCycleGame
                                                  ? 'Good try. Here is the safer answer.'
                                                  : 'Not quite',
                                      style: context.dawaSectionTitle,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _question.explanation,
                                      style: context.dawaBody,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            DawaPrimaryButton(
              label: _questionIndex == widget.game.questions.length - 1
                  ? 'Finish game'
                  : _question.urgentGuidance && _answer != null
                      ? 'I understand • Next round'
                      : widget.game.isCycleGame
                          ? 'Next round'
                          : 'Next question',
              busy: _busy,
              onPressed: _answer == null ? null : _continue,
            ),
            if (!(_question.urgentGuidance && _answer != null)) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Score $_score • Pass with ${widget.game.passingScore}/${widget.game.questions.length}',
                  style: context.dawaCaption,
                ),
              ),
            ],
          ],
        ),
      );
}

class DawaGameCompletionDialog extends StatelessWidget {
  const DawaGameCompletionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.asset,
    this.visualAssetId,
    required this.primaryLabel,
    required this.passed,
    required this.score,
    required this.total,
    this.secondaryLabel,
    this.rewardCoins = 0,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String asset;
  final String? visualAssetId;
  final String primaryLabel;
  final String? secondaryLabel;
  final bool passed;
  final int score;
  final int total;
  final int rewardCoins;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        elevation: 8,
        shadowColor: const Color(0x330C2878),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DawaRadii.large),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .82, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 154,
                    height: 154,
                    decoration: BoxDecoration(
                      color:
                          passed ? DawaColors.softGreen : DawaColors.softBlue,
                      shape: BoxShape.circle,
                    ),
                    child: visualAssetId == null
                        ? Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          )
                        : DawaContextualImage(
                            assetId: visualAssetId!,
                            variant: DawaImageVariant.compactThumbnail,
                            borderRadius: BorderRadius.circular(77),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.dawaTitle.copyWith(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.dawaBody,
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DawaStatusPill(
                      label: '$score of $total correct',
                      icon: passed
                          ? Icons.workspace_premium_rounded
                          : Icons.refresh_rounded,
                      color: passed ? DawaColors.green : DawaColors.primary,
                    ),
                    if (rewardCoins > 0)
                      DawaStatusPill(
                        label: '+$rewardCoins points',
                        icon: Icons.monetization_on_rounded,
                        color: DawaColors.gold,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (secondaryLabel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(primaryLabel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(primaryLabel),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _GamesHero extends StatelessWidget {
  const _GamesHero({
    required this.completed,
    required this.total,
    required this.coins,
  });

  final int completed;
  final int total;
  final int coins;

  @override
  Widget build(BuildContext context) => DawaIllustratedHeroCard(
        category: 'PLAY • LEARN • GROW',
        title: 'Healthy choices become easier with practice',
        subtitle: '$completed of $total games completed • $coins Dawa points',
        illustrationPath: DawaArtwork.banaCelebrate,
        progress: total == 0 ? 0 : completed / total,
        progressLabel: 'Health game progress',
        backgroundColor: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .18),
        semanticLabel:
            '$completed of $total health games completed. $coins Dawa points.',
      );
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.completed,
    required this.onTap,
  });

  final DawaHealthGame game;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        onTap: onTap,
        semanticLabel:
            '${game.title}. ${completed ? 'Completed, replay available' : '${game.rewardCoins} point reward'}',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 148),
          child: Row(
            children: [
              SizedBox(
                width: DawaBreakpoints.isMobile(context) ? 96 : 112,
                child: DawaContextualImage(
                  assetId: game.visualAssetId,
                  variant: DawaImageVariant.cardSideImage,
                  heroTag: 'game-${game.id}-${game.visualAssetId}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.eyebrow,
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 3),
                    Text(game.title, style: context.dawaSectionTitle),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      style: context.dawaCaption,
                    ),
                    const SizedBox(height: 8),
                    DawaStatusPill(
                      label: completed ? 'Replay' : '+${game.rewardCoins} pts',
                      icon: completed
                          ? Icons.replay_rounded
                          : Icons.monetization_on_rounded,
                      color: completed ? DawaColors.primary : DawaColors.gold,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: DawaColors.primary),
            ],
          ),
        ),
      );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.game,
    required this.question,
    required this.onListen,
  });

  final DawaHealthGame game;
  final DawaGameQuestion question;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final visual = SizedBox(
              width: stacked ? 132 : 116,
              child: DawaContextualImage(
                assetId: game.visualAssetId,
                variant: DawaImageVariant.cardSideImage,
                borderRadius: BorderRadius.circular(DawaRadii.small),
              ),
            );
            final copy = Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    question.prompt,
                    textAlign: stacked ? TextAlign.center : TextAlign.start,
                    style: context.dawaTitle.copyWith(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: stacked
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        'Choose the best answer.',
                        style: context.dawaCaption,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Replay spoken question',
                      onPressed: onListen,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            );
            if (stacked) {
              return Column(
                children: [
                  visual,
                  const SizedBox(height: 10),
                  copy,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                visual,
                const SizedBox(width: 14),
                Expanded(child: copy),
              ],
            );
          },
        ),
      );
}

class _AnswerChoices extends StatelessWidget {
  const _AnswerChoices({
    required this.question,
    required this.selectedAnswer,
    required this.onSelect,
  });

  final DawaGameQuestion question;
  final DawaGameAnswer? selectedAnswer;
  final ValueChanged<DawaGameAnswer> onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Choose one answer',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final answers = question.answers;
            final stacked = answers.length > 2 ||
                constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.25;
            final buttons = [
              for (final answer in answers)
                _AnswerButton(
                  label: answer.$2,
                  answer: answer.$1,
                  selectedAnswer: selectedAnswer,
                  correctAnswer: question.correctAnswer,
                  onPressed: () => onSelect(answer.$1),
                ),
            ];
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    buttons[index],
                    if (index < buttons.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  Expanded(child: buttons[index]),
                  if (index < buttons.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      );
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.answer,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onPressed,
  });

  final String label;
  final DawaGameAnswer answer;
  final DawaGameAnswer? selectedAnswer;
  final DawaGameAnswer correctAnswer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final answered = selectedAnswer != null;
    final selected = selectedAnswer == answer;
    final correct = answered && answer == correctAnswer;
    final incorrect = selected && !correct;
    final color = correct
        ? DawaColors.green
        : incorrect
            ? DawaColors.pink
            : DawaColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: answered
          ? '$label. ${correct ? 'Correct answer' : incorrect ? 'Selected, incorrect' : 'Not selected'}'
          : label,
      child: OutlinedButton(
        onPressed: answered ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 58),
          foregroundColor: color,
          backgroundColor: (correct || incorrect)
              ? color.withValues(alpha: .1)
              : Colors.white,
          side: BorderSide(
            color: (selected || correct) ? color : DawaColors.line,
            width: (selected || correct) ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (correct || incorrect) ...[
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 19,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameRule extends StatelessWidget {
  const _GameRule({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: DawaColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.dawaSectionTitle),
                  const SizedBox(height: 2),
                  Text(description, style: context.dawaCaption),
                ],
              ),
            ),
          ],
        ),
      );
}
