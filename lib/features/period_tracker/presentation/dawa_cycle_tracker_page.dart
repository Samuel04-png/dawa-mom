import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/backend/period_tracker_service.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/profile/data/health_profile_repository.dart';

class DawaCycleTrackerPage extends StatefulWidget {
  const DawaCycleTrackerPage({
    super.key,
    this.service,
    this.profileRepository,
  });

  final PeriodTrackerService? service;
  final HealthProfileRepository? profileRepository;

  @override
  State<DawaCycleTrackerPage> createState() => _DawaCycleTrackerPageState();
}

class _DawaCycleTrackerPageState extends State<DawaCycleTrackerPage> {
  late final PeriodTrackerService _service;
  late final HealthProfileRepository _profiles;
  late Future<_CyclePageData> _data;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _pregnancyTab = false;
  bool _periodActionBusy = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PeriodTrackerService();
    _profiles = widget.profileRepository ?? HealthProfileRepository();
    PeriodTrackerService.changes.addListener(_onChanged);
    HealthProfileRepository.changes.addListener(_onChanged);
    _data = _load();
  }

  @override
  void dispose() {
    PeriodTrackerService.changes.removeListener(_onChanged);
    HealthProfileRepository.changes.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) _refresh();
  }

  Future<_CyclePageData> _load() async {
    final results = await Future.wait<dynamic>([
      _service.loadUserSettings(),
      _service.loadPeriodHistory(),
      _profiles.load(),
    ]);
    final settings = results[0] as Map<String, dynamic>?;
    final history = results[1] as List<PeriodRecord>;
    return _CyclePageData(
      settings: settings,
      history: history,
      profile: results[2] as HealthProfileSnapshot,
      summary: PeriodCycleSummary.derive(
        now: DateTime.now(),
        settings: settings,
        history: history,
      ),
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  Future<void> _setup(_CyclePageData data) async {
    final result = await showPeriodSetupFlow(
      context,
      allowSkip: true,
      initialStartDate: data.summary.lastPeriodStart,
      initialCycleLength: data.settings?['averageCycleLength'] as int? ?? 28,
      initialPeriodLength: data.settings?['periodLength'] as int? ?? 5,
      initialIsRegular: data.settings?['isRegular'] as bool? ?? true,
    );
    if (result != null && result != PeriodSetupOutcome.back && mounted) {
      await _refresh();
    }
  }

  Future<void> _checkIn() async {
    final existing = await _service.loadDailyData(_selectedDay);
    if (!mounted) return;
    final saved = await showDawaDailyCheckInSheet(
      context,
      date: _selectedDay,
      existing: existing,
      onSave: ({
        required symptoms,
        required pain,
        required feeling,
        required note,
      }) async {
        final notes = <String>[
          'Pain: ${pain.round()}/10',
          'Overall feeling: $feeling',
          if (note.trim().isNotEmpty) note.trim(),
        ];
        await _service.saveDailyData(
          date: _selectedDay,
          symptoms: symptoms,
          notes: notes,
        );
      },
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in saved for ${DateFormat('d MMMM').format(_selectedDay)}.',
          ),
        ),
      );
      await _refresh();
    }
  }

  Future<void> _markPeriodStarted(_CyclePageData data) async {
    if (_periodActionBusy) return;
    if (!data.summary.isConfigured) {
      await _setup(data);
      return;
    }
    final today = _dateOnly(DateTime.now());
    setState(() => _periodActionBusy = true);
    try {
      await _service.savePeriodRecord(startDate: today);
      if (!mounted) return;
      setState(() {
        _selectedDay = today;
        _focusedDay = today;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Period start saved for today.'),
          action: SnackBarAction(
            label: 'Change date',
            onPressed: () => _changePeriodStartDate(today),
          ),
        ),
      );
      await _refresh();
    } on PeriodTrackerException catch (error) {
      if (mounted) _showPeriodError(error.message);
    } catch (_) {
      if (mounted) {
        _showPeriodError(
          'Your period start could not be saved. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _periodActionBusy = false);
    }
  }

  Future<void> _changePeriodStartDate(DateTime originalDate) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: originalDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: _dateOnly(DateTime.now()),
      helpText: context.tr('Choose the first day of your period'),
      cancelText: context.tr('Cancel'),
      confirmText: context.tr('Save'),
    );
    if (selected == null || _dateOnly(selected) == _dateOnly(originalDate)) {
      return;
    }
    setState(() => _periodActionBusy = true);
    try {
      await _service.updatePeriodRecord(
        originalStartDate: originalDate,
        startDate: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Period start changed to ${DateFormat('d MMMM').format(selected)}.',
          ),
        ),
      );
      await _refresh();
    } on PeriodTrackerException catch (error) {
      if (mounted) _showPeriodError(error.message);
    } catch (_) {
      if (mounted) {
        _showPeriodError('The date could not be changed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _periodActionBusy = false);
    }
  }

  Future<void> _markPeriodEnded(_CyclePageData data) async {
    if (_periodActionBusy || data.history.isEmpty) return;
    final latest = [...data.history]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final current = latest.first;
    final today = _dateOnly(DateTime.now());
    setState(() => _periodActionBusy = true);
    try {
      await _service.updatePeriodRecord(
        originalStartDate: current.startDate,
        startDate: current.startDate,
        endDate: today,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period end saved for today.')),
      );
      await _refresh();
    } on PeriodTrackerException catch (error) {
      if (mounted) _showPeriodError(error.message);
    } catch (_) {
      if (mounted) {
        _showPeriodError(
          'Your period end could not be saved. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _periodActionBusy = false);
    }
  }

  void _showPeriodError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DawaColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_CyclePageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const DawaPageScaffold(
              child: DawaPageSkeleton(
                label: 'Loading your cycle',
                cardCount: 3,
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return DawaPageScaffold(
              child: DawaCard(
                child: Column(
                  children: [
                    const DawaIconBadge(
                      icon: Icons.cloud_off_rounded,
                      size: 58,
                    ),
                    const SizedBox(height: 10),
                    Text('Cycle tracker could not be loaded',
                        style: context.dawaSectionTitle),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: DawaPageScaffold(
              bottomNavigationBar:
                  _pregnancyTab ? null : _buildLogTodayAction(context),
              child: _buildContent(context, data),
            ),
          );
        },
      );

  Widget _buildLogTodayAction(BuildContext context) => Material(
        color: DawaColors.canvas,
        elevation: 2,
        shadowColor: DawaColors.primary.withValues(alpha: .12),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              DawaBreakpoints.pagePadding(context),
              8,
              DawaBreakpoints.pagePadding(context),
              10,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: DawaBreakpoints.isMobile(context) ? 420 : 260,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('cycle-log-today-action'),
                    onPressed: _checkIn,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Log today'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildContent(BuildContext context, _CyclePageData data) {
    final summary = data.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaAppHeader(
          title:
              DawaBreakpoints.isMobile(context) ? 'Track' : 'Track your cycle',
          notificationUnread: true,
          onNotifications: () => context.push('/notifications'),
          onProfile: () => context.go('/settings'),
        ),
        const SizedBox(height: DawaSpacing.xs),
        _TrackerModeSelector(
          pregnancySelected: _pregnancyTab,
          onChanged: (value) => setState(() => _pregnancyTab = value),
        ),
        const SizedBox(height: DawaSpacing.md),
        if (_pregnancyTab) ...[
          _PregnancyTrackingOverview(profile: data.profile),
        ] else ...[
          if (!summary.isConfigured) ...[
            DawaCard(
              color: DawaColors.softBlue,
              child: Row(
                children: [
                  const SizedBox(
                    width: 90,
                    child: DawaContextualImage(
                      assetId: 'period_tracking_03',
                      variant: DawaImageVariant.cardSideImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set up cycle tracking',
                            style: context.dawaTitle.copyWith(fontSize: 19)),
                        const SizedBox(height: 4),
                        Text(
                          'Add your last period and usual cycle length to see estimates.',
                          style: context.dawaCaption,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _setup(data),
                          child: const Text('Set up tracker'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _PeriodQuickActions(
              periodActive: summary.isPeriodActive,
              busy: _periodActionBusy,
              onStarted: () => _markPeriodStarted(data),
              onEnded: () => _markPeriodEnded(data),
            ),
            const SizedBox(height: DawaSpacing.md),
          ],
          DawaCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TableCalendar<void>(
                  firstDay: DateTime(DateTime.now().year - 2),
                  lastDay: DateTime(DateTime.now().year + 2),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) => _focusedDay = focused,
                  sixWeekMonthsEnforced: false,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  rowHeight: DawaBreakpoints.isMobile(context) ? 36 : 42,
                  daysOfWeekHeight: 22,
                  headerStyle: HeaderStyle(
                    headerPadding: const EdgeInsets.only(bottom: 4),
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: context.dawaSectionTitle,
                    leftChevronIcon: const Icon(
                      Icons.chevron_left_rounded,
                      color: DawaColors.primary,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right_rounded,
                      color: DawaColors.primary,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: DawaColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: DawaColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    outsideTextStyle: const TextStyle(
                      color: DawaColors.line,
                      fontSize: 11,
                    ),
                    defaultTextStyle: const TextStyle(
                      color: DawaColors.ink,
                      fontSize: 11,
                    ),
                    weekendTextStyle: const TextStyle(
                      color: DawaColors.ink,
                      fontSize: 11,
                    ),
                    todayDecoration: const BoxDecoration(
                      color: DawaColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: DawaColors.primary.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: DawaColors.pink,
                      shape: BoxShape.circle,
                    ),
                    cellMargin: const EdgeInsets.all(3),
                  ),
                  eventLoader: (day) {
                    if (_isPeriodDay(day, data)) return const [null];
                    return const [];
                  },
                  calendarBuilders: CalendarBuilders(
                    prioritizedBuilder: (context, day, focused) {
                      if (_isFertileDay(day, data)) {
                        return _DayDecoration(
                          day: day.day,
                          color: DawaColors.green.withValues(alpha: 0.16),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                const Divider(height: 20, color: DawaColors.line),
                const Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _LegendDot(color: DawaColors.pink, label: 'Period'),
                      _LegendDot(
                        color: DawaColors.green,
                        label: 'Estimated fertile window',
                      ),
                      _LegendDot(color: DawaColors.primary, label: 'Today'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          _CycleSummaryCards(
            nextPeriod: _CycleMetric(
              icon: Icons.water_drop_rounded,
              color: DawaColors.pink,
              surface: DawaColors.softPink,
              label: 'Next period',
              value: summary.daysUntilNextPeriod == null
                  ? 'Not set up'
                  : summary.daysUntilNextPeriod == 0
                      ? 'Estimated today'
                      : _predictionRange(summary),
              helper: summary.predictedWindowStart == null
                  ? 'Add a cycle start date'
                  : '${summary.confidenceLabel} • ${summary.predictionReason}',
            ),
            cycleDay: _CycleMetric(
              icon: Icons.sync_rounded,
              color: DawaColors.purple,
              surface: DawaColors.softPurple,
              label: 'Cycle day',
              value: summary.cycleDay == null
                  ? 'Not available'
                  : 'Day ${summary.cycleDay}',
              helper: summary.cycleDay == null
                  ? 'Based on the periods you added'
                  : '${summary.statusLabel} • Usual cycle ${summary.averageCycleLength ?? 28} days',
            ),
            fertileWindow: _CycleMetric(
              icon: Icons.eco_outlined,
              color: DawaColors.green,
              surface: DawaColors.softGreen,
              label: 'Estimated fertile window',
              value: summary.lastPeriodStart == null
                  ? 'Not available'
                  : summary.isRegular == true
                      ? _fertileRange(summary)
                      : 'Hidden for variable cycles',
              helper: summary.isRegular == true
                  ? 'Estimate only • Not a form of contraception'
                  : 'Add more cycle history before using this estimate.',
            ),
          ),
          const SizedBox(height: DawaSpacing.sm),
          DawaCard(
            color: DawaColors.warningSurface,
            borderColor: DawaColors.warning,
            padding: const EdgeInsets.all(DawaSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: DawaColors.warning,
                ),
                const SizedBox(width: DawaSpacing.xs),
                Expanded(
                  child: Text(
                    'Cycle dates and fertile days are estimates, not a diagnosis or a form of birth control.',
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          DawaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How are you feeling ${isSameDay(_selectedDay, DateTime.now()) ? 'today' : DateFormat('d MMM').format(_selectedDay)}?',
                  style: context.dawaSectionTitle,
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: const [
                    DawaStatusPill(
                      label: 'Cramps',
                      icon: Icons.gesture_rounded,
                      color: DawaColors.primary,
                    ),
                    DawaStatusPill(
                      label: 'Mood',
                      icon: Icons.sentiment_satisfied_outlined,
                      color: DawaColors.purple,
                    ),
                    DawaStatusPill(
                      label: 'Headache',
                      icon: Icons.psychology_outlined,
                      color: DawaColors.muted,
                    ),
                    DawaStatusPill(
                      label: 'Energy',
                      icon: Icons.bolt_rounded,
                      color: DawaColors.green,
                    ),
                    DawaStatusPill(
                      label: 'Discharge',
                      icon: Icons.water_drop_outlined,
                      color: DawaColors.pink,
                    ),
                  ],
                ),
                const SizedBox(height: DawaSpacing.sm),
                Text(
                  'Choose Log today below to record symptoms, pain, mood and a private note.',
                  style: context.dawaCaption,
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          DawaCard(
            onTap: () => context.push('/learn/topic/period-tracking'),
            semanticLabel: 'Open the cycle tracking visual guide',
            child: Row(
              children: [
                const SizedBox(
                  width: 82,
                  child: DawaContextualImage(
                    assetId: 'period_tracking_07',
                    variant: DawaImageVariant.cardSideImage,
                  ),
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Understand your cycle',
                        style: context.dawaSectionTitle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Learn what to record and why predictions remain estimates.',
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DawaColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          DawaIllustratedHeroCard(
            key: const ValueKey('cycle-pregnancy-journey-card'),
            category: 'PREGNANCY JOURNEY',
            title: data.profile.pregnancyWeek == null
                ? 'Guides for every stage'
                : 'Week ${data.profile.pregnancyWeek}',
            subtitle: data.profile.trimester == null
                ? 'Clear pregnancy tips and clinic help when you need it.'
                : '${_ordinal(data.profile.trimester!)} trimester • Guidance matched to this stage.',
            illustrationPath: data.profile.pregnancyWeek == null
                ? DawaArtwork.pregnancyEarly
                : DawaArtwork.pregnancyPhone,
            primaryActionLabel: 'View pregnancy',
            onPrimaryAction: () => context.push('/learn/pregnancy'),
            progress: data.profile.pregnancyWeek == null
                ? null
                : data.profile.pregnancyWeek! / 40,
            progressLabel: data.profile.pregnancyWeek == null
                ? null
                : 'Week ${data.profile.pregnancyWeek} of 40',
            semanticLabel: data.profile.pregnancyWeek == null
                ? 'Open pregnancy guides'
                : 'Pregnancy week ${data.profile.pregnancyWeek}',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _setup(data),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Cycle settings and history'),
            ),
          ),
        ],
      ],
    );
  }

  bool _isPeriodDay(DateTime day, _CyclePageData data) {
    final length = data.settings?['periodLength'] as int? ?? 5;
    for (final record in data.history) {
      final end =
          record.endDate ?? record.startDate.add(Duration(days: length - 1));
      if (!_dateOnly(day).isBefore(_dateOnly(record.startDate)) &&
          !_dateOnly(day).isAfter(_dateOnly(end))) {
        return true;
      }
    }
    return false;
  }

  bool _isFertileDay(DateTime day, _CyclePageData data) {
    if (data.summary.isRegular != true) return false;
    final start = data.summary.lastPeriodStart;
    if (start == null) return false;
    final cycleLength = data.summary.averageCycleLength ?? 28;
    final ovulation = start.add(Duration(days: cycleLength - 14));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));
    final value = _dateOnly(day);
    return !value.isBefore(_dateOnly(fertileStart)) &&
        !value.isAfter(_dateOnly(fertileEnd));
  }
}

class _PeriodQuickActions extends StatelessWidget {
  const _PeriodQuickActions({
    required this.periodActive,
    required this.busy,
    required this.onStarted,
    required this.onEnded,
  });

  final bool periodActive;
  final bool busy;
  final VoidCallback onStarted;
  final VoidCallback onEnded;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: periodActive ? DawaColors.softPink : DawaColors.softBlue,
        borderColor: periodActive ? DawaColors.pink : DawaColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DawaIconBadge(
                  icon: Icons.water_drop_rounded,
                  color: periodActive ? DawaColors.pink : DawaColors.primary,
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodActive
                            ? 'Your period is in progress'
                            : 'Quick period logging',
                        style: context.dawaSectionTitle,
                      ),
                      Text(
                        periodActive
                            ? 'End it today or use Log today for symptoms and flow.'
                            : 'Record the first day now. You can change the date afterward.',
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DawaSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final start = OutlinedButton.icon(
                  key: const ValueKey('period-start-action'),
                  onPressed: busy || periodActive ? null : onStarted,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(
                    periodActive ? 'Period started' : 'My period started',
                  ),
                );
                final end = FilledButton.icon(
                  key: const ValueKey('period-end-action'),
                  onPressed: busy || !periodActive ? null : onEnded,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: const Text('My period ended'),
                );
                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      start,
                      const SizedBox(height: DawaSpacing.xs),
                      end,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: start),
                    const SizedBox(width: DawaSpacing.xs),
                    Expanded(child: end),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _TrackerModeSelector extends StatelessWidget {
  const _TrackerModeSelector({
    required this.pregnancySelected,
    required this.onChanged,
  });

  final bool pregnancySelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: DawaCard(
            padding: const EdgeInsets.all(DawaSpacing.xxs),
            radius: DawaRadii.pill,
            child: Row(
              children: [
                Expanded(
                  child: _TrackerModeOption(
                    label: 'Cycle',
                    icon: Icons.sync_rounded,
                    selected: !pregnancySelected,
                    onTap: () => onChanged(false),
                  ),
                ),
                const SizedBox(width: DawaSpacing.xxs),
                Expanded(
                  child: _TrackerModeOption(
                    label: 'Pregnancy',
                    icon: Icons.pregnant_woman_rounded,
                    selected: pregnancySelected,
                    onTap: () => onChanged(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TrackerModeOption extends StatelessWidget {
  const _TrackerModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$label tracking',
        child: Material(
          color: selected ? DawaColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(DawaRadii.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DawaRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DawaSpacing.sm,
                vertical: DawaSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : DawaColors.muted,
                  ),
                  const SizedBox(width: DawaSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: context.dawaBody.copyWith(
                        color: selected ? Colors.white : DawaColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PregnancyTrackingOverview extends StatelessWidget {
  const _PregnancyTrackingOverview({required this.profile});

  final HealthProfileSnapshot profile;

  @override
  Widget build(BuildContext context) {
    final week = profile.pregnancyWeek;
    final dueDate = profile.calculatedDueDate;
    final configured = profile.pregnancyProfileStatus ==
        PregnancyProfileStatus.pregnantWithData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaIllustratedHeroCard(
          key: const ValueKey('pregnancy-tracking-hero'),
          category: 'YOUR PREGNANCY',
          title: week == null ? 'Add pregnancy dates' : 'Week $week',
          subtitle: profile.trimester == null
              ? 'Add pregnancy dates to see the right tips.'
              : '${_ordinal(profile.trimester!)} trimester'
                  '${dueDate == null ? '' : '\nDue around ${DateFormat('d MMMM y').format(dueDate)}'}',
          illustrationPath: week == null
              ? DawaArtwork.pregnancyEarly
              : DawaArtwork.pregnancyPhone,
          primaryActionLabel:
              configured ? 'Update details' : 'Add pregnancy details',
          onPrimaryAction: () => context.push('/settings'),
          progress: week == null ? null : week / 40,
          progressLabel: week == null ? null : 'Week $week of 40',
        ),
        const SizedBox(height: 12),
        DawaResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 3,
          children: [
            _PregnancyMetric(
              icon: Icons.calendar_today_outlined,
              label: 'Current week',
              value: week?.toString() ?? 'Not set',
            ),
            _PregnancyMetric(
              icon: Icons.timelapse_rounded,
              label: 'Trimester',
              value: profile.trimester?.toString() ?? 'Not set',
            ),
            _PregnancyMetric(
              icon: Icons.event_available_outlined,
              label: 'Due date',
              value: dueDate == null
                  ? 'Not set'
                  : DateFormat('d MMM').format(dueDate),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DawaCard(
          onTap: () => context.push('/learn/pregnancy'),
          semanticLabel: 'Open pregnancy guides',
          child: Row(
            children: [
              const SizedBox(
                width: 66,
                child: DawaContextualImage(
                  assetId: 'antenatal_stages_03',
                  variant: DawaImageVariant.cardSideImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What to expect', style: context.dawaSectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      configured
                          ? 'Read tips for this stage of pregnancy.'
                          : 'See clear tips for every stage of pregnancy.',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DawaColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PregnancyMetric extends StatelessWidget {
  const _PregnancyMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          children: [
            DawaIconBadge(icon: icon, color: DawaColors.green),
            const SizedBox(height: 8),
            Text(label, style: context.dawaCaption),
            Text(value, style: context.dawaTitle),
          ],
        ),
      );
}

class _DayDecoration extends StatelessWidget {
  const _DayDecoration({required this.day, required this.color});

  final int day;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          '$day',
          style: const TextStyle(color: DawaColors.ink, fontSize: 11),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: context.dawaCaption,
            ),
          ),
        ],
      );
}

class _CycleSummaryCards extends StatelessWidget {
  const _CycleSummaryCards({
    required this.nextPeriod,
    required this.cycleDay,
    required this.fertileWindow,
  });

  final Widget nextPeriod;
  final Widget cycleDay;
  final Widget fertileWindow;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = DawaSpacing.xs;
          if (constraints.maxWidth < 600) {
            final half = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(width: half, child: nextPeriod),
                SizedBox(width: half, child: cycleDay),
                SizedBox(width: constraints.maxWidth, child: fertileWindow),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nextPeriod),
              const SizedBox(width: gap),
              Expanded(child: cycleDay),
              const SizedBox(width: gap),
              Expanded(child: fertileWindow),
            ],
          );
        },
      );
}

class _CycleMetric extends StatelessWidget {
  const _CycleMetric({
    required this.icon,
    required this.color,
    required this.surface,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final Color color;
  final Color surface;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: surface,
        borderColor: color.withValues(alpha: 0.24),
        padding: const EdgeInsets.all(DawaSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DawaIconBadge(icon: icon, color: color, size: 38),
                const SizedBox(width: DawaSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DawaSpacing.xs),
            Text(
              value,
              style: context.dawaSectionTitle.copyWith(color: color),
            ),
            const SizedBox(height: DawaSpacing.xxs),
            Text(
              helper,
              style: context.dawaCaption,
            ),
          ],
        ),
      );
}

class _CyclePageData {
  const _CyclePageData({
    required this.settings,
    required this.history,
    required this.profile,
    required this.summary,
  });

  final Map<String, dynamic>? settings;
  final List<PeriodRecord> history;
  final HealthProfileSnapshot profile;
  final PeriodCycleSummary summary;
}

typedef DawaDailyCheckInSave = Future<void> Function({
  required List<String> symptoms,
  required double pain,
  required String feeling,
  required String note,
});

Future<bool> showDawaDailyCheckInSheet(
  BuildContext context, {
  required DateTime date,
  required Map<String, dynamic>? existing,
  required DawaDailyCheckInSave onSave,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) => _DawaDailyCheckInSheet(
        date: date,
        existing: existing,
        onSave: onSave,
      ),
    ) ??
    false;

class _DawaDailyCheckInSheet extends StatefulWidget {
  const _DawaDailyCheckInSheet({
    required this.date,
    required this.existing,
    required this.onSave,
  });

  final DateTime date;
  final Map<String, dynamic>? existing;
  final DawaDailyCheckInSave onSave;

  @override
  State<_DawaDailyCheckInSheet> createState() => _DawaDailyCheckInSheetState();
}

class _DawaDailyCheckInSheetState extends State<_DawaDailyCheckInSheet> {
  static const _symptoms = [
    ('Cramps', Icons.gesture_rounded),
    ('Headache', Icons.psychology_outlined),
    ('Nausea', Icons.sick_outlined),
    ('Discharge', Icons.water_drop_outlined),
    ('Mood', Icons.sentiment_satisfied_outlined),
    ('Energy', Icons.bolt_rounded),
    ('Appetite', Icons.restaurant_outlined),
    ('Sleep', Icons.bedtime_outlined),
  ];
  static const _feelings = ['Great', 'Good', 'Okay', 'Poor', 'Very poor'];

  late final Set<String> _selected;
  final _note = TextEditingController();
  double _pain = 1;
  String _feeling = 'Good';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(
      widget.existing?['symptoms'] as List? ?? const [],
    );
    final notes =
        List<String>.from(widget.existing?['notes'] as List? ?? const []);
    for (final value in notes) {
      if (value.startsWith('Pain:')) {
        _pain = double.tryParse(
              RegExp(r'\d+').firstMatch(value)?.group(0) ?? '',
            ) ??
            1;
      } else if (value.startsWith('Overall feeling:')) {
        _feeling = value.split(':').last.trim();
      } else {
        _note.text = value;
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(
        symptoms: _selected.toList()..sort(),
        pain: _pain,
        feeling: _feeling,
        note: _note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Your check-in could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => DawaBottomSheetFrame(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'How are you feeling today?',
                          textAlign: TextAlign.center,
                          style: context.dawaTitle,
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM').format(widget.date),
                          style: context.dawaCaption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close check-in',
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DawaCard(
                        color: DawaColors.softBlue,
                        child: Row(
                          children: [
                            const DawaIconBadge(
                              icon: Icons.water_drop_rounded,
                              color: DawaColors.pink,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cycle day check-in • your entries help you notice patterns.',
                                style: context.dawaCaption,
                              ),
                            ),
                            SizedBox(
                              width: 62,
                              height: 74,
                              child: Image.asset(
                                DawaArtwork.cycleCramps,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Select any symptoms you’re experiencing',
                          style: context.dawaSectionTitle),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.8,
                        children: [
                          for (final symptom in _symptoms)
                            FilterChip(
                              avatar: Icon(symptom.$2, size: 17),
                              label: Text(symptom.$1),
                              selected: _selected.contains(symptom.$1),
                              onSelected: (selected) => setState(() {
                                selected
                                    ? _selected.add(symptom.$1)
                                    : _selected.remove(symptom.$1);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Pain level: ${_pain.round()} out of 10',
                          style: context.dawaSectionTitle),
                      Slider(
                        value: _pain,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '${_pain.round()}',
                        onChanged: (value) => setState(() => _pain = value),
                      ),
                      TextField(
                        controller: _note,
                        maxLength: 250,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Add a note (optional)',
                          hintText:
                              'How are you feeling? Add details that may be helpful.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('How would you describe your overall feeling?',
                          style: context.dawaSectionTitle),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final feeling in _feelings)
                            ChoiceChip(
                              avatar: Icon(
                                _feelingIcon(feeling),
                                color:
                                    feeling == 'Poor' || feeling == 'Very poor'
                                        ? DawaColors.danger
                                        : DawaColors.green,
                                size: 17,
                              ),
                              label: Text(feeling),
                              selected: _feeling == feeling,
                              onSelected: (_) =>
                                  setState(() => _feeling = feeling),
                            ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: context.dawaCaption
                                .copyWith(color: DawaColors.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save log'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

IconData _feelingIcon(String feeling) => switch (feeling) {
      'Great' => Icons.sentiment_very_satisfied_rounded,
      'Good' => Icons.sentiment_satisfied_rounded,
      'Okay' => Icons.sentiment_neutral_rounded,
      'Poor' => Icons.sentiment_dissatisfied_rounded,
      _ => Icons.sentiment_very_dissatisfied_rounded,
    };

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _fertileRange(PeriodCycleSummary summary) {
  final start = summary.lastPeriodStart;
  if (start == null) return 'Not set';
  final ovulation =
      start.add(Duration(days: (summary.averageCycleLength ?? 28) - 14));
  return '${DateFormat('d').format(ovulation.subtract(const Duration(days: 5)))}–${DateFormat('d MMM').format(ovulation.add(const Duration(days: 1)))}';
}

String _predictionRange(PeriodCycleSummary summary) {
  final start = summary.predictedWindowStart;
  final end = summary.predictedWindowEnd;
  if (start == null || end == null) return 'Not available';
  if (start.year == end.year && start.month == end.month) {
    return '${DateFormat('d').format(start)}–${DateFormat('d MMM').format(end)}';
  }
  return '${DateFormat('d MMM').format(start)}–${DateFormat('d MMM').format(end)}';
}

String _ordinal(int value) => switch (value) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '${value}th',
    };
