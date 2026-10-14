import 'dart:math' as math;

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
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The frame itself contains the grab handle and vertical padding. Reserve
    // that space (and any keyboard/system inset) before giving this sheet a
    // fixed, bounded height. This keeps the settings list scrollable instead
    // of allowing the action row to overflow on short Android viewports.
    final availableHeight = media.size.height -
        media.padding.top -
        media.padding.bottom -
        media.viewInsets.bottom -
        52;
    final sheetHeight = math.max(
      0.0,
      math.min(media.size.height * .80, availableHeight),
    );
    final stackActions =
        media.size.width < 360 || media.textScaler.scale(1) > 1.25;

    return DawaBottomSheetFrame(
      child: SizedBox(
        height: sheetHeight,
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
                    DawaIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close reminder settings',
                      onPressed: _saving ? null : () => Navigator.pop(context),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          DawaSegmentedControl(
                            keyPrefix: 'appointment-reminder-when',
                            selectedIndex: _reminderDayIndex(value.daysBefore),
                            onSelected: (index) => setState(
                              () => _value = value.copyWith(
                                daysBefore: _reminderDayOptions[index],
                              ),
                            ),
                            items: const [
                              DawaSegmentedItem(id: 'on-day', label: 'On day'),
                              DawaSegmentedItem(id: 'one-day', label: '1 day'),
                              DawaSegmentedItem(
                                  id: 'two-days', label: '2 days'),
                              DawaSegmentedItem(
                                  id: 'one-week', label: '1 week'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Notification channels',
                            style: context.dawaSectionTitle,
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.notifications_outlined),
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
                          const SizedBox(height: 8),
                          DawaCard(
                            color: DawaColors.softBlue,
                            borderColor:
                                DawaColors.primary.withValues(alpha: 0.16),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: DawaColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'These choices save your communication preferences. Dawa only treats an SMS or email as delivered when a verified contact and the DAWA backend confirm delivery.',
                                    style: context.dawaCaption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ReminderActions(
                  stack: stackActions,
                  saving: _saving,
                  onCancel: () => Navigator.pop(context),
                  onSave: _save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderActions extends StatelessWidget {
  const _ReminderActions({
    required this.stack,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool stack;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cancel = DawaTextButton(
      label: 'Cancel',
      fullWidth: true,
      compact: true,
      onPressed: saving ? null : onCancel,
    );
    final save = DawaPrimaryButton(
      label: 'Save reminder',
      icon: Icons.check_rounded,
      busy: saving,
      onPressed: saving ? null : onSave,
    );
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          save,
          const SizedBox(height: DawaSpacing.xs),
          cancel,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: DawaSpacing.xs),
        Expanded(child: save),
      ],
    );
  }
}

const _reminderDayOptions = [0, 1, 2, 7];

int _reminderDayIndex(int daysBefore) {
  final index = _reminderDayOptions.indexOf(daysBefore);
  return index < 0 ? 0 : index;
}
