import 'dart:async';
import 'dart:math' as math;

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
import '/design_system/dawa_interactions.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/feedback/dawa_success_feedback.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/features/period_tracker/presentation/dawa_daily_check_in_sheet.dart';
import '/features/pregnancy/presentation/dawa_pregnancy_journey_overview.dart';

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
  _TrackerRoutineFeedback? _routineFeedback;
  Timer? _feedbackTimer;

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
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted || _periodActionBusy) return;
    unawaited(_refreshAfterExternalChange());
  }

  Future<void> _refreshAfterExternalChange() async {
    try {
      await _refresh();
    } catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: 'period_tracker_change',
        stage: 'refresh',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<_CyclePageData> _load() async {
    final results = await Future.wait<dynamic>([
      _service.loadUserSettings(),
      _service.loadPeriodHistory(),
      _profiles.load(),
    ]);
    final settings = results[0] as Map<String, dynamic>?;
    final history = results[1] as List<PeriodRecord>;
    final data = _CyclePageData(
      settings: settings,
      history: history,
      profile: results[2] as HealthProfileSnapshot,
      summary: PeriodCycleSummary.derive(
        now: DateTime.now(),
        settings: settings,
        history: history,
      ),
    );
    return data;
  }

  Future<void> _refresh({bool preserveCurrentOnFailure = false}) async {
    if (!mounted) return;
    final next = _load();
    if (!preserveCurrentOnFailure) {
      setState(() => _data = next);
    }
    try {
      final loaded = await next;
      if (preserveCurrentOnFailure && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _data = Future.value(loaded);
            });
          }
        });
      }
    } catch (_) {
      rethrow;
    }
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
      await _refresh(preserveCurrentOnFailure: true);
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
      _showRoutineFeedback(
        title: 'Check-in saved',
        message:
            'Your health log has been updated for ${DateFormat('d MMMM').format(_selectedDay)}.',
      );
      unawaited(
        DawaSuccessFeedbackController.show(
          context,
          DawaSuccessFeedback.checkInSaved,
        ),
      );
      await _refresh();
    }
  }

  Future<void> _markPeriodStarted(
    _CyclePageData data, {
    DateTime? startDate,
  }) async {
    if (_periodActionBusy) return;
    if (!data.summary.isConfigured) {
      await _setup(data);
      return;
    }
    final today = _dateOnly(DateTime.now());
    final selectedStart = _dateOnly(startDate ?? _selectedDay);
    if (selectedStart.isAfter(today)) {
      _showPeriodError('Choose today or an earlier date to log a period.');
      return;
    }
    setState(() => _periodActionBusy = true);
    var writeConfirmed = false;
    try {
      await _service.savePeriodRecord(startDate: selectedStart);
      writeConfirmed = true;
      if (!mounted) return;
      setState(() {
        _selectedDay = selectedStart;
        _focusedDay = selectedStart;
      });
      _showRoutineFeedback(
        title: 'Period started',
        message:
            "We'll update your cycle from ${DateFormat('d MMMM').format(selectedStart)}.",
        actionLabel: 'Change date',
        onAction: () {
          _changePeriodStartDate(selectedStart);
        },
      );
      unawaited(
        DawaSuccessFeedbackController.show(
          context,
          DawaSuccessFeedback.periodStarted,
        ),
      );
    } on PeriodTrackerPersistenceException catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: error.operation,
        stage: error.stage,
        error: error,
        stackTrace: stackTrace,
      );
      writeConfirmed = error.writeConfirmed;
      if (writeConfirmed && mounted) {
        setState(() {
          _selectedDay = selectedStart;
          _focusedDay = selectedStart;
        });
        _showRoutineFeedback(title: 'Period saved', message: error.message);
      } else if (mounted) {
        _showPeriodError(error.message);
      }
    } on PeriodTrackerException catch (error) {
      if (mounted) _showPeriodError(error.message);
    } catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: 'save_period_record',
        stage: 'unexpected',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showPeriodError('Your period could not be saved. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _periodActionBusy = false);
    }
    if (writeConfirmed && mounted) {
      await _refreshAfterConfirmedPeriodWrite(operation: 'save_period_record');
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
    var writeConfirmed = false;
    try {
      await _service.updatePeriodRecord(
        originalStartDate: originalDate,
        startDate: selected,
      );
      writeConfirmed = true;
      if (!mounted) return;
      setState(() {
        _selectedDay = selected;
        _focusedDay = selected;
      });
      _showRoutineFeedback(
        title: 'Cycle updated',
        message:
            'Your period start is now ${DateFormat('d MMMM').format(selected)}.',
      );
    } on PeriodTrackerPersistenceException catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: error.operation,
        stage: error.stage,
        error: error,
        stackTrace: stackTrace,
      );
      writeConfirmed = error.writeConfirmed;
      if (writeConfirmed && mounted) {
        _showRoutineFeedback(title: 'Period saved', message: error.message);
      } else if (mounted) {
        _showPeriodError(error.message);
      }
    } on PeriodTrackerException catch (error) {
      if (mounted) _showPeriodError(error.message);
    } catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: 'change_period_start',
        stage: 'unexpected',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showPeriodError('The date could not be changed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _periodActionBusy = false);
    }
    if (writeConfirmed && mounted) {
      await _refreshAfterConfirmedPeriodWrite(operation: 'change_period_start');
    }
  }

  Future<void> _markPeriodEnded(_CyclePageData data) async {
    if (_periodActionBusy || data.history.isEmpty) return;
    final latest = [...data.history]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final current = latest.first;
    final today = _dateOnly(DateTime.now());
    final selectedEnd = _dateOnly(_selectedDay);
    if (selectedEnd.isAfter(today)) {
      _showPeriodError('Choose today or an earlier date to end a period.');
      return;
    }
    if (selectedEnd.isBefore(_dateOnly(current.startDate))) {
      _showPeriodError('The period end date cannot be before its start date.');
      return;
    }
    setState(() => _periodActionBusy = true);
    var writeConfirmed = false;
    try {
      await _service.updatePeriodRecord(
        originalStartDate: current.startDate,
        startDate: current.startDate,
        endDate: selectedEnd,
      );
      writeConfirmed = true;
      if (!mounted) return;
      _showRoutineFeedback(
        title: 'Period ended',
        message:
            'Your cycle history has been updated through ${DateFormat('d MMMM').format(selectedEnd)}.',
      );
      unawaited(
        DawaSuccessFeedbackController.show(
          context,
          DawaSuccessFeedback.periodEnded,
        ),
      );
    } on PeriodTrackerPersistenceException catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: error.operation,
        stage: error.stage,
        error: error,
        stackTrace: stackTrace,
      );
      writeConfirmed = error.writeConfirmed;
      if (writeConfirmed && mounted) {
        _showRoutineFeedback(title: 'Period saved', message: error.message);
      } else if (mounted) {
        _showPeriodError(error.message);
      }
    } on PeriodTrackerException catch (error) {
      if (mounted) _showPeriodError(error.message);
    } catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: 'end_period_record',
        stage: 'unexpected',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showPeriodError('Your period could not be saved. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _periodActionBusy = false);
    }
    if (writeConfirmed && mounted) {
      await _refreshAfterConfirmedPeriodWrite(operation: 'end_period_record');
    }
  }

  Future<void> _refreshAfterConfirmedPeriodWrite({
    required String operation,
  }) async {
    try {
      await _refresh(preserveCurrentOnFailure: true);
    } catch (error, stackTrace) {
      _logPeriodDiagnostic(
        operation: operation,
        stage: 'post_write_refresh',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showRoutineFeedback(
          title: 'Period saved',
          message:
              'Your period was saved. We could not refresh the cycle view yet.',
        );
      }
    }
  }

  void _logPeriodDiagnostic({
    required String operation,
    required String stage,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '[CycleTracker] operation=$operation stage=$stage '
      'error_type=${error.runtimeType}',
    );
    debugPrintStack(
      label: '[CycleTracker] $operation/$stage',
      stackTrace: stackTrace,
      maxFrames: 8,
    );
  }

  void _showPeriodError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DawaColors.danger,
      ),
    );
  }

  void _showRoutineFeedback({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _feedbackTimer?.cancel();
    setState(
      () => _routineFeedback = _TrackerRoutineFeedback(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
    _feedbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _routineFeedback = null);
    });
  }

  void _dismissRoutineFeedback() {
    _feedbackTimer?.cancel();
    setState(() => _routineFeedback = null);
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
              child: _buildContent(context, data),
            ),
          );
        },
      );

  Widget _buildLogTodayAction(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          DawaBreakpoints.pagePadding(context),
          DawaSpacing.sm,
          DawaBreakpoints.pagePadding(context),
          0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DawaBreakpoints.isMobile(context) ? 420 : 260,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const ValueKey('cycle-log-today-action'),
                onPressed: _checkIn,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Log today'),
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
          onNotifications: () => context.push('/notifications'),
          onProfile: () => context.go('/settings'),
        ),
        if (_routineFeedback != null) ...[
          const SizedBox(height: DawaSpacing.xs),
          DawaActionFeedback(
            title: _routineFeedback!.title,
            message: _routineFeedback!.message,
            actionLabel: _routineFeedback!.actionLabel,
            onAction: _routineFeedback!.onAction,
            dismissLabel: 'Dismiss',
            onDismiss: _dismissRoutineFeedback,
          ),
        ],
        const SizedBox(height: DawaSpacing.xs),
        _TrackerModeSelector(
          pregnancySelected: _pregnancyTab,
          onChanged: (value) => setState(() => _pregnancyTab = value),
        ),
        const SizedBox(height: DawaSpacing.md),
        if (_pregnancyTab) ...[
          DawaPregnancyJourneyOverview(profile: data.profile),
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
            _CycleVisualOverview(
              summary: summary,
              selectedDay: _selectedDay,
              busy: _periodActionBusy,
              onSelectedDay: (selected) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = selected;
                });
              },
              onPeriodAction: () => summary.isPeriodActive
                  ? _markPeriodEnded(data)
                  : _markPeriodStarted(data, startDate: _selectedDay),
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
                  : '${summary.cycleDay} of ${summary.averageCycleLength ?? 28} days',
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
                  'Use Log today below to record symptoms, pain, mood and a private note.',
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
          DawaCard(
            key: const ValueKey('cycle-pregnancy-journey-card'),
            padding: EdgeInsets.zero,
            color: DawaColors.softPurple,
            borderColor: DawaColors.purple.withValues(alpha: .2),
            child: DawaActionRow(
              icon: Icons.pregnant_woman_rounded,
              color: DawaColors.purple,
              title: 'Pregnancy guidance',
              subtitle: data.profile.pregnancyWeek == null
                  ? 'Clear tips and clinic help for every stage.'
                  : 'Week ${data.profile.pregnancyWeek} • ${_ordinal(data.profile.trimester ?? 1)} trimester',
              onTap: () => context.push('/learn/pregnancy'),
            ),
          ),
          const SizedBox(height: DawaSpacing.sm),
          DawaCard(
            padding: EdgeInsets.zero,
            child: DawaActionRow(
              icon: Icons.settings_outlined,
              title: 'Cycle settings and history',
              subtitle: 'Review dates and adjust your usual cycle.',
              onTap: () => _setup(data),
            ),
          ),
          _buildLogTodayAction(context),
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

class _CycleVisualOverview extends StatelessWidget {
  const _CycleVisualOverview({
    required this.summary,
    required this.selectedDay,
    required this.busy,
    required this.onSelectedDay,
    required this.onPeriodAction,
  });

  final PeriodCycleSummary summary;
  final DateTime selectedDay;
  final bool busy;
  final ValueChanged<DateTime> onSelectedDay;
  final VoidCallback onPeriodAction;

  @override
  Widget build(BuildContext context) {
    final phase = _CyclePhase.fromSummary(summary);
    final cycleLength = summary.averageCycleLength ?? 28;
    final periodLength = summary.averagePeriodLength ?? 5;
    final day = summary.cycleDay ?? 1;
    final actionLabel = summary.isPeriodActive ? 'End period' : 'Log period';

    return Semantics(
      label:
          'Cycle overview. Day $day of $cycleLength. ${phase.label}. ${phase.detail}',
      child: DawaCard(
        key: const ValueKey('cycle-ring-hero'),
        featured: true,
        color: DawaColors.surface,
        borderColor: phase.color.withValues(alpha: .25),
        padding: const EdgeInsets.all(DawaSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                DawaIconBadge(
                  icon: Icons.auto_graph_rounded,
                  color: phase.color,
                  background: phase.color.withValues(alpha: .10),
                  size: 42,
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR CYCLE TODAY',
                          style: context.dawaCaption.copyWith(
                            color: phase.color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .7,
                          )),
                      const SizedBox(height: 2),
                      Text('A clearer view of your cycle',
                          style: context.dawaSectionTitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DawaSpacing.sm),
            _CycleWeekStrip(
              selectedDay: selectedDay,
              onSelected: onSelectedDay,
            ),
            const SizedBox(height: DawaSpacing.xs),
            SizedBox(
              height: 224,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size.square(224),
                      painter: _CycleRingPainter(
                        cycleLength: cycleLength,
                        periodLength: periodLength,
                        cycleDay: day,
                        showFertileWindow: summary.isRegular == true,
                        phaseColor: phase.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          phase.label,
                          textAlign: TextAlign.center,
                          style: context.dawaCaption.copyWith(
                            color: DawaColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day $day',
                          style: context.dawaTitle.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          phase.detail,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.dawaCaption,
                        ),
                        const SizedBox(height: DawaSpacing.sm),
                        SizedBox(
                          width: 152,
                          height: 42,
                          child: KeyedSubtree(
                            key: ValueKey(summary.isPeriodActive
                                ? 'period-end-action'
                                : 'period-start-action'),
                            child: FilledButton.icon(
                              onPressed: busy ? null : onPeriodAction,
                              icon: Icon(summary.isPeriodActive
                                  ? Icons.stop_circle_outlined
                                  : Icons.water_drop_outlined),
                              label: Text(
                                actionLabel,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DawaColors.surface,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DawaSpacing.xs,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: DawaSpacing.sm,
              runSpacing: DawaSpacing.xxs,
              children: [
                _LegendDot(color: DawaColors.pink, label: 'Period'),
                _LegendDot(
                  color: DawaColors.green,
                  label: 'Estimated fertile window',
                ),
                _LegendDot(color: DawaColors.primary, label: 'Today'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleWeekStrip extends StatelessWidget {
  const _CycleWeekStrip({
    required this.selectedDay,
    required this.onSelected,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    return Row(
      children: List<Widget>.generate(7, (index) {
        final date = _dateOnly(selectedDay.add(Duration(days: index - 3)));
        final selected = isSameDay(date, selectedDay);
        final isToday = isSameDay(date, today);
        return Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label:
                '${DateFormat('EEEE, d MMMM').format(date)}${isToday ? ', today' : ''}',
            child: InkWell(
              key: ValueKey(
                  'cycle-week-day-${PeriodTrackerService.formatDateId(date)}'),
              borderRadius: BorderRadius.circular(DawaRadii.medium),
              onTap: () => onSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? DawaColors.primary
                      : isToday
                          ? DawaColors.softBlue
                          : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? DawaColors.primary
                        : isToday
                            ? DawaColors.primary.withValues(alpha: .32)
                            : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(DawaRadii.medium),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: context.dawaCaption.copyWith(
                        color: selected
                            ? DawaColors.surface
                            : DawaColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: context.dawaBody.copyWith(
                        color: selected ? DawaColors.surface : DawaColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CyclePhase {
  const _CyclePhase({
    required this.label,
    required this.detail,
    required this.color,
  });

  final String label;
  final String detail;
  final Color color;

  factory _CyclePhase.fromSummary(PeriodCycleSummary summary) {
    if (summary.isPeriodActive) {
      return const _CyclePhase(
        label: 'Period phase',
        detail: 'Your period is in progress',
        color: DawaColors.pink,
      );
    }
    final cycleLength = summary.averageCycleLength ?? 28;
    final cycleDay = summary.cycleDay ?? 1;
    final ovulationDay = cycleLength - 14;
    if (summary.isRegular == true &&
        cycleDay >= ovulationDay - 5 &&
        cycleDay <= ovulationDay + 1) {
      return const _CyclePhase(
        label: 'Estimated fertile window',
        detail: 'An estimate based on your cycle pattern',
        color: DawaColors.green,
      );
    }
    final days = summary.daysUntilNextPeriod;
    return _CyclePhase(
      label: summary.statusLabel,
      detail: days == null
          ? 'Add more period dates for an estimate'
          : days == 0
              ? 'Your next period is estimated today'
              : 'Next period estimate in $days ${days == 1 ? 'day' : 'days'}',
      color: DawaColors.primary,
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  const _CycleRingPainter({
    required this.cycleLength,
    required this.periodLength,
    required this.cycleDay,
    required this.showFertileWindow,
    required this.phaseColor,
  });

  final int cycleLength;
  final int periodLength;
  final int cycleDay;
  final bool showFertileWindow;
  final Color phaseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 20;
    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final safeCycleLength = cycleLength.clamp(21, 45);
    final dayAngle = 2 * math.pi / safeCycleLength;
    final basePaint = Paint()
      ..color = DawaColors.line.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ringRect, 0, 2 * math.pi, false, basePaint);

    void drawArc(int startDay, int length, Color color) {
      final boundedStart = startDay.clamp(1, safeCycleLength);
      final boundedLength = length.clamp(0, safeCycleLength);
      if (boundedLength == 0) return;
      final paint = Paint()
        ..color = color.withValues(alpha: .84)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        ringRect,
        startAngle + (boundedStart - 1) * dayAngle,
        math.min(boundedLength * dayAngle - .025, 2 * math.pi - .025),
        false,
        paint,
      );
    }

    drawArc(1, periodLength, DawaColors.pink);
    if (showFertileWindow) {
      drawArc(safeCycleLength - 19, 7, DawaColors.green);
    }

    final markerAngle =
        startAngle + ((cycleDay.clamp(1, safeCycleLength) - 1) * dayAngle);
    final markerCenter = Offset(
      center.dx + math.cos(markerAngle) * radius,
      center.dy + math.sin(markerAngle) * radius,
    );
    canvas.drawCircle(
      markerCenter,
      9,
      Paint()..color = DawaColors.surface,
    );
    canvas.drawCircle(markerCenter, 6, Paint()..color = phaseColor);

    for (var day = 1; day <= safeCycleLength; day++) {
      final angle = startAngle + (day - 1) * dayAngle;
      final majorTick = day == 1 || day % 4 == 0 || day == safeCycleLength;
      final tickStart = radius + (majorTick ? 15 : 17);
      final tickEnd = tickStart + (majorTick ? 6 : 3);
      final tickPaint = Paint()
        ..color = DawaColors.textSecondary.withValues(
          alpha: majorTick ? .78 : .34,
        )
        ..strokeWidth = majorTick ? 2.4 : 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * tickStart,
          center.dy + math.sin(angle) * tickStart,
        ),
        Offset(
          center.dx + math.cos(angle) * tickEnd,
          center.dy + math.sin(angle) * tickEnd,
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CycleRingPainter oldDelegate) =>
      cycleLength != oldDelegate.cycleLength ||
      periodLength != oldDelegate.periodLength ||
      cycleDay != oldDelegate.cycleDay ||
      showFertileWindow != oldDelegate.showFertileWindow ||
      phaseColor != oldDelegate.phaseColor;
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
          child: DawaSegmentedControl(
            keyPrefix: 'track-mode',
            selectedIndex: pregnancySelected ? 1 : 0,
            onSelected: (index) => onChanged(index == 1),
            items: const [
              DawaSegmentedItem(label: 'Cycle', icon: Icons.sync_rounded),
              DawaSegmentedItem(
                label: 'Pregnancy',
                icon: Icons.pregnant_woman_rounded,
              ),
            ],
          ),
        ),
      );
}

// Retained temporarily for the existing setup illustration composition while
// the interactive journey lives in its dedicated presentation component.
// ignore: unused_element
class _PregnancyTrackingOverview extends StatelessWidget {
  const _PregnancyTrackingOverview({required this.profile});

  final HealthProfileSnapshot profile;

  @override
  Widget build(BuildContext context) {
    final week = profile.pregnancyWeek;
    final dueDate = profile.calculatedDueDate;
    final configured = profile.pregnancyProfileStatus ==
        PregnancyProfileStatus.pregnantWithData;
    if (!configured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaCard(
            key: const ValueKey('pregnancy-tracking-hero'),
            featured: true,
            showPattern: true,
            color: DawaColors.softPurple,
            borderColor: DawaColors.purple.withValues(alpha: .2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR PREGNANCY',
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: DawaSpacing.xxs),
                      Text('Set up pregnancy tracking',
                          style: context.dawaTitle),
                      const SizedBox(height: DawaSpacing.xs),
                      Text(
                        'Add a last period or due date to see guidance for your stage.',
                        style: context.dawaCaption,
                      ),
                      const SizedBox(height: DawaSpacing.sm),
                      DawaCompactButton(
                        label: 'Add pregnancy details',
                        icon: Icons.arrow_forward_rounded,
                        filled: true,
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DawaSpacing.xs),
                SizedBox(
                  width: 92,
                  height: 132,
                  child: Image.asset(
                    DawaArtwork.pregnancyEarly,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          Text('After setup you’ll see', style: context.dawaSectionTitle),
          const SizedBox(height: DawaSpacing.xs),
          DawaCard(
            padding: const EdgeInsets.symmetric(vertical: DawaSpacing.xxs),
            child: const Column(
              children: [
                _PregnancySetupBenefit(
                  icon: Icons.calendar_today_outlined,
                  title: 'Current pregnancy week',
                ),
                Divider(height: 1),
                _PregnancySetupBenefit(
                  icon: Icons.timelapse_rounded,
                  title: 'Trimester and estimated due date',
                ),
                Divider(height: 1),
                _PregnancySetupBenefit(
                  icon: Icons.menu_book_outlined,
                  title: 'Guidance relevant to your stage',
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.sm),
          DawaCard(
            padding: EdgeInsets.zero,
            child: DawaActionRow(
              icon: Icons.auto_stories_outlined,
              color: DawaColors.purple,
              title: 'What to expect',
              subtitle: 'Read clear guidance for every stage of pregnancy.',
              onTap: () => context.push('/learn/pregnancy'),
            ),
          ),
        ],
      );
    }
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
            DawaMetricTile(
              icon: Icons.calendar_today_outlined,
              label: 'Current week',
              value: 'Week $week',
              color: DawaColors.purple,
            ),
            DawaMetricTile(
              icon: Icons.timelapse_rounded,
              label: 'Trimester',
              value: _ordinal(profile.trimester!),
              color: DawaColors.purple,
            ),
            DawaMetricTile(
              icon: Icons.event_available_outlined,
              label: 'Due date',
              value: DateFormat('d MMM').format(dueDate!),
              color: DawaColors.greenDark,
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

// ignore: unused_element
class _PregnancySetupBenefit extends StatelessWidget {
  const _PregnancySetupBenefit({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DawaSpacing.sm,
          vertical: DawaSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, color: DawaColors.greenDark, size: 20),
            const SizedBox(width: DawaSpacing.sm),
            Expanded(child: Text(title, style: context.dawaBody)),
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
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.all(DawaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cycle outlook', style: context.dawaSectionTitle),
            const SizedBox(height: DawaSpacing.sm),
            _CycleOutlookRow(child: cycleDay),
            const Divider(height: 20, color: DawaColors.line),
            _CycleOutlookRow(child: nextPeriod),
            const Divider(height: 20, color: DawaColors.line),
            _CycleOutlookRow(child: fertileWindow),
          ],
        ),
      );
}

class _CycleOutlookRow extends StatelessWidget {
  const _CycleOutlookRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child is _CycleMetric
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              (child as _CycleMetric).icon,
              color: (child as _CycleMetric).color,
              size: 20,
            ),
            const SizedBox(width: DawaSpacing.sm),
            Expanded(child: child),
          ],
        )
      : child;
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.dawaCaption.copyWith(
              color: DawaColors.ink,
              fontWeight: FontWeight.w600,
            ),
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

class _TrackerRoutineFeedback {
  const _TrackerRoutineFeedback({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
}

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
