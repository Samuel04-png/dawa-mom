import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/preferences/dawa_user_preferences_repository.dart';

class DawaNotificationPreferencesPage extends StatefulWidget {
  const DawaNotificationPreferencesPage({
    super.key,
    this.repository,
  });

  static const routeName = 'NotificationPreferences';
  static const routePath = '/notification-preferences';

  final DawaUserPreferencesRepository? repository;

  @override
  State<DawaNotificationPreferencesPage> createState() =>
      _DawaNotificationPreferencesPageState();
}

class _DawaNotificationPreferencesPageState
    extends State<DawaNotificationPreferencesPage> {
  late final DawaUserPreferencesRepository _repository;
  DawaUserPreferences? _value;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaUserPreferencesRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await _repository.load();
      if (!mounted) return;
      setState(() {
        _value = value;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Notification preferences could not be loaded. Check your connection and try again.';
      });
    }
  }

  Future<void> _save() async {
    final value = _value;
    if (value == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await _repository.save(value);
      if (!mounted) return;
      setState(() {
        _value = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification preferences saved. External delivery remains off unless you enable a supported channel for a reminder.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Your preferences could not be saved. Please try again.';
      });
    }
  }

  Future<void> _chooseTime({required bool start}) async {
    final value = _value;
    if (value == null) return;
    final current =
        _parseTime(start ? value.quietHoursStart : value.quietHoursEnd);
    final selected = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: context.tr(
        start ? 'Quiet hours start' : 'Quiet hours end',
      ),
      cancelText: context.tr('Cancel'),
      confirmText: context.tr('Save'),
    );
    if (selected == null) return;
    final formatted = _formatTime(selected);
    setState(() {
      _value = start
          ? value.copyWith(quietHoursStart: formatted)
          : value.copyWith(quietHoursEnd: formatted);
    });
  }

  void _update(DawaUserPreferences value) => setState(() => _value = value);

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Notification preferences',
              onBack: context.pop,
            ),
            const SizedBox(height: DawaSpacing.sm),
            if (_loading)
              const DawaLoadingSkeleton(
                lines: 5,
                label: 'Loading notification preferences',
              )
            else if (_value == null)
              DawaErrorState(
                title: 'Preferences unavailable',
                message: _error ??
                    'Your notification preferences could not be loaded.',
                onRetry: _load,
              )
            else
              _buildPreferences(context, _value!),
          ],
        ),
      );

  Widget _buildPreferences(
    BuildContext context,
    DawaUserPreferences value,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaCard(
            color: DawaColors.softBlue,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DawaIconBadge(
                  icon: Icons.notifications_active_outlined,
                  color: DawaColors.primary,
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You stay in control',
                        style: context.dawaSectionTitle,
                      ),
                      const SizedBox(height: DawaSpacing.xxs),
                      Text(
                        'Dawa asks for push permission only when you create a reminder. SMS and email appear only when those services are configured and you choose them.',
                        style: context.dawaBody,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          const DawaSectionHeader(
            title: 'What you want to receive',
            subtitle:
                'These choices control the in-app notification center and any channel you later enable.',
          ),
          const SizedBox(height: DawaSpacing.xs),
          DawaCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _PreferenceSwitch(
                  icon: Icons.calendar_month_outlined,
                  title: 'Appointments',
                  subtitle: 'Booking updates and reminders you create.',
                  value: value.appointmentNotifications,
                  onChanged: (enabled) => _update(
                    value.copyWith(appointmentNotifications: enabled),
                  ),
                ),
                _PreferenceSwitch(
                  icon: Icons.water_drop_outlined,
                  title: 'Period & cycle',
                  subtitle:
                      'Optional, generic reminders without sensitive details.',
                  value: value.cycleNotifications,
                  onChanged: (enabled) =>
                      _update(value.copyWith(cycleNotifications: enabled)),
                ),
                _PreferenceSwitch(
                  icon: Icons.menu_book_outlined,
                  title: 'Learning',
                  subtitle: 'Approved lessons and content you chose to follow.',
                  value: value.learningNotifications,
                  onChanged: (enabled) =>
                      _update(value.copyWith(learningNotifications: enabled)),
                ),
                _PreferenceSwitch(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Rewards',
                  subtitle: 'Eligibility and redemption updates.',
                  value: value.rewardNotifications,
                  onChanged: (enabled) =>
                      _update(value.copyWith(rewardNotifications: enabled)),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          const DawaSectionHeader(
            title: 'Timing and privacy',
            subtitle:
                'Transactional care changes may still appear when they are time-sensitive.',
          ),
          const SizedBox(height: DawaSpacing.xs),
          DawaCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _PreferenceSwitch(
                  icon: Icons.bedtime_outlined,
                  title: 'Quiet hours',
                  subtitle: value.quietHoursEnabled
                      ? '${_displayTime(value.quietHoursStart)} to ${_displayTime(value.quietHoursEnd)}'
                      : 'Non-urgent updates may arrive at any time.',
                  value: value.quietHoursEnabled,
                  onChanged: (enabled) =>
                      _update(value.copyWith(quietHoursEnabled: enabled)),
                ),
                if (value.quietHoursEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final startButton = OutlinedButton.icon(
                          onPressed: () => _chooseTime(start: true),
                          icon: const Icon(Icons.nights_stay_outlined),
                          label: Text(
                            'Starts ${_displayTime(value.quietHoursStart)}',
                          ),
                        );
                        final endButton = OutlinedButton.icon(
                          onPressed: () => _chooseTime(start: false),
                          icon: const Icon(Icons.wb_sunny_outlined),
                          label: Text(
                            'Ends ${_displayTime(value.quietHoursEnd)}',
                          ),
                        );
                        if (constraints.maxWidth < 460) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              startButton,
                              const SizedBox(height: DawaSpacing.xs),
                              endButton,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: startButton),
                            const SizedBox(width: DawaSpacing.xs),
                            Expanded(child: endButton),
                          ],
                        );
                      },
                    ),
                  ),
                _PreferenceSwitch(
                  icon: Icons.lock_outline_rounded,
                  title: 'Private lock-screen wording',
                  subtitle:
                      'Show “You have a Dawa reminder” instead of health details.',
                  value: value.privateLockScreen,
                  onChanged: (enabled) =>
                      _update(value.copyWith(privateLockScreen: enabled)),
                ),
                _PreferenceSwitch(
                  icon: Icons.summarize_outlined,
                  title: 'Weekly summary',
                  subtitle:
                      'One optional summary of lessons, check-ins, care and your next action.',
                  value: value.weeklySummary,
                  onChanged: (enabled) =>
                      _update(value.copyWith(weeklySummary: enabled)),
                  showDivider: false,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: DawaSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: context.dawaBody.copyWith(color: DawaColors.danger),
              ),
            ),
          ],
          const SizedBox(height: DawaSpacing.md),
          DawaPrimaryButton(
            key: const ValueKey('save-notification-preferences'),
            label: 'Save preferences',
            onPressed: _save,
            icon: Icons.check_rounded,
            busy: _saving,
          ),
        ],
      );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SwitchListTile(
            secondary: Icon(icon, color: DawaColors.primary),
            title: Text(title, style: context.dawaSectionTitle),
            subtitle: Text(subtitle, style: context.dawaCaption),
            value: value,
            activeTrackColor: DawaColors.primary,
            onChanged: onChanged,
          ),
          if (showDivider) const Divider(height: 1),
        ],
      );
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  final hour = int.tryParse(parts.firstOrNull ?? '') ?? 21;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

String _formatTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _displayTime(String value) {
  final time = _parseTime(value);
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
