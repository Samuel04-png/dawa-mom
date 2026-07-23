import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/games/domain/dawa_health_game.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/features/learning/presentation/dawa_quest_pages.dart';

class DawaRewardsPage extends StatefulWidget {
  const DawaRewardsPage({super.key, this.repository});

  static const routeName = 'DawaRewards';
  static const routePath = '/learn/rewards';

  final DawaLearningRepository? repository;

  @override
  State<DawaRewardsPage> createState() => _DawaRewardsPageState();
}

class _DawaRewardsPageState extends State<DawaRewardsPage> {
  late final DawaLearningRepository _repository;
  late Future<_RewardsSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaLearningRepository();
    _snapshot = _load();
  }

  Future<_RewardsSnapshot> _load() async {
    final state = await _repository.load();
    final redemption = await _repository.loadRedemption(state: state);
    return _RewardsSnapshot(state: state, redemption: redemption);
  }

  Future<void> _redeem(_RewardsSnapshot snapshot) async {
    final next = await showDawaRewardDialog(
      context,
      repository: _repository,
      state: snapshot.state,
    );
    if (next != null && mounted) {
      setState(() => _snapshot = _load());
    }
  }

  void _showHistory(DawaLearningState state) {
    final activities = _rewardActivities(state);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DawaBottomSheetFrame(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DawaIconBadge(
                    icon: Icons.history_rounded,
                    color: DawaColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Reward activity', style: context.dawaTitle),
                  ),
                  IconButton(
                    tooltip: 'Close reward history',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (activities.isEmpty)
                DawaCard(
                  color: DawaColors.softBlue,
                  child: Row(
                    children: [
                      const DawaIconBadge(
                        icon: Icons.auto_awesome_rounded,
                        color: DawaColors.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your completed lessons and games will appear here.',
                          style: context.dawaBody,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: DawaIconBadge(
                          icon: activity.icon,
                          color: activity.color,
                        ),
                        title: Text(activity.title,
                            style: context.dawaSectionTitle),
                        subtitle:
                            Text(activity.category, style: context.dawaCaption),
                        trailing: Text(
                          activity.coins == 0
                              ? 'Completed'
                              : '+${activity.coins} pts',
                          style: TextStyle(
                            color: activity.coins == 0
                                ? DawaColors.muted
                                : DawaColors.green,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
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
              title: 'Dawa Rewards',
              onBack: context.pop,
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/settings'),
            ),
            FutureBuilder<_RewardsSnapshot>(
              future: _snapshot,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final value = snapshot.data ??
                    const _RewardsSnapshot(
                      state: DawaLearningState(),
                    );
                final activities = _rewardActivities(value.state);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RewardsHero(state: value.state),
                    if (value.redemption != null) ...[
                      const SizedBox(height: 14),
                      _ActiveVoucherCard(
                        redemption: value.redemption!,
                      ),
                    ],
                    const SizedBox(height: 18),
                    DawaSectionHeader(
                      title: 'Rewards',
                      subtitle: 'Healthy actions build towards meaningful care',
                      actionLabel: 'History',
                      onAction: () => _showHistory(value.state),
                    ),
                    const SizedBox(height: 10),
                    _ScanRewardCard(
                      state: value.state,
                      alreadyRedeemed: value.redemption != null,
                      onRedeem: () => _redeem(value),
                    ),
                    const SizedBox(height: 18),
                    const DawaSectionHeader(
                      title: 'Ways to earn',
                      subtitle: 'Every small step counts',
                    ),
                    const SizedBox(height: 10),
                    DawaResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 3,
                      desktopColumns: 3,
                      children: [
                        _EarnCard(
                          icon: Icons.sports_esports_rounded,
                          color: DawaColors.purple,
                          title: 'Play a health game',
                          value: '+10 points',
                          onTap: () => context.push('/learn/games'),
                        ),
                        _EarnCard(
                          icon: Icons.menu_book_rounded,
                          color: DawaColors.green,
                          title: 'Complete a lesson',
                          value: '+5 points',
                          onTap: () => context.push('/learn'),
                        ),
                        _EarnCard(
                          icon: Icons.route_rounded,
                          color: DawaColors.primary,
                          title: 'Finish a quest',
                          value: '+20 points',
                          onTap: () => context.push('/learn/quests'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const DawaSectionHeader(
                      title: 'Achievements',
                      subtitle: 'Milestones from your learning journey',
                    ),
                    const SizedBox(height: 10),
                    _Achievements(state: value.state),
                    if (activities.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      DawaCard(
                        onTap: () => _showHistory(value.state),
                        semanticLabel:
                            'Open reward activity with ${activities.length} completed actions',
                        child: Row(
                          children: [
                            const DawaIconBadge(
                              icon: Icons.history_rounded,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Recent activity',
                                      style: context.dawaSectionTitle),
                                  Text(
                                    '${activities.length} healthy actions completed',
                                    style: context.dawaCaption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: DawaColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _RewardsHero extends StatelessWidget {
  const _RewardsHero({required this.state});

  final DawaLearningState state;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .18),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: DawaBreakpoints.isMobile(context) ? 205 : 225,
          child: Stack(
            children: [
              Positioned(
                right: DawaBreakpoints.isMobile(context) ? -6 : 28,
                bottom: 0,
                width: DawaBreakpoints.isMobile(context) ? 145 : 205,
                height: 210,
                child: Image.asset(
                  DawaArtwork.motherReward,
                  fit: BoxFit.contain,
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
                        maxWidth: DawaBreakpoints.isMobile(context) ? 210 : 450,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR HEALTHY-ACTION BALANCE',
                            style: TextStyle(
                              color: DawaColors.green,
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            label: '${state.coins} Dawa reward points',
                            child: Text(
                              '${state.coins}',
                              style: context.dawaDisplay.copyWith(fontSize: 42),
                            ),
                          ),
                          Text('Dawa points', style: context.dawaSectionTitle),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 190,
                            child: DawaProgressBar(
                              value: state.coins / 1000,
                              semanticLabel: 'Progress to free scan voucher',
                              color: DawaColors.green,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${(1000 - state.coins).clamp(0, 1000)} points to the free scan voucher',
                            style: context.dawaCaption,
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

class _ScanRewardCard extends StatelessWidget {
  const _ScanRewardCard({
    required this.state,
    required this.alreadyRedeemed,
    required this.onRedeem,
  });

  final DawaLearningState state;
  final bool alreadyRedeemed;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final available = state.coins >= 1000;
    return DawaCard(
      child: Column(
        children: [
          Row(
            children: [
              const DawaIconBadge(
                icon: Icons.card_giftcard_rounded,
                color: DawaColors.green,
                size: 54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free scan voucher', style: context.dawaSectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      '1000 points • Participating Dawa clinics',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              DawaStatusPill(
                label: alreadyRedeemed
                    ? 'Redeemed'
                    : available
                        ? 'Ready'
                        : 'Locked',
                icon: alreadyRedeemed
                    ? Icons.check_rounded
                    : available
                        ? Icons.redeem_rounded
                        : Icons.lock_outline_rounded,
                color: alreadyRedeemed
                    ? DawaColors.green
                    : available
                        ? DawaColors.primary
                        : DawaColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DawaProgressBar(
            value: alreadyRedeemed ? 1 : state.coins / 1000,
            semanticLabel: 'Free scan reward progress',
            color: DawaColors.green,
          ),
          const SizedBox(height: 12),
          DawaPrimaryButton(
            label: alreadyRedeemed
                ? 'View voucher'
                : available
                    ? 'Redeem voucher'
                    : '${1000 - state.coins} points to go',
            icon: alreadyRedeemed
                ? Icons.confirmation_number_outlined
                : Icons.redeem_rounded,
            onPressed: alreadyRedeemed || available ? onRedeem : null,
          ),
        ],
      ),
    );
  }
}

class _ActiveVoucherCard extends StatelessWidget {
  const _ActiveVoucherCard({required this.redemption});

  final DawaRewardRedemption redemption;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Active free scan voucher ${redemption.voucherCode}',
        child: DawaCard(
          color: DawaColors.softGreen,
          borderColor: DawaColors.green.withValues(alpha: .35),
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.verified_rounded,
                color: DawaColors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your active voucher',
                        style: context.dawaSectionTitle),
                    const SizedBox(height: 3),
                    SelectionArea(
                      child: Text(
                        redemption.voucherCode,
                        style: context.dawaTitle.copyWith(
                          letterSpacing: 1.4,
                          color: DawaColors.green,
                        ),
                      ),
                    ),
                    Text(
                      'Show this code at a participating Dawa clinic.',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy voucher code',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: redemption.voucherCode),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voucher code copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                color: DawaColors.primary,
              ),
            ],
          ),
        ),
      );
}

class _EarnCard extends StatelessWidget {
  const _EarnCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        onTap: onTap,
        semanticLabel: '$title, $value',
        child: Row(
          children: [
            DawaIconBadge(icon: icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.dawaSectionTitle),
                  Text(
                    value,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DawaColors.primary),
          ],
        ),
      );
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.state});

  final DawaLearningState state;

  @override
  Widget build(BuildContext context) {
    final hasCompletion = state.completedIds.isNotEmpty;
    final gameComplete = state.completedIds.any(DawaHealthGameCatalog.isGameId);
    final questComplete = state.completedIds.contains('screening-without-fear');
    return DawaResponsiveGrid(
      mobileColumns: 3,
      tabletColumns: 3,
      desktopColumns: 3,
      spacing: 8,
      children: [
        _AchievementBadge(
          title: 'First step',
          icon: Icons.directions_walk_rounded,
          unlocked: hasCompletion,
        ),
        _AchievementBadge(
          title: 'Game changer',
          icon: Icons.sports_esports_rounded,
          unlocked: gameComplete,
        ),
        _AchievementBadge(
          title: 'Path finisher',
          icon: Icons.route_rounded,
          unlocked: questComplete,
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.title,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$title achievement, ${unlocked ? 'unlocked' : 'locked'}',
        child: DawaCard(
          color: unlocked ? DawaColors.softGreen : DawaColors.surface,
          borderColor: unlocked
              ? DawaColors.green.withValues(alpha: .3)
              : DawaColors.line,
          child: Column(
            children: [
              DawaIconBadge(
                icon: unlocked ? icon : Icons.lock_outline_rounded,
                color: unlocked ? DawaColors.gold : DawaColors.muted,
              ),
              const SizedBox(height: 7),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: context.dawaCaption.copyWith(
                  color: unlocked ? DawaColors.ink : DawaColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _RewardActivity {
  const _RewardActivity({
    required this.title,
    required this.category,
    required this.coins,
    required this.icon,
    required this.color,
  });

  final String title;
  final String category;
  final int coins;
  final IconData icon;
  final Color color;
}

List<_RewardActivity> _rewardActivities(DawaLearningState state) {
  final activities = <_RewardActivity>[];
  for (final id in state.completedIds) {
    if (DawaHealthGameCatalog.isGameId(id)) {
      activities.add(
        _RewardActivity(
          title: DawaHealthGameCatalog.titleFor(id),
          category: 'Health game',
          coins: DawaHealthGameCatalog.rewardFor(id),
          icon: Icons.sports_esports_rounded,
          color: DawaColors.purple,
        ),
      );
      continue;
    }
    final detail = switch (id) {
      'myth-vs-fact' => ('Myth vs Fact', 'Lesson', 5),
      'pregnancy-basics' => ('Pregnancy basics', 'Audio lesson', 5),
      'screening-checkpoint' => ('Screening checkpoint', 'Quest step', 5),
      'screening-without-fear' => ('Screening Without Fear', 'Quest', 20),
      _ => (id.replaceAll('-', ' '), 'Learning', 0),
    };
    activities.add(
      _RewardActivity(
        title: detail.$1,
        category: detail.$2,
        coins: detail.$3,
        icon: detail.$2.contains('Quest')
            ? Icons.route_rounded
            : Icons.menu_book_rounded,
        color:
            detail.$2.contains('Quest') ? DawaColors.primary : DawaColors.green,
      ),
    );
  }
  activities.sort((a, b) => b.coins.compareTo(a.coins));
  return activities;
}

class _RewardsSnapshot {
  const _RewardsSnapshot({
    required this.state,
    this.redemption,
  });

  final DawaLearningState state;
  final DawaRewardRedemption? redemption;
}
