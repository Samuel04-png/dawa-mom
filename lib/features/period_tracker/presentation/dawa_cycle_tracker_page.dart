import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/backend/period_tracker_service.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/design_system/dawa_components.dart';
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

  @override
  Widget build(BuildContext context) => FutureBuilder<_CyclePageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const DawaPageScaffold(
              scrollable: false,
              child: Center(child: CircularProgressIndicator()),
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

  Widget _buildContent(BuildContext context, _CyclePageData data) {
    final summary = data.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaAppHeader(
          title: 'Track your cycle',
          notificationUnread: true,
          onNotifications: () => context.push('/notifications'),
          onProfile: () => context.go('/settings'),
        ),
        const SizedBox(height: 7),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.sync_rounded),
                  label: Text('Cycle'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.pregnant_woman_rounded),
                  label: Text('Pregnancy'),
                ),
              ],
              selected: {_pregnancyTab},
              onSelectionChanged: (value) =>
                  setState(() => _pregnancyTab = value.first),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_pregnancyTab) ...[
          _PregnancyTrackingOverview(profile: data.profile),
        ] else ...[
          if (!summary.isConfigured) ...[
            DawaCard(
              color: DawaColors.softBlue,
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 110,
                    child: Image.asset(
                      DawaArtwork.cycleCalendar,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
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
          ],
          DawaCard(
            padding: const EdgeInsets.all(12),
            child: TableCalendar<void>(
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
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: context.dawaSectionTitle,
                leftChevronIcon: const Icon(Icons.chevron_left_rounded,
                    color: DawaColors.primary),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded,
                    color: DawaColors.primary),
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
                defaultTextStyle:
                    const TextStyle(color: DawaColors.ink, fontSize: 11),
                weekendTextStyle:
                    const TextStyle(color: DawaColors.ink, fontSize: 11),
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
          ),
          const SizedBox(height: 7),
          const Wrap(
            spacing: 14,
            runSpacing: 5,
            children: [
              _LegendDot(color: DawaColors.pink, label: 'Period'),
              _LegendDot(color: DawaColors.green, label: 'Fertile window'),
              _LegendDot(color: DawaColors.primary, label: 'Today'),
            ],
          ),
          const SizedBox(height: 12),
          DawaResponsiveGrid(
            mobileColumns: 3,
            tabletColumns: 3,
            desktopColumns: 3,
            spacing: 8,
            children: [
              _CycleMetric(
                icon: Icons.water_drop_rounded,
                color: DawaColors.pink,
                label: 'Next period',
                value: summary.daysUntilNextPeriod == null
                    ? 'Not set'
                    : '${summary.daysUntilNextPeriod} days',
                helper: summary.nextPeriodEstimate == null
                    ? 'Set up tracker'
                    : DateFormat('d–MMM').format(summary.nextPeriodEstimate!),
              ),
              _CycleMetric(
                icon: Icons.sync_rounded,
                color: DawaColors.purple,
                label: 'Cycle day',
                value: summary.cycleDay == null
                    ? '—'
                    : '${summary.cycleDay} / ${summary.averageCycleLength ?? 28}',
                helper: summary.statusLabel,
              ),
              _CycleMetric(
                icon: Icons.eco_outlined,
                color: DawaColors.green,
                label: 'Fertile window',
                value: summary.lastPeriodStart == null
                    ? 'Not set'
                    : _fertileRange(summary),
                helper: summary.confidenceLabel,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: FilledButton(
                    onPressed: _checkIn,
                    child: const Text('Log today'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DawaCard(
            color: DawaColors.softBlue,
            onTap: () => context.push('/learn/pregnancy'),
            semanticLabel: data.profile.pregnancyWeek == null
                ? 'Open pregnancy guides'
                : 'Pregnancy journey week ${data.profile.pregnancyWeek}',
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 110,
                  child: Image.asset(
                    data.profile.pregnancyWeek == null
                        ? DawaArtwork.pregnancyEarly
                        : DawaArtwork.pregnancyPhone,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pregnancy journey', style: context.dawaCaption),
                      Text(
                        data.profile.pregnancyWeek == null
                            ? 'Guides for every stage'
                            : 'Week ${data.profile.pregnancyWeek} ♥',
                        style: context.dawaTitle,
                      ),
                      Text(
                        data.profile.trimester == null
                            ? 'Trusted information and clinic guidance'
                            : '${data.profile.trimester} trimester',
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
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
        DawaCard(
          color: DawaColors.softBlue,
          padding: const EdgeInsets.fromLTRB(18, 18, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DawaStatusPill(
                      label: 'Pregnancy journey',
                      icon: Icons.favorite_rounded,
                      color: DawaColors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      week == null ? 'Set up your journey' : 'Week $week',
                      style: context.dawaDisplay.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.trimester == null
                          ? 'Add pregnancy dates for personalised guidance.'
                          : 'Trimester ${profile.trimester}',
                      style: context.dawaBody,
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Estimated due date: ${DateFormat('d MMMM y').format(dueDate)}',
                        style: context.dawaCaption,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 128,
                height: 180,
                child: Image.asset(
                  week == null
                      ? DawaArtwork.pregnancyEarly
                      : DawaArtwork.pregnancyPhone,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
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
              value: week?.toString() ?? '—',
            ),
            _PregnancyMetric(
              icon: Icons.timelapse_rounded,
              label: 'Trimester',
              value: profile.trimester?.toString() ?? '—',
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
              const DawaIconBadge(
                icon: Icons.menu_book_outlined,
                color: DawaColors.primary,
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
                          ? 'Read guidance matched to this stage of pregnancy.'
                          : 'Explore trusted guidance for every pregnancy stage.',
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
        const SizedBox(height: 12),
        DawaPrimaryButton(
          label:
              configured ? 'Update pregnancy details' : 'Add pregnancy details',
          icon: Icons.edit_outlined,
          onPressed: () => context.push('/settings'),
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
          Text(label, style: context.dawaCaption),
        ],
      );
}

class _CycleMetric extends StatelessWidget {
  const _CycleMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        child: Column(
          children: [
            DawaIconBadge(icon: icon, color: color, size: 38),
            const SizedBox(height: 5),
            Text(label,
                textAlign: TextAlign.center, style: context.dawaCaption),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.dawaSectionTitle.copyWith(color: color),
            ),
            Text(
              helper,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.dawaCaption.copyWith(fontSize: 9),
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  decoration: const InputDecoration(
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
                          color: feeling == 'Poor' || feeling == 'Very poor'
                              ? DawaColors.danger
                              : DawaColors.green,
                          size: 17,
                        ),
                        label: Text(feeling),
                        selected: _feeling == feeling,
                        onSelected: (_) => setState(() => _feeling = feeling),
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
                const SizedBox(height: 14),
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
