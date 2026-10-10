import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dawa_learning_asset_registry.dart';

enum DawaRotationCadence { stable, daily, weekly, session }

class DawaVisualRotationRequest {
  const DawaVisualRotationRequest({
    required this.placement,
    required this.contextKey,
    this.topics,
    this.cadence = DawaRotationCadence.daily,
    this.aspectRatio,
    this.excludedAssetIds = const <String>{},
    this.userId,
    this.languageCode = 'en',
    this.journey = DawaJourneyContext.general,
    this.now,
  });

  final DawaAssetPlacement placement;
  final String contextKey;
  final Iterable<DawaLearningTopic>? topics;
  final DawaRotationCadence cadence;
  final double? aspectRatio;
  final Set<String> excludedAssetIds;
  final String? userId;
  final String languageCode;
  final DawaJourneyContext journey;
  final DateTime? now;
}

/// Deterministic, local-first visual selection with a short recently-seen list.
///
/// The user's raw identifier is used only while calculating a hash. Storage
/// keys contain a hash of the display context and never contain a user id,
/// profile state, date of birth, pregnancy week, or other health information.
class DawaVisualRotationService {
  DawaVisualRotationService({
    Future<SharedPreferences>? preferences,
    DateTime Function()? clock,
    String? sessionToken,
  })  : _preferences = preferences ?? SharedPreferences.getInstance(),
        _clock = clock ?? DateTime.now,
        _sessionToken =
            sessionToken ?? DateTime.now().microsecondsSinceEpoch.toString();

  static const _namespace = 'dawa_visual_rotation_v1';
  static const _recentLimit = 8;

  final Future<SharedPreferences> _preferences;
  final DateTime Function() _clock;
  final String _sessionToken;

  Future<DawaLearningAsset?> select(
    DawaVisualRotationRequest request,
  ) async {
    final candidates = DawaLearningAssetRegistry.eligible(
      placement: request.placement,
      topics: request.topics ??
          DawaLearningAssetRegistry.topicsForJourney(request.journey),
      aspectRatio: request.aspectRatio,
      includeSensitive: request.placement != DawaAssetPlacement.notification &&
          request.placement != DawaAssetPlacement.announcement,
    ).where((asset) => !request.excludedAssetIds.contains(asset.id)).toList();
    if (candidates.isEmpty) return null;

    if (request.cadence == DawaRotationCadence.stable) {
      return candidates.firstWhere(
        (asset) => asset.role == DawaAssetRole.stableCover,
        orElse: () => candidates.first,
      );
    }

    final now = request.now ?? _clock();
    final token = _periodToken(request.cadence, now);
    final contextHash = _fnv1a(request.contextKey).toRadixString(16);
    final selectionKey =
        '$_namespace:selected:${request.placement.name}:$contextHash:$token';
    final prefs = await _preferences;
    final stored = DawaLearningAssetRegistry.maybeById(
      prefs.getString(selectionKey),
    );
    if (stored != null &&
        candidates.any((candidate) => candidate.id == stored.id)) {
      return stored;
    }

    final recentKey =
        '$_namespace:recent:${request.placement.name}:$contextHash';
    final recent = _readRecent(prefs.getString(recentKey));
    final selected = selectDeterministically(
      candidates: candidates,
      seed: _seedFor(request, token),
      recentlySeen: recent,
      periodOffset: _periodOffset(request.cadence, now),
    );
    await prefs.setString(selectionKey, selected.id);
    await prefs.setString(
      recentKey,
      jsonEncode(
        [selected.id, ...recent.where((id) => id != selected.id)]
            .take(_recentLimit)
            .toList(),
      ),
    );
    return selected;
  }

  static DawaLearningAsset selectDeterministically({
    required List<DawaLearningAsset> candidates,
    required String seed,
    Iterable<String> recentlySeen = const <String>[],
    int periodOffset = 0,
  }) {
    if (candidates.isEmpty) {
      throw ArgumentError.value(
        candidates,
        'candidates',
        'At least one visual candidate is required',
      );
    }
    final recent = recentlySeen.toSet();
    final fresh = candidates
        .where((candidate) => !recent.contains(candidate.id))
        .toList();
    final pool = fresh.isEmpty ? candidates : fresh;
    final stable = [...pool]..sort((a, b) => a.id.compareTo(b.id));
    final base = _fnv1a(seed) % stable.length;
    return stable[(base + periodOffset) % stable.length];
  }

  String _seedFor(DawaVisualRotationRequest request, String token) {
    final anonymousOrUser = request.userId?.trim().isNotEmpty == true
        ? _fnv1a(request.userId!.trim()).toRadixString(16)
        : 'anonymous';
    return [
      anonymousOrUser,
      request.contextKey,
      request.placement.name,
      request.journey.name,
      request.languageCode.toLowerCase(),
      token,
    ].join('|');
  }

  String _periodToken(DawaRotationCadence cadence, DateTime now) =>
      switch (cadence) {
        DawaRotationCadence.stable => 'stable',
        DawaRotationCadence.session => _sessionToken,
        DawaRotationCadence.daily =>
          '${now.year}-${_two(now.month)}-${_two(now.day)}',
        DawaRotationCadence.weekly =>
          '${_isoWeekYear(now)}-W${_two(_isoWeek(now))}',
      };

  static int _periodOffset(DawaRotationCadence cadence, DateTime now) =>
      switch (cadence) {
        DawaRotationCadence.stable => 0,
        DawaRotationCadence.session => 0,
        DawaRotationCadence.daily => DateTime.utc(now.year, now.month, now.day)
            .difference(DateTime.utc(2020))
            .inDays,
        DawaRotationCadence.weekly => DateTime.utc(now.year, now.month, now.day)
                .difference(DateTime.utc(2020))
                .inDays ~/
            7,
      };

  static List<String> _readRecent(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(value) as List);
    } on FormatException {
      return const [];
    }
  }

  static int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static int _isoWeek(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    return 1 +
        thursday
                .difference(
                  firstThursday.add(Duration(days: 4 - firstThursday.weekday)),
                )
                .inDays ~/
            7;
  }

  static int _isoWeekYear(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    return day.add(Duration(days: 4 - day.weekday)).year;
  }
}
