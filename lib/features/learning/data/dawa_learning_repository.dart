import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DawaLearningState {
  const DawaLearningState({
    this.savedIds = const <String>{},
    this.completedIds = const <String>{},
    this.offlineIds = const <String>{},
    this.coins = 180,
    this.streak = 1,
  });

  final Set<String> savedIds;
  final Set<String> completedIds;
  final Set<String> offlineIds;
  final int coins;
  final int streak;

  DawaLearningState copyWith({
    Set<String>? savedIds,
    Set<String>? completedIds,
    Set<String>? offlineIds,
    int? coins,
    int? streak,
  }) =>
      DawaLearningState(
        savedIds: savedIds ?? this.savedIds,
        completedIds: completedIds ?? this.completedIds,
        offlineIds: offlineIds ?? this.offlineIds,
        coins: coins ?? this.coins,
        streak: streak ?? this.streak,
      );
}

double dawaQuestProgress(DawaLearningState state) {
  if (state.completedIds.contains('screening-without-fear')) return 1;
  if (state.completedIds.contains('screening-checkpoint')) return 0.75;
  return 0;
}

/// Stores learning progress locally for immediate offline behavior and mirrors
/// it to the owner-scoped Supabase table when the migration is available.
class DawaLearningRepository {
  DawaLearningRepository({
    SharedPreferences? preferences,
    SupabaseClient? client,
  })  : _preferences = preferences,
        _client = client;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  SharedPreferences? _preferences;
  SupabaseClient? _client;

  static const _savedKey = 'dawa_learning_saved';
  static const _completedKey = 'dawa_learning_completed';
  static const _offlineKey = 'dawa_learning_offline';
  static const _pendingCompletionKey = 'dawa_learning_pending_completions';
  static const _coinsKey = 'dawa_learning_coins';
  static const _streakKey = 'dawa_learning_streak';

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

  Future<DawaLearningState> load() async {
    final prefs = await _prefs;
    final local = DawaLearningState(
      savedIds: (prefs.getStringList(_savedKey) ?? const <String>[]).toSet(),
      completedIds:
          (prefs.getStringList(_completedKey) ?? const <String>[]).toSet(),
      offlineIds:
          (prefs.getStringList(_offlineKey) ?? const <String>[]).toSet(),
      coins: prefs.getInt(_coinsKey) ?? 180,
      streak: prefs.getInt(_streakKey) ?? 1,
    );

    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return local;
    try {
      await _flushPendingCompletions(client);
      final row = await client
          .from('dawa_mom_learning_state')
          .select()
          .eq('profile_id', userId)
          .maybeSingle();
      if (row == null) return local;
      final remote = DawaLearningState(
        savedIds: Set<String>.from(row['saved_content_ids'] ?? const []),
        completedIds:
            Set<String>.from(row['completed_content_ids'] ?? const []),
        offlineIds: local.offlineIds,
        coins: row['coin_balance'] as int? ?? local.coins,
        streak: row['streak_days'] as int? ?? local.streak,
      );
      await _saveLocal(remote);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Learning sync unavailable; using local state: ${error.code}');
      return local;
    }
  }

  Future<DawaLearningState> toggleSaved(
    DawaLearningState state,
    String id,
  ) async {
    final saved = {...state.savedIds};
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    return _persist(state.copyWith(savedIds: saved));
  }

  Future<DawaLearningState> toggleOffline(
    DawaLearningState state,
    String id,
  ) async {
    final offline = {...state.offlineIds};
    offline.contains(id) ? offline.remove(id) : offline.add(id);
    return _persist(state.copyWith(offlineIds: offline));
  }

  Future<DawaLearningState> complete(
    DawaLearningState state,
    String id, {
    int rewardCoins = 0,
  }) async {
    final pending = await _pendingCompletionIds();
    if (state.completedIds.contains(id) && !pending.contains(id)) return state;
    final isNew = !state.completedIds.contains(id);
    final completed = {...state.completedIds, id};
    final local = isNew
        ? await _persist(
            state.copyWith(
              completedIds: completed,
              coins: state.coins + rewardCoins,
            ),
          )
        : state;
    await _setPendingCompletionIds({...pending, id});
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return local;
    try {
      final result = await client.rpc(
        'complete_dawa_mom_learning_item',
        params: {'p_content_id': id},
      );
      if (result is! Map) return local;
      final data = Map<String, dynamic>.from(result);
      final remote = local.copyWith(
        completedIds:
            Set<String>.from(data['completed_content_ids'] ?? completed),
        coins: data['coin_balance'] as int? ?? local.coins,
      );
      final remaining = await _pendingCompletionIds()
        ..remove(id);
      await _setPendingCompletionIds(remaining);
      await _saveLocal(remote);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Learning completion remains local: ${error.code}');
      return local;
    }
  }

  Future<DawaLearningState> redeem(
    DawaLearningState state, {
    required int cost,
  }) async {
    if (state.coins < cost) {
      throw const DawaLearningException(
        'You do not have enough points for this reward yet.',
      );
    }
    // Server-backed redemption is intentionally not simulated. The current
    // screen can preview the reward; an issued voucher requires the RPC
    // introduced by the optional backend migration and a successful response.
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw const DawaLearningException(
        'Please sign in before redeeming a reward.',
      );
    }
    try {
      final result = await client.rpc(
        'redeem_dawa_mom_reward',
        params: {
          'p_reward_code': 'free_scan_voucher',
          'p_cost': cost,
        },
      );
      final data = result is Map ? Map<String, dynamic>.from(result) : null;
      final balance = data?['coin_balance'] as int?;
      if (balance == null) {
        throw const DawaLearningException(
          'The reward service did not confirm a voucher.',
        );
      }
      return _persist(state.copyWith(coins: balance));
    } on PostgrestException catch (error) {
      debugPrint('Reward redemption unavailable: ${error.code}');
      throw const DawaLearningException(
        'Reward redemption is not available yet. Your points were not changed.',
      );
    }
  }

  Future<DawaLearningState> _persist(DawaLearningState state) async {
    await _saveLocal(state);
    unawaited(_sync(state));
    changes.value += 1;
    return state;
  }

  Future<void> _saveLocal(DawaLearningState state) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setStringList(_savedKey, state.savedIds.toList()..sort()),
      prefs.setStringList(_completedKey, state.completedIds.toList()..sort()),
      prefs.setStringList(_offlineKey, state.offlineIds.toList()..sort()),
      prefs.setInt(_coinsKey, state.coins),
      prefs.setInt(_streakKey, state.streak),
    ]);
  }

  Future<void> _sync(DawaLearningState state) async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client.from('dawa_mom_learning_state').upsert({
        'profile_id': userId,
        'saved_content_ids': state.savedIds.toList()..sort(),
        'completed_content_ids': state.completedIds.toList()..sort(),
      }, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      debugPrint('Learning state remains local: ${error.code}');
    }
  }

  Future<Set<String>> _pendingCompletionIds() async =>
      ((await _prefs).getStringList(_pendingCompletionKey) ?? const <String>[])
          .toSet();

  Future<void> _setPendingCompletionIds(Set<String> ids) async {
    await (await _prefs)
        .setStringList(_pendingCompletionKey, ids.toList()..sort());
  }

  Future<void> _flushPendingCompletions(SupabaseClient client) async {
    final pending = await _pendingCompletionIds();
    if (pending.isEmpty) return;
    final remaining = {...pending};
    for (final id in pending) {
      try {
        await client.rpc(
          'complete_dawa_mom_learning_item',
          params: {'p_content_id': id},
        );
        remaining.remove(id);
      } on PostgrestException catch (error) {
        debugPrint('Pending learning completion remains queued: ${error.code}');
      }
    }
    if (remaining.length != pending.length) {
      await _setPendingCompletionIds(remaining);
    }
  }
}

class DawaLearningException implements Exception {
  const DawaLearningException(this.message);

  final String message;

  @override
  String toString() => message;
}
