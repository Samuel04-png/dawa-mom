import '/localization/dawa_localized_material.dart';

import '/backend/period_tracker_service.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/components/responsive/responsive_layout.dart';
import '/design_system/dawa_components.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/navbar/period_tracker/period_tracker_widget.dart';

class PeriodCycleStatusLoader extends StatefulWidget {
  const PeriodCycleStatusLoader({super.key});

  @override
  State<PeriodCycleStatusLoader> createState() =>
      _PeriodCycleStatusLoaderState();
}

class _PeriodCycleStatusLoaderState extends State<PeriodCycleStatusLoader> {
  final _profiles = HealthProfileRepository();
  final _periods = PeriodTrackerService();
  late Future<(HealthProfileSnapshot, List<PeriodRecord>)> _data;

  @override
  void initState() {
    super.initState();
    HealthProfileRepository.changes.addListener(_reload);
    PeriodTrackerService.changes.addListener(_reload);
    _data = _load();
  }

  @override
  void dispose() {
    HealthProfileRepository.changes.removeListener(_reload);
    PeriodTrackerService.changes.removeListener(_reload);
    super.dispose();
  }

  Future<(HealthProfileSnapshot, List<PeriodRecord>)> _load() async {
    final result = await Future.wait<dynamic>([
      _profiles.load(),
      _periods.loadPeriodHistory(),
    ]);
    return (
      result[0] as HealthProfileSnapshot,
      result[1] as List<PeriodRecord>,
    );
  }

  void _reload() {
    if (mounted) setState(() => _data = _load());
  }

  Future<void> _open(HealthProfileSnapshot profile) async {
    if (profile.periodSettings?['lastPeriodStart'] != null) {
      if (mounted) context.pushNamed(PeriodTrackerWidget.routeName);
      return;
    }
    await showPeriodSetupFlow(context, allowSkip: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(HealthProfileSnapshot, List<PeriodRecord>)>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DawaLoadingSkeleton(
            label: 'Loading your cycle dates',
            lines: 3,
          );
        }
        if (!snapshot.hasData) {
          return DawaMomCard(
            child: Center(
              child: TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload cycle status'),
              ),
            ),
          );
        }
        final profile = snapshot.data!.$1;
        final summary = PeriodCycleSummary.derive(
          now: DateTime.now(),
          settings: profile.periodSettings,
          history: snapshot.data!.$2,
        );
        return DawaMomCard(
          child: PeriodCycleStatusCard(
            summary: summary,
            onOpenTracker: () => _open(profile),
          ),
        );
      },
    );
  }
}

class PeriodCycleStatusCard extends StatelessWidget {
  const PeriodCycleStatusCard({
    super.key,
    required this.summary,
    required this.onOpenTracker,
  });

  final PeriodCycleSummary summary;
  final VoidCallback onOpenTracker;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (!summary.isConfigured) {
      return _EmptyCycleCard(onOpenTracker: onOpenTracker);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 560;
        final overview = _CycleOverview(summary: summary);
        final details = _CycleDetails(
          summary: summary,
          onOpenTracker: onOpenTracker,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2557B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFFE2557B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cycle status',
                        style: theme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        summary.statusLabel,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Open Period Tracker',
                  onPressed: onOpenTracker,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (horizontal)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: overview),
                  const SizedBox(width: 22),
                  Expanded(child: details),
                ],
              )
            else ...[
              overview,
              const SizedBox(height: 18),
              details,
            ],
            const SizedBox(height: 12),
            Text(
              'Cycle dates are estimates and may change as you add history.',
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ],
        );
      },
    );
  }
}

class _CycleOverview extends StatelessWidget {
  const _CycleOverview({required this.summary});

  final PeriodCycleSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final cycleLength = summary.averageCycleLength ?? 28;
    final displayDay = (summary.cycleDay ?? 1).clamp(1, cycleLength);
    final progress = (displayDay / cycleLength).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CYCLE DAY',
              style: theme.labelSmall.copyWith(color: theme.primary)),
          const SizedBox(height: 4),
          Text(
            summary.cycleDay?.toString() ?? 'Not set',
            style: theme.headlineMedium.copyWith(
              color: theme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: theme.primary,
              backgroundColor: theme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.averageCycleLength}-day average cycle · ${summary.averagePeriodLength}-day period',
            style: theme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CycleDetails extends StatelessWidget {
  const _CycleDetails({required this.summary, required this.onOpenTracker});

  final PeriodCycleSummary summary;
  final VoidCallback onOpenTracker;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final estimate = summary.nextPeriodEstimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailLine(
          label: 'Next estimate',
          value: estimate == null
              ? 'Not available'
              : DateFormat('d MMMM').format(estimate),
        ),
        const SizedBox(height: 11),
        _DetailLine(
          label: 'Estimate quality',
          value:
              '${summary.confidenceLabel} · ${summary.historyCount} cycle record${summary.historyCount == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 11),
        _DetailLine(
          label: 'Last period',
          value: summary.lastPeriodStart == null
              ? 'Not recorded'
              : DateFormat('d MMM y').format(summary.lastPeriodStart!),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onOpenTracker,
          icon: const Icon(Icons.edit_calendar_outlined, size: 18),
          label: const Text('View or update history'),
          style: TextButton.styleFrom(foregroundColor: theme.primary),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.bodySmall.copyWith(color: theme.secondaryText)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _EmptyCycleCard extends StatelessWidget {
  const _EmptyCycleCard({required this.onOpenTracker});

  final VoidCallback onOpenTracker;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined, color: theme.primary, size: 36),
            const SizedBox(height: 10),
            Text(
              'Set up your cycle tracker',
              style: theme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your last period and typical cycle length to see a private estimate here.',
              textAlign: TextAlign.center,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpenTracker,
              child: const Text('Set up Period Tracker'),
            ),
          ],
        ),
      ),
    );
  }
}
