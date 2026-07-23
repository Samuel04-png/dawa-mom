import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '../data/dawa_learning_repository.dart';
import '../domain/dawa_learning_content.dart';

class DawaLearnPage extends StatefulWidget {
  const DawaLearnPage({
    super.key,
    this.repository,
  });

  static const routeName = 'Learn';
  static const routePath = '/learn';

  final DawaLearningRepository? repository;

  @override
  State<DawaLearnPage> createState() => _DawaLearnPageState();
}

class _DawaLearnPageState extends State<DawaLearnPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;
  String _category = 'For you';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  List<DawaLearningItem> get _filtered {
    final query = _query.trim().toLowerCase();
    return DawaLearningCatalog.items.where((item) {
      final inCategory = _category == 'For you' ||
          _category == item.category ||
          (_category == 'Pregnancy' && item.category == 'Nutrition');
      final inQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
      return inCategory && inQuery;
    }).toList();
  }

  Future<void> _toggleSaved(DawaLearningState state, String id) async {
    final next = await _repository.toggleSaved(state, id);
    if (mounted) setState(() => _state = Future.value(next));
  }

  @override
  Widget build(BuildContext context) {
    return DawaPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaAppHeader(
            title: 'Learn',
            notificationUnread: true,
            onNotifications: () => context.push('/notifications'),
            onProfile: () => context.go('/settings'),
          ),
          const SizedBox(height: 5),
          TextField(
            key: const ValueKey('learning-search'),
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search articles, topics or guides...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Learning categories',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in DawaLearningCatalog.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: category == _category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<DawaLearningState>(
            future: _state,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final state = snapshot.data ?? const DawaLearningState();
              return _LearningContent(
                state: state,
                items: _filtered,
                featuredMode: _category == 'For you' && _query.trim().isEmpty,
                onToggleSaved: (id) => _toggleSaved(state, id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LearningContent extends StatelessWidget {
  const _LearningContent({
    required this.state,
    required this.items,
    required this.featuredMode,
    required this.onToggleSaved,
  });

  final DawaLearningState state;
  final List<DawaLearningItem> items;
  final bool featuredMode;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const DawaCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              'No lessons match this search yet.',
              style: TextStyle(color: DawaColors.muted),
            ),
          ),
        ),
      );
    }

    if (featuredMode) {
      return _FeaturedLearningContent(
        state: state,
        onToggleSaved: onToggleSaved,
      );
    }

    final quest = DawaLearningCatalog.byId('screening-without-fear');
    final regular = items.where((item) => item.id != quest.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.contains(quest)) ...[
          DawaCard(
            color: DawaColors.softGreen,
            borderColor: DawaColors.green.withValues(alpha: 0.25),
            onTap: () => context.push('/learn/quests'),
            semanticLabel: 'Continue the Screening Without Fear quest',
            child: Row(
              children: [
                DawaIconBadge(
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
                      Text(quest.title, style: context.dawaSectionTitle),
                      const SizedBox(height: 7),
                      DawaProgressBar(
                        value: dawaQuestProgress(state),
                        semanticLabel: 'Quest progress',
                        color: DawaColors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded,
                    color: DawaColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF0843E),
                value: '${state.streak} day streak',
                label: 'Today’s check-in',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.monetization_on_rounded,
                color: DawaColors.gold,
                value: '${state.coins} coins',
                label: 'My rewards',
                onTap: () => context.push('/learn/rewards'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const DawaSectionHeader(
          title: 'Recommended for you',
          subtitle: 'Clinically careful guidance you can save for later',
        ),
        const SizedBox(height: 10),
        DawaResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          children: [
            for (final item in regular)
              _LearningItemCard(
                item: item,
                saved: state.savedIds.contains(item.id),
                completed: state.completedIds.contains(item.id),
                onSave: () => onToggleSaved(item.id),
                onOpen: () => context.push(item.route),
              ),
          ],
        ),
        const SizedBox(height: 14),
        DawaCard(
          color: DawaColors.softGreen,
          borderColor: DawaColors.green.withValues(alpha: 0.25),
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.monetization_on_outlined,
                color: DawaColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earn coins from healthy actions',
                        style: context.dawaSectionTitle),
                    Text(
                      'Check in • Learn • Track • Share',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/learn/rewards'),
                child: const Text('How it works'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedLearningContent extends StatelessWidget {
  const _FeaturedLearningContent({
    required this.state,
    required this.onToggleSaved,
  });

  final DawaLearningState state;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final cervical = DawaLearningCatalog.byId('cervical-awareness');
    final myth = DawaLearningCatalog.byId('myth-vs-fact');
    final nutrition = DawaLearningCatalog.byId('second-trimester-foods');
    final clinic = DawaLearningCatalog.byId('clinic-visit');
    final audio = DawaLearningCatalog.byId('pregnancy-basics');
    final quest = DawaLearningCatalog.byId('screening-without-fear');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeaturedLearningCard(item: cervical),
        const SizedBox(height: 12),
        _MythFactBanner(
          item: myth,
          onOpen: () => context.push(myth.route),
        ),
        const SizedBox(height: 12),
        DawaResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 2,
          desktopColumns: 2,
          spacing: 10,
          children: [
            _CompactLearningTile(
              item: nutrition,
              saved: state.savedIds.contains(nutrition.id),
              onSave: () => onToggleSaved(nutrition.id),
              onOpen: () => context.push(nutrition.route),
            ),
            _CompactLearningTile(
              item: clinic,
              saved: state.savedIds.contains(clinic.id),
              onSave: () => onToggleSaved(clinic.id),
              onOpen: () => context.push(clinic.route),
            ),
          ],
        ),
        const SizedBox(height: 17),
        DawaSectionHeader(
          title: 'Audio lessons in your language',
          actionLabel: 'View all',
          onAction: () => context.push(audio.route),
        ),
        const SizedBox(height: 9),
        _AudioLessonCard(
          item: audio,
          onPlay: () => context.push(audio.route),
        ),
        const SizedBox(height: 16),
        DawaCard(
          color: DawaColors.softGreen,
          borderColor: DawaColors.green.withValues(alpha: 0.25),
          onTap: () => context.push('/learn/quests'),
          semanticLabel: 'Continue the Screening Without Fear quest',
          child: Row(
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
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(quest.title, style: context.dawaSectionTitle),
                    const SizedBox(height: 7),
                    DawaProgressBar(
                      value: dawaQuestProgress(state),
                      semanticLabel: 'Quest progress',
                      color: DawaColors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: DawaColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DawaCard(
          color: DawaColors.softPurple,
          borderColor: DawaColors.purple.withValues(alpha: .25),
          onTap: () => context.push('/learn/games'),
          semanticLabel: 'Open health games and earn reward points',
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 78,
                child: Image.asset(
                  DawaArtwork.banaCelebrate,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Play health games', style: context.dawaSectionTitle),
                    Text(
                      'Test your knowledge • Earn 10 points',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              const DawaStatusPill(
                label: 'Play',
                icon: Icons.sports_esports_rounded,
                color: DawaColors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF0843E),
                value: '${state.streak} day streak',
                label: 'Today’s check-in',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.monetization_on_rounded,
                color: DawaColors.gold,
                value: '${state.coins} coins',
                label: 'My rewards',
                onTap: () => context.push('/learn/rewards'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedLearningCard extends StatelessWidget {
  const _FeaturedLearningCard({required this.item});

  final DawaLearningItem item;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: DawaCard(
          padding: EdgeInsets.zero,
          color: DawaColors.softBlue,
          borderColor: DawaColors.primary.withValues(alpha: .12),
          child: SizedBox(
            height: DawaBreakpoints.isMobile(context) ? 248 : 264,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned(
                    right: -4,
                    bottom: 0,
                    width: constraints.maxWidth * .52,
                    height: constraints.maxHeight * .94,
                    child: Image.asset(
                      item.asset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned(
                    left: 17,
                    top: 18,
                    bottom: 16,
                    width: constraints.maxWidth * .57,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: DawaColors.primary,
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.title,
                          maxLines: 3,
                          style: context.dawaTitle.copyWith(
                            color: DawaColors.primary,
                            fontSize: 23,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.dawaBody,
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => context.push(item.route),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                          label: const Text('Read now'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(118, 43),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MythFactBanner extends StatelessWidget {
  const _MythFactBanner({
    required this.item,
    required this.onOpen,
  });

  final DawaLearningItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: DawaCard(
          color: DawaColors.softGreen,
          borderColor: DawaColors.green.withValues(alpha: .22),
          padding: const EdgeInsets.fromLTRB(12, 12, 9, 12),
          onTap: onOpen,
          semanticLabel: 'Open ${item.title}',
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.verified_user_outlined,
                color: DawaColors.green,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MYTH VS FACT',
                      style: TextStyle(
                        color: DawaColors.green,
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: 'Myth: ',
                        style: context.dawaBody.copyWith(
                          color: DawaColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Eating for two is best for your baby.',
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fact: Quality matters more than quantity.',
                      maxLines: 2,
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DawaColors.green,
              ),
            ],
          ),
        ),
      );
}

class _CompactLearningTile extends StatelessWidget {
  const _CompactLearningTile({
    required this.item,
    required this.saved,
    required this.onSave,
    required this.onOpen,
  });

  final DawaLearningItem item;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: EdgeInsets.zero,
        onTap: onOpen,
        semanticLabel: 'Open ${item.title}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 112,
              decoration: const BoxDecoration(
                color: DawaColors.softBlue,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DawaRadii.medium),
                ),
              ),
              child: Image.asset(
                item.asset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                excludeFromSemantics: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      color: DawaColors.green,
                      fontFamily: 'Poppins',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaSectionTitle.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: DawaColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.durationMinutes} min read',
                          style: context.dawaCaption.copyWith(fontSize: 9),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            saved ? 'Remove from library' : 'Save to library',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onSave,
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: DawaColors.primary,
                          size: 19,
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

class _AudioLessonCard extends StatelessWidget {
  const _AudioLessonCard({
    required this.item,
    required this.onPlay,
  });

  final DawaLearningItem item;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: DawaCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          onTap: onPlay,
          semanticLabel: 'Play ${item.title}',
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.headphones_rounded,
                color: DawaColors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.dawaSectionTitle),
                    Text(
                      '${item.durationMinutes} min • audio lesson',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Play',
                onPressed: onPlay,
                style: IconButton.styleFrom(
                  backgroundColor: DawaColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        semanticLabel: '$label, $value',
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.dawaCaption),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaSectionTitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LearningItemCard extends StatelessWidget {
  const _LearningItemCard({
    required this.item,
    required this.saved,
    required this.completed,
    required this.onSave,
    required this.onOpen,
  });

  final DawaLearningItem item;
  final bool saved;
  final bool completed;
  final VoidCallback onSave;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 126,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: DawaColors.softBlue,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DawaRadii.medium),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    bottom: 0,
                    top: 5,
                    width: 116,
                    child: Image.asset(
                      item.asset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: DawaStatusPill(
                      label: item.category,
                      icon: item.icon,
                      color: item.category == 'Nutrition'
                          ? DawaColors.green
                          : DawaColors.purple,
                    ),
                  ),
                  if (completed)
                    const Positioned(
                      left: 14,
                      bottom: 12,
                      child: DawaStatusPill(
                        label: 'Completed',
                        icon: Icons.check_circle_outline,
                        color: DawaColors.green,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.dawaSectionTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: saved ? 'Remove from library' : 'Save to library',
                    onPressed: onSave,
                    icon: Icon(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_border,
                      color: DawaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
              child: Row(
                children: [
                  Icon(
                    item.type == DawaLearningType.audio
                        ? Icons.headphones_rounded
                        : Icons.schedule_rounded,
                    size: 15,
                    color: DawaColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.durationMinutes} min ${item.type == DawaLearningType.audio ? 'listen' : 'read'}',
                    style: context.dawaCaption,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onOpen,
                    child: Text(
                      item.type == DawaLearningType.audio
                          ? 'Listen'
                          : item.type == DawaLearningType.quest
                              ? 'Continue'
                              : 'Read now',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
