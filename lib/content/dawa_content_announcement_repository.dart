import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dawa_learning_asset_registry.dart';

@immutable
class DawaContentAnnouncement {
  const DawaContentAnnouncement({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.assetId,
    required this.deepLink,
    required this.journeyContexts,
    required this.requiredProfileStates,
    required this.placements,
    required this.startsAt,
    required this.priority,
    required this.enabled,
    this.endsAt,
    this.minAppVersion,
    this.maxAppVersion,
  });

  final String id;
  final String slug;
  final String title;
  final String body;
  final String assetId;
  final String deepLink;
  final Set<String> journeyContexts;
  final Set<String> requiredProfileStates;
  final Set<String> placements;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? minAppVersion;
  final String? maxAppVersion;
  final int priority;
  final bool enabled;

  factory DawaContentAnnouncement.fromJson(Map<String, dynamic> json) =>
      DawaContentAnnouncement(
        id: json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        title: json['title']?.toString().trim() ?? '',
        body: json['body']?.toString().trim() ?? '',
        assetId: json['asset_id']?.toString() ?? '',
        deepLink: json['deep_link']?.toString() ?? '',
        journeyContexts: _strings(json['journey_contexts']),
        requiredProfileStates: _strings(json['required_profile_states']),
        placements: _strings(json['placements']),
        startsAt:
            DateTime.tryParse(json['starts_at']?.toString() ?? '')?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '')?.toUtc(),
        minAppVersion: _optional(json['min_app_version']),
        maxAppVersion: _optional(json['max_app_version']),
        priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
        enabled: json['enabled'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'body': body,
        'asset_id': assetId,
        'deep_link': deepLink,
        'journey_contexts': journeyContexts.toList()..sort(),
        'required_profile_states': requiredProfileStates.toList()..sort(),
        'placements': placements.toList()..sort(),
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'min_app_version': minAppVersion,
        'max_app_version': maxAppVersion,
        'priority': priority,
        'enabled': enabled,
      };

  static Set<String> _strings(dynamic value) =>
      value is Iterable ? value.map((item) => item.toString()).toSet() : {};

  static String? _optional(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class DawaContentAnnouncementRepository {
  DawaContentAnnouncementRepository({
    SupabaseClient? client,
    Future<SharedPreferences>? preferences,
    DateTime Function()? clock,
  })  : _client = client,
        _preferences = preferences ?? SharedPreferences.getInstance(),
        _clock = clock ?? DateTime.now;

  factory DawaContentAnnouncementRepository.live() =>
      DawaContentAnnouncementRepository(client: Supabase.instance.client);

  factory DawaContentAnnouncementRepository.tryLive() {
    try {
      return DawaContentAnnouncementRepository.live();
    } catch (_) {
      return DawaContentAnnouncementRepository();
    }
  }

  static const _cacheKey = 'dawa_content_announcements_v1';
  static const _fields =
      'id,slug,title,body,asset_id,deep_link,journey_contexts,'
      'required_profile_states,placements,starts_at,ends_at,min_app_version,'
      'max_app_version,priority,enabled';

  final SupabaseClient? _client;
  final Future<SharedPreferences> _preferences;
  final DateTime Function() _clock;

  Future<List<DawaContentAnnouncement>> load({
    required DawaJourneyContext journey,
    required String placement,
    String? profileState,
    String appVersion = '1.0.0',
  }) async {
    List<Map<String, dynamic>> rows;
    try {
      final client = _client;
      if (client == null) throw const _OfflineAnnouncementSource();
      final response = await client
          .from('content_announcements')
          .select(_fields)
          .eq('enabled', true)
          .order('priority', ascending: false)
          .order('starts_at', ascending: false)
          .limit(50);
      rows = [
        for (final row in response) Map<String, dynamic>.from(row),
      ];
      await _writeCache(rows);
    } catch (error) {
      if (kDebugMode && error is! _OfflineAnnouncementSource) {
        debugPrint(
          '[ContentAnnouncements] Live content unavailable; using cache.',
        );
      }
      rows = await _readCache();
    }
    return filterRows(
      rows,
      now: _clock().toUtc(),
      journey: journey,
      placement: placement,
      profileState: profileState,
      appVersion: appVersion,
    );
  }

  @visibleForTesting
  static List<DawaContentAnnouncement> filterRows(
    Iterable<Map<String, dynamic>> rows, {
    required DateTime now,
    required DawaJourneyContext journey,
    required String placement,
    String? profileState,
    String appVersion = '1.0.0',
  }) {
    final result = <DawaContentAnnouncement>[];
    for (final row in rows) {
      final item = DawaContentAnnouncement.fromJson(row);
      final asset = DawaLearningAssetRegistry.maybeById(item.assetId);
      if (!item.enabled ||
          item.id.isEmpty ||
          item.title.isEmpty ||
          item.body.isEmpty ||
          item.startsAt.isAfter(now) ||
          (item.endsAt != null && !item.endsAt!.isAfter(now)) ||
          asset == null ||
          asset.isSensitive ||
          !isSafeDeepLink(item.deepLink) ||
          !item.placements.contains(placement) ||
          !_supportsPlacement(asset, placement) ||
          !_supportsVersion(item, appVersion)) {
        continue;
      }
      final journeys = item.journeyContexts;
      if (journeys.isNotEmpty &&
          !journeys.contains('general') &&
          !journeys.contains(journey.name)) {
        continue;
      }
      if (item.requiredProfileStates.isNotEmpty &&
          (profileState == null ||
              !item.requiredProfileStates.contains(profileState))) {
        continue;
      }
      result.add(item);
    }
    result.sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      return priority == 0 ? b.startsAt.compareTo(a.startsAt) : priority;
    });
    return List.unmodifiable(result);
  }

  @visibleForTesting
  static bool isSafeDeepLink(String value) {
    if (!value.startsWith('/') ||
        value.startsWith('//') ||
        value.contains('://')) {
      return false;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
    const allowedRoots = <String>[
      '/home',
      '/learn',
      '/encounters',
      '/periodTracker',
      '/notifications',
      '/settings',
      '/profileCompletion',
    ];
    return allowedRoots.any(
      (root) => uri.path == root || uri.path.startsWith('$root/'),
    );
  }

  Future<void> _writeCache(List<Map<String, dynamic>> rows) async {
    final safe = rows.take(50).map((row) {
      final item = DawaContentAnnouncement.fromJson(row);
      return item.toJson();
    }).toList();
    await (await _preferences).setString(_cacheKey, jsonEncode(safe));
  }

  Future<List<Map<String, dynamic>>> _readCache() async {
    final raw = (await _preferences).getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final row in decoded)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    } on FormatException {
      return const [];
    }
  }

  static bool _supportsPlacement(
    DawaLearningAsset asset,
    String placement,
  ) =>
      switch (placement) {
        'home' => asset.placements.any(
            {
              DawaAssetPlacement.announcement,
              DawaAssetPlacement.homeHero,
              DawaAssetPlacement.homeSpotlight,
            }.contains,
          ),
        'learn' => asset.placements.any(
            {
              DawaAssetPlacement.announcement,
              DawaAssetPlacement.featuredBanner,
              DawaAssetPlacement.learnCard,
            }.contains,
          ),
        'track' => asset.placements.any(
            {
              DawaAssetPlacement.announcement,
              DawaAssetPlacement.trackHero,
              DawaAssetPlacement.trackerEducation,
            }.contains,
          ),
        'care' => asset.placements.any(
            {
              DawaAssetPlacement.announcement,
              DawaAssetPlacement.careHero,
              DawaAssetPlacement.carePreparation,
            }.contains,
          ),
        'notification' =>
          asset.placements.contains(DawaAssetPlacement.notification),
        _ => false,
      };

  static bool _supportsVersion(
    DawaContentAnnouncement item,
    String appVersion,
  ) {
    final minimum = item.minAppVersion;
    final maximum = item.maxAppVersion;
    return (minimum == null || _compareVersions(appVersion, minimum) >= 0) &&
        (maximum == null || _compareVersions(appVersion, maximum) <= 0);
  }

  static int _compareVersions(String first, String second) {
    final a = _versionParts(first);
    final b = _versionParts(second);
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final left = index < a.length ? a[index] : 0;
      final right = index < b.length ? b[index] : 0;
      if (left != right) return left.compareTo(right);
    }
    return 0;
  }

  static List<int> _versionParts(String version) => version
      .split('+')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
}

class _OfflineAnnouncementSource implements Exception {
  const _OfflineAnnouncementSource();
}
