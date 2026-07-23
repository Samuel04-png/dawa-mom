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

class DawaRewardRedemption {
  const DawaRewardRedemption({
    required this.state,
    required this.rewardCode,
    required this.voucherCode,
    required this.alreadyRedeemed,
  });

  final DawaLearningState state;
  final String rewardCode;
  final String voucherCode;
  final bool alreadyRedeemed;
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
  static const _freeScanVoucherKey = 'dawa_reward_free_scan_voucher';
  static const _localOwnerKey = 'dawa_learning_local_owner';

  String? _preparedStorageScope;

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
    await _prepareOwnerScopedStorage();
    final prefs = await _prefs;
    final local = DawaLearningState(
      savedIds:
          (prefs.getStringList(_keyFor(_savedKey)) ?? const <String>[]).toSet(),
      completedIds:
          (prefs.getStringList(_keyFor(_completedKey)) ?? const <String>[])
              .toSet(),
      offlineIds:
          (prefs.getStringList(_keyFor(_offlineKey)) ?? const <String>[])
              .toSet(),
      coins: prefs.getInt(_keyFor(_coinsKey)) ?? 180,
      streak: prefs.getInt(_keyFor(_streakKey)) ?? 1,
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
  }) async =>
      (await redeemReward(state, cost: cost)).state;

  Future<DawaRewardRedemption> redeemReward(
    DawaLearningState state, {
    required int cost,
  }) async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw const DawaLearningException(
        'Please sign in before redeeming a reward.',
      );
    }
    if (state.coins < cost) {
      final previous = await loadRedemption(state: state);
      if (previous != null) return previous;
      throw const DawaLearningException(
        'You do not have enough points for this reward yet.',
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
      final voucherCode = data?['voucher_code']?.toString();
      if (balance == null || voucherCode == null || voucherCode.isEmpty) {
        throw const DawaLearningException(
          'The reward service did not confirm a voucher.',
        );
      }
      final next = await _persist(state.copyWith(coins: balance));
      await (await _prefs).setString(_keyFor(_freeScanVoucherKey), voucherCode);
      return DawaRewardRedemption(
        state: next,
        rewardCode: data?['reward_code']?.toString() ?? 'free_scan_voucher',
        voucherCode: voucherCode,
        alreadyRedeemed: data?['already_redeemed'] as bool? ?? false,
      );
    } on PostgrestException catch (error) {
      debugPrint('Reward redemption unavailable: ${error.code}');
      if (error.code == '23514') {
        throw const DawaLearningException(
          'You do not have enough points for this reward yet.',
        );
      }
      throw const DawaLearningException(
        'Reward redemption is not available yet. Your points were not changed.',
      );
    }
  }

  Future<DawaRewardRedemption?> loadRedemption({
    DawaLearningState? state,
  }) async {
    await _prepareOwnerScopedStorage();
    final current = state ?? await load();
    final prefs = await _prefs;
    final localVoucher = prefs.getString(_keyFor(_freeScanVoucherKey));
    if (localVoucher != null && localVoucher.isNotEmpty) {
      return DawaRewardRedemption(
        state: current,
        rewardCode: 'free_scan_voucher',
        voucherCode: localVoucher,
        alreadyRedeemed: true,
      );
    }

    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    try {
      final row = await client
          .from('dawa_mom_reward_redemptions')
          .select('reward_code, voucher_code')
          .eq('profile_id', userId)
          .eq('reward_code', 'free_scan_voucher')
          .maybeSingle();
      final voucherCode = row?['voucher_code']?.toString();
      if (voucherCode == null || voucherCode.isEmpty) return null;
      await prefs.setString(_keyFor(_freeScanVoucherKey), voucherCode);
      return DawaRewardRedemption(
        state: current,
        rewardCode: row?['reward_code']?.toString() ?? 'free_scan_voucher',
        voucherCode: voucherCode,
        alreadyRedeemed: true,
      );
    } on PostgrestException catch (error) {
      debugPrint('Reward voucher lookup unavailable: ${error.code}');
      return null;
    }
  }

  Future<DawaLearningState> _persist(DawaLearningState state) async {
    await _saveLocal(state);
    unawaited(_sync(state));
    changes.value += 1;
    return state;
  }

  Future<void> _saveLocal(DawaLearningState state) async {
    await _prepareOwnerScopedStorage();
    final prefs = await _prefs;
    await Future.wait([
      prefs.setStringList(
        _keyFor(_savedKey),
        state.savedIds.toList()..sort(),
      ),
      prefs.setStringList(
        _keyFor(_completedKey),
        state.completedIds.toList()..sort(),
      ),
      prefs.setStringList(
        _keyFor(_offlineKey),
        state.offlineIds.toList()..sort(),
      ),
      prefs.setInt(_keyFor(_coinsKey), state.coins),
      prefs.setInt(_keyFor(_streakKey), state.streak),
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

  Future<Set<String>> _pendingCompletionIds() async {
    await _prepareOwnerScopedStorage();
    return ((await _prefs).getStringList(_keyFor(_pendingCompletionKey)) ??
            const <String>[])
        .toSet();
  }

  Future<void> _setPendingCompletionIds(Set<String> ids) async {
    await _prepareOwnerScopedStorage();
    await (await _prefs).setStringList(
      _keyFor(_pendingCompletionKey),
      ids.toList()..sort(),
    );
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

  String _keyFor(String base) {
    final userId = _supabase?.auth.currentUser?.id;
    return userId == null ? base : '${base}_$userId';
  }

  Future<void> _prepareOwnerScopedStorage() async {
    final userId = _supabase?.auth.currentUser?.id;
    final scope = userId ?? 'guest';
    if (_preparedStorageScope == scope) return;
    _preparedStorageScope = scope;
    if (userId == null) return;

    final prefs = await _prefs;
    final owner = prefs.getString(_localOwnerKey);
    if (owner != null && owner != userId) return;
    if (!prefs.containsKey(_keyFor(_completedKey))) {
      for (final base in [
        _savedKey,
        _completedKey,
        _offlineKey,
        _pendingCompletionKey,
      ]) {
        final legacy = prefs.getStringList(base);
        if (legacy != null) {
          await prefs.setStringList(_keyFor(base), legacy);
        }
      }
      for (final base in [_coinsKey, _streakKey]) {
        final legacy = prefs.getInt(base);
        if (legacy != null) await prefs.setInt(_keyFor(base), legacy);
      }
      final voucher = prefs.getString(_freeScanVoucherKey);
      if (voucher != null && voucher.isNotEmpty) {
        await prefs.setString(_keyFor(_freeScanVoucherKey), voucher);
      }
    }
    await prefs.setString(_localOwnerKey, userId);
  }
}

class DawaLearningException implements Exception {
  const DawaLearningException(this.message);

  final String message;

  @override
  String toString() => message;
}
