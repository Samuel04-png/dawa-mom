import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase/supabase_database.dart';

class PeriodTrackerService {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void notifyChanged() => changes.value++;

  SupabaseClient get _client => Supabase.instance.client;

  String? get userId => _client.auth.currentUser?.id;

  Future<void> saveUserSettings({
    required int averageCycleLength,
    required int periodLength,
    required bool isRegular,
    DateTime? lastPeriodStart,
  }) async {
    validateSettings(
      averageCycleLength: averageCycleLength,
      periodLength: periodLength,
    );
    if (lastPeriodStart != null) {
      validatePeriodRecord(startDate: lastPeriodStart);
    }
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to save period tracker settings.',
      );
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

    if (lastPeriodStart != null) {
      await _ensurePeriodStartMarker(lastPeriodStart);
      await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('profiles')
            .update({'period_setup_skipped_at': null}).eq('id', profileId),
      );
    }
    notifyChanged();
  }

  Future<void> _ensurePeriodStartMarker(DateTime startDate) async {
    final profileId = userId!;
    final start = _dateOnly(startDate);
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('period_tracker_entries').upsert({
        'profile_id': profileId,
        'entry_date': formatDateId(start),
        'is_period_start': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id,entry_date'),
    );
  }

  Future<void> markSetupSkipped() async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to update period tracker setup.',
      );
    }
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('profiles').update({
        'period_setup_skipped_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', profileId),
    );
    notifyChanged();
  }

  Future<void> savePeriodRecord({
    required DateTime startDate,
    DateTime? endDate,
    DateTime? replacingStartDate,
  }) async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to save a period record.',
      );
    }
    final start = _dateOnly(startDate);
    final end = endDate == null ? null : _dateOnly(endDate);
    validatePeriodRecord(startDate: start, endDate: end);
    await _validatePeriodOverlap(
      startDate: start,
      endDate: end,
      replacingStartDate: replacingStartDate,
    );
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('period_tracker_entries').upsert({
        'profile_id': profileId,
        'entry_date': formatDateId(start),
        'is_period_start': true,
        'period_end_date': end == null ? null : formatDateId(end),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id,entry_date'),
    );
    await _syncLatestPeriodStart();
    notifyChanged();
  }

  Future<List<PeriodRecord>> loadPeriodHistory() async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to load period history.',
      );
    }
    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_entries')
          .select('entry_date,period_end_date')
          .eq('profile_id', profileId)
          .eq('is_period_start', true)
          .order('entry_date', ascending: false),
    );
    return (rows as List)
        .map((row) => PeriodRecord.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  Future<void> updatePeriodRecord({
    required DateTime originalStartDate,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to update a period record.',
      );
    }
    final original = _dateOnly(originalStartDate);
    final next = _dateOnly(startDate);
    final end = endDate == null ? null : _dateOnly(endDate);
    validatePeriodRecord(startDate: next, endDate: end);
    await _validatePeriodOverlap(
      startDate: next,
      endDate: end,
      replacingStartDate: original,
    );
    if (original != next) {
      await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('period_tracker_entries')
            .update({
              'is_period_start': false,
              'period_end_date': null,
            })
            .eq('profile_id', profileId)
            .eq('entry_date', formatDateId(original)),
      );
    }
    await savePeriodRecord(
      startDate: next,
      endDate: end,
      replacingStartDate: original,
    );
  }

  Future<void> deletePeriodRecord(DateTime startDate) async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to delete a period record.',
      );
    }
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_entries')
          .update({
            'is_period_start': false,
            'period_end_date': null,
          })
          .eq('profile_id', profileId)
          .eq('entry_date', formatDateId(startDate)),
    );
    await _syncLatestPeriodStart();
    notifyChanged();
  }

  Future<void> _syncLatestPeriodStart() async {
    final profileId = userId!;
    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_entries')
          .select('entry_date')
          .eq('profile_id', profileId)
          .eq('is_period_start', true)
          .order('entry_date', ascending: false)
          .limit(1),
    );
    final latest = (rows as List).isEmpty
        ? null
        : (rows.first as Map)['entry_date']?.toString();
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('period_tracker_settings')
          .update({'last_period_start': latest}).eq('profile_id', profileId),
    );
  }

  Future<void> _validatePeriodOverlap({
    required DateTime startDate,
    required DateTime? endDate,
    DateTime? replacingStartDate,
  }) async {
    final history = await loadPeriodHistory();
    final settings = await loadUserSettings();
    final configuredLength = settings?['periodLength'] as int? ?? 5;
    final candidateEnd = endDate ?? startDate;
    for (final record in history) {
      if (replacingStartDate != null &&
          _dateOnly(record.startDate) == _dateOnly(replacingStartDate)) {
        continue;
      }
      if (_dateOnly(record.startDate) == startDate) continue;
      final existingStart = _dateOnly(record.startDate);
      final existingEnd = _dateOnly(
        record.endDate ??
            existingStart.add(Duration(days: configuredLength - 1)),
      );
      final overlaps = !candidateEnd.isBefore(existingStart) &&
          !startDate.isAfter(existingEnd);
      if (overlaps) {
        throw const PeriodTrackerException(
          'These dates overlap another period. Edit the existing period instead.',
        );
      }
    }
  }

  Future<Map<String, dynamic>?> loadUserSettings() async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to load period tracker settings.',
      );
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
      throw const PeriodTrackerException(
        'Please sign in to save period tracker data.',
      );
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
    notifyChanged();
  }

  Future<Map<String, dynamic>?> loadDailyData(DateTime date) async {
    final profileId = userId;
    if (profileId == null) {
      throw const PeriodTrackerException(
        'Please sign in to load period tracker data.',
      );
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
      throw const PeriodTrackerException(
        'Please sign in to load period tracker data.',
      );
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
    final records = await loadPeriodHistory();
    return records.map((record) => record.startDate).toList();
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
      'isPeriodStart': row['is_period_start'] as bool? ?? false,
      'periodEndDate': row['period_end_date'] == null
          ? null
          : DateTime.tryParse(row['period_end_date'].toString()),
    };
  }

  static String formatDateId(DateTime date) {
    final normalizedDate = _dateOnly(date);
    return '${normalizedDate.year}-${normalizedDate.month.toString().padLeft(2, '0')}-${normalizedDate.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static void validateSettings({
    required int averageCycleLength,
    required int periodLength,
  }) {
    if (averageCycleLength < 15 || averageCycleLength > 60) {
      throw const PeriodTrackerException(
        'Average cycle length must be between 15 and 60 days.',
      );
    }
    if (periodLength < 1 || periodLength > 15) {
      throw const PeriodTrackerException(
        'Period length must be between 1 and 15 days.',
      );
    }
    if (periodLength >= averageCycleLength) {
      throw const PeriodTrackerException(
        'Period length must be shorter than the average cycle length.',
      );
    }
  }

  static void validatePeriodRecord({
    required DateTime startDate,
    DateTime? endDate,
    DateTime? today,
  }) {
    final start = _dateOnly(startDate);
    final normalizedToday = _dateOnly(today ?? DateTime.now());
    final normalizedEnd = endDate == null ? null : _dateOnly(endDate);
    if (start.isAfter(normalizedToday)) {
      throw const PeriodTrackerException(
        'Period start cannot be in the future.',
      );
    }
    if (normalizedEnd != null && normalizedEnd.isBefore(start)) {
      throw const PeriodTrackerException(
        'Period end cannot be before the start date.',
      );
    }
    if (normalizedEnd != null && normalizedEnd.isAfter(normalizedToday)) {
      throw const PeriodTrackerException(
        'Period end cannot be in the future.',
      );
    }
    if (normalizedEnd != null && normalizedEnd.difference(start).inDays >= 15) {
      throw const PeriodTrackerException(
        'A period cannot be longer than 15 days. Check the dates and try again.',
      );
    }
  }
}

class PeriodRecord {
  const PeriodRecord({required this.startDate, this.endDate});

  final DateTime startDate;
  final DateTime? endDate;

  factory PeriodRecord.fromJson(Map<String, dynamic> json) => PeriodRecord(
        startDate: DateTime.parse(json['entry_date'].toString()),
        endDate: json['period_end_date'] == null
            ? null
            : DateTime.tryParse(json['period_end_date'].toString()),
      );
}

class PeriodTrackerException implements Exception {
  const PeriodTrackerException(this.message);

  final String message;

  @override
  String toString() => message;
}
