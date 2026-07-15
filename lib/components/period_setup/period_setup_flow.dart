import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/backend/period_tracker_service.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';

enum PeriodSetupOutcome { completed, skipped, back }

Future<PeriodSetupOutcome?> showPeriodSetupFlow(
  BuildContext context, {
  bool allowSkip = true,
  bool registration = false,
  PeriodTrackerService? service,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  int initialCycleLength = 28,
  int initialPeriodLength = 5,
  bool initialIsRegular = true,
}) {
  final tracker = service ?? PeriodTrackerService();
  final compact = MediaQuery.sizeOf(context).width < 600;
  return showDialog<PeriodSetupOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      insetPadding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 0 : 20),
      ),
      child: SizedBox(
        width: compact ? double.infinity : 620,
        height: compact ? double.infinity : null,
        child: PeriodSetupForm(
          registration: registration,
          allowSkip: allowSkip,
          initialStartDate: initialStartDate,
          initialEndDate: initialEndDate,
          initialCycleLength: initialCycleLength,
          initialPeriodLength: initialPeriodLength,
          initialIsRegular: initialIsRegular,
          onBack: () => Navigator.pop(
            dialogContext,
            PeriodSetupOutcome.back,
          ),
          onSkip: () async {
            await tracker.markSetupSkipped();
            HealthProfileRepository.notifyChanged();
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext, PeriodSetupOutcome.skipped);
            }
          },
          onSave: ({
            required startDate,
            required endDate,
            required cycleLength,
            required periodLength,
            required isRegular,
          }) async {
            await tracker.saveUserSettings(
              averageCycleLength: cycleLength,
              periodLength: periodLength,
              isRegular: isRegular,
              lastPeriodStart: startDate,
            );
            await tracker.savePeriodRecord(
              startDate: startDate,
              endDate: endDate,
            );
            HealthProfileRepository.notifyChanged();
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext, PeriodSetupOutcome.completed);
            }
          },
        ),
      ),
    ),
  );
}

typedef PeriodSetupSave = Future<void> Function({
  required DateTime startDate,
  required DateTime? endDate,
  required int cycleLength,
  required int periodLength,
  required bool isRegular,
});

class PeriodSetupForm extends StatefulWidget {
  const PeriodSetupForm({
    super.key,
    required this.onSave,
    required this.onBack,
    this.onSkip,
    this.allowSkip = true,
    this.registration = false,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCycleLength = 28,
    this.initialPeriodLength = 5,
    this.initialIsRegular = true,
  });

  final PeriodSetupSave onSave;
  final Future<void> Function()? onSkip;
  final VoidCallback onBack;
  final bool allowSkip;
  final bool registration;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int initialCycleLength;
  final int initialPeriodLength;
  final bool initialIsRegular;

  @override
  State<PeriodSetupForm> createState() => _PeriodSetupFormState();
}

class _PeriodSetupFormState extends State<PeriodSetupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cycleController;
  late final TextEditingController _periodController;
  DateTime? _startDate;
  DateTime? _endDate;
  late bool _isRegular;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _isRegular = widget.initialIsRegular;
    _cycleController =
        TextEditingController(text: '${widget.initialCycleLength}');
    _periodController =
        TextEditingController(text: '${widget.initialPeriodLength}');
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _chooseStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate?.isBefore(_startDate!) == true) _endDate = null;
      _error = null;
    });
  }

  Future<void> _chooseEnd() async {
    final now = DateTime.now();
    final start = _startDate;
    if (start == null) {
      setState(() => _error = 'Choose the period start date first.');
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: now.isBefore(start) ? start : now,
    );
    if (picked == null) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_startDate == null) {
      setState(() => _error = 'Add your last period start date.');
      return;
    }
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        startDate: _startDate!,
        endDate: _endDate,
        cycleLength: int.parse(_cycleController.text),
        periodLength: int.parse(_periodController.text),
        isRegular: _isRegular,
      );
    } on PeriodTrackerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Your Period Tracker could not be saved. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skip() async {
    final onSkip = widget.onSkip;
    if (onSkip == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await onSkip();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Your choice could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SafeArea(
      child: Column(
        children: [
          if (_saving) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: _saving ? null : widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.registration
                                ? 'Set up your Period Tracker'
                                : 'Period Tracker setup',
                            style: theme.headlineSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Add your recent period information to receive cycle and period estimates. You can skip this and complete it later.',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DateField(
                      label: 'Last period start date',
                      value: _startDate,
                      required: true,
                      onTap: _saving ? null : _chooseStart,
                    ),
                    const SizedBox(height: 14),
                    _DateField(
                      label: 'Last period end date',
                      value: _endDate,
                      onTap: _saving ? null : _chooseEnd,
                      onClear: _endDate == null
                          ? null
                          : () => setState(() => _endDate = null),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          TextFormField(
                            key: const ValueKey('period-cycle-length'),
                            controller: _cycleController,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Average cycle length',
                              helperText: 'Optional if known; 28 is common',
                              suffixText: 'days',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = int.tryParse(value ?? '');
                              if (number == null ||
                                  number < 15 ||
                                  number > 60) {
                                return 'Use 15 to 60 days.';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            key: const ValueKey('period-duration'),
                            controller: _periodController,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Average period duration',
                              helperText: 'Optional if known; 5 is common',
                              suffixText: 'days',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final number = int.tryParse(value ?? '');
                              final cycle = int.tryParse(_cycleController.text);
                              if (number == null || number < 1 || number > 15) {
                                return 'Use 1 to 15 days.';
                              }
                              if (cycle != null && number >= cycle) {
                                return 'Must be shorter than the cycle.';
                              }
                              return null;
                            },
                          ),
                        ];
                        if (constraints.maxWidth >= 520) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 14),
                              Expanded(child: fields[1]),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            fields[0],
                            const SizedBox(height: 14),
                            fields[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cycles are usually regular'),
                      subtitle: const Text(
                        'Turn this off if cycle length varies considerably.',
                      ),
                      value: _isRegular,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _isRegular = value),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              border: Border(top: BorderSide(color: theme.alternate)),
            ),
            child: Row(
              children: [
                if (widget.allowSkip)
                  TextButton(
                    key: const ValueKey('skip-period-setup'),
                    onPressed: _saving ? null : _skip,
                    child: const Text('Skip for now'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('continue-period-setup'),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue'),
                  style: FilledButton.styleFrom(backgroundColor: theme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final bool required;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label${required ? ' *' : ' (optional)'}'),
          const SizedBox(height: 7),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: onClear == null
                      ? const Icon(Icons.arrow_drop_down_rounded)
                      : IconButton(
                          tooltip: 'Clear $label',
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                child: Text(
                  value == null
                      ? 'Choose date'
                      : DateFormat('d MMMM y').format(value!),
                ),
              ),
            ),
          ),
        ],
      );
}
