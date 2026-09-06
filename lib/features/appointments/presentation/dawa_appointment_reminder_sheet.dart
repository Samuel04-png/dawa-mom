import '/localization/dawa_localized_material.dart';
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: FutureBuilder<DawaAppointmentReminder>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DawaLoadingSkeleton(
                  label: 'Loading your reminder',
                  lines: 4,
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              'Choose when and how you want to be reminded.',
                              style: context.dawaCaption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DawaCard(
                            color: DawaColors.softBlue,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 76,
                                  child: Image.asset(
                                    DawaArtwork.clinicConversation,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.appointment.appointmentType
                                            .replaceAll('_', ' '),
                                        style: context.dawaSectionTitle,
                                      ),
                                      Text(
                                        widget.appointment.clinicName ??
                                            'Your clinic',
                                        style: context.dawaBody,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('EEE, d MMM • h:mm a')
                                            .format(start),
                                        style: context.dawaCaption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Remind me'),
                            subtitle: const Text(
                              'Keep a reminder preference for this appointment.',
                            ),
                            value: value.enabled,
                            onChanged: (enabled) => setState(
                              () => _value = value.copyWith(enabled: enabled),
                            ),
                          ),
                          if (value.enabled) ...[
                            const SizedBox(height: 8),
                            Text('When', style: context.dawaSectionTitle),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(
                                    value: 1,
                                    label: Text('1 day'),
                                  ),
                                  ButtonSegment(
                                    value: 2,
                                    label: Text('2 days'),
                                  ),
                                  ButtonSegment(
                                    value: 7,
                                    label: Text('1 week'),
                                  ),
                                ],
                                selected: {value.daysBefore},
                                onSelectionChanged: (selection) => setState(
                                  () => _value = value.copyWith(
                                    daysBefore: selection.first,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Notification channels',
                              style: context.dawaSectionTitle,
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              secondary:
                                  const Icon(Icons.notifications_outlined),
                              title: const Text('In-app notification'),
                              subtitle: const Text(
                                'Shown inside DawaMom on this device.',
                              ),
                              value: value.appNotification,
                              onChanged: (enabled) => setState(
                                () => _value = value.copyWith(
                                  appNotification: enabled,
                                ),
                              ),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(Icons.sms_outlined),
                              title: const Text('SMS'),
                              subtitle: const Text(
                                'Requires a verified +260 mobile number and server delivery.',
                              ),
                              value: value.smsNotification,
                              onChanged: (enabled) => setState(
                                () => _value = value.copyWith(
                                  smsNotification: enabled,
                                ),
                              ),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(Icons.email_outlined),
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
                              _saving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            _saving ? 'Saving…' : 'Save reminder',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
}
