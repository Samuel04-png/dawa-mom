import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class DawaGameProgress {
  const DawaGameProgress({
    required this.gameId,
    required this.roundIndex,
    required this.correctAnswers,
    required this.updatedAt,
    this.pendingSync = false,
    this.contentVersion = 1,
  });

  final String gameId;
  final int roundIndex;
  final int correctAnswers;
  final DateTime updatedAt;
  final bool pendingSync;
  final int contentVersion;

  DawaGameProgress copyWith({
    int? roundIndex,
    int? correctAnswers,
    DateTime? updatedAt,
    bool? pendingSync,
    int? contentVersion,
  }) =>
      DawaGameProgress(
        gameId: gameId,
        roundIndex: roundIndex ?? this.roundIndex,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        updatedAt: updatedAt ?? this.updatedAt,
        pendingSync: pendingSync ?? this.pendingSync,
        contentVersion: contentVersion ?? this.contentVersion,
      );

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'round_index': roundIndex,
        'correct_answers': correctAnswers,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'pending_sync': pendingSync,
        'content_version': contentVersion,
      };

  static DawaGameProgress? fromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final gameId = json['game_id']?.toString();
    final updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '');
    if (gameId == null || gameId.isEmpty || updatedAt == null) return null;
    return DawaGameProgress(
      gameId: gameId,
      roundIndex: (json['round_index'] as num?)?.toInt() ??
          (json['current_round'] as num?)?.toInt() ??
          0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      updatedAt: updatedAt,
      pendingSync: json['pending_sync'] as bool? ?? false,
      contentVersion: (json['content_version'] as num?)?.toInt() ?? 1,
    );
  }
}

class DawaLearningState {
  const DawaLearningState({
    this.savedIds = const <String>{},
    this.completedIds = const <String>{},
    this.offlineIds = const <String>{},
    this.gameProgress = const <String, DawaGameProgress>{},
    this.coins = 180,
    this.streak = 1,
    this.balanceVerified = false,
  });

  final Set<String> savedIds;
  final Set<String> completedIds;
  final Set<String> offlineIds;
  final Map<String, DawaGameProgress> gameProgress;
  final int coins;
  final int streak;

  /// `coins` is displayable while offline, but only becomes reward-authoritative
  /// after it has been returned by the owner-scoped server ledger.
  final bool balanceVerified;

  DawaLearningState copyWith({
    Set<String>? savedIds,
    Set<String>? completedIds,
    Set<String>? offlineIds,
    Map<String, DawaGameProgress>? gameProgress,
    int? coins,
    int? streak,
    bool? balanceVerified,
  }) =>
      DawaLearningState(
        savedIds: savedIds ?? this.savedIds,
        completedIds: completedIds ?? this.completedIds,
        offlineIds: offlineIds ?? this.offlineIds,
        gameProgress: gameProgress ?? this.gameProgress,
        coins: coins ?? this.coins,
        streak: streak ?? this.streak,
        balanceVerified: balanceVerified ?? this.balanceVerified,
      );
}

class DawaRewardRedemption {
  const DawaRewardRedemption({
    required this.state,
    required this.rewardCode,
    required this.voucherCode,
    required this.alreadyRedeemed,
    this.id,
    this.claimId,
    this.claimReference,
    this.status = DawaVoucherStatus.claimed,
    this.expiresAt,
    this.qrPayload,
  });

  final DawaLearningState state;
  final String rewardCode;
  final String voucherCode;
  final bool alreadyRedeemed;
  final String? id;
  final String? claimId;
  final String? claimReference;
  final DawaVoucherStatus status;
  final DateTime? expiresAt;
  final String? qrPayload;
}

enum DawaVoucherStatus { claimed, redeemed, expired, cancelled }

DawaVoucherStatus dawaVoucherStatusFrom(Object? value) =>
    switch (value?.toString().toLowerCase()) {
      'redeemed' => DawaVoucherStatus.redeemed,
      'expired' => DawaVoucherStatus.expired,
      'cancelled' => DawaVoucherStatus.cancelled,
      _ => DawaVoucherStatus.claimed,
    };

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
  static const _gameProgressKey = 'dawa_learning_game_progress_v1';
  static const _coinsKey = 'dawa_learning_coins';
  static const _streakKey = 'dawa_learning_streak';
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
      gameProgress: _decodeGameProgress(
        prefs.getString(_keyFor(_gameProgressKey)),
      ),
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
      final baseRemote = DawaLearningState(
        savedIds: Set<String>.from(row['saved_content_ids'] ?? const []),
        completedIds:
            Set<String>.from(row['completed_content_ids'] ?? const []),
        offlineIds: local.offlineIds,
        gameProgress: local.gameProgress,
        coins: row['coin_balance'] as int? ?? local.coins,
        streak: row['streak_days'] as int? ?? local.streak,
        balanceVerified: true,
      );
      final remoteProgress = await _loadRemoteGameProgress(client, userId);
      final mergedProgress = {...remoteProgress};
      for (final progress in local.gameProgress.values) {
        final remote = mergedProgress[progress.gameId];
        if (progress.pendingSync ||
            remote == null ||
            progress.updatedAt.isAfter(remote.updatedAt)) {
          mergedProgress[progress.gameId] = progress;
        }
      }
      var remote = baseRemote.copyWith(gameProgress: mergedProgress);
      remote = await _flushPendingGameProgress(client, userId, remote);
      await _saveLocal(remote);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Learning sync unavailable; using local state: ${error.code}');
      return local;
    } on ClientException catch (error) {
      debugPrint(
        'Learning sync unavailable; using local state: ${error.runtimeType}',
      );
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
    // Content progress may be saved locally for offline learning, but points
    // are deliberately never calculated by Flutter. The `rewardCoins`
    // parameter remains for call-site compatibility and must not influence a
    // balance; the server-owned award ledger decides the amount exactly once.
    final local = isNew
        ? await _persist(
            state.copyWith(
              completedIds: completed,
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
        balanceVerified: true,
      );
      final remaining = await _pendingCompletionIds()
        ..remove(id);
      await _setPendingCompletionIds(remaining);
      await _saveLocal(remote);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Learning completion remains local: ${error.code}');
      return local;
    } on ClientException catch (error) {
      debugPrint('Learning completion remains local: ${error.runtimeType}');
      return local;
    }
  }

  /// Saves the next playable round immediately on-device, then mirrors it to
  /// the owner-scoped Supabase progress table when signed in and online.
  Future<DawaLearningState> saveGameProgress(
    DawaLearningState state, {
    required String gameId,
    required int roundIndex,
    required int correctAnswers,
    int contentVersion = 1,
  }) async {
    final progress = DawaGameProgress(
      gameId: gameId,
      roundIndex: roundIndex,
      correctAnswers: correctAnswers,
      updatedAt: DateTime.now().toUtc(),
      pendingSync: true,
      contentVersion: contentVersion,
    );
    var local = await _persist(
      state.copyWith(gameProgress: {...state.gameProgress, gameId: progress}),
    );
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return local;
    try {
      await _upsertGameProgress(client, userId, progress);
      local = local.copyWith(
        gameProgress: {
          ...local.gameProgress,
          gameId: progress.copyWith(pendingSync: false),
        },
      );
      await _saveLocal(local);
      return local;
    } on PostgrestException catch (error) {
      debugPrint('Game progress remains local: ${error.code}');
      return local;
    } on ClientException catch (error) {
      debugPrint('Game progress remains local: ${error.runtimeType}');
      return local;
    }
  }

  Future<DawaLearningState> clearGameProgress(
    DawaLearningState state,
    String gameId,
  ) async {
    final progress = {...state.gameProgress}..remove(gameId);
    final local = await _persist(state.copyWith(gameProgress: progress));
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return local;
    try {
      await client
          .from('dawa_mom_cycle_game_progress')
          .delete()
          .eq('profile_id', userId)
          .eq('game_id', gameId);
    } on PostgrestException catch (error) {
      debugPrint('Completed game progress cleanup deferred: ${error.code}');
    } on ClientException catch (error) {
      debugPrint(
        'Completed game progress cleanup deferred: ${error.runtimeType}',
      );
    }
    return local;
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
    if (state.balanceVerified && state.coins < cost) {
      final previous = await loadRedemption(state: state);
      if (previous != null) return previous;
      throw const DawaLearningException(
        'You do not have enough points for this reward yet.',
      );
    }
    try {
      dynamic result;
      try {
        result = await client.rpc(
          'claim_dawa_mom_reward',
          params: {'p_reward_code': 'free_scan_voucher'},
        );
      } on PostgrestException catch (error) {
        // The current production schema may not yet have the additive claim
        // RPC. Keep the released wallet usable during its approved rolling
        // deployment; the legacy RPC is replaced with a safe wrapper by the
        // migration before the new endpoint is enabled.
        if (error.code != 'PGRST202' && error.code != '42883') rethrow;
        result = await client.rpc(
          'redeem_dawa_mom_reward',
          params: {
            'p_reward_code': 'free_scan_voucher',
            'p_cost': cost,
          },
        );
      }
      final data = result is Map ? Map<String, dynamic>.from(result) : null;
      final balance = data?['coin_balance'] as int?;
      final voucherCode = data?['voucher_code']?.toString();
      if (balance == null || voucherCode == null || voucherCode.isEmpty) {
        throw const DawaLearningException(
          'The reward service did not confirm a voucher.',
        );
      }
      final next = await _persist(
        state.copyWith(coins: balance, balanceVerified: true),
      );
      return DawaRewardRedemption(
        state: next,
        rewardCode: data?['reward_code']?.toString() ?? 'free_scan_voucher',
        voucherCode: voucherCode,
        alreadyRedeemed: data?['already_redeemed'] as bool? ?? false,
        id: data?['id']?.toString(),
        claimId: data?['claim_id']?.toString(),
        claimReference: data?['claim_reference']?.toString() ?? voucherCode,
        status: dawaVoucherStatusFrom(data?['status']),
        expiresAt: DateTime.tryParse(data?['expires_at']?.toString() ?? ''),
        qrPayload: data?['qr_payload']?.toString(),
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
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    try {
      final row = await client
          .from('dawa_mom_reward_redemptions')
          .select()
          .eq('profile_id', userId)
          .eq('reward_code', 'free_scan_voucher')
          .maybeSingle();
      final voucherCode = row?['voucher_code']?.toString();
      if (voucherCode == null || voucherCode.isEmpty) return null;
      return DawaRewardRedemption(
        state: current,
        rewardCode: row?['reward_code']?.toString() ?? 'free_scan_voucher',
        voucherCode: voucherCode,
        alreadyRedeemed: true,
        id: row?['id']?.toString(),
        claimId: row?['claim_id']?.toString(),
        claimReference: row?['claim_reference']?.toString() ?? voucherCode,
        status: dawaVoucherStatusFrom(row?['status']),
        expiresAt: DateTime.tryParse(row?['expires_at']?.toString() ?? ''),
        qrPayload: _voucherQrPayload(row),
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

  String? _voucherQrPayload(Map<String, dynamic>? row) {
    final claimId = row?['claim_id']?.toString();
    final reference = row?['claim_reference']?.toString();
    if (claimId == null ||
        claimId.isEmpty ||
        reference == null ||
        reference.isEmpty) {
      return null;
    }
    return 'dawa-mom://voucher/$claimId?ref=$reference';
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
      prefs.setString(
        _keyFor(_gameProgressKey),
        jsonEncode({
          for (final entry in state.gameProgress.entries)
            entry.key: entry.value.toJson(),
        }),
      ),
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
    } on ClientException catch (error) {
      debugPrint('Learning state remains local: ${error.runtimeType}');
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
      } on ClientException catch (error) {
        debugPrint(
          'Pending learning completion remains queued: ${error.runtimeType}',
        );
      }
    }
    if (remaining.length != pending.length) {
      await _setPendingCompletionIds(remaining);
    }
  }

  Future<Map<String, DawaGameProgress>> _loadRemoteGameProgress(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      final rows = await client
          .from('dawa_mom_cycle_game_progress')
          .select()
          .eq('profile_id', userId);
      final result = <String, DawaGameProgress>{};
      for (final row in rows) {
        final progress = DawaGameProgress.fromJson(row);
        if (progress != null) result[progress.gameId] = progress;
      }
      return result;
    } on PostgrestException catch (error) {
      debugPrint('Remote game progress unavailable: ${error.code}');
      return const <String, DawaGameProgress>{};
    } on ClientException catch (error) {
      debugPrint('Remote game progress unavailable: ${error.runtimeType}');
      return const <String, DawaGameProgress>{};
    }
  }

  Future<DawaLearningState> _flushPendingGameProgress(
    SupabaseClient client,
    String userId,
    DawaLearningState state,
  ) async {
    final updated = {...state.gameProgress};
    for (final progress
        in state.gameProgress.values.where((item) => item.pendingSync)) {
      try {
        await _upsertGameProgress(client, userId, progress);
        updated[progress.gameId] = progress.copyWith(pendingSync: false);
      } on PostgrestException catch (error) {
        debugPrint('Pending game progress remains queued: ${error.code}');
      } on ClientException catch (error) {
        debugPrint(
          'Pending game progress remains queued: ${error.runtimeType}',
        );
      }
    }
    return state.copyWith(gameProgress: updated);
  }

  Future<void> _upsertGameProgress(
    SupabaseClient client,
    String userId,
    DawaGameProgress progress,
  ) =>
      client.from('dawa_mom_cycle_game_progress').upsert({
        'profile_id': userId,
        'game_id': progress.gameId,
        'current_round': progress.roundIndex,
        'correct_answers': progress.correctAnswers,
        'content_version': progress.contentVersion,
        'updated_at': progress.updatedAt.toUtc().toIso8601String(),
      }, onConflict: 'profile_id,game_id');

  static Map<String, DawaGameProgress> _decodeGameProgress(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const {};
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return const {};
      final result = <String, DawaGameProgress>{};
      for (final entry in decoded.entries) {
        final progress = DawaGameProgress.fromJson(entry.value);
        if (progress != null) result[progress.gameId] = progress;
      }
      return result;
    } on FormatException {
      return const {};
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
      final gameProgress = prefs.getString(_gameProgressKey);
      if (gameProgress != null && gameProgress.isNotEmpty) {
        await prefs.setString(_keyFor(_gameProgressKey), gameProgress);
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
