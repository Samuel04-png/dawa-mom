import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/design_system/dawa_components.dart';
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
            DawaCard(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: DawaBreakpoints.isMobile(context) ? 250 : 300,
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
                      right: 18,
                      bottom: 0,
                      width: DawaBreakpoints.isMobile(context) ? 150 : 210,
                      height: 240,
                      child: Image.asset(
                        DawaArtwork.cervicalAwareness,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DawaStatusPill(
                              label: 'FEATURED',
                              icon: Icons.auto_awesome_outlined,
                              color: DawaColors.purple,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Cervical cancer\nawareness',
                              style: context.dawaDisplay.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Early screening can save lives. Learn the facts and protect your future.',
                              style: context.dawaBody,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const DawaLearningState();
                final saved = state.savedIds.contains('cervical-awareness');
                return DawaCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const DawaStatusPill(
                        label: 'Women’s health',
                        icon: Icons.female_rounded,
                        color: DawaColors.purple,
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_rounded,
                          size: 16, color: DawaColors.muted),
                      const SizedBox(width: 5),
                      Text('6 min read', style: context.dawaCaption),
                      const Spacer(),
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
                  'Cervical cancer starts in the cells of the cervix — the lower part of the womb that connects to the vagina. Persistent infection with certain high-risk types of human papillomavirus (HPV) can cause cell changes over time.',
            ),
            const _ArticleSection(
              title: 'Warning signs',
              body:
                  'Early cervical changes may not cause symptoms. Later warning signs can include unusual bleeding, pelvic pain, pain during sex, or unusual discharge. These symptoms can have other causes, but they should be checked by a clinician.',
            ),
            const _ArticleSection(
              title: 'When to get screened',
              body:
                  'Screening schedules differ by age, health history and local guidance. Ask a qualified clinician which screening test and interval are right for you. Screening and HPV vaccination are important prevention tools.',
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
  const _ArticleSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child:
                  Icon(Icons.eco_outlined, color: DawaColors.green, size: 18),
            ),
            const SizedBox(width: 9),
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
  late Future<DawaLearningState> _state;

  bool get _isClinic => widget.guideId == 'clinic-visit';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  Future<void> _toggleSaved(DawaLearningState state) async {
    final next = await _repository.toggleSaved(state, widget.guideId);
    if (mounted) setState(() => _state = Future.value(next));
  }

  Future<void> _complete(DawaLearningState state) async {
    final next = await _repository.complete(state, widget.guideId);
    if (mounted) setState(() => _state = Future.value(next));
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
          DawaCard(
            color: _isClinic ? DawaColors.softBlue : DawaColors.softGreen,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaStatusPill(
                      label: _isClinic ? 'Clinic visits' : 'Nutrition',
                      icon: _isClinic
                          ? Icons.medical_services_outlined
                          : Icons.restaurant_outlined,
                      color: _isClinic ? DawaColors.primary : DawaColors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: context.dawaDisplay.copyWith(fontSize: 27),
                    ),
                    const SizedBox(height: 7),
                    Text(subtitle, style: context.dawaBody),
                  ],
                );
                final art = SizedBox(
                  width: 170,
                  height: 205,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                );
                if (constraints.maxWidth < 560) {
                  return Column(children: [art, copy]);
                }
                return Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 16),
                    art,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<DawaLearningState>(
            future: _state,
            builder: (context, snapshot) {
              final state = snapshot.data ?? const DawaLearningState();
              final saved = state.savedIds.contains(widget.guideId);
              final completed = state.completedIds.contains(widget.guideId);
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          snapshot.connectionState == ConnectionState.done
                              ? () => _toggleSaved(state)
                              : null,
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                      label: Text(saved ? 'Saved' : 'Save guide'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
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
                    ),
                  ),
                ],
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
                  'Share new symptoms honestly and ask the clinician to explain anything you do not understand. You can ask what each test or medicine is for.',
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
                  'Wash produce, cook animal foods thoroughly, use safe water and store food safely. Ask a clinician before using herbal products or changing prescribed supplements.',
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
                      final art = SizedBox(
                        width: 170,
                        height: 210,
                        child: Image.asset(
                          DawaArtwork.cycleCramps,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
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
                        return Column(children: [art, copy]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: copy),
                          const SizedBox(width: 20),
                          art,
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
                      'Clinician tip: regular check-ups, safe movement, hydration and balanced nutrition support a safer pregnancy.',
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
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: DawaColors.softBlue,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                style:
                                    context.dawaDisplay.copyWith(fontSize: 27),
                              ),
                              const SizedBox(height: 6),
                              Text(_language, style: context.dawaCaption),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Image.asset(
                            DawaArtwork.pregnancyPhone,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
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
            decoration: const InputDecoration(
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
                  'Pregnancy',
                  'Nutrition',
                  'Clinic visits',
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
                                ? 'Pregnancy guidance for every stage'
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
                            height: 104,
                            child: Image.asset(
                              guide.asset,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
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
                        'Chat with the digital health assistant for general guidance.',
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
