import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase/supabase_database.dart';

class PeriodTrackerService {
  SupabaseClient get _client => Supabase.instance.client;

  String? get userId => _client.auth.currentUser?.id;

  Future<void> saveUserSettings({
    required int averageCycleLength,
    required int periodLength,
    required bool isRegular,
    DateTime? lastPeriodStart,
  }) async {
    final profileId = userId;
    if (profileId == null) {
      return;
    }

    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('period_tracker_settings').upsert({
        'profile_id': profileId,
        'average_cycle_length': averageCycleLength,
        'period_length': periodLength,
        'is_regular': isRegular,
        'last_period_start':
            lastPeriodStart != null ? formatDateId(lastPeriodStart) : null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id'),
    );
  }

  Future<Map<String, dynamic>?> loadUserSettings() async {
    final profileId = userId;
    if (profileId == null) {
      return null;
    }

    final row = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_settings')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle(),
    );

    if (row == null) {
      return null;
    }

    return {
      'averageCycleLength': row['average_cycle_length'],
      'periodLength': row['period_length'],
      'isRegular': row['is_regular'],
      'lastPeriodStart': row['last_period_start'] == null
          ? null
          : DateTime.tryParse(row['last_period_start'].toString()),
    };
  }

  Future<void> saveDailyData({
    required DateTime date,
    List<String>? symptoms,
    List<String>? notes,
    List<Map<String, dynamic>>? sexualActivity,
  }) async {
    final profileId = userId;
    if (profileId == null) {
      return;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('period_tracker_entries').upsert({
        'profile_id': profileId,
        'entry_date': formatDateId(normalizedDate),
        if (symptoms != null) 'symptoms': symptoms,
        if (notes != null) 'notes': notes,
        if (sexualActivity != null)
          'sexual_activity': sexualActivity
              .map((activity) => {
                    'protected': activity['protected'],
                    'time': activity['time'] is DateTime
                        ? (activity['time'] as DateTime).toIso8601String()
                        : activity['time'],
                  })
              .toList(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id,entry_date'),
    );
  }

  Future<Map<String, dynamic>?> loadDailyData(DateTime date) async {
    final profileId = userId;
    if (profileId == null) {
      return null;
    }

    final row = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_entries')
          .select()
          .eq('profile_id', profileId)
          .eq('entry_date', formatDateId(date))
          .maybeSingle(),
    );

    return row == null
        ? null
        : entryToLegacyMap(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> loadDateRangeData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final profileId = userId;
    if (profileId == null) {
      return [];
    }

    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_entries')
          .select()
          .eq('profile_id', profileId)
          .gte('entry_date', formatDateId(startDate))
          .lte('entry_date', formatDateId(endDate)),
    );

    return (rows as List)
        .map((row) => entryToLegacyMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<DateTime>> loadAllPeriodStarts() async {
    final settings = await loadUserSettings();
    final lastPeriodStart = settings?['lastPeriodStart'];
    return lastPeriodStart is DateTime ? [lastPeriodStart] : [];
  }

  static Map<String, dynamic> entryToLegacyMap(Map<String, dynamic> row) {
    final sexualActivity =
        (row['sexual_activity'] as List? ?? []).map((activity) {
      final data = Map<String, dynamic>.from(activity as Map);
      final time = data['time'];
      return {
        'protected': data['protected'],
        'time': time is String ? DateTime.tryParse(time) : time,
      };
    }).toList();

    return {
      'date': DateTime.tryParse(row['entry_date'].toString()),
      'symptoms': List<String>.from(row['symptoms'] ?? const []),
      'notes': List<String>.from(row['notes'] ?? const []),
      'sexualActivity': sexualActivity,
    };
  }

  static String formatDateId(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return '${normalizedDate.year}-${normalizedDate.month.toString().padLeft(2, '0')}-${normalizedDate.day.toString().padLeft(2, '0')}';
  }
}
