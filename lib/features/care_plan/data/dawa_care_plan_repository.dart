import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_database.dart';
import '../domain/dawa_care_item.dart';

@immutable
class DawaCarePlanSnapshot {
  const DawaCarePlanSnapshot({
    required this.items,
    required this.isCached,
    this.cachedAt,
    this.availability = DawaCarePlanAvailability.available,
  });

  final List<DawaCareItem> items;
  final bool isCached;
  final DateTime? cachedAt;
  final DawaCarePlanAvailability availability;

  List<DawaCareItem> get actionable =>
      items.where((item) => item.isActionable).toList(growable: false)
        ..sort(_compareCareItems);

  DawaCareItem? get nextActionable =>
      actionable.isEmpty ? null : actionable.first;
}

enum DawaCarePlanAvailability { available, cached, schemaUnavailable }

class DawaCarePlanRepository {
  DawaCarePlanRepository({
    SupabaseClient? client,
    SharedPreferences? preferences,
  })  : _client = client,
        _preferences = preferences;

  SupabaseClient? _client;
  SharedPreferences? _preferences;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static RealtimeChannel? _carePlanChannel;
  static String? _realtimeUserId;
  static const _cachePrefix = 'dawa_care_plan_v1';

  SupabaseClient get _supabase {
    if (_client != null) return _client!;
    return _client = Supabase.instance.client;
  }

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<DawaCarePlanSnapshot> load() async {
    final userId = _requireUserId();
    try {
      final rows = await SupabaseDatabase.instance.runWithFreshSession(
        () => _supabase
            .from('care_plan_items')
            .select()
            .order('due_at', ascending: true)
            .order('created_at', ascending: false),
      );
      final items = (rows as List)
          .map((row) => DawaCareItem.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList(growable: false);
      _ensureRealtime(userId);
      final cachedAt = DateTime.now();
      await _saveCache(userId, items, cachedAt);
      return DawaCarePlanSnapshot(
        items: items,
        isCached: false,
        cachedAt: cachedAt,
      );
    } catch (error, stackTrace) {
      if (isMissingSchemaError(error)) {
        if (kDebugMode) {
          debugPrint(
            'Care Plan unavailable: required backend schema is not deployed. '
            '$error',
          );
        }
        return const DawaCarePlanSnapshot(
          items: [],
          isCached: false,
          availability: DawaCarePlanAvailability.schemaUnavailable,
        );
      }
      final cached = await _loadCache(userId);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('Care Plan refresh failed; showing saved data. $error');
        }
        return cached;
      }
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Dawa care plan',
            context: ErrorDescription('while refreshing care plan items'),
          ),
        );
      }
      rethrow;
    }
  }

  Future<DawaCareItem?> getNextActionable() async =>
      (await load()).nextActionable;

  void _ensureRealtime(String userId) {
    if (userId == _realtimeUserId) return;
    final previous = _carePlanChannel;
    if (previous != null) {
      unawaited(_supabase.removeChannel(previous).then<void>((_) {}));
    }
    _realtimeUserId = userId;
    _carePlanChannel = _supabase
        .channel('dawa-mom-care-plan-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'care_plan_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: userId,
          ),
          callback: (_) => changes.value += 1,
        )
        .subscribe();
  }

  Future<void> _saveCache(
    String userId,
    List<DawaCareItem> items,
    DateTime cachedAt,
  ) async {
    final payload = <String, dynamic>{
      'cached_at': cachedAt.toUtc().toIso8601String(),
      'items': items.map(_toCacheJson).toList(growable: false),
    };
    await (await _prefs).setString(_cacheKey(userId), jsonEncode(payload));
  }

  Future<DawaCarePlanSnapshot?> _loadCache(String userId) async {
    final raw = (await _prefs).getString(_cacheKey(userId));
    if (raw == null) return null;
    try {
      final payload = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final source = payload['items'];
      if (source is! List) return null;
      return DawaCarePlanSnapshot(
        items: source
            .whereType<Map>()
            .map((item) => DawaCareItem.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
        isCached: true,
        cachedAt: DateTime.tryParse(payload['cached_at']?.toString() ?? '')
            ?.toLocal(),
        availability: DawaCarePlanAvailability.cached,
      );
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String userId) => '$_cachePrefix:$userId';

  String _requireUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const DawaCarePlanException(
          'Please sign in to view your care plan.');
    }
    return userId;
  }

  @visibleForTesting
  static bool isMissingSchemaError(Object error) =>
      _isMissingCarePlanSchema(error);
}

bool _isMissingCarePlanSchema(Object error) {
  if (error is! PostgrestException) return false;
  final code = (error.code ?? '').toUpperCase();
  final message = '${error.message} ${error.details ?? ''}'.toLowerCase();
  return code == 'PGRST205' ||
      code == '42P01' ||
      (message.contains('care_plan_items') &&
          (message.contains('schema cache') ||
              message.contains('does not exist') ||
              message.contains('could not find the table')));
}

class DawaCarePlanException implements Exception {
  const DawaCarePlanException(this.message);

  final String message;

  @override
  String toString() => message;
}

int _compareCareItems(DawaCareItem left, DawaCareItem right) {
  int rank(DawaCareItem item) => switch (item.priority) {
        DawaCareItemPriority.urgent => 0,
        DawaCareItemPriority.high => 1,
        DawaCareItemPriority.standard => 2,
        DawaCareItemPriority.routine => 3,
      };
  final priority = rank(left).compareTo(rank(right));
  if (priority != 0) return priority;
  int statusRank(DawaCareItem item) => switch (item.status) {
        DawaCareItemStatus.overdue => 0,
        DawaCareItemStatus.due => 1,
        DawaCareItemStatus.scheduled => 2,
        DawaCareItemStatus.recommended => 3,
        _ => 4,
      };
  final status = statusRank(left).compareTo(statusRank(right));
  if (status != 0) return status;
  return (left.relevantAt ?? DateTime(9999))
      .compareTo(right.relevantAt ?? DateTime(9999));
}

Map<String, dynamic> _toCacheJson(DawaCareItem item) => <String, dynamic>{
      'id': item.id,
      'mother_id': item.motherId,
      'patient_id': item.patientId,
      'care_type': item.type,
      'title': item.title,
      'description': item.description,
      'status': item.status.name,
      'priority': item.priority.name,
      'due_at': item.dueAt?.toUtc().toIso8601String(),
      'scheduled_at': item.scheduledAt?.toUtc().toIso8601String(),
      'completed_at': item.completedAt?.toUtc().toIso8601String(),
      'source': item.source,
      'source_record_id': item.sourceRecordId,
      'clinic_id': item.clinicId,
      'appointment_id': item.appointmentId,
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'updated_at': item.updatedAt.toUtc().toIso8601String(),
    };
