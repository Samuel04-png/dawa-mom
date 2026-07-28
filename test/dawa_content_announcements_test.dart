import 'dart:convert';

import 'package:dawa_mom/content/dawa_content_announcement_repository.dart';
import 'package:dawa_mom/content/dawa_learning_asset_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> announcement({
  String id = 'announcement-id',
  String assetId = 'cervical_awareness_02',
  String deepLink = '/learn/article/cervical-awareness',
  String startsAt = '2026-07-27T00:00:00Z',
  String? endsAt = '2026-07-30T00:00:00Z',
  List<String> journeys = const ['general'],
  List<String> profileStates = const [],
  List<String> placements = const ['home'],
  bool enabled = true,
  String? minVersion,
  String? maxVersion,
}) =>
    {
      'id': id,
      'slug': 'screening-week',
      'title': 'Screening week',
      'body': 'Read a clear screening guide.',
      'asset_id': assetId,
      'deep_link': deepLink,
      'journey_contexts': journeys,
      'required_profile_states': profileStates,
      'placements': placements,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'min_app_version': minVersion,
      'max_app_version': maxVersion,
      'priority': 20,
      'enabled': enabled,
    };

void main() {
  final now = DateTime.utc(2026, 7, 28, 12);

  test('shows only active, matching, registry-backed announcements', () {
    final items = DawaContentAnnouncementRepository.filterRows(
      [
        announcement(),
        announcement(id: 'expired', endsAt: '2026-07-28T11:00:00Z'),
        announcement(id: 'future', startsAt: '2026-07-29T00:00:00Z'),
        announcement(id: 'draft', enabled: false),
        announcement(id: 'unknown', assetId: 'unknown_01'),
        announcement(id: 'external', deepLink: 'https://example.com'),
      ],
      now: now,
      journey: DawaJourneyContext.general,
      placement: 'home',
    );
    expect(items.map((item) => item.id), ['announcement-id']);
  });

  test('filters journey, profile state, placement and app version', () {
    final row = announcement(
      journeys: ['pregnancy'],
      profileStates: ['profile_incomplete'],
      minVersion: '1.0.0',
      maxVersion: '1.4.0',
    );
    expect(
      DawaContentAnnouncementRepository.filterRows(
        [row],
        now: now,
        journey: DawaJourneyContext.pregnancy,
        placement: 'home',
        profileState: 'profile_incomplete',
        appVersion: '1.2.0',
      ),
      hasLength(1),
    );
    expect(
      DawaContentAnnouncementRepository.filterRows(
        [row],
        now: now,
        journey: DawaJourneyContext.cycle,
        placement: 'home',
        profileState: 'profile_incomplete',
        appVersion: '1.2.0',
      ),
      isEmpty,
    );
  });

  test('rejects unsafe or unhandled deep links', () {
    expect(
      DawaContentAnnouncementRepository.isSafeDeepLink('/learn/topics'),
      isTrue,
    );
    expect(
      DawaContentAnnouncementRepository.isSafeDeepLink('//evil.example'),
      isFalse,
    );
    expect(
      DawaContentAnnouncementRepository.isSafeDeepLink('/unknown/place'),
      isFalse,
    );
  });

  test('uses valid last-known content while offline', () async {
    SharedPreferences.setMockInitialValues({
      'dawa_content_announcements_v1': jsonEncode([announcement()]),
    });
    final repository = DawaContentAnnouncementRepository(
      clock: () => now,
    );
    final items = await repository.load(
      journey: DawaJourneyContext.general,
      placement: 'home',
    );
    expect(items, hasLength(1));
    expect(items.single.assetId, 'cervical_awareness_02');
  });

  test('expired cached content is never displayed', () async {
    SharedPreferences.setMockInitialValues({
      'dawa_content_announcements_v1': jsonEncode([
        announcement(endsAt: '2026-07-28T11:00:00Z'),
      ]),
    });
    final items = await DawaContentAnnouncementRepository(
      clock: () => now,
    ).load(
      journey: DawaJourneyContext.general,
      placement: 'home',
    );
    expect(items, isEmpty);
  });
}
