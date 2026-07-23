import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/dawa_appointment_reminder_repository.dart';
import '/features/appointments/domain/appointment.dart';

class DawaAppointmentReminderSheet extends StatefulWidget {
  const DawaAppointmentReminderSheet({
    super.key,
    required this.appointment,
    this.repository,
  });

  final Appointment appointment;
  final DawaAppointmentReminderRepository? repository;

  @override
  State<DawaAppointmentReminderSheet> createState() =>
      _DawaAppointmentReminderSheetState();
}

class _DawaAppointmentReminderSheetState
    extends State<DawaAppointmentReminderSheet> {
  late final DawaAppointmentReminderRepository _repository;
  late Future<DawaAppointmentReminder> _future;
  DawaAppointmentReminder? _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaAppointmentReminderRepository();
    _future = _repository.load(widget.appointment.id);
  }

  Future<void> _save() async {
    final value = _value;
    if (value == null || _saving) return;
    setState(() => _saving = true);
    await _repository.save(value);
    if (!mounted) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => DawaBottomSheetFrame(
        child: FutureBuilder<DawaAppointmentReminder>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              );
            }
            final value = _value ?? snapshot.data;
            if (value == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Reminder preferences could not be loaded.'),
              );
            }
            _value ??= value;
            final start = Appointment.dateAtTime(
              widget.appointment.date,
              widget.appointment.startTime,
            );
            return Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const DawaIconBadge(
                          icon: Icons.notifications_active_outlined,
                          color: DawaColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment reminder',
                                style: context.dawaTitle.copyWith(fontSize: 20),
                              ),
                              Text(
                                DateFormat('EEE, d MMM • h:mm a').format(start),
                                style: context.dawaCaption,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remind me'),
                      subtitle: const Text(
                        'Keep a reminder preference for this appointment.',
                      ),
                      value: value.enabled,
                      onChanged: (enabled) => setState(
                          () => _value = value.copyWith(enabled: enabled)),
                    ),
                    if (value.enabled) ...[
                      const SizedBox(height: 8),
                      Text('When', style: context.dawaSectionTitle),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1 day')),
                          ButtonSegment(value: 2, label: Text('2 days')),
                          ButtonSegment(value: 7, label: Text('1 week')),
                        ],
                        selected: {value.daysBefore},
                        onSelectionChanged: (selection) => setState(
                          () => _value =
                              value.copyWith(daysBefore: selection.first),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Channels', style: context.dawaSectionTitle),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('In-app notification'),
                        value: value.appNotification,
                        onChanged: (enabled) => setState(
                          () =>
                              _value = value.copyWith(appNotification: enabled),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('SMS'),
                        subtitle: const Text(
                          'Requires a verified mobile number and server delivery.',
                        ),
                        value: value.smsNotification,
                        onChanged: (enabled) => setState(
                          () =>
                              _value = value.copyWith(smsNotification: enabled),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Email'),
                        subtitle: const Text(
                          'Requires a verified email and server delivery.',
                        ),
                        value: value.emailNotification,
                        onChanged: (enabled) => setState(
                          () => _value =
                              value.copyWith(emailNotification: enabled),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DawaPrimaryButton(
                      label: _saving ? 'Saving…' : 'Save reminder',
                      icon: Icons.check_rounded,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
