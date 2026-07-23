import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/period_tracker_service.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/dawa_appointment_reminder_repository.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/learning/data/dawa_learning_repository.dart';

enum DawaNotificationCategory { appointments, learning, rewards, cycle }

class DawaNotificationItem {
  const DawaNotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.icon,
    required this.color,
    this.route,
  });

  final String id;
  final DawaNotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final String? route;
}

class DawaNotificationsRepository {
  DawaNotificationsRepository({
    AppointmentRepository? appointments,
    PeriodTrackerService? periodTracker,
    DawaLearningRepository? learning,
    DawaAppointmentReminderRepository? reminders,
    SharedPreferences? preferences,
    SupabaseClient? client,
  })  : _appointments = appointments ?? AppointmentRepository(),
        _periodTracker = periodTracker ?? PeriodTrackerService(),
        _learning = learning ?? DawaLearningRepository(),
        _reminders = reminders ?? DawaAppointmentReminderRepository(),
        _preferences = preferences,
        _client = client;

  final AppointmentRepository _appointments;
  final PeriodTrackerService _periodTracker;
  final DawaLearningRepository _learning;
  final DawaAppointmentReminderRepository _reminders;
  SharedPreferences? _preferences;
  SupabaseClient? _client;

  static const _readKey = 'dawa_notification_read_ids';

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return _client = Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<(List<DawaNotificationItem>, Set<String>)> load() async {
    final results = await Future.wait<dynamic>([
      _appointments.getAppointments(),
      _periodTracker.loadUserSettings(),
      _learning.load(),
    ]);
    final appointments = results[0] as List<Appointment>;
    final period = results[1] as Map<String, dynamic>?;
    final learning = results[2] as DawaLearningState;
    final notifications = <DawaNotificationItem>[];
    final reminderEntries = await Future.wait(
      appointments
          .where((appointment) => appointment.isUpcoming)
          .take(8)
          .map(
            (appointment) async => MapEntry(
              appointment.id,
              await _reminders.load(appointment.id),
            ),
          ),
    );
    final reminders = Map.fromEntries(reminderEntries);

    for (final appointment in appointments.take(8)) {
      final start = Appointment.dateAtTime(
        appointment.date,
        appointment.startTime,
      );
      final upcoming = appointment.isUpcoming;
      final reminder = reminders[appointment.id];
      final reminderAt = reminder == null
          ? start.subtract(const Duration(days: 1))
          : start.subtract(Duration(days: reminder.daysBefore));
      if (upcoming &&
          (reminder == null ||
              !reminder.enabled ||
              !reminder.appNotification ||
              DateTime.now().isBefore(reminderAt))) {
        continue;
      }
      notifications.add(
        DawaNotificationItem(
          id: 'appointment-${appointment.id}-${appointment.status}',
          category: DawaNotificationCategory.appointments,
          title: upcoming
              ? 'Appointment reminder'
              : 'Appointment ${appointment.status}',
          body: upcoming
              ? '${appointment.clinicName ?? 'Your clinic'} • ${DateFormat('EEE, d MMM • h:mm a').format(start)}'
              : appointment.patientSafeStatusMessage ??
                  'Your appointment status is ${appointment.status}.',
          createdAt: upcoming ? reminderAt : appointment.createdAt,
          icon: Icons.calendar_month_rounded,
          color: DawaColors.green,
          route: '/appointmentDetails?appointmentId=${appointment.id}',
        ),
      );
    }

    final lastPeriod = period?['lastPeriodStart'] as DateTime?;
    final cycleLength = period?['averageCycleLength'] as int?;
    if (lastPeriod != null && cycleLength != null) {
      final next = lastPeriod.add(Duration(days: cycleLength));
      final days = DateTime(next.year, next.month, next.day)
          .difference(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ))
          .inDays;
      notifications.add(
        DawaNotificationItem(
          id: 'cycle-${next.toIso8601String().substring(0, 10)}',
          category: DawaNotificationCategory.cycle,
          title: 'Cycle update',
          body: days >= 0
              ? 'Your next period is estimated in $days ${days == 1 ? 'day' : 'days'}.'
              : 'Open Track to review your latest cycle information.',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          icon: Icons.water_drop_rounded,
          color: DawaColors.pink,
          route: '/periodTracker',
        ),
      );
    }

    if (learning.completedIds.isNotEmpty) {
      notifications.add(
        DawaNotificationItem(
          id: 'learning-${learning.completedIds.length}',
          category: DawaNotificationCategory.learning,
          title: 'Learning progress saved',
          body:
              'You have completed ${learning.completedIds.length} ${learning.completedIds.length == 1 ? 'lesson' : 'lessons'}. Keep going!',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          icon: Icons.menu_book_rounded,
          color: DawaColors.purple,
          route: '/learn',
        ),
      );
    }

    if (learning.coins > 180) {
      notifications.add(
        DawaNotificationItem(
          id: 'rewards-${learning.coins}',
          category: DawaNotificationCategory.rewards,
          title: 'Reward points updated',
          body: 'Your healthy actions balance is now ${learning.coins} coins.',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          icon: Icons.workspace_premium_rounded,
          color: DawaColors.gold,
          route: '/learn/quests',
        ),
      );
    }

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final prefs = await _prefs;
    final read = (prefs.getStringList(_readKey) ?? const <String>[]).toSet();
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        final row = await client
            .from('dawa_mom_user_preferences')
            .select('read_notification_ids')
            .eq('profile_id', userId)
            .maybeSingle();
        read.addAll(
          Set<String>.from(row?['read_notification_ids'] ?? const []),
        );
        await prefs.setStringList(_readKey, read.toList()..sort());
      } on PostgrestException catch (error) {
        debugPrint('Notification read sync unavailable: ${error.code}');
      }
    }
    return (notifications, read);
  }

  Future<Set<String>> markRead(Set<String> read, String id) async {
    final next = {...read, id};
    await (await _prefs).setStringList(_readKey, next.toList()..sort());
    unawaited(_syncRead(next));
    return next;
  }

  Future<Set<String>> markAllRead(Iterable<String> ids) async {
    final next = ids.toSet();
    await (await _prefs).setStringList(_readKey, next.toList()..sort());
    unawaited(_syncRead(next));
    return next;
  }

  Future<void> _syncRead(Set<String> read) async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client.from('dawa_mom_user_preferences').upsert({
        'profile_id': userId,
        'read_notification_ids': read.toList()..sort(),
      }, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      debugPrint('Notification read state remains local: ${error.code}');
    }
  }
}

class DawaNotificationsPage extends StatefulWidget {
  const DawaNotificationsPage({
    super.key,
    this.repository,
  });

  static const routeName = 'Notifications';
  static const routePath = '/notifications';

  final DawaNotificationsRepository? repository;

  @override
  State<DawaNotificationsPage> createState() => _DawaNotificationsPageState();
}

class _DawaNotificationsPageState extends State<DawaNotificationsPage> {
  late final DawaNotificationsRepository _repository;
  late Future<(List<DawaNotificationItem>, Set<String>)> _data;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DawaNotificationsRepository();
    _data = _repository.load();
  }

  Future<void> _markRead(
    List<DawaNotificationItem> items,
    Set<String> read,
    DawaNotificationItem item,
  ) async {
    final next = await _repository.markRead(read, item.id);
    if (!mounted) return;
    setState(() => _data = Future.value((items, next)));
    if (item.route != null) context.push(item.route!);
  }

  Future<void> _markAll(
    List<DawaNotificationItem> items,
    Set<String> read,
  ) async {
    final next = await _repository.markAllRead(items.map((item) => item.id));
    if (mounted) setState(() => _data = Future.value((items, next)));
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Notifications',
              onBack: context.pop,
              onProfile: () => context.go('/settings'),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in [
                    'All',
                    'Appointments',
                    'Learning',
                    'Rewards'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<(List<DawaNotificationItem>, Set<String>)>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return DawaCard(
                    child: Column(
                      children: [
                        const DawaIconBadge(
                          icon: Icons.cloud_off_rounded,
                          size: 58,
                        ),
                        const SizedBox(height: 10),
                        Text('Notifications could not be loaded',
                            style: context.dawaSectionTitle),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _data = _repository.load()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final (allItems, read) = snapshot.data!;
                final items = allItems.where((item) {
                  return switch (_filter) {
                    'Appointments' =>
                      item.category == DawaNotificationCategory.appointments,
                    'Learning' =>
                      item.category == DawaNotificationCategory.learning ||
                          item.category == DawaNotificationCategory.cycle,
                    'Rewards' =>
                      item.category == DawaNotificationCategory.rewards,
                    _ => true,
                  };
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            items.isEmpty ? 'No updates' : 'Recent',
                            style: context.dawaCaption,
                          ),
                        ),
                        if (items.any((item) => !read.contains(item.id)))
                          TextButton.icon(
                            onPressed: () => _markAll(allItems, read),
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: const Text('Mark all as read'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(
                          item: item,
                          unread: !read.contains(item.id),
                          onTap: () => _markRead(allItems, read, item),
                        ),
                      ),
                    if (items.isEmpty ||
                        items.every((item) => read.contains(item.id)))
                      DawaCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 140,
                                height: 145,
                                child: Image.asset(
                                  DawaArtwork.pregnancyPhone,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                              ),
                              Text('You’re all caught up for now.',
                                  style: context.dawaSectionTitle),
                              const SizedBox(height: 4),
                              Text(
                                'We’ll show appointment, cycle and learning updates here.',
                                textAlign: TextAlign.center,
                                style: context.dawaCaption,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.unread,
    required this.onTap,
  });

  final DawaNotificationItem item;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            '${unread ? 'Unread' : 'Read'} notification. ${item.title}. ${item.body}',
        child: DawaCard(
          onTap: onTap,
          semanticLabel: item.title,
          borderColor: unread
              ? DawaColors.green.withValues(alpha: 0.55)
              : DawaColors.line,
          child: Row(
            children: [
              if (unread)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: DawaColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              DawaIconBadge(icon: item.icon, color: item.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.dawaSectionTitle),
                    const SizedBox(height: 3),
                    Text(item.body, style: context.dawaCaption),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_relativeTime(item.createdAt),
                      style: context.dawaCaption),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: DawaColors.primary),
                ],
              ),
            ],
          ),
        ),
      );
}

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hr ago';
  if (difference.inDays == 1) return 'Yesterday';
  return DateFormat('d MMM').format(value);
}
