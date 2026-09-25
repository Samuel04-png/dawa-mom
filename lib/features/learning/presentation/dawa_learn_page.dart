import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/content/dawa_learning_asset_registry.dart';
import '/content/dawa_visual_rotation_service.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
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
  late Future<DawaLearningAsset?> _featuredVisual;
  String _category = 'For you';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
    _featuredVisual = DawaVisualRotationService().select(
      const DawaVisualRotationRequest(
        placement: DawaAssetPlacement.featuredBanner,
        contextKey: 'learn-featured',
        cadence: DawaRotationCadence.weekly,
      ),
    );
  }

  List<DawaLearningItem> get _filtered {
    final query = _query.trim().toLowerCase();
    return DawaLearningCatalog.items.where((item) {
      final inCategory = _category == 'For you' ||
          _category == item.category ||
          (_category == 'Audio' && item.type == DawaLearningType.audio);
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
          const SizedBox(height: DawaSpacing.xs),
          Text(
            'Small lessons. Clear answers.',
            style: context.dawaTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            'Read or listen in the language you chose.',
            style: context.dawaCaption,
          ),
          const SizedBox(height: DawaSpacing.sm),
          TextField(
            key: const ValueKey('learning-search'),
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search health lessons',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: Icon(Icons.tune_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Learning categories',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: DawaSpacing.md),
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
                return const Column(
                  children: [
                    DawaLoadingSkeleton(
                      layout: DawaSkeletonLayout.thumbnail,
                      label: 'Loading lesson thumbnail',
                    ),
                    SizedBox(height: DawaSpacing.sm),
                    DawaLoadingSkeleton(
                      layout: DawaSkeletonLayout.questRow,
                      label: 'Loading your lesson progress',
                    ),
                  ],
                );
              }
              final state = snapshot.data ?? const DawaLearningState();
              return FutureBuilder<DawaLearningAsset?>(
                future: _featuredVisual,
                builder: (context, visualSnapshot) => _LearningContent(
                  state: state,
                  items: _filtered,
                  featuredMode: _category == 'For you' && _query.trim().isEmpty,
                  featuredAssetId:
                      visualSnapshot.data?.id ?? 'cervical_awareness_02',
                  onToggleSaved: (id) => _toggleSaved(state, id),
                ),
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
    required this.featuredAssetId,
    required this.onToggleSaved,
  });

  final DawaLearningState state;
  final List<DawaLearningItem> items;
  final bool featuredMode;
  final String featuredAssetId;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const DawaEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No lesson found',
        message: 'Try a shorter word or choose another topic.',
      );
    }

    if (featuredMode) {
      return _FeaturedLearningContent(
        state: state,
        featuredAssetId: featuredAssetId,
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
            onTap: () => context.push('/learn/quests'),
            semanticLabel: 'Continue the Screening Without Fear quest',
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: DawaContextualImage(
                    assetId: quest.visualAssetId,
                    variant: DawaImageVariant.cardSideImage,
                  ),
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
          title: 'Picked for you',
          subtitle: 'Clear health tips you can save for later.',
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
    required this.featuredAssetId,
    required this.onToggleSaved,
  });

  final DawaLearningState state;
  final String featuredAssetId;
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
        _FeaturedLearningCard(
          item: cervical,
          visualAssetId: featuredAssetId,
        ),
        const SizedBox(height: 12),
        DawaCard(
          onTap: () => context.push('/learn/quests'),
          semanticLabel: 'Continue the Screening Without Fear quest',
          child: Row(
            children: [
              SizedBox(
                width: 82,
                child: DawaContextualImage(
                  assetId: quest.visualAssetId,
                  variant: DawaImageVariant.cardSideImage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The Mother’s Path',
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
                    const SizedBox(height: 4),
                    Text(
                      '${(dawaQuestProgress(state) * 100).round()}% complete • Keep going',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: DawaColors.primary,
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
          completed: state.completedIds.contains(audio.id),
          saved: state.savedIds.contains(audio.id),
          onSave: () => onToggleSaved(audio.id),
          onPlay: () => context.push(audio.route),
        ),
        const SizedBox(height: 12),
        DawaCard(
          onTap: () => context.push('/learn/games'),
          semanticLabel: 'Open health games and earn reward points',
          child: Row(
            children: [
              const SizedBox(
                width: 58,
                child: DawaContextualImage(
                  assetId: 'myths_vs_fact_04',
                  variant: DawaImageVariant.compactThumbnail,
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
        DawaCard(
          onTap: () => context.push('/learn/topics'),
          semanticLabel: 'Browse all nine visual learning topics',
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.grid_view_rounded,
                color: DawaColors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore all 9 visual topics',
                        style: context.dawaSectionTitle),
                    Text(
                      'Pregnancy, periods, screening, nutrition, clinic visits and recovery.',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: DawaColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedLearningCard extends StatelessWidget {
  const _FeaturedLearningCard({
    required this.item,
    required this.visualAssetId,
  });

  final DawaLearningItem item;
  final String visualAssetId;

  @override
  Widget build(BuildContext context) => DawaContentThumbnailCard(
        thumbnail: DawaContextualImage(
          assetId: visualAssetId,
          variant: DawaImageVariant.featuredBanner,
          borderRadius: BorderRadius.zero,
          heroTag: 'learning-$visualAssetId',
        ),
        category: 'Today’s pick · ${item.category}',
        title: item.title,
        description: item.subtitle,
        durationMinutes: item.durationMinutes,
        onOpen: () => context.push(item.route),
        actionLabel: 'Read now',
        featured: true,
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
                      'Myth vs Fact',
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
  Widget build(BuildContext context) => DawaContentThumbnailCard(
        thumbnail: DawaContextualImage(
          assetId: item.visualAssetId,
          variant: DawaImageVariant.moduleThumbnail,
          borderRadius: BorderRadius.zero,
        ),
        category: item.category,
        title: item.title,
        description: item.subtitle,
        durationMinutes: item.durationMinutes,
        onOpen: onOpen,
        onSave: onSave,
        saved: saved,
      );
}

class _AudioLessonCard extends StatelessWidget {
  const _AudioLessonCard({
    required this.item,
    required this.completed,
    required this.saved,
    required this.onSave,
    required this.onPlay,
  });

  final DawaLearningItem item;
  final bool completed;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final displayCategory =
        item.id == 'pregnancy-basics' ? 'Pregnancy' : item.category;
    return SizedBox(
      width: double.infinity,
      child: DawaCard(
        padding: const EdgeInsets.all(DawaSpacing.md),
        onTap: onPlay,
        semanticLabel:
            '$displayCategory. ${item.title}. ${item.durationMinutes} minute audio lesson.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final thumbnailWidth = constraints.maxWidth < 330 ? 84.0 : 104.0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: thumbnailWidth,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DawaContextualImage(
                      assetId: item.visualAssetId,
                      variant: DawaImageVariant.moduleThumbnail,
                      borderRadius: BorderRadius.circular(DawaRadii.small),
                    ),
                  ),
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: DawaSpacing.xs,
                        runSpacing: DawaSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            displayCategory,
                            style: context.dawaCaption.copyWith(
                              color: DawaColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (completed)
                            const DawaStatusPill(
                              label: 'Completed',
                              icon: Icons.check_circle_outline_rounded,
                              color: DawaColors.green,
                            ),
                        ],
                      ),
                      const SizedBox(height: DawaSpacing.xxs),
                      Text(
                        item.title,
                        style: context.dawaSectionTitle,
                      ),
                      const SizedBox(height: DawaSpacing.xxs),
                      Text(
                        item.subtitle,
                        maxLines: 3,
                        softWrap: true,
                        style: context.dawaCaption,
                      ),
                      const SizedBox(height: DawaSpacing.xs),
                      Wrap(
                        spacing: DawaSpacing.xxs,
                        runSpacing: DawaSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.headphones_rounded,
                            size: 17,
                            color: DawaColors.muted,
                          ),
                          Text(
                            '${item.durationMinutes} min audio',
                            style: context.dawaCaption,
                          ),
                          DawaIconButton(
                            icon: saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            tooltip: saved
                                ? 'Remove from library'
                                : 'Save to library',
                            onPressed: onSave,
                          ),
                          DawaCompactButton(
                            label: completed ? 'Listen again' : 'Listen',
                            icon: Icons.play_arrow_rounded,
                            filled: true,
                            onPressed: onPlay,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
            DawaIconBadge(icon: icon, color: color, size: 40),
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
  Widget build(BuildContext context) => DawaContentThumbnailCard(
        thumbnail: DawaContextualImage(
          assetId: item.visualAssetId,
          variant: DawaImageVariant.moduleThumbnail,
          borderRadius: BorderRadius.zero,
        ),
        category: item.category,
        title: item.title,
        description: item.subtitle,
        durationMinutes: item.durationMinutes,
        onOpen: onOpen,
        actionLabel: item.type == DawaLearningType.audio
            ? 'Listen'
            : item.type == DawaLearningType.quest
                ? 'Continue'
                : 'Read now',
        onSave: onSave,
        saved: saved,
        audioAvailable: item.type == DawaLearningType.audio,
        completed: completed,
      );
}
