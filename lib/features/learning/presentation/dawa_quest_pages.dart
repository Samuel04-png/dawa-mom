import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/services/voice_service.dart';
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
              'Stories, lessons and small steps for your health.',
              style: context.dawaCaption,
            ),
            const SizedBox(height: 12),
            const DawaIllustratedHeroCard(
              category: 'Your guide and friend',
              title: 'Bana Chenjela is here to guide you',
              subtitle:
                  'Learn in small steps, build confidence and earn Dawa points for completed healthy actions.',
              illustrationPath: DawaArtwork.banaWelcome,
              contextualAssetId: 'screening_without_fear_01',
              illustrationAspectRatio: .9,
              backgroundColor: DawaColors.softBlue,
              semanticLabel:
                  'Bana Chenjela welcomes you to Mother’s Path quests',
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
                              'The Mother’s Path',
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
                              'Learn how screening can find cell changes early and what to expect at a clinic.',
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
                  action: 'Keep going',
                  onTap: () => context.push('/learn/quests/screening'),
                ),
                _QuestActionCard(
                  icon: Icons.groups_outlined,
                  title: 'Women’s cohort',
                  description:
                      'Learn with other women who are caring for their health.',
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
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onTap,
              child: Text(action),
            ),
          ],
        ),
      );
}

class DawaQuestModulePage extends StatefulWidget {
  const DawaQuestModulePage({super.key});

  static const routeName = 'QuestModule';
  static const routePath = '/learn/quests/screening';

  @override
  State<DawaQuestModulePage> createState() => _DawaQuestModulePageState();
}

class _DawaQuestModulePageState extends State<DawaQuestModulePage> {
  late final VoiceService _voiceService;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
  }

  @override
  void dispose() {
    unawaited(_voiceService.dispose());
    super.dispose();
  }

  Future<void> _toggleGuideAudio() async {
    if (_speaking) {
      await _voiceService.stopPlayback();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await _voiceService.speakText(
        'Let us walk through cervical screening together. '
            'I will explain why screening matters, what a clinic visit may involve, '
            'and how to ask questions about your care.',
        'English',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio is not available on this device right now.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Screening Without Fear', onBack: context.pop),
            const SizedBox(height: 10),
            DawaCard(
              color: DawaColors.softGreen,
              borderColor: DawaColors.green.withValues(alpha: .22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 3 of 4',
                          style: context.dawaSectionTitle,
                        ),
                      ),
                      const DawaStatusPill(
                        label: '+20 points',
                        icon: Icons.toll_rounded,
                        color: DawaColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const DawaProgressBar(
                    value: .6,
                    semanticLabel: 'Screening quest 60 percent complete',
                    color: DawaColors.green,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '60% complete • Screening Champion badge in progress',
                    style: context.dawaCaption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DawaIllustratedHeroCard(
              category: 'Bana Chenjela, your guide',
              title: 'Let’s walk through screening together',
              subtitle:
                  'I’ll show you what a clinic visit may involve, step by step.',
              illustrationPath: DawaArtwork.banaWelcome,
              contextualAssetId: 'screening_without_fear_02',
              illustrationAspectRatio: .9,
              primaryActionLabel: _speaking ? 'Stop audio' : 'Listen to guide',
              onPrimaryAction: _toggleGuideAudio,
              backgroundColor: DawaColors.softBlue,
              semanticLabel: 'Bana Chenjela screening guide',
            ),
            const SizedBox(height: 12),
            const _QuestStep(
              number: 1,
              icon: Icons.help_outline_rounded,
              title: 'What is screening?',
              subtitle: 'Learn why screening is important.',
              state: 'Completed',
            ),
            const _QuestStep(
              number: 2,
              icon: Icons.health_and_safety_outlined,
              title: 'Will it hurt?',
              subtitle: 'Find out what to expect.',
              state: 'Completed',
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
        child: DawaModuleRow(
          stepNumber: number,
          icon: icon,
          title: title,
          description: subtitle,
          status: state,
          onTap: onTap,
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
                          'It checks for changes in the cervix. This means care can start early.',
                          style: context.dawaBody,
                        ),
                      ],
                    ),
                  );
                  const image = DawaContextualImage(
                    assetId: 'screening_without_fear_03',
                    variant: DawaImageVariant.moduleThumbnail,
                    borderRadius: BorderRadius.zero,
                    semanticLabel:
                        'A health worker and patient review screening preparation.',
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(children: [copy, image]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      'A trained health worker does the test in a few minutes.',
                ),
                _ClinicStep(
                  number: 3,
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Get your next steps',
                  description:
                      'The health worker explains the results and what happens next.',
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
                      'Screening is usually quick. Ask the health worker to explain each step. Tell them if you feel uncomfortable.',
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
                    'The Mother’s Path',
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
                        const SizedBox(
                          width: 85,
                          child: DawaContextualImage(
                            assetId: 'screening_without_fear_04',
                            variant: DawaImageVariant.cardSideImage,
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
                            'Who needs screening and when can differ. Follow advice from a trained health worker at your clinic.',
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
            const DawaIllustratedHeroCard(
              category: 'The Mother’s Path, complete',
              title: 'You completed Screening Without Fear',
              subtitle:
                  'You now know what screening is, what happens at the clinic, and why finding cell changes early matters.',
              illustrationPath: DawaArtwork.banaCelebrate,
              contextualAssetId: 'screening_without_fear_05',
              illustrationAspectRatio: .9,
              progress: 1,
              progressLabel: 'Journey step complete',
              backgroundColor: DawaColors.softGreen,
              borderColor: Color(0x4D42BE53),
              semanticLabel:
                  'Screening Without Fear completed. Mother’s Path step complete.',
            ),
            const SizedBox(height: 12),
            const DawaSectionHeader(
              title: 'Your achievements',
              subtitle: 'Your progress is saved in DawaMom',
            ),
            const SizedBox(height: 8),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) => DawaResponsiveGrid(
                mobileColumns: 3,
                tabletColumns: 3,
                desktopColumns: 3,
                spacing: 8,
                children: [
                  _AchievementCard(
                    icon: Icons.monetization_on_rounded,
                    color: DawaColors.gold,
                    title: '+20 points',
                    subtitle: _wasAlreadyComplete
                        ? 'Already collected • ${snapshot.data?.coins ?? '…'} total'
                        : '${snapshot.data?.coins ?? '…'} total',
                  ),
                  const _AchievementCard(
                    icon: Icons.workspace_premium_rounded,
                    color: DawaColors.green,
                    title: 'Screening Champion',
                    subtitle: 'Badge advanced',
                  ),
                  const _AchievementCard(
                    icon: Icons.auto_stories_rounded,
                    color: DawaColors.purple,
                    title: 'Story unlocked',
                    subtitle: 'At the Clinic',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softBlue,
              borderColor: DawaColors.primary.withValues(alpha: .16),
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.lightbulb_outline_rounded,
                    color: DawaColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What you learned',
                            style: context.dawaSectionTitle),
                        const SizedBox(height: 3),
                        Text(
                          'Screening can find cell changes before you feel ill. A health worker should explain each step and your results.',
                          style: context.dawaBody,
                        ),
                      ],
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
                  action: 'Keep going',
                  onTap: () => context.go('/learn'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softPurple,
              borderColor: DawaColors.purple.withValues(alpha: .2),
              child: Row(
                children: [
                  const SizedBox(
                    width: 72,
                    child: DawaContextualImage(
                      assetId: 'screening_without_fear_05',
                      variant: DawaImageVariant.cardSideImage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community momentum',
                            style: context.dawaSectionTitle),
                        const SizedBox(height: 3),
                        Text(
                          'You’re part of a growing community choosing informed, preventive care.',
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softGreen,
              borderColor: DawaColors.green.withValues(alpha: .2),
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.toll_rounded,
                    color: DawaColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Keep earning Dawa points through learning, tracking and health games.',
                      style: context.dawaBody,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/learn/rewards'),
                    child: const Text('How it works'),
                  ),
                ],
              ),
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
        color: color.withValues(alpha: .08),
        borderColor: color.withValues(alpha: .2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.dawaCaption.copyWith(
                color: DawaColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.dawaCaption.copyWith(fontSize: 9.5),
            ),
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
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: SingleChildScrollView(
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
                    child: _redemption == null
                        ? SizedBox(
                            width: 118,
                            height: 102,
                            child: Image.asset(
                              DawaArtwork.motherReward,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          )
                        : const Icon(
                            Icons.verified_rounded,
                            color: DawaColors.green,
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Voucher code copied'),
                                        ),
                                      );
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.copy_rounded, size: 18),
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
                  const SizedBox(height: 10),
                  DawaCard(
                    color: DawaColors.softGreen,
                    borderColor: DawaColors.green.withValues(alpha: .22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: DawaColors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _redemption == null
                                ? 'A secure voucher code is generated after confirmation and can be used at participating Dawa clinics.'
                                : 'Keep your voucher code private and show it to the participating clinic when arranging eligible care.',
                            style: context.dawaCaption.copyWith(
                              color: DawaColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: DawaColors.green,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Redemption is subject to participating-clinic and clinical eligibility terms.',
                          style: context.dawaCaption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_redemption != null)
                    DawaPrimaryButton(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      onPressed: () =>
                          Navigator.pop(context, _redemption!.state),
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
