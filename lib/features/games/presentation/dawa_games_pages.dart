import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/learning/data/dawa_learning_repository.dart';
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
              'Games support learning and do not replace advice from a qualified health professional.',
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
  }

  @override
  void dispose() {
    unawaited(_feedback.dispose());
    super.dispose();
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
      setState(() {
        _questionIndex += 1;
        _answer = null;
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
          primaryLabel: 'Try again',
          passed: false,
          score: _score,
          total: widget.game.questions.length,
        ),
      );
      if (replay == true) _reset();
      return;
    }

    setState(() => _busy = true);
    final current = await _state;
    final alreadyCompleted = current.completedIds.contains(widget.game.id);
    final next = await _repository.complete(
      current,
      widget.game.id,
      rewardCoins: widget.game.rewardCoins,
    );
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
            : 'You earned ${widget.game.rewardCoins} Dawa points for completing ${widget.game.title}.',
        asset: DawaArtwork.banaCelebrate,
        primaryLabel: 'Play again',
        secondaryLabel: 'View rewards',
        passed: true,
        score: _score,
        total: widget.game.questions.length,
        rewardCoins: alreadyCompleted ? 0 : widget.game.rewardCoins,
        onSecondary: () {
          Navigator.pop(dialogContext, false);
          pageContext.push('/learn/rewards');
        },
      ),
    );
    if (replay == true) _reset();
  }

  void _reset() {
    setState(() {
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
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
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
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Choose one answer',
              child: Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: _question.firstLabel,
                      answer: DawaGameAnswer.first,
                      selectedAnswer: _answer,
                      correctAnswer: _question.correctAnswer,
                      onPressed: () => _select(DawaGameAnswer.first),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AnswerButton(
                      label: _question.secondLabel,
                      answer: DawaGameAnswer.second,
                      selectedAnswer: _answer,
                      correctAnswer: _question.correctAnswer,
                      onPressed: () => _select(DawaGameAnswer.second),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _answer == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Semantics(
                        liveRegion: true,
                        container: true,
                        label:
                            '${_isCorrect ? 'Correct' : 'Not quite'}. ${_question.explanation}',
                        child: DawaCard(
                          color: _isCorrect
                              ? DawaColors.softGreen
                              : DawaColors.softPink,
                          borderColor:
                              (_isCorrect ? DawaColors.green : DawaColors.pink)
                                  .withValues(alpha: .35),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DawaIconBadge(
                                icon: _isCorrect
                                    ? Icons.check_rounded
                                    : Icons.lightbulb_outline_rounded,
                                color: _isCorrect
                                    ? DawaColors.green
                                    : DawaColors.pink,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isCorrect
                                          ? 'That’s right!'
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
                  : 'Next question',
              busy: _busy,
              onPressed: _answer == null ? null : _continue,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Score $_score • Pass with ${widget.game.passingScore}/${widget.game.questions.length}',
                style: context.dawaCaption,
              ),
            ),
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
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
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
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
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
  Widget build(BuildContext context) => DawaCard(
        padding: EdgeInsets.zero,
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .18),
        child: SizedBox(
          height: DawaBreakpoints.isMobile(context) ? 210 : 228,
          child: Stack(
            children: [
              Positioned(
                right: DawaBreakpoints.isMobile(context) ? -8 : 24,
                bottom: 0,
                width: DawaBreakpoints.isMobile(context) ? 146 : 210,
                height: 210,
                child: Image.asset(
                  DawaArtwork.banaCelebrate,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  excludeFromSemantics: true,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: DawaBreakpoints.isMobile(context) ? 210 : 440,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PLAY • LEARN • GROW',
                            style: TextStyle(
                              color: DawaColors.green,
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Healthy choices become easier with practice.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: context.dawaDisplay.copyWith(
                              fontSize:
                                  DawaBreakpoints.isMobile(context) ? 20 : 24,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            '$completed of $total games completed • $coins points',
                            style: context.dawaCaption.copyWith(
                              color: DawaColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 190,
                            child: DawaProgressBar(
                              value: total == 0 ? 0 : completed / total,
                              semanticLabel: 'Health games completed',
                              color: DawaColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        child: SizedBox(
          height: 154,
          child: Row(
            children: [
              SizedBox(
                width: 105,
                height: 140,
                child: Image.asset(
                  game.asset,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
  });

  final DawaHealthGame game;
  final DawaGameQuestion question;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .16),
        child: Column(
          children: [
            SizedBox(
              height: DawaBreakpoints.isMobile(context) ? 205 : 240,
              child: Image.asset(
                game.asset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                question.prompt,
                textAlign: TextAlign.center,
                style: context.dawaTitle.copyWith(fontSize: 21),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the best answer.',
              textAlign: TextAlign.center,
              style: context.dawaCaption,
            ),
          ],
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
            ? DawaColors.danger
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
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
