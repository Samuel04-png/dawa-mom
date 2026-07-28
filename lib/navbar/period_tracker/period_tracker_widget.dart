import '/localization/dawa_localized_material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/backend/period_tracker_service.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/components/responsive/responsive_layout.dart';
import '/design_system/dawa_components.dart';
import '/flutter_flow/flutter_flow_theme.dart';

export 'period_tracker_model.dart';

class PeriodTrackerWidget extends StatefulWidget {
  const PeriodTrackerWidget({super.key});

  static const String routeName = 'PeriodTracker';
  static const String routePath = '/periodTracker';

  @override
  State<PeriodTrackerWidget> createState() => _PeriodTrackerWidgetState();
}

class _PeriodTrackerWidgetState extends State<PeriodTrackerWidget> {
  static const _availableSymptoms = <String>[
    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Back pain',
    'Mood changes',
    'Breast tenderness',
    'Nausea',
  ];

  final _service = PeriodTrackerService();
  final _notesController = TextEditingController();

  DateTime _focusedDay = _normalize(DateTime.now());
  DateTime _selectedDay = _normalize(DateTime.now());
  DateTime? _lastPeriodStart;
  int _averageCycleLength = 28;
  int _periodLength = 5;
  bool _isRegular = true;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<PeriodRecord> _periodHistory = const [];

  final Map<DateTime, List<String>> _symptoms = {};
  final Map<DateTime, List<String>> _notes = {};
  final Map<DateTime, List<Map<String, dynamic>>> _sexualActivity = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await _service.loadUserSettings();
      if (settings != null) {
        _averageCycleLength = settings['averageCycleLength'] as int? ?? 28;
        _periodLength = settings['periodLength'] as int? ?? 5;
        _isRegular = settings['isRegular'] as bool? ?? true;
        _lastPeriodStart = settings['lastPeriodStart'] is DateTime
            ? _normalize(settings['lastPeriodStart'] as DateTime)
            : null;
        if (_lastPeriodStart != null) {
          _selectedDay = _lastPeriodStart!;
          _focusedDay = _lastPeriodStart!;
        }
      }
      _periodHistory = await _service.loadPeriodHistory();
      await _loadMonth(_focusedDay, notify: false);
      _syncTodayNotes();
      if (!mounted) return;
      setState(() => _loading = false);
    } on PeriodTrackerException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Your cycle data could not be loaded. Please try again.';
      });
    }
  }

  Future<void> _loadMonth(DateTime month, {bool notify = true}) async {
    final start = DateTime(month.year, month.month - 1, 1);
    final end = DateTime(month.year, month.month + 2, 0);
    try {
      final entries = await _service.loadDateRangeData(start, end);
      for (final entry in entries) {
        final date = entry['date'];
        if (date is! DateTime) continue;
        final key = _normalize(date);
        _symptoms[key] = List<String>.from(entry['symptoms'] ?? const []);
        _notes[key] = List<String>.from(entry['notes'] ?? const []);
        _sexualActivity[key] = (entry['sexualActivity'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      if (notify && mounted) setState(() {});
    } catch (_) {
      if (notify && mounted) {
        _showMessage(
          'Some calendar details could not be refreshed.',
          isError: true,
        );
      }
    }
  }

  void _syncTodayNotes() {
    final todayNotes = _notes[_normalize(DateTime.now())] ?? const [];
    _notesController.text = todayNotes.join('\n');
  }

  Future<void> _saveSettings({bool showSuccess = false}) async {
    setState(() => _saving = true);
    try {
      await _service.saveUserSettings(
        averageCycleLength: _averageCycleLength,
        periodLength: _periodLength,
        isRegular: _isRegular,
        lastPeriodStart: _lastPeriodStart,
      );
      if (showSuccess && mounted) {
        _showMessage('Cycle settings saved');
      }
    } on PeriodTrackerException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Your cycle settings could not be saved. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDaily(DateTime date, {String? successMessage}) async {
    final key = _normalize(date);
    setState(() => _saving = true);
    try {
      await _service.saveDailyData(
        date: key,
        symptoms: _symptoms[key] ?? const [],
        notes: _notes[key] ?? const [],
        sexualActivity: _sexualActivity[key] ?? const [],
      );
      if (mounted && successMessage != null) _showMessage(successMessage);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Today’s cycle details could not be saved. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markSelectedAsPeriodStart() async {
    final today = _normalize(DateTime.now());
    if (_selectedDay.isAfter(today)) {
      _showMessage('A period start cannot be in the future.', isError: true);
      return;
    }
    setState(() => _lastPeriodStart = _normalize(_selectedDay));
    await _saveSettings(showSuccess: true);
    final history = await _service.loadPeriodHistory();
    if (mounted) setState(() => _periodHistory = history);
  }

  Future<void> _showPeriodSetup() async {
    final result = await showPeriodSetupFlow(
      context,
      allowSkip: true,
      initialStartDate: _lastPeriodStart,
      initialCycleLength: _averageCycleLength,
      initialPeriodLength: _periodLength,
      initialIsRegular: _isRegular,
    );
    if (result != null && result != PeriodSetupOutcome.back && mounted) {
      await _load();
    }
  }

  Future<void> _saveNotes() async {
    final today = _normalize(DateTime.now());
    final value = _notesController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _notes.remove(today);
      } else {
        _notes[today] = [value];
      }
    });
    await _saveDaily(today, successMessage: 'Today’s notes saved');
  }

  void _showMessage(String message, {bool isError = false}) {
    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? theme.error : theme.success,
        ),
      );
  }

  DateTime? get _nextPredictedPeriod => _lastPeriodStart == null
      ? null
      : _lastPeriodStart!.add(Duration(days: _averageCycleLength));

  DateTime? get _ovulationEstimate =>
      !_isRegular || _nextPredictedPeriod == null
          ? null
          : _nextPredictedPeriod!.subtract(const Duration(days: 14));

  List<DateTime> get _periodDays => _lastPeriodStart == null
      ? const []
      : List.generate(
          _periodLength,
          (index) => _lastPeriodStart!.add(Duration(days: index)),
        );

  List<DateTime> get _fertileDays {
    final ovulation = _ovulationEstimate;
    if (ovulation == null) return const [];
    return List.generate(
      6,
      (index) => ovulation.subtract(Duration(days: 5 - index)),
    );
  }

  bool get _isLate {
    final next = _nextPredictedPeriod;
    if (!_isRegular || next == null) return false;
    return _normalize(DateTime.now())
        .isAfter(next.add(const Duration(days: 3)));
  }

  int? get _cycleDay {
    if (_lastPeriodStart == null) return null;
    final day =
        _normalize(DateTime.now()).difference(_lastPeriodStart!).inDays + 1;
    return day > 0 ? day : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        title: Text(
          'Period Tracker',
          style: theme.headlineSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Cycle settings',
            onPressed: _saving ? null : _showSettingsDialog,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'About cycle estimates',
            onPressed: _showInformation,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  DawaLoadingSkeleton(lines: 3),
                  SizedBox(height: 12),
                  DawaLoadingSkeleton(lines: 2),
                ],
              ),
            )
          : _loadError != null
              ? _LoadError(message: _loadError!, onRetry: _load)
              : _lastPeriodStart == null
                  ? _PeriodTrackerEmptyState(onSetup: _showPeriodSetup)
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          child: ResponsivePageContainer(
                            maxWidth: 1180,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 880;
                                final calendar = _CalendarCard(
                                  focusedDay: _focusedDay,
                                  selectedDay: _selectedDay,
                                  lastPeriodStart: _lastPeriodStart,
                                  periodDays: _periodDays,
                                  fertileDays: _fertileDays,
                                  ovulationDay: _ovulationEstimate,
                                  eventLoader: _eventsForDay,
                                  dayBuilder: _buildDayCell,
                                  onDaySelected: (selected, focused) {
                                    setState(() {
                                      _selectedDay = _normalize(selected);
                                      _focusedDay = focused;
                                    });
                                  },
                                  onPageChanged: (focused) {
                                    setState(() => _focusedDay = focused);
                                    _loadMonth(focused);
                                  },
                                  onMarkPeriodStart: _saving
                                      ? null
                                      : _markSelectedAsPeriodStart,
                                );
                                final summary = _buildSummaryColumn();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildOverviewCard(),
                                    const SizedBox(height: 18),
                                    if (wide)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 3, child: calendar),
                                          const SizedBox(width: 18),
                                          Expanded(flex: 2, child: summary),
                                        ],
                                      )
                                    else ...[
                                      calendar,
                                      const SizedBox(height: 18),
                                      summary,
                                    ],
                                    const SizedBox(height: 18),
                                    _buildTodayCard(),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        if (_saving)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildOverviewCard() {
    final theme = FlutterFlowTheme.of(context);
    final next = _nextPredictedPeriod;
    final daysUntil = next?.difference(_normalize(DateTime.now())).inDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _isLate ? const Color(0xFF9F2337) : theme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        children: [
          SizedBox(
            width: 230,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current cycle',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  _cycleDay == null ? 'Not set up' : 'Day $_cycleDay',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _lastPeriodStart == null
                      ? 'Choose a date below to start tracking'
                      : 'Last period: ${DateFormat('d MMM y').format(_lastPeriodStart!)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next period estimate',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  !_isRegular
                      ? 'Hidden for irregular cycles'
                      : next == null
                          ? 'Add a period start'
                          : DateFormat('d MMMM').format(next),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLate)
                  const Text(
                    'Your period may be late',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (daysUntil != null && daysUntil >= 0 && _isRegular)
                  Text(
                    '$daysUntil days away • estimate only',
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn() {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        DawaMomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cycle summary',
                style: theme.titleSmall.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                icon: Icons.sync_rounded,
                label: 'Average cycle',
                value: '$_averageCycleLength days',
              ),
              _SummaryRow(
                icon: Icons.water_drop_outlined,
                label: 'Typical period',
                value: '$_periodLength days',
              ),
              _SummaryRow(
                icon: Icons.timeline_rounded,
                label: 'Cycle pattern',
                value: _isRegular ? 'Regular' : 'Irregular',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        DawaMomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar legend',
                style: theme.titleSmall.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const _LegendItem(color: Color(0xFFFF6B6B), label: 'Period'),
              if (_isRegular) ...[
                const _LegendItem(
                  color: Color(0xFF4ECDC4),
                  label: 'Estimated fertile window',
                ),
                const _LegendItem(
                  color: Color(0xFF9D4EDD),
                  label: 'Estimated ovulation',
                ),
              ],
              const _LegendItem(
                color: Color(0xFF1945CD),
                label: 'Saved daily details',
              ),
              const SizedBox(height: 10),
              Text(
                'Predictions are estimates and should not be used as contraception or a diagnosis.',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildHistoryCard(),
      ],
    );
  }

  Widget _buildHistoryCard() {
    final theme = FlutterFlowTheme.of(context);
    return DawaMomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recorded cycle history',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _saving ? null : _showPeriodSetup,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add period'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_periodHistory.isEmpty)
            Text(
              'No recorded periods yet.',
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            )
          else
            ..._periodHistory.take(6).map(
                  (record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.water_drop_outlined),
                    title:
                        Text(DateFormat('d MMMM y').format(record.startDate)),
                    subtitle: Text(
                      record.endDate == null
                          ? 'End date not recorded'
                          : 'Ended ${DateFormat('d MMM y').format(record.endDate!)}',
                    ),
                    trailing: PopupMenuButton<_HistoryAction>(
                      tooltip: 'Period record actions',
                      onSelected: (action) {
                        switch (action) {
                          case _HistoryAction.edit:
                            _editPeriodRecord(record);
                          case _HistoryAction.delete:
                            _deletePeriodRecord(record);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _HistoryAction.edit,
                          child: Text('Edit record'),
                        ),
                        PopupMenuItem(
                          value: _HistoryAction.delete,
                          child: Text('Delete record'),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _editPeriodRecord(PeriodRecord record) async {
    final result = await showDialog<PeriodRecord>(
      context: context,
      builder: (context) => _PeriodRecordDialog(record: record),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _service.updatePeriodRecord(
        originalStartDate: record.startDate,
        startDate: result.startDate,
        endDate: result.endDate,
      );
      await _load();
      if (mounted) _showMessage('Period record updated');
    } on PeriodTrackerException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showMessage('The period record could not be updated.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePeriodRecord(PeriodRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete period record?'),
        content: Text(
          'Delete the period recorded on ${DateFormat('d MMMM y').format(record.startDate)}? Daily symptoms and notes will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep record'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _service.deletePeriodRecord(record.startDate);
      await _load();
      if (mounted) _showMessage('Period record deleted');
    } catch (_) {
      if (mounted) {
        _showMessage('The period record could not be deleted.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildTodayCard() {
    final theme = FlutterFlowTheme.of(context);
    final today = _normalize(DateTime.now());
    final todaySymptoms = _symptoms[today] ?? const [];
    final activities = _sexualActivity[today] ?? const [];
    return DawaMomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: 'Today',
            subtitle: DateFormat('EEEE, d MMMM').format(today),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _showSymptomDialog,
                icon: const Icon(Icons.health_and_safety_outlined),
                label: Text(
                  todaySymptoms.isEmpty
                      ? 'Add symptoms'
                      : '${todaySymptoms.length} symptoms',
                ),
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _showSexualActivityDialog,
                icon: const Icon(Icons.favorite_border_rounded),
                label: Text(
                  activities.isEmpty
                      ? 'Log sexual activity'
                      : '${activities.length} activities',
                ),
              ),
            ],
          ),
          if (todaySymptoms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: todaySymptoms
                  .map(
                    (symptom) => Chip(
                      label: Text(symptom),
                      backgroundColor: theme.primary.withValues(alpha: 0.08),
                      side: BorderSide(
                          color: theme.primary.withValues(alpha: 0.2)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...activities.map((activity) {
              final time = activity['time'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 17,
                      color: activity['protected'] == true
                          ? theme.success
                          : theme.error,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${time is DateTime ? DateFormat.jm().format(time) : 'Today'} • '
                      '${activity['protected'] == true ? 'Protected' : 'Unprotected'}',
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Notes for today',
              hintText:
                  'Mood, flow intensity, or anything you want to remember',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveNotes,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save notes'),
              style: FilledButton.styleFrom(backgroundColor: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _eventsForDay(DateTime day) {
    final key = _normalize(day);
    final events = <String>[];
    if ((_symptoms[key] ?? const []).isNotEmpty) events.add('symptoms');
    if ((_notes[key] ?? const []).isNotEmpty) events.add('notes');
    if ((_sexualActivity[key] ?? const []).isNotEmpty) events.add('activity');
    return events;
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    bool selected = false,
    bool outside = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final isPeriod = _periodDays.any((value) => isSameDay(value, day));
    final isOvulation = isSameDay(_ovulationEstimate, day);
    final isFertile = _fertileDays.any((value) => isSameDay(value, day));
    Color background = Colors.transparent;
    if (isPeriod) {
      background = const Color(0xFFFF6B6B).withValues(alpha: 0.22);
    } else if (isOvulation) {
      background = const Color(0xFF9D4EDD).withValues(alpha: 0.2);
    } else if (isFertile) {
      background = const Color(0xFF4ECDC4).withValues(alpha: 0.2);
    }
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? theme.primary : Colors.transparent,
          width: selected ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: outside
              ? theme.secondaryText.withValues(alpha: 0.55)
              : theme.primaryText,
          fontWeight: isSameDay(day, DateTime.now())
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    final cycle = TextEditingController(text: '$_averageCycleLength');
    final period = TextEditingController(text: '$_periodLength');
    final formKey = GlobalKey<FormState>();
    var regular = _isRegular;
    final result = await showDialog<_SettingsResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cycle settings'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cycle,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Average cycle length (days)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      if (number == null || number < 15 || number > 60) {
                        return context.tr('Enter a number from 15 to 60.');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: period,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Period length (days)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      final cycleNumber = int.tryParse(cycle.text);
                      if (number == null || number < 1 || number > 15) {
                        return context.tr('Enter a number from 1 to 15.');
                      }
                      if (cycleNumber != null && number >= cycleNumber) {
                        return context
                            .tr('Must be shorter than the cycle length.');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Regular cycle'),
                    subtitle: const Text(
                      'Turn off to hide fertile-window estimates.',
                    ),
                    value: regular,
                    onChanged: (value) => setDialogState(() => regular = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(
                  dialogContext,
                  _SettingsResult(
                    cycleLength: int.parse(cycle.text),
                    periodLength: int.parse(period.text),
                    isRegular: regular,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    cycle.dispose();
    period.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _averageCycleLength = result.cycleLength;
      _periodLength = result.periodLength;
      _isRegular = result.isRegular;
    });
    await _saveSettings(showSuccess: true);
  }

  Future<void> _showSymptomDialog() async {
    final today = _normalize(DateTime.now());
    final selected = Set<String>.from(_symptoms[today] ?? const []);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Symptoms today'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _availableSymptoms
                    .map(
                      (symptom) => CheckboxListTile(
                        value: selected.contains(symptom),
                        title: Text(symptom),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() {
                          value == true
                              ? selected.add(symptom)
                              : selected.remove(symptom);
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _symptoms[today] = result.toList());
    await _saveDaily(today, successMessage: 'Symptoms saved');
  }

  Future<void> _showSexualActivityDialog() async {
    final protected = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log sexual activity'),
        content: const Text('Was protection used?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (protected == null || !mounted) return;
    final today = _normalize(DateTime.now());
    setState(() {
      _sexualActivity.putIfAbsent(today, () => []);
      _sexualActivity[today]!.add({
        'protected': protected,
        'time': DateTime.now(),
      });
    });
    await _saveDaily(today, successMessage: 'Activity saved');
  }

  Future<void> _showInformation() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About cycle estimates'),
        content: const Text(
          'DawaMom estimates future cycle dates from the information you enter. '
          'Cycles can change, and these estimates should not be used as contraception '
          'or to diagnose a health condition. Speak with a healthcare professional if '
          'you are concerned about a late, missed, or unusual period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.lastPeriodStart,
    required this.periodDays,
    required this.fertileDays,
    required this.ovulationDay,
    required this.eventLoader,
    required this.dayBuilder,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onMarkPeriodStart,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final DateTime? lastPeriodStart;
  final List<DateTime> periodDays;
  final List<DateTime> fertileDays;
  final DateTime? ovulationDay;
  final List<String> Function(DateTime) eventLoader;
  final Widget Function(
    BuildContext,
    DateTime,
    DateTime, {
    bool selected,
    bool outside,
  }) dayBuilder;
  final void Function(DateTime, DateTime) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final VoidCallback? onMarkPeriodStart;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final today = DateTime.now();
    return DawaMomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle calendar',
            style: theme.titleSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TableCalendar<String>(
            firstDay: DateTime(today.year - 5),
            lastDay: DateTime(today.year + 1, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            enabledDayPredicate: (day) => !day.isAfter(
              DateTime(today.year, today.month, today.day),
            ),
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            eventLoader: eventLoader,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            rowHeight: 48,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              markerDecoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              disabledTextStyle: TextStyle(
                color: theme.secondaryText.withValues(alpha: 0.45),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: dayBuilder,
              todayBuilder: (context, day, focused) =>
                  dayBuilder(context, day, focused),
              selectedBuilder: (context, day, focused) =>
                  dayBuilder(context, day, focused, selected: true),
              outsideBuilder: (context, day, focused) =>
                  dayBuilder(context, day, focused, outside: true),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastPeriodStart != null &&
                          isSameDay(lastPeriodStart, selectedDay)
                      ? 'Current period start: ${DateFormat('d MMM y').format(selectedDay)}'
                      : 'Selected: ${DateFormat('d MMM y').format(selectedDay)}',
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ),
              FilledButton.icon(
                onPressed: onMarkPeriodStart,
                icon: const Icon(Icons.water_drop_outlined, size: 18),
                label: const Text('Mark period start'),
                style: FilledButton.styleFrom(backgroundColor: theme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: theme.bodyMedium)),
          Text(
            value,
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(label)),
          ],
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class _PeriodTrackerEmptyState extends StatelessWidget {
  const _PeriodTrackerEmptyState({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: ResponsivePageContainer(
          maxWidth: 760,
          child: DawaMomEmptyState(
            icon: Icons.water_drop_outlined,
            title: 'Your Period Tracker is not set up.',
            description:
                'Add your latest period to begin receiving cycle estimates.',
            actionLabel: 'Set Up Period Tracker',
            onAction: onSetup,
          ),
        ),
      );
}

enum _HistoryAction { edit, delete }

class _PeriodRecordDialog extends StatefulWidget {
  const _PeriodRecordDialog({required this.record});

  final PeriodRecord record;

  @override
  State<_PeriodRecordDialog> createState() => _PeriodRecordDialogState();
}

class _PeriodRecordDialogState extends State<_PeriodRecordDialog> {
  late DateTime _startDate;
  DateTime? _endDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDate = widget.record.startDate;
    _endDate = widget.record.endDate;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: context.tr('Choose period start date'),
      cancelText: context.tr('Cancel'),
      confirmText: context.tr('Save'),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate?.isBefore(picked) == true) _endDate = null;
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: now,
      helpText: context.tr('Choose period end date'),
      cancelText: context.tr('Cancel'),
      confirmText: context.tr('Save'),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit period record'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Start date'),
                subtitle: Text(DateFormat('d MMMM y').format(_startDate)),
                onTap: _pickStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('End date'),
                subtitle: Text(
                  _endDate == null
                      ? 'Not recorded'
                      : DateFormat('d MMMM y').format(_endDate!),
                ),
                trailing: _endDate == null
                    ? null
                    : IconButton(
                        tooltip: 'Clear end date',
                        onPressed: () => setState(() => _endDate = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                onTap: _pickEnd,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_endDate?.isBefore(_startDate) == true) {
                setState(
                    () => _error = 'End date cannot be before start date.');
                return;
              }
              Navigator.pop(
                context,
                PeriodRecord(startDate: _startDate, endDate: _endDate),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
}

class _SettingsResult {
  const _SettingsResult({
    required this.cycleLength,
    required this.periodLength,
    required this.isRegular,
  });

  final int cycleLength;
  final int periodLength;
  final bool isRegular;
}
