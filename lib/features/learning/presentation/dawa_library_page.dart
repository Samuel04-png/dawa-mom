import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '../data/dawa_learning_repository.dart';
import '../domain/dawa_learning_content.dart';

class DawaLibraryPage extends StatefulWidget {
  const DawaLibraryPage({super.key, this.repository});

  static const routeName = 'LearningLibrary';
  static const routePath = '/learn/library';

  final DawaLearningRepository? repository;

  @override
  State<DawaLibraryPage> createState() => _DawaLibraryPageState();
}

class _DawaLibraryPageState extends State<DawaLibraryPage> {
  late final DawaLearningRepository _repository;
  late Future<DawaLearningState> _state;
  String _section = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _state = _repository.load();
  }

  Future<void> _toggleSaved(
    DawaLearningState state,
    DawaLearningItem item,
  ) async {
    final next = await _repository.toggleSaved(state, item.id);
    if (mounted) setState(() => _state = Future.value(next));
  }

  Future<void> _toggleOffline(
    DawaLearningState state,
    DawaLearningItem item,
  ) async {
    final next = await _repository.toggleOffline(state, item.id);
    if (mounted) setState(() => _state = Future.value(next));
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'My library',
              onBack: context.pop,
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/settings'),
            ),
            const SizedBox(height: 10),
            Semantics(
              label: 'Library sections',
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'All',
                      icon: Icon(Icons.apps_rounded),
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: 'Saved',
                      icon: Icon(Icons.bookmark_border_rounded),
                      label: Text('Saved'),
                    ),
                    ButtonSegment(
                      value: 'Audio',
                      icon: Icon(Icons.headphones_rounded),
                      label: Text('Audio'),
                    ),
                    ButtonSegment(
                      value: 'Offline',
                      icon: Icon(Icons.download_done_rounded),
                      label: Text('Offline'),
                    ),
                  ],
                  selected: {_section},
                  onSelectionChanged: (value) =>
                      setState(() => _section = value.first),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search your saved content...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<DawaLearningState>(
              future: _state,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Column(
                    children: [
                      DawaLoadingSkeleton(lines: 2),
                      SizedBox(height: DawaSpacing.sm),
                      DawaLoadingSkeleton(lines: 3),
                    ],
                  );
                }
                final state = snapshot.data ?? const DawaLearningState();
                final items = DawaLearningCatalog.items.where((item) {
                  final query = _query.toLowerCase();
                  final queryMatch = query.isEmpty ||
                      item.title.toLowerCase().contains(query) ||
                      item.subtitle.toLowerCase().contains(query);
                  final sectionMatch = switch (_section) {
                    'Saved' => state.savedIds.contains(item.id),
                    'Audio' => item.type == DawaLearningType.audio,
                    'Offline' => state.offlineIds.contains(item.id),
                    _ => state.savedIds.contains(item.id) ||
                        item.type == DawaLearningType.audio,
                  };
                  return queryMatch && sectionMatch;
                }).toList();

                if (items.isEmpty) {
                  return DawaCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Column(
                        children: [
                          const DawaIconBadge(
                            icon: Icons.bookmarks_outlined,
                            size: 58,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _query.isEmpty
                                ? 'Nothing in this section yet'
                                : 'No library items match your search',
                            style: context.dawaSectionTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save a lesson from Learn to find it here.',
                            style: context.dawaCaption,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => context.go('/learn'),
                            child: const Text('Browse lessons'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaSectionHeader(
                      title: _section == 'Audio'
                          ? 'Downloaded audio'
                          : 'Saved learning',
                      subtitle: '${items.length} items',
                    ),
                    const SizedBox(height: 9),
                    DawaResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 2,
                      children: [
                        for (final item in items)
                          _LibraryItemCard(
                            item: item,
                            saved: state.savedIds.contains(item.id),
                            offline: state.offlineIds.contains(item.id),
                            onOpen: () => context.push(item.route),
                            onToggleSaved: () => _toggleSaved(state, item),
                            onToggleOffline: () => _toggleOffline(state, item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DawaCard(
                      color: DawaColors.softGreen,
                      borderColor: DawaColors.green.withValues(alpha: 0.25),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            height: 82,
                            child: Image.asset(
                              DawaArtwork.motherGreeting,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Need more learning help?',
                                    style: context.dawaSectionTitle),
                                Text(
                                  'Ask Rudo for help finding the right health page.',
                                  style: context.dawaCaption,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                DawaMomResponsiveShell.openRudo(context),
                            child: const Text('Ask Rudo'),
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

class _LibraryItemCard extends StatelessWidget {
  const _LibraryItemCard({
    required this.item,
    required this.saved,
    required this.offline,
    required this.onOpen,
    required this.onToggleSaved,
    required this.onToggleOffline,
  });

  final DawaLearningItem item;
  final bool saved;
  final bool offline;
  final VoidCallback onOpen;
  final VoidCallback onToggleSaved;
  final VoidCallback onToggleOffline;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: DawaContextualImage(
                assetId: item.visualAssetId,
                variant: DawaImageVariant.cardSideImage,
                borderRadius: BorderRadius.all(
                  Radius.circular(DawaRadii.small),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      color: DawaColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(item.title, style: context.dawaSectionTitle),
                  const SizedBox(height: 3),
                  Text(
                    '${item.durationMinutes} min • ${offline ? 'Available offline' : 'Online'}',
                    style: context.dawaCaption,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: onOpen,
                        child: Text(
                          item.type == DawaLearningType.audio ? 'Play' : 'Open',
                        ),
                      ),
                      IconButton(
                        tooltip:
                            saved ? 'Remove from saved' : 'Save this lesson',
                        onPressed: onToggleSaved,
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: DawaColors.primary,
                        ),
                      ),
                      IconButton(
                        tooltip: offline
                            ? 'Remove offline copy'
                            : 'Make transcript available offline',
                        onPressed: onToggleOffline,
                        icon: Icon(
                          offline
                              ? Icons.download_done_rounded
                              : Icons.download_for_offline_outlined,
                          color:
                              offline ? DawaColors.green : DawaColors.primary,
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
