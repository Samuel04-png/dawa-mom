import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/period_tracker_service.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/dawa_appointment_reminder_repository.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/features/preferences/dawa_user_preferences_repository.dart';

enum DawaNotificationCategory {
  appointments,
  cycle,
  pregnancy,
  checkIns,
  learning,
  rewards,
  system,
}

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
    this.assetId,
  });

  final String id;
  final DawaNotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final String? route;
  final String? assetId;
}

class DawaNotificationsRepository {
  DawaNotificationsRepository({
    AppointmentRepository? appointments,
    PeriodTrackerService? periodTracker,
    DawaLearningRepository? learning,
    DawaAppointmentReminderRepository? reminders,
    DawaUserPreferencesRepository? userPreferences,
    SharedPreferences? preferences,
    SupabaseClient? client,
  })  : _appointments = appointments ?? AppointmentRepository(),
        _periodTracker = periodTracker ?? PeriodTrackerService(),
        _learning = learning ?? DawaLearningRepository(),
        _reminders = reminders ?? DawaAppointmentReminderRepository(),
        _userPreferences =
            userPreferences ?? DawaUserPreferencesRepository(client: client),
        _preferences = preferences,
        _client = client {
    _ensureRealtime(_supabase);
  }

  final AppointmentRepository _appointments;
  final PeriodTrackerService _periodTracker;
  final DawaLearningRepository _learning;
  final DawaAppointmentReminderRepository _reminders;
  final DawaUserPreferencesRepository _userPreferences;
  SharedPreferences? _preferences;
  SupabaseClient? _client;

  static const _readKey = 'dawa_notification_read_ids';
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static RealtimeChannel? _notificationsChannel;
  static SupabaseClient? _realtimeClient;
  static String? _realtimeUserId;

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

  static void _ensureRealtime(SupabaseClient? client) {
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return;
    }
    if (userId == null || userId.isEmpty) {
      final previous = _notificationsChannel;
      final previousClient = _realtimeClient;
      if (previous != null) {
        unawaited(
          (previousClient ?? client).removeChannel(previous).then<void>((_) {}),
        );
      }
      _notificationsChannel = null;
      _realtimeClient = null;
      _realtimeUserId = null;
      return;
    }
    if (userId == _realtimeUserId && identical(client, _realtimeClient)) {
      return;
    }
    final previous = _notificationsChannel;
    final previousClient = _realtimeClient;
    if (previous != null) {
      unawaited(
        (previousClient ?? client).removeChannel(previous).then<void>((_) {}),
      );
    }
    _realtimeClient = client;
    _realtimeUserId = userId;
    _notificationsChannel = client
        .channel('dawa-mom-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (_) => changes.value += 1,
        )
        .subscribe();
  }

  Future<(List<DawaNotificationItem>, Set<String>)> load() async {
    final results = await Future.wait<dynamic>([
      _appointments.getAppointments(),
      _periodTracker.loadUserSettings(),
      _learning.load(),
      _userPreferences.load(),
      _loadServerNotifications(),
    ]);
    final appointments = results[0] as List<Appointment>;
    final period = results[1] as Map<String, dynamic>?;
    final learning = results[2] as DawaLearningState;
    final userPreferences = results[3] as DawaUserPreferences;
    final serverNotifications =
        results[4] as (List<DawaNotificationItem>, Set<String>);
    final notifications = <DawaNotificationItem>[];
    final reminderEntries = await Future.wait(
      appointments.where((appointment) => appointment.isUpcoming).take(8).map(
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
          assetId: 'clinic_visit_05',
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
          assetId: 'period_tracking_09',
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
          assetId: 'pregnancy_basics_05',
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

    if (userPreferences.weeklySummary) {
      notifications.add(
        DawaNotificationItem(
          id: 'weekly-${DateTime.now().year}-${_weekOfYear(DateTime.now())}',
          category: DawaNotificationCategory.learning,
          title: 'Your weekly Dawa summary',
          body:
              '${learning.completedIds.length} lessons completed • ${learning.coins} points • Open DawaMom for your next useful action.',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          icon: Icons.summarize_outlined,
          color: DawaColors.primary,
          route: '/home',
          assetId: 'cervical_awareness_05',
        ),
      );
    }

    notifications.removeWhere((item) => switch (item.category) {
          DawaNotificationCategory.appointments =>
            !userPreferences.appointmentNotifications,
          DawaNotificationCategory.learning =>
            !userPreferences.learningNotifications,
          DawaNotificationCategory.rewards =>
            !userPreferences.rewardNotifications,
          DawaNotificationCategory.cycle => !userPreferences.cycleNotifications,
          DawaNotificationCategory.pregnancy =>
            !userPreferences.cycleNotifications,
          DawaNotificationCategory.checkIns =>
            !userPreferences.cycleNotifications,
          DawaNotificationCategory.system => false,
        });

    final serverCategories =
        serverNotifications.$1.map((item) => item.category).toSet();
    notifications.removeWhere(
      (item) => serverCategories.contains(item.category),
    );
    notifications.addAll(serverNotifications.$1);

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final prefs = await _prefs;
    final read = (prefs.getStringList(_readKey) ?? const <String>[]).toSet();
    read.addAll(serverNotifications.$2);
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
    unawaited(_markServerRead(id));
    unawaited(_syncRead(next));
    return next;
  }

  Future<Set<String>> markAllRead(
    Set<String> read,
    Iterable<String> ids,
  ) async {
    final next = {...read, ...ids};
    await (await _prefs).setStringList(_readKey, next.toList()..sort());
    unawaited(_markServerReadMany(next));
    unawaited(_syncRead(next));
    return next;
  }

  Future<(List<DawaNotificationItem>, Set<String>)>
      _loadServerNotifications() async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return (const <DawaNotificationItem>[], const <String>{});
    }
    try {
      final rows = await client
          .from('notifications')
          .select(
            'id,category,title,body,route,created_at,read_at',
          )
          .eq('profile_id', userId)
          .isFilter('archived_at', null)
          .order('created_at', ascending: false)
          .limit(80);
      final items = <DawaNotificationItem>[];
      final read = <String>{};
      for (final raw in rows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final category =
            _serverNotificationCategory(row['category']?.toString());
        if (category == null) continue;
        final id = 'server:${row['id']}';
        if (row['read_at'] != null) read.add(id);
        items.add(
          DawaNotificationItem(
            id: id,
            category: category,
            title: row['title']?.toString() ?? 'DawaMom update',
            body: row['body']?.toString() ??
                'Open DawaMom to review this update.',
            createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')
                    ?.toLocal() ??
                DateTime.now(),
            icon: _categoryIcon(category),
            color: _categoryColor(category),
            route: row['route']?.toString(),
          ),
        );
      }
      return (items, read);
    } on PostgrestException catch (error) {
      debugPrint('Durable notifications unavailable: ${error.code}');
      return (const <DawaNotificationItem>[], const <String>{});
    }
  }

  Future<void> _markServerRead(String id) async {
    if (!id.startsWith('server:')) return;
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('profile_id', userId)
          .eq('id', id.substring('server:'.length));
    } on PostgrestException catch (error) {
      debugPrint('Notification read update queued locally: ${error.code}');
    }
  }

  Future<void> _markServerReadMany(Set<String> ids) async {
    final serverIds = ids
        .where((id) => id.startsWith('server:'))
        .map((id) => id.substring('server:'.length))
        .toList();
    if (serverIds.isEmpty) return;
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('profile_id', userId)
          .inFilter('id', serverIds);
    } on PostgrestException catch (error) {
      debugPrint('Notification read updates queued locally: ${error.code}');
    }
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
    DawaNotificationsRepository.changes.addListener(_onNotificationsChanged);
    _data = _repository.load();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() => _data = _repository.load());
  }

  @override
  void dispose() {
    DawaNotificationsRepository.changes.removeListener(_onNotificationsChanged);
    super.dispose();
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
    final next = await _repository.markAllRead(
      read,
      items.map((item) => item.id),
    );
    if (mounted) setState(() => _data = Future.value((items, next)));
  }

  Future<void> _refresh() async {
    final next = _repository.load();
    setState(() => _data = next);
    try {
      await next;
    } catch (_) {
      // The FutureBuilder renders the retry state; pull-to-refresh still ends.
    }
  }

  Future<void> _openPreferences() async {
    await context.push('/notification-preferences');
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 900,
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Notifications',
              onBack: context.pop,
              onProfile: () => context.go('/settings'),
            ),
            const SizedBox(height: 10),
            DawaSectionHeader(
              title: 'Your updates',
              subtitle: 'Only timely updates connected to your choices.',
              actionLabel: 'Preferences',
              onAction: _openPreferences,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final filter in [
                  'All',
                  'Appointments',
                  'Cycle',
                  'Pregnancy',
                  'Check-ins',
                  'Learning',
                  'Rewards',
                  'System',
                ])
                  ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FutureBuilder<(List<DawaNotificationItem>, Set<String>)>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Column(
                    children: [
                      DawaLoadingSkeleton(lines: 2),
                      SizedBox(height: DawaSpacing.sm),
                      DawaLoadingSkeleton(lines: 2),
                      SizedBox(height: DawaSpacing.sm),
                      DawaLoadingSkeleton(lines: 2),
                    ],
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
                    'Cycle' => item.category == DawaNotificationCategory.cycle,
                    'Pregnancy' =>
                      item.category == DawaNotificationCategory.pregnancy,
                    'Check-ins' =>
                      item.category == DawaNotificationCategory.checkIns,
                    'Learning' =>
                      item.category == DawaNotificationCategory.learning,
                    'Rewards' =>
                      item.category == DawaNotificationCategory.rewards,
                    'System' =>
                      item.category == DawaNotificationCategory.system,
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
                    _NotificationList(
                      items: items,
                      read: read,
                      onTap: (item) => _markRead(allItems, read, item),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: DawaCard(
                          color: DawaColors.softBlue,
                          borderColor:
                              DawaColors.primary.withValues(alpha: 0.12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 116,
                                  child: DawaContextualImage(
                                    assetId: 'screening_without_fear_05',
                                    variant: DawaImageVariant.emptyState,
                                  ),
                                ),
                                Text(
                                  items.isEmpty
                                      ? 'You’re all caught up for now.'
                                      : 'End of recent updates',
                                  textAlign: TextAlign.center,
                                  style: context.dawaSectionTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  items.isEmpty
                                      ? 'There are no updates in this category.'
                                      : 'You’ve reached the end of your recent updates.',
                                  textAlign: TextAlign.center,
                                  style: context.dawaCaption,
                                ),
                              ],
                            ),
                          ),
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

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.read,
    required this.onTap,
  });

  final List<DawaNotificationItem> items;
  final Set<String> read;
  final ValueChanged<DawaNotificationItem> onTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    String? previousGroup;
    for (final item in items) {
      final group = _dateGroup(item.createdAt);
      if (group != previousGroup) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: children.isEmpty ? 0 : DawaSpacing.xs,
              bottom: DawaSpacing.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(group, style: context.dawaSectionTitle),
            ),
          ),
        );
        previousGroup = group;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _NotificationCard(
            item: item,
            unread: !read.contains(item.id),
            onTap: () => onTap(item),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
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
  Widget build(BuildContext context) => DawaCard(
        onTap: onTap,
        semanticLabel:
            '${unread ? 'Unread' : 'Read'} notification. ${item.title}. ${item.body}',
        color: unread ? DawaColors.softBlue : DawaColors.surface,
        borderColor: unread
            ? DawaColors.primary.withValues(alpha: 0.24)
            : DawaColors.line,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.assetId == null)
              DawaIconBadge(icon: item.icon, color: item.color)
            else
              SizedBox(
                width: 48,
                child: DawaContextualImage(
                  assetId: item.assetId!,
                  variant: DawaImageVariant.compactThumbnail,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unread) ...[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 6, right: 7),
                          decoration: const BoxDecoration(
                            color: DawaColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: context.dawaSectionTitle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(item.createdAt),
                        maxLines: 1,
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.body, style: context.dawaCaption),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Icon(
                Icons.chevron_right_rounded,
                color: DawaColors.primary,
              ),
            ),
          ],
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

String _dateGroup(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final difference = today.difference(date).inDays;
  if (difference <= 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return 'Earlier';
}

int _weekOfYear(DateTime value) {
  final firstDay = DateTime(value.year, 1, 1);
  return ((value.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
}

DawaNotificationCategory? _serverNotificationCategory(String? value) =>
    switch (value) {
      'appointments' => DawaNotificationCategory.appointments,
      'cycle' => DawaNotificationCategory.cycle,
      'pregnancy' => DawaNotificationCategory.pregnancy,
      'check_ins' => DawaNotificationCategory.checkIns,
      'learning' => DawaNotificationCategory.learning,
      'rewards' => DawaNotificationCategory.rewards,
      'account' => DawaNotificationCategory.system,
      _ => null,
    };

IconData _categoryIcon(DawaNotificationCategory category) => switch (category) {
      DawaNotificationCategory.appointments => Icons.calendar_month_rounded,
      DawaNotificationCategory.cycle => Icons.water_drop_rounded,
      DawaNotificationCategory.pregnancy => Icons.pregnant_woman_rounded,
      DawaNotificationCategory.checkIns => Icons.fact_check_outlined,
      DawaNotificationCategory.learning => Icons.menu_book_rounded,
      DawaNotificationCategory.rewards => Icons.workspace_premium_rounded,
      DawaNotificationCategory.system => Icons.shield_outlined,
    };

Color _categoryColor(DawaNotificationCategory category) => switch (category) {
      DawaNotificationCategory.appointments => DawaColors.green,
      DawaNotificationCategory.cycle => DawaColors.pink,
      DawaNotificationCategory.pregnancy => DawaColors.purple,
      DawaNotificationCategory.checkIns => DawaColors.primary,
      DawaNotificationCategory.learning => DawaColors.purple,
      DawaNotificationCategory.rewards => DawaColors.warning,
      DawaNotificationCategory.system => DawaColors.muted,
    };
