import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/features/pregnancy/domain/dawa_pregnancy_journey.dart';
import '/features/profile/data/health_profile_repository.dart';

/// Track's interactive, read-only pregnancy journey. Week exploration is local
/// UI state; it can never amend the pregnancy dates saved in Health Profile.
class DawaPregnancyJourneyOverview extends StatefulWidget {
  const DawaPregnancyJourneyOverview({super.key, required this.profile});

  final HealthProfileSnapshot profile;

  @override
  State<DawaPregnancyJourneyOverview> createState() =>
      _DawaPregnancyJourneyOverviewState();
}

class _DawaPregnancyJourneyOverviewState
    extends State<DawaPregnancyJourneyOverview> {
  int? _exploredWeek;

  @override
  Widget build(BuildContext context) {
    final journey = DawaPregnancyJourney.fromProfile(widget.profile);
    if (journey == null) return _SetupPregnancyJourney(profile: widget.profile);

    final selectedWeek = _exploredWeek ?? journey.actualWeek;
    final development = DawaPregnancyDevelopment.forWeek(selectedWeek);
    final isPreview = selectedWeek != journey.actualWeek;
    final nearbyWeeks = List<int>.generate(
      7,
      (index) => (journey.actualWeek - 3 + index).clamp(0, 42),
    ).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your pregnancy journey', style: context.dawaTitle),
        const SizedBox(height: DawaSpacing.xxs),
        Text(
          'Follow your baby’s development and discover what to expect each week.',
          style: context.dawaBody,
        ),
        const SizedBox(height: DawaSpacing.md),
        DawaCard(
          key: const ValueKey('pregnancy-development-wheel'),
          featured: true,
          color: DawaColors.softPurple,
          borderColor: DawaColors.purple.withValues(alpha: .22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: selectedWeek == 0
                        ? null
                        : () =>
                            setState(() => _exploredWeek = selectedWeek - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Week $selectedWeek${isPreview ? ' preview' : ', Day ${journey.dayOfWeek}'}',
                          style: context.dawaSectionTitle,
                        ),
                        Text(
                          '${_ordinal(_trimesterFor(selectedWeek))} trimester',
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: selectedWeek == 42
                        ? null
                        : () =>
                            setState(() => _exploredWeek = selectedWeek + 1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: DawaSpacing.xs),
              _PregnancyProgressWheel(
                journey: journey,
                development: development,
                selectedWeek: selectedWeek,
              ),
              const SizedBox(height: DawaSpacing.sm),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearbyWeeks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, index) {
                    final week = nearbyWeeks[index];
                    return ChoiceChip(
                      label: Text('Week $week'),
                      selected: week == selectedWeek,
                      onSelected: (_) => setState(() => _exploredWeek = week),
                    );
                  },
                ),
              ),
              if (isPreview)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _exploredWeek = null),
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Back to today'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DawaSpacing.md),
        _JourneyMetrics(journey: journey),
        const SizedBox(height: DawaSpacing.md),
        DawaCard(
          semanticLabel: 'Your baby this week. Open pregnancy learning.',
          onTap: () => context.push('/learn/pregnancy'),
          child: Row(
            children: [
              _DevelopmentImage(development: development, size: 74),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your baby this week',
                        style: context.dawaSectionTitle),
                    const SizedBox(height: 3),
                    Text(development.summary, style: context.dawaCaption),
                    const SizedBox(height: 6),
                    Text('Illustrative stage · Explore guidance',
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.purple,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: DawaColors.primary),
            ],
          ),
        ),
        const SizedBox(height: DawaSpacing.sm),
        DawaCard(
          color: DawaColors.warmSurface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DawaIconBadge(
                icon: Icons.favorite_outline_rounded,
                color: DawaColors.purple,
                background: DawaColors.softPurple,
              ),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Changes you may notice',
                        style: context.dawaSectionTitle),
                    const SizedBox(height: 3),
                    Text(development.maternalNote, style: context.dawaCaption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DawaSpacing.sm),
        DawaCard(
          padding: EdgeInsets.zero,
          child: DawaActionRow(
            icon: Icons.calendar_month_rounded,
            color: DawaColors.greenDark,
            title: 'Your pregnancy care',
            subtitle: journey.isPastDue
                ? 'Your due date has passed. Contact your health worker for guidance.'
                : 'Book or review an antenatal visit when you are ready.',
            onTap: () => context.push('/care'),
          ),
        ),
      ],
    );
  }
}

class _SetupPregnancyJourney extends StatelessWidget {
  const _SetupPregnancyJourney({required this.profile});
  final HealthProfileSnapshot profile;

  @override
  Widget build(BuildContext context) => DawaCard(
        key: const ValueKey('pregnancy-tracking-hero'),
        featured: true,
        showPattern: true,
        color: DawaColors.softPurple,
        borderColor: DawaColors.purple.withValues(alpha: .2),
        child: DawaActionRow(
          icon: Icons.pregnant_woman_rounded,
          color: DawaColors.purple,
          title: widgetTitle,
          subtitle: widgetSubtitle,
          onTap: () => context.push('/settings'),
        ),
      );

  String get widgetTitle => profile.pregnancyStatus == 'pregnant'
      ? 'Add pregnancy dates'
      : 'Set up pregnancy tracking';
  String get widgetSubtitle =>
      'Add a last period or due date to see guidance for your stage.';
}

class _PregnancyProgressWheel extends StatelessWidget {
  const _PregnancyProgressWheel({
    required this.journey,
    required this.development,
    required this.selectedWeek,
  });
  final DawaPregnancyJourney journey;
  final DawaPregnancyDevelopment development;
  final int selectedWeek;

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            'Pregnancy progress. Actual week ${journey.actualWeek}. Showing week $selectedWeek.',
        child: SizedBox(
          width: 218,
          height: 218,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 208,
                height: 208,
                child: CircularProgressIndicator(
                  value: journey.progress,
                  strokeWidth: 11,
                  color: DawaColors.purple,
                  backgroundColor: DawaColors.surface,
                ),
              ),
              _DevelopmentImage(development: development, size: 176),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DawaColors.surface,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Week $selectedWeek of 40',
                      style: context.dawaCaption
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DevelopmentImage extends StatelessWidget {
  const _DevelopmentImage({required this.development, required this.size});
  final DawaPregnancyDevelopment development;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: development.assetPath == null
              ? _EarlyDatingVisual(key: const ValueKey('pregnancy-dating'))
              : Image.asset(
                  development.assetPath!,
                  key: ValueKey('pregnancy-development-${development.week}'),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  semanticLabel: 'Illustrative pregnancy development stage',
                  errorBuilder: (_, error, __) {
                    debugPrint(
                      '[Pregnancy] development asset unavailable '
                      'stage=${development.week} error_type=${error.runtimeType}',
                    );
                    return const _UnavailableDevelopmentVisual();
                  },
                ),
        ),
      );
}

class _EarlyDatingVisual extends StatelessWidget {
  const _EarlyDatingVisual({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Early pregnancy dating information',
        child: Container(
          color: DawaColors.surface,
          alignment: Alignment.center,
          child: const Icon(
            Icons.calendar_month_outlined,
            color: DawaColors.purple,
            size: 38,
          ),
        ),
      );
}

class _UnavailableDevelopmentVisual extends StatelessWidget {
  const _UnavailableDevelopmentVisual();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Pregnancy development illustration unavailable',
        child: Container(
          color: DawaColors.surface,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: DawaColors.textMuted,
            size: 34,
          ),
        ),
      );
}

class _JourneyMetrics extends StatelessWidget {
  const _JourneyMetrics({required this.journey});
  final DawaPregnancyJourney journey;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: _Metric(
                  label: 'Today',
                  value:
                      'Week ${journey.actualWeek}\nDay ${journey.dayOfWeek}')),
          const SizedBox(width: DawaSpacing.xs),
          Expanded(
              child: _Metric(
                  label: 'Due date',
                  value: DateFormat('d MMM y').format(journey.dueDate))),
          const SizedBox(width: DawaSpacing.xs),
          Expanded(
              child: _Metric(
                  label: journey.isPastDue ? 'Next step' : 'Remaining',
                  value: journey.isPastDue
                      ? 'Contact care'
                      : '${journey.daysRemaining} days')),
        ],
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.dawaCaption),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.dawaBody.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}

int _trimesterFor(int week) => week <= 13
    ? 1
    : week <= 27
        ? 2
        : 3;
String _ordinal(int value) =>
    switch (value) { 1 => 'First', 2 => 'Second', _ => 'Third' };
