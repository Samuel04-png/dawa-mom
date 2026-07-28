import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/services/voice_service.dart';
import '../data/dawa_learning_repository.dart';
import '../domain/dawa_learning_content.dart';

class DawaArticlePage extends StatefulWidget {
  const DawaArticlePage({super.key, this.repository});

  static const routeName = 'LearnArticle';
  static const routePath = '/learn/article/cervical-awareness';

  final DawaLearningRepository? repository;

  @override
  State<DawaArticlePage> createState() => _DawaArticlePageState();
}

class _DawaArticlePageState extends State<DawaArticlePage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  Future<void> _toggleSaved(DawaLearningState state) async {
    final next = await _repository.toggleSaved(state, 'cervical-awareness');
    if (mounted) setState(() => _state = Future.value(next));
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Learn',
              onBack: context.pop,
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/settings'),
            ),
            const SizedBox(height: 8),
            DawaIllustratedHeroCard(
              category: 'FEATURED • CERVICAL HEALTH',
              title: 'Cervical cancer awareness',
              subtitle:
                  'Screening can find changes early. Learn what happens and when to talk to a health worker.',
              illustrationPath: DawaArtwork.cervicalAwareness,
              contextualAssetId: 'cervical_awareness_01',
              illustrationAspectRatio: .9,
              illustrationAlignment: Alignment.bottomCenter,
              primaryActionLabel: 'Find screening',
              onPrimaryAction: () => context.go('/encounters'),
              secondaryActionLabel: 'Start quest',
              onSecondaryAction: () => context.push('/learn/quests/screening'),
              semanticLabel:
                  'Cervical cancer awareness article and screening actions',
            ),
            const SizedBox(height: 10),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const DawaLearningState();
                final saved = state.savedIds.contains('cervical-awareness');
                return DawaCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const DawaStatusPill(
                        label: 'Women’s health',
                        icon: Icons.female_rounded,
                        color: DawaColors.purple,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: DawaColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text('6 min read', style: context.dawaCaption),
                        ],
                      ),
                      TextButton.icon(
                        onPressed:
                            snapshot.connectionState == ConnectionState.done
                                ? () => _toggleSaved(state)
                                : null,
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                        label: Text(saved ? 'Saved' : 'Save article'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const _ArticleSection(
              title: 'What is cervical cancer?',
              body:
                  'Cervical cancer starts in the cervix. The cervix is the lower part of the womb. Some types of HPV can cause cell changes over time.',
              icon: Icons.info_outline_rounded,
              color: DawaColors.softBlue,
              accent: DawaColors.primary,
            ),
            const _ArticleSection(
              title: 'Warning signs',
              body:
                  'Early changes in the cervix may not make you feel ill. Warning signs can include unusual bleeding, lower belly pain, pain during sex, or unusual discharge. Other things can cause these signs, but a health worker should check them.',
              icon: Icons.warning_amber_rounded,
              color: DawaColors.softPink,
              accent: DawaColors.pink,
            ),
            const _ArticleSection(
              title: 'Who should ask about screening?',
              body:
                  'When you need screening depends on your age and health. Ask a health worker which test is right for you. The HPV vaccine and screening can help prevent cervical cancer.',
              icon: Icons.groups_2_outlined,
              color: DawaColors.softPurple,
              accent: DawaColors.purple,
            ),
            const _ArticleSection(
              title: 'What happens during screening?',
              body:
                  'A trained health worker explains the test, answers your questions and takes a small sample. Many visits are short. You can ask the health worker to pause at any time.',
              icon: Icons.medical_services_outlined,
              color: DawaColors.softGreen,
              accent: DawaColors.green,
            ),
            const _ArticleSection(
              title: 'When to contact a health worker',
              body:
                  'Contact a clinic if you notice unusual bleeding, persistent pelvic pain, pain during sex or unusual discharge. Seek urgent local care for severe pain, heavy bleeding, fainting or trouble breathing.',
              icon: Icons.support_agent_rounded,
              color: DawaColors.surface,
              accent: DawaColors.primary,
            ),
            DawaCard(
              color: DawaColors.softGreen,
              borderColor: DawaColors.green.withValues(alpha: 0.3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DawaIconBadge(
                    icon: Icons.health_and_safety_outlined,
                    color: DawaColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Why it matters', style: context.dawaSectionTitle),
                        const SizedBox(height: 4),
                        Text(
                          'Cervical cancer is highly preventable when screening finds cell changes early and treatment is available.',
                          style: context.dawaBody,
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () =>
                              context.push('/learn/quests/screening'),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text('Start screening quest'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const DawaSectionHeader(title: 'Related learning'),
            const SizedBox(height: 10),
            DawaResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
              children: [
                _RelatedCard(
                  title: 'Screening Without Fear',
                  subtitle: 'Walk through each clinic step with Bana Chenjela.',
                  asset: DawaArtwork.banaWelcome,
                  onTap: () => context.push('/learn/quests/screening'),
                ),
                _RelatedCard(
                  title: 'Myth vs Fact',
                  subtitle: 'Learn to separate community advice from evidence.',
                  asset: DawaArtwork.motherLearning,
                  onTap: () => context.push('/learn/lesson/myth-vs-fact'),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ArticleSection extends StatelessWidget {
  const _ArticleSection({
    required this.title,
    required this.body,
    this.icon = Icons.eco_outlined,
    this.color = DawaColors.surface,
    this.accent = DawaColors.green,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DawaCard(
          color: color,
          borderColor: accent.withValues(alpha: 0.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DawaIconBadge(icon: icon, color: accent, size: 38),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.dawaSectionTitle),
                    const SizedBox(height: 5),
                    Text(body, style: context.dawaBody),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class DawaPregnancyGuideDetailPage extends StatefulWidget {
  const DawaPregnancyGuideDetailPage({
    super.key,
    required this.guideId,
    this.repository,
  });

  static const routeName = 'PregnancyGuideDetail';
  static const routePath = '/learn/pregnancy/:guideId';

  final String guideId;
  final DawaLearningRepository? repository;

  @override
  State<DawaPregnancyGuideDetailPage> createState() =>
      _DawaPregnancyGuideDetailPageState();
}

class _DawaPregnancyGuideDetailPageState
    extends State<DawaPregnancyGuideDetailPage> {
  late final DawaLearningRepository _repository;
  late final VoiceService _voiceService;
  late Future<DawaLearningState> _state;
  bool _speaking = false;

  bool get _isClinic => widget.guideId == 'clinic-visit';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _voiceService = VoiceService();
    _state = _repository.load();
  }

  @override
  void dispose() {
    unawaited(_voiceService.dispose());
    super.dispose();
  }

  Future<void> _toggleSaved(DawaLearningState state) async {
    final next = await _repository.toggleSaved(state, widget.guideId);
    if (mounted) setState(() => _state = Future.value(next));
  }

  Future<void> _complete(DawaLearningState state) async {
    final next = await _repository.complete(state, widget.guideId);
    if (mounted) setState(() => _state = Future.value(next));
  }

  Future<void> _listenToGuide(String title, String subtitle) async {
    if (_speaking) {
      await _voiceService.stopPlayback();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await _voiceService.speakText(
        '$title. $subtitle. '
            '${_isClinic ? 'Take your questions, medicines and health records. Tell the health worker about any new symptoms. Ask them to explain each test or medicine. Before you leave, ask what happens next.' : 'Build a balanced plate using familiar foods. Add vegetables or fruit, beans or another protein food, and a staple food. Wash food, use safe water and cook meat and eggs well.'}',
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
  Widget build(BuildContext context) {
    if (!_isClinic && widget.guideId != 'second-trimester-foods') {
      return DawaPageScaffold(
        maxWidth: 800,
        child: Column(
          children: [
            DawaAppHeader(title: 'Pregnancy guide', onBack: context.pop),
            const SizedBox(height: 28),
            const DawaCard(
              child: Text('This pregnancy guide is not available.'),
            ),
          ],
        ),
      );
    }
    final title = _isClinic
        ? 'How to prepare for your clinic visit'
        : 'Foods for your second trimester';
    final subtitle = _isClinic
        ? 'A little preparation can help you use your appointment time well.'
        : 'Build balanced meals from safe, familiar and nutrient-rich foods.';
    final asset =
        _isClinic ? DawaArtwork.clinicianDoctor : DawaArtwork.pregnancyPhone;

    return DawaPageScaffold(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaAppHeader(title: 'Pregnancy guide', onBack: context.pop),
          const SizedBox(height: 8),
          DawaIllustratedHeroCard(
            category: _isClinic ? 'CLINIC VISITS' : 'PREGNANCY NUTRITION',
            title: title,
            subtitle: subtitle,
            illustrationPath: asset,
            contextualAssetId:
                _isClinic ? 'clinic_visit_01' : 'second_trimester_foods_01',
            illustrationAspectRatio: .9,
            backgroundColor:
                _isClinic ? DawaColors.softBlue : DawaColors.softGreen,
            borderColor: (_isClinic ? DawaColors.primary : DawaColors.green)
                .withValues(alpha: 0.18),
            semanticLabel: '$title pregnancy guide',
          ),
          const SizedBox(height: 12),
          FutureBuilder<DawaLearningState>(
            future: _state,
            builder: (context, snapshot) {
              final state = snapshot.data ?? const DawaLearningState();
              final saved = state.savedIds.contains(widget.guideId);
              final completed = state.completedIds.contains(widget.guideId);
              return LayoutBuilder(
                builder: (context, constraints) {
                  final complete = FilledButton.icon(
                    onPressed:
                        snapshot.connectionState == ConnectionState.done &&
                                !completed
                            ? () => _complete(state)
                            : null,
                    icon: Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.check_rounded,
                    ),
                    label: Text(completed ? 'Completed' : 'Mark complete'),
                  );
                  final save = OutlinedButton.icon(
                    onPressed: snapshot.connectionState == ConnectionState.done
                        ? () => _toggleSaved(state)
                        : null,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                    label: Text(saved ? 'Saved' : 'Save guide'),
                  );
                  final listen = OutlinedButton.icon(
                    onPressed: () => _listenToGuide(title, subtitle),
                    icon: Icon(
                      _speaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                    ),
                    label: Text(_speaking ? 'Stop audio' : 'Listen'),
                  );
                  if (constraints.maxWidth < 540) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        complete,
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: save),
                            const SizedBox(width: 8),
                            Expanded(child: listen),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 2, child: complete),
                      const SizedBox(width: 8),
                      Expanded(child: save),
                      const SizedBox(width: 8),
                      Expanded(child: listen),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 18),
          if (_isClinic) ...[
            const _ArticleSection(
              title: 'Before you leave',
              body:
                  'Write down your questions, medicines and supplements. Bring the appointment information and any health records your clinic has asked you to carry.',
            ),
            const _ArticleSection(
              title: 'During the visit',
              body:
                  'Tell the health worker about new symptoms. Ask them to explain anything you do not understand. You can ask what each test or medicine is for.',
            ),
            const _ArticleSection(
              title: 'Before you go home',
              body:
                  'Confirm your next steps, follow-up date and where to seek help if you develop worrying symptoms.',
            ),
            DawaPrimaryButton(
              label: 'Book a clinic visit',
              icon: Icons.calendar_month_outlined,
              onPressed: () => context.go('/encounters'),
            ),
          ] else ...[
            const _ArticleSection(
              title: 'Build a balanced plate',
              body:
                  'Choose a varied mix of vegetables and fruit, beans or other protein foods, and familiar staple foods. Safe variety matters more than a single “perfect” food.',
            ),
            const _ArticleSection(
              title: 'Support healthy growth',
              body:
                  'Protein, iron, calcium and folate are important during pregnancy. Your clinic can recommend foods and supplements that fit your health needs and what is available locally.',
            ),
            const _ArticleSection(
              title: 'Keep food safe',
              body:
                  'Wash food, cook meat and eggs well, use safe water and store food safely. Ask a health worker before using herbs or changing vitamins they gave you.',
            ),
            DawaCard(
              color: DawaColors.softGreen,
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.health_and_safety_outlined,
                    color: DawaColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If nausea, vomiting or another condition makes eating difficult, contact your clinic for individual advice.',
                      style: context.dawaBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        onTap: onTap,
        semanticLabel: '$title. $subtitle',
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 82,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.dawaSectionTitle),
                  const SizedBox(height: 3),
                  Text(subtitle, style: context.dawaCaption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DawaColors.primary),
          ],
        ),
      );
}

class DawaMythFactPage extends StatefulWidget {
  const DawaMythFactPage({super.key, this.repository});

  static const routeName = 'MythFact';
  static const routePath = '/learn/lesson/myth-vs-fact';

  final DawaLearningRepository? repository;

  @override
  State<DawaMythFactPage> createState() => _DawaMythFactPageState();
}

class _DawaMythFactPageState extends State<DawaMythFactPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;
  bool? _knewThis;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  Future<void> _respond(bool knew, DawaLearningState state) async {
    final next =
        await _repository.complete(state, 'myth-vs-fact', rewardCoins: 5);
    if (!mounted) return;
    setState(() {
      _knewThis = knew;
      _state = Future.value(next);
    });
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Myth vs Fact', onBack: context.pop),
            const SizedBox(height: 10),
            DawaCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const DawaStatusPill(
                    label: 'Lesson 2 of 8',
                    icon: Icons.menu_book_outlined,
                    color: DawaColors.green,
                  ),
                  const SizedBox(height: 12),
                  const DawaProgressBar(
                    value: 0.25,
                    semanticLabel: 'Lesson progress',
                    color: DawaColors.green,
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const art = DawaContextualImage(
                        assetId: 'myths_vs_fact_01',
                        variant: DawaImageVariant.moduleThumbnail,
                      );
                      final copy = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DawaStatusPill(
                            label: 'Myth',
                            icon: Icons.close_rounded,
                            color: DawaColors.pink,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'If you eat certain slimy foods, labour will always be easier.',
                            style: context.dawaTitle.copyWith(fontSize: 23),
                          ),
                          const SizedBox(height: 16),
                          const DawaStatusPill(
                            label: 'Fact',
                            icon: Icons.check_rounded,
                            color: DawaColors.green,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No food or drink can guarantee an easier birth. Every pregnancy and labour is unique. Follow clinical advice and eat a balanced diet for a healthy pregnancy.',
                            style: context.dawaBody,
                          ),
                        ],
                      );
                      if (constraints.maxWidth < 620) {
                        return Column(
                          children: [
                            art,
                            const SizedBox(height: 18),
                            copy,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: copy),
                          const SizedBox(width: 20),
                          const SizedBox(width: 230, child: art),
                        ],
                      );
                    },
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
                      child: OutlinedButton.icon(
                        onPressed:
                            snapshot.connectionState == ConnectionState.done
                                ? () => _respond(true, state)
                                : null,
                        icon: const Icon(Icons.headphones_outlined),
                        label: const Text('I’ve heard this'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            snapshot.connectionState == ConnectionState.done
                                ? () => _respond(false, state)
                                : null,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('I didn’t know this'),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_knewThis != null) ...[
              const SizedBox(height: 12),
              DawaCard(
                color: DawaColors.softGreen,
                borderColor: DawaColors.green.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: DawaColors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _knewThis!
                            ? 'Great. This lesson is now marked complete.'
                            : 'You learned something new and earned 5 coins.',
                        style: context.dawaBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softGreen,
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.medical_information_outlined,
                    color: DawaColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Health worker tip: regular visits, safe movement, enough water and balanced meals support a safer pregnancy.',
                      style: context.dawaBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class DawaAudioLessonPage extends StatefulWidget {
  const DawaAudioLessonPage({
    super.key,
    this.voiceService,
    this.repository,
  });

  static const routeName = 'AudioLesson';
  static const routePath = '/learn/audio/pregnancy-basics';

  final VoiceService? voiceService;
  final DawaLearningRepository? repository;

  @override
  State<DawaAudioLessonPage> createState() => _DawaAudioLessonPageState();
}

class _DawaAudioLessonPageState extends State<DawaAudioLessonPage> {
  late final VoiceService _voiceService;
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;
  bool _playing = false;
  bool _showTranscript = true;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _voiceService = widget.voiceService ?? VoiceService();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playing) {
      await _voiceService.stopPlayback();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    try {
      await _voiceService.speakText(
        dawaPregnancyBasicsTranscript,
        _language,
      );
      final state = await _state;
      final next =
          await _repository.complete(state, 'pregnancy-basics', rewardCoins: 5);
      if (mounted) setState(() => _state = Future.value(next));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Audio could not play. The full transcript is available below.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(title: 'Audio lesson', onBack: context.pop),
            const SizedBox(height: 10),
            DawaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const DawaContextualImage(
                    assetId: 'pregnancy_basics_01',
                    variant: DawaImageVariant.articleHeader,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(DawaRadii.medium),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
                    decoration: const BoxDecoration(
                      color: DawaColors.softBlue,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AUDIO LESSON',
                          style: TextStyle(
                            color: DawaColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Pregnancy basics',
                          style: context.dawaDisplay.copyWith(fontSize: 27),
                        ),
                        const SizedBox(height: 6),
                        Text(_language, style: context.dawaCaption),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _playing ? null : 0,
                          minHeight: 5,
                          backgroundColor: DawaColors.line,
                          color: DawaColors.primary,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Replay from beginning',
                              onPressed: _playing
                                  ? null
                                  : () => _voiceService.stopPlayback(),
                              icon: const Icon(Icons.replay_rounded),
                            ),
                            const SizedBox(width: 16),
                            Semantics(
                              button: true,
                              label: _playing ? 'Pause lesson' : 'Play lesson',
                              child: FilledButton(
                                onPressed: _togglePlayback,
                                style: FilledButton.styleFrom(
                                  shape: const CircleBorder(),
                                  minimumSize: const Size(62, 62),
                                ),
                                child: Icon(
                                  _playing
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const DawaSectionHeader(title: 'Listen in your language'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final language in ['English', 'Nyanja', 'Bemba', 'Tonga'])
                  ChoiceChip(
                    avatar: const Icon(Icons.headphones_rounded, size: 16),
                    label: Text(language),
                    selected: _language == language,
                    onSelected: _playing
                        ? null
                        : (_) => setState(() => _language = language),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DawaCard(
              child: Column(
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _showTranscript = !_showTranscript),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const DawaIconBadge(
                            icon: Icons.article_outlined,
                            color: DawaColors.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Transcript',
                              style: context.dawaSectionTitle,
                            ),
                          ),
                          Icon(_showTranscript
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  ),
                  if (_showTranscript) ...[
                    const Divider(),
                    Text(
                      dawaPregnancyBasicsTranscript.trim(),
                      style: context.dawaBody,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            DawaCard(
              color: DawaColors.softGreen,
              child: Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.download_for_offline_outlined,
                    color: DawaColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transcript available offline',
                            style: context.dawaSectionTitle),
                        Text(
                          'Audio uses the secure voice service or your device voice.',
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class DawaPregnancyGuidesPage extends StatefulWidget {
  const DawaPregnancyGuidesPage({
    super.key,
    this.profileRepository,
    this.learningRepository,
  });

  static const routeName = 'PregnancyGuides';
  static const routePath = '/learn/pregnancy';

  final HealthProfileRepository? profileRepository;
  final DawaLearningRepository? learningRepository;

  @override
  State<DawaPregnancyGuidesPage> createState() =>
      _DawaPregnancyGuidesPageState();
}

class _DawaPregnancyGuidesPageState extends State<DawaPregnancyGuidesPage> {
  late final HealthProfileRepository _profileRepository;
  late final DawaLearningRepository _learningRepository;
  late Future<HealthProfileSnapshot> _profile;
  late Future<DawaLearningState> _state;
  String _filter = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? HealthProfileRepository();
    _learningRepository = widget.learningRepository ?? DawaLearningRepository();
    _profile = _profileRepository.load();
    _state = _learningRepository.load();
  }

  @override
  Widget build(BuildContext context) {
    final guides = DawaLearningCatalog.items.where((item) {
      final query = _query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
      final matchesFilter = _filter == 'All' ||
          item.category == _filter ||
          (_filter == 'Clinic visits' && item.id == 'clinic-visit') ||
          (_filter == 'Warning signs' && item.id == 'cervical-awareness');
      return matchesQuery && matchesFilter;
    }).toList();

    return DawaPageScaffold(
      maxWidth: 950,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaAppHeader(title: 'Pregnancy guides', onBack: context.pop),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search pregnancy guides...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in [
                  'All',
                  'Pregnancy basics',
                  'Nutrition',
                  'Clinic visits',
                  'Antenatal',
                  'Postpartum',
                  'Warning signs'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<HealthProfileSnapshot>(
            future: _profile,
            builder: (context, snapshot) {
              final week = snapshot.data?.pregnancyWeek;
              return DawaCard(
                color: DawaColors.softGreen,
                child: Row(
                  children: [
                    const DawaIconBadge(
                      icon: Icons.menu_book_rounded,
                      color: DawaColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            week == null
                                ? 'Pregnancy tips for every stage'
                                : 'Guidance for pregnancy week $week',
                            style: context.dawaSectionTitle,
                          ),
                          const SizedBox(height: 7),
                          FutureBuilder<DawaLearningState>(
                            future: _state,
                            builder: (context, learningSnapshot) {
                              final completed =
                                  learningSnapshot.data?.completedIds
                                          .where(
                                            (id) => DawaLearningCatalog.items
                                                .any((item) => item.id == id),
                                          )
                                          .length ??
                                      0;
                              return DawaProgressBar(
                                value: completed /
                                    DawaLearningCatalog.items.length,
                                semanticLabel:
                                    '$completed of ${DawaLearningCatalog.items.length} guides completed',
                                color: DawaColors.green,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          FutureBuilder<DawaLearningState>(
            future: _state,
            builder: (context, snapshot) {
              final state = snapshot.data ?? const DawaLearningState();
              return DawaResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 2,
                children: [
                  for (final guide in guides)
                    DawaCard(
                      onTap: () => context.push(guide.route),
                      semanticLabel: '${guide.title}, ${guide.subtitle}',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 92,
                            child: DawaContextualImage(
                              assetId: guide.visualAssetId,
                              variant: DawaImageVariant.cardSideImage,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guide.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: DawaColors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  guide.title,
                                  style: context.dawaSectionTitle,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  guide.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.dawaCaption,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      state.savedIds.contains(guide.id)
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      size: 16,
                                      color: DawaColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${guide.durationMinutes} min',
                                      style: context.dawaCaption,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DawaCard(
            color: DawaColors.softGreen,
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 76,
                  child: Image.asset(
                    DawaArtwork.motherGreeting,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need personal help? Ask Rudo',
                          style: context.dawaSectionTitle),
                      Text(
                        'Ask Rudo for general health help.',
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => DawaMomResponsiveShell.openRudo(context),
                  child: const Text('Chat now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
