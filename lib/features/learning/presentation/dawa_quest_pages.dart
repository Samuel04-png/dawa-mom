import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '../data/dawa_learning_repository.dart';

class DawaQuestHubPage extends StatefulWidget {
  const DawaQuestHubPage({super.key, this.repository});

  static const routeName = 'QuestHub';
  static const routePath = '/learn/quests';

  final DawaLearningRepository? repository;

  @override
  State<DawaQuestHubPage> createState() => _DawaQuestHubPageState();
}

class _DawaQuestHubPageState extends State<DawaQuestHubPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Learn',
              onBack: context.pop,
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/settings'),
            ),
            Text(
              'Stories, lessons and quests for your health journey.',
              style: context.dawaCaption,
            ),
            const SizedBox(height: 12),
            DawaCard(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: DawaColors.softBlue,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: DawaBreakpoints.isMobile(context) ? 10 : 40,
                      bottom: 0,
                      height: 194,
                      width: DawaBreakpoints.isMobile(context) ? 130 : 170,
                      child: Image.asset(
                        DawaArtwork.banaWelcome,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '♥  Your guide, your friend',
                              style: TextStyle(
                                color: DawaColors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bana Chenjela\nis here to guide you.',
                              style: context.dawaDisplay.copyWith(fontSize: 25),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Learn in small steps and earn healthy-action rewards.',
                              style: context.dawaCaption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            DawaCard(
              color: DawaColors.softGreen,
              borderColor: DawaColors.green.withValues(alpha: 0.3),
              child: Column(
                children: [
                  Row(
                    children: [
                      const DawaIconBadge(
                        icon: Icons.route_rounded,
                        color: DawaColors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THE MOTHER’S PATH',
                              style: TextStyle(
                                color: DawaColors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Screening Without Fear',
                              style: context.dawaTitle.copyWith(fontSize: 18),
                            ),
                            Text(
                              'Learn why screening is safe, simple and life-saving.',
                              style: context.dawaCaption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<DawaLearningState>(
                    future: _state,
                    builder: (context, snapshot) => DawaProgressBar(
                      value: dawaQuestProgress(
                        snapshot.data ?? const DawaLearningState(),
                      ),
                      semanticLabel: 'Screening Without Fear progress',
                      color: DawaColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DawaPrimaryButton(
                    label: 'Continue quest',
                    onPressed: () => context.push('/learn/quests/screening'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const DawaLearningState();
                return Row(
                  children: [
                    Expanded(
                      child: DawaCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFF0843E),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${state.streak} day streak',
                                      style: context.dawaSectionTitle),
                                  Text('Today’s check-in',
                                      style: context.dawaCaption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DawaCard(
                        onTap: snapshot.connectionState == ConnectionState.done
                            ? () => context.push('/learn/rewards')
                            : null,
                        semanticLabel:
                            'My rewards. Current balance ${state.coins} coins',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.redeem_rounded,
                              color: DawaColors.gold,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${state.coins} coins',
                                      style: context.dawaSectionTitle),
                                  Text('My rewards',
                                      style: context.dawaCaption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            DawaResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 3,
              children: [
                _QuestActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book my screening',
                  description: 'Find a clinic and choose a time.',
                  action: 'Book now',
                  onTap: () => context.go('/encounters'),
                ),
                _QuestActionCard(
                  icon: Icons.auto_stories_rounded,
                  title: 'Continue Mother’s Path',
                  description: 'Explore more stories and complete the quest.',
                  action: 'Continue journey',
                  onTap: () => context.push('/learn/quests/screening'),
                ),
                _QuestActionCard(
                  icon: Icons.groups_outlined,
                  title: 'Women’s cohort',
                  description:
                      'Learn alongside other women on their health journey.',
                  action: 'Continue learning',
                  onTap: () => context.push('/learn/quests/screening'),
                ),
              ],
            ),
          ],
        ),
      );
}

class _QuestActionCard extends StatelessWidget {
  const _QuestActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaIconBadge(icon: icon, color: DawaColors.primary),
            const SizedBox(height: 10),
            Text(title, style: context.dawaSectionTitle),
            const SizedBox(height: 4),
            Text(description, style: context.dawaCaption),
            const Spacer(),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onTap,
              child: Text(action),
            ),
          ],
        ),
      );
}

class DawaQuestModulePage extends StatelessWidget {
  const DawaQuestModulePage({super.key});

  static const routeName = 'QuestModule';
  static const routePath = '/learn/quests/screening';

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Screening Without Fear', onBack: context.pop),
            const SizedBox(height: 10),
            DawaCard(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 230,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: DawaColors.softBlue,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 0,
                      width: 175,
                      height: 220,
                      child: Image.asset(
                        DawaArtwork.banaWelcome,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bana Chenjela',
                              style: context.dawaSectionTitle
                                  .copyWith(color: DawaColors.green),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Let’s walk through screening together. I’ll show you what to expect, step by step.',
                              style: context.dawaTitle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.volume_up_outlined),
                              label: const Text('Play in Nyanja'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _QuestStep(
              number: 1,
              icon: Icons.help_outline_rounded,
              title: 'What is screening?',
              subtitle: 'Learn why screening is important.',
              state: 'Learn',
            ),
            const _QuestStep(
              number: 2,
              icon: Icons.health_and_safety_outlined,
              title: 'Will it hurt?',
              subtitle: 'Find out what to expect.',
              state: 'Learn',
            ),
            _QuestStep(
              number: 3,
              icon: Icons.local_hospital_outlined,
              title: 'What happens at the clinic',
              subtitle: 'Step-by-step through your visit.',
              state: 'In progress',
              onTap: () => context.push('/learn/quests/screening/clinic'),
            ),
            _QuestStep(
              number: 4,
              icon: Icons.calendar_month_outlined,
              title: 'Book my screening',
              subtitle: 'Choose a time that works for you.',
              state: 'Next',
              onTap: () => context.go('/encounters'),
            ),
            const SizedBox(height: 12),
            DawaPrimaryButton(
              label: 'Start next step',
              onPressed: () => context.push('/learn/quests/screening/clinic'),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => context.go('/learn'),
                child: const Text('Back to Learn'),
              ),
            ),
          ],
        ),
      );
}

class _QuestStep extends StatelessWidget {
  const _QuestStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    this.onTap,
  });

  final int number;
  final IconData icon;
  final String title;
  final String subtitle;
  final String state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DawaCard(
          padding: const EdgeInsets.all(12),
          onTap: onTap,
          semanticLabel: 'Step $number. $title. $state.',
          child: Row(
            children: [
              DawaIconBadge(
                icon: icon,
                color: DawaColors.primary,
              ),
              const SizedBox(width: 10),
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DawaColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.dawaSectionTitle),
                    Text(subtitle, style: context.dawaCaption),
                  ],
                ),
              ),
              Text(
                state,
                style: context.dawaCaption.copyWith(
                  color: DawaColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                onTap == null
                    ? Icons.circle_outlined
                    : Icons.chevron_right_rounded,
                color: DawaColors.primary,
              ),
            ],
          ),
        ),
      );
}

class DawaClinicLessonPage extends StatelessWidget {
  const DawaClinicLessonPage({super.key});

  static const routeName = 'ClinicLesson';
  static const routePath = '/learn/quests/screening/clinic';

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 950,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Screening Without Fear', onBack: context.pop),
            const SizedBox(height: 6),
            const DawaProgressBar(
              value: 0.7,
              semanticLabel: 'Quest progress',
              color: DawaColors.green,
            ),
            const SizedBox(height: 12),
            DawaCard(
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final copy = Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bana Chenjela says',
                          style: context.dawaSectionTitle
                              .copyWith(color: DawaColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '“Cervical screening helps find problems early, before they become dangerous.”',
                          style: context.dawaTitle.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'It checks for changes in the cervix so treatment can start early — when it works best.',
                          style: context.dawaBody,
                        ),
                      ],
                    ),
                  );
                  final image = Image.asset(
                    DawaArtwork.clinicConversation,
                    height: 310,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    semanticLabel:
                        'A clinician explains cervical screening to a woman.',
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(children: [copy, image]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: copy),
                      Expanded(child: image),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            const DawaSectionHeader(title: 'What to expect at the clinic'),
            const SizedBox(height: 9),
            DawaResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 3,
              desktopColumns: 3,
              children: const [
                _ClinicStep(
                  number: 1,
                  icon: Icons.meeting_room_outlined,
                  title: 'Check in',
                  description: 'The clinic team greets you and gets you ready.',
                ),
                _ClinicStep(
                  number: 2,
                  icon: Icons.medical_services_outlined,
                  title: 'Quick screening test',
                  description:
                      'A trained clinician performs the test in a few minutes.',
                ),
                _ClinicStep(
                  number: 3,
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Get your next steps',
                  description:
                      'The clinician explains results and follow-up timing.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softGreen,
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: DawaColors.green, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Screening is usually quick. Ask the clinician to explain any step and tell them if you are uncomfortable.',
                      style: context.dawaBody,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/learn/quests/screening/checkpoint'),
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: const Text('I understand'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/learn/quests/screening/checkpoint'),
                    icon: const Icon(Icons.sentiment_dissatisfied_outlined),
                    label: const Text('I’m still worried'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ClinicStep extends StatelessWidget {
  const _ClinicStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                DawaIconBadge(icon: icon, size: 56),
                Positioned(
                  left: -7,
                  top: -7,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: DawaColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center, style: context.dawaSectionTitle),
            const SizedBox(height: 3),
            Text(description,
                textAlign: TextAlign.center, style: context.dawaCaption),
          ],
        ),
      );
}

class DawaQuestCheckpointPage extends StatefulWidget {
  const DawaQuestCheckpointPage({super.key, this.repository});

  static const routeName = 'QuestCheckpoint';
  static const routePath = '/learn/quests/screening/checkpoint';

  final DawaLearningRepository? repository;

  @override
  State<DawaQuestCheckpointPage> createState() =>
      _DawaQuestCheckpointPageState();
}

class _DawaQuestCheckpointPageState extends State<DawaQuestCheckpointPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  Future<void> _select(String value) async {
    setState(() => _selected = value);
    if (value != 'B') return;
    final state = await _state;
    final next = await _repository.complete(
      state,
      'screening-checkpoint',
      rewardCoins: 5,
    );
    if (mounted) setState(() => _state = Future.value(next));
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Quest Checkpoint', onBack: context.pop),
            const SizedBox(height: 10),
            DawaCard(
              color: DawaColors.softGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THE MOTHER’S PATH',
                    style: TextStyle(
                      color: DawaColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('Screening Without Fear',
                      style: context.dawaTitle.copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  const DawaProgressBar(
                    value: 0.85,
                    semanticLabel: 'Quest progress',
                    color: DawaColors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Which statement is true?',
                      style: context.dawaTitle.copyWith(fontSize: 22)),
                  Text('Choose one answer.', style: context.dawaCaption),
                  const SizedBox(height: 14),
                  _AnswerCard(
                    key: const ValueKey('checkpoint-answer-a'),
                    letter: 'A',
                    text:
                        'Screening is only needed when you already feel sick.',
                    selected: _selected == 'A',
                    correct: false,
                    showResult: _selected != null,
                    onTap: () => _select('A'),
                  ),
                  const SizedBox(height: 10),
                  _AnswerCard(
                    key: const ValueKey('checkpoint-answer-b'),
                    letter: 'B',
                    text:
                        'Screening can help find problems early, before you feel sick.',
                    selected: _selected == 'B',
                    correct: true,
                    showResult: _selected != null,
                    onTap: () => _select('B'),
                  ),
                ],
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              DawaResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 2,
                children: [
                  DawaCard(
                    color: DawaColors.softBlue,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 85,
                          height: 110,
                          child: Image.asset(
                            DawaArtwork.banaExplain,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selected == 'B'
                                ? 'That’s right. Screening is for prevention, not only when symptoms appear.'
                                : 'Not quite. People can benefit from screening before symptoms appear.',
                            style: context.dawaBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DawaCard(
                    color: DawaColors.softGreen,
                    child: Row(
                      children: [
                        const DawaIconBadge(
                          icon: Icons.health_and_safety_outlined,
                          color: DawaColors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Eligibility and screening intervals vary. Follow qualified local clinical guidance.',
                            style: context.dawaBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            DawaPrimaryButton(
              label: 'Continue quest',
              onPressed: _selected == 'B'
                  ? () => context.push('/learn/quests/completed')
                  : null,
            ),
          ],
        ),
      );
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    super.key,
    required this.letter,
    required this.text,
    required this.selected,
    required this.correct,
    required this.showResult,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool correct;
  final bool showResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resultColor = correct ? DawaColors.green : DawaColors.danger;
    final resultLabel = correct ? 'Correct answer' : 'Incorrect answer';
    return Semantics(
      button: true,
      selected: selected,
      label: 'Answer $letter. $text'
          '${showResult && (selected || correct) ? '. $resultLabel' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DawaRadii.medium),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: showResult && (selected || correct)
                ? resultColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(DawaRadii.medium),
            border: Border.all(
              color: showResult && (selected || correct)
                  ? resultColor
                  : DawaColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DawaColors.primary, width: 2),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: DawaColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: context.dawaSectionTitle),
              ),
              if (showResult && (selected || correct))
                Icon(
                  correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: resultColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DawaQuestCompletePage extends StatefulWidget {
  const DawaQuestCompletePage({super.key, this.repository});

  static const routeName = 'QuestComplete';
  static const routePath = '/learn/quests/completed';

  final DawaLearningRepository? repository;

  @override
  State<DawaQuestCompletePage> createState() => _DawaQuestCompletePageState();
}

class _DawaQuestCompletePageState extends State<DawaQuestCompletePage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;
  bool _wasAlreadyComplete = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _complete();
  }

  Future<DawaLearningState> _complete() async {
    final state = await _repository.load();
    _wasAlreadyComplete = state.completedIds.contains('screening-without-fear');
    return _repository.complete(
      state,
      'screening-without-fear',
      rewardCoins: 20,
    );
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 950,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Quest complete', onBack: context.pop),
            Text(
              'Great work, Mama! You’re building a healthier future.',
              style: context.dawaCaption,
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softGreen,
              borderColor: DawaColors.green.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.check_rounded,
                    color: DawaColors.green,
                    size: 64,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THE MOTHER’S PATH',
                          style: TextStyle(
                            color: DawaColors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'You completed\nScreening Without Fear.',
                          style: context.dawaTitle.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You’re one step closer to a healthy you and a healthy baby.',
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 160,
                    child: Image.asset(
                      DawaArtwork.banaCelebrate,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) => DawaResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 3,
                desktopColumns: 3,
                children: [
                  _AchievementCard(
                    icon: Icons.monetization_on_rounded,
                    color: DawaColors.gold,
                    title: _wasAlreadyComplete ? '20 coin reward' : '+20 coins',
                    subtitle: 'Balance ${snapshot.data?.coins ?? '…'} coins',
                  ),
                  const _AchievementCard(
                    icon: Icons.workspace_premium_rounded,
                    color: DawaColors.green,
                    title: 'Knowledge milestone',
                    subtitle: 'Quest completion saved',
                  ),
                  const _AchievementCard(
                    icon: Icons.auto_stories_rounded,
                    color: DawaColors.purple,
                    title: 'Keep learning',
                    subtitle: 'At the Clinic is ready to read',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaCard(
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.lightbulb_outline_rounded,
                    color: DawaColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You learned what screening is, what happens at the clinic, and why finding cell changes early matters.',
                      style: context.dawaBody,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
              children: [
                _QuestActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book my screening',
                  description: 'Find a clinic and choose a suitable time.',
                  action: 'Book now',
                  onTap: () => context.go('/encounters'),
                ),
                _QuestActionCard(
                  icon: Icons.route_rounded,
                  title: 'Continue Mother’s Path',
                  description: 'Explore more stories and healthy actions.',
                  action: 'Continue journey',
                  onTap: () => context.go('/learn'),
                ),
              ],
            ),
          ],
        ),
      );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center, style: context.dawaSectionTitle),
            const SizedBox(height: 3),
            Text(subtitle,
                textAlign: TextAlign.center, style: context.dawaCaption),
          ],
        ),
      );
}

Future<DawaLearningState?> showDawaRewardDialog(
  BuildContext context, {
  required DawaLearningRepository repository,
  required DawaLearningState state,
}) {
  return showDialog<DawaLearningState>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DawaRewardDialog(
      repository: repository,
      initialState: state,
    ),
  );
}

class _DawaRewardDialog extends StatefulWidget {
  const _DawaRewardDialog({
    required this.repository,
    required this.initialState,
  });

  final DawaLearningRepository repository;
  final DawaLearningState initialState;

  @override
  State<_DawaRewardDialog> createState() => _DawaRewardDialogState();
}

class _DawaRewardDialogState extends State<_DawaRewardDialog> {
  bool _busy = false;
  String? _error;
  DawaRewardRedemption? _redemption;

  Future<void> _redeem() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.redeemReward(
        widget.initialState,
        cost: 1000,
      );
      if (mounted) {
        setState(() => _redemption = result);
      }
    } on DawaLearningException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        elevation: 8,
        shadowColor: const Color(0x330C2878),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DawaRadii.large),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Close reward dialog',
                    onPressed: _busy
                        ? null
                        : () => Navigator.pop(
                              context,
                              _redemption?.state,
                            ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Text(
                  _redemption == null
                      ? 'Redeem reward'
                      : _redemption!.alreadyRedeemed
                          ? 'Your voucher'
                          : 'Reward redeemed!',
                  style: context.dawaTitle,
                ),
                Text(
                  _redemption == null
                      ? 'You’re just a few healthy actions away from great care.'
                      : 'Show this code at a participating Dawa clinic.',
                  textAlign: TextAlign.center,
                  style: context.dawaCaption,
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .84, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Icon(
                    _redemption == null
                        ? Icons.redeem_rounded
                        : Icons.verified_rounded,
                    color: _redemption == null
                        ? DawaColors.primary
                        : DawaColors.green,
                    size: 78,
                  ),
                ),
                const SizedBox(height: 12),
                DawaCard(
                  color: _redemption == null
                      ? DawaColors.softBlue
                      : DawaColors.softGreen,
                  borderColor: _redemption == null
                      ? DawaColors.line
                      : DawaColors.green.withValues(alpha: .35),
                  child: _redemption == null
                      ? Row(
                          children: [
                            const DawaIconBadge(
                              icon: Icons.card_giftcard_rounded,
                              color: DawaColors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Free scan voucher',
                                      style: context.dawaSectionTitle),
                                  const Text(
                                    '1000 points',
                                    style: TextStyle(
                                      color: DawaColors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Use at a participating Dawa clinic.',
                                    style: context.dawaCaption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Semantics(
                          label:
                              'Free scan voucher code ${_redemption!.voucherCode}',
                          child: Column(
                            children: [
                              Text(
                                'FREE SCAN VOUCHER',
                                style: context.dawaCaption.copyWith(
                                  color: DawaColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectionArea(
                                child: Text(
                                  _redemption!.voucherCode,
                                  textAlign: TextAlign.center,
                                  style: context.dawaTitle.copyWith(
                                    color: DawaColors.green,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              TextButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: _redemption!.voucherCode,
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Voucher code copied'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copy code'),
                              ),
                            ],
                          ),
                        ),
                ),
                if (_redemption == null) ...[
                  const SizedBox(height: 10),
                  DawaCard(
                    child: Column(
                      children: [
                        _BalanceRow(
                          label: 'Current balance',
                          value: '${widget.initialState.coins} points',
                        ),
                        const Divider(),
                        _BalanceRow(
                          label: 'Balance after redemption',
                          value:
                              '${(widget.initialState.coins - 1000).clamp(0, 999999)} points',
                          color: DawaColors.green,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(
                    _redemption!.alreadyRedeemed
                        ? 'This is the same secure code issued for your earlier redemption.'
                        : 'Your new balance is ${_redemption!.state.coins} points. Keep this code for your clinic visit.',
                    textAlign: TextAlign.center,
                    style: context.dawaCaption,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: context.dawaCaption
                          .copyWith(color: DawaColors.danger),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_redemption != null)
                  DawaPrimaryButton(
                    label: 'Done',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context, _redemption!.state),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _busy ? null : () => Navigator.pop(context),
                          child: const Text('Maybe later'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _redeem,
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Redeem now'),
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

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.color = DawaColors.primary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: context.dawaCaption)),
          Text(
            value,
            style: context.dawaSectionTitle.copyWith(color: color),
          ),
        ],
      );
}
