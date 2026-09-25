import 'package:dawa_mom/content/dawa_learning_asset_registry.dart';
import 'package:dawa_mom/content/dawa_visual_rotation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  DawaVisualRotationRequest request(
    DateTime now, {
    Set<String> excluded = const {},
  }) =>
      DawaVisualRotationRequest(
        placement: DawaAssetPlacement.homeSpotlight,
        contextKey: 'home-test',
        topics: const [
          DawaLearningTopic.pregnancyBasics,
          DawaLearningTopic.secondTrimesterFoods,
          DawaLearningTopic.antenatalVisitsAndStages,
        ],
        cadence: DawaRotationCadence.daily,
        journey: DawaJourneyContext.pregnancy,
        userId: 'test-user-not-persisted',
        languageCode: 'ny',
        now: now,
        excludedAssetIds: excluded,
      );

  test('same daily request is stable across service instances', () async {
    final day = DateTime.utc(2026, 7, 28);
    final first = await DawaVisualRotationService().select(request(day));
    final second = await DawaVisualRotationService().select(request(day));
    expect(first, isNotNull);
    expect(second?.id, first?.id);
  });

  test('Home cycle thumbnail rotates only through the five approved images',
      () async {
    final request = DawaVisualRotationRequest(
      placement: DawaAssetPlacement.homeHero,
      contextKey: 'home-cycle-thumbnail',
      topics: const [DawaLearningTopic.periodTracking],
      cadence: DawaRotationCadence.daily,
      journey: DawaJourneyContext.cycle,
      userId: 'cycle-user',
      aspectRatio: 1,
      now: DateTime.utc(2026, 7, 28, 8),
    );
    final first = await DawaVisualRotationService().select(request);
    final rebuilt = await DawaVisualRotationService().select(request);
    expect(first?.id, rebuilt?.id);
    expect(
      first?.id,
      isIn({
        'period_tracking_01',
        'period_tracking_02',
        'period_tracking_03',
        'period_tracking_04',
        'period_tracking_05',
      }),
    );
  });

  test('moves predictably and avoids recently seen visuals', () async {
    final service = DawaVisualRotationService();
    final first = await service.select(request(DateTime.utc(2026, 7, 28)));
    final second = await service.select(request(DateTime.utc(2026, 7, 29)));
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(second?.id, isNot(first?.id));
  });

  test('honours on-screen duplicate exclusions', () async {
    final service = DawaVisualRotationService();
    final first = await service.select(request(DateTime.utc(2026, 7, 28)));
    final other = await service.select(
      request(
        DateTime.utc(2026, 7, 29),
        excluded: {first!.id},
      ),
    );
    expect(other?.id, isNot(first.id));
  });

  test('anonymous selection works fully offline', () async {
    final selected = await DawaVisualRotationService().select(
      DawaVisualRotationRequest(
        placement: DawaAssetPlacement.trackerEducation,
        contextKey: 'offline-track',
        topics: const [DawaLearningTopic.periodTracking],
        cadence: DawaRotationCadence.weekly,
        now: DateTime.utc(2026, 7, 28),
      ),
    );
    expect(selected, isNotNull);
    expect(selected?.topic, DawaLearningTopic.periodTracking);
  });

  test('stable cadence always returns the topic cover', () async {
    final selected = await DawaVisualRotationService().select(
      const DawaVisualRotationRequest(
        placement: DawaAssetPlacement.learnCard,
        contextKey: 'period-cover',
        topics: [DawaLearningTopic.periodTracking],
        cadence: DawaRotationCadence.stable,
      ),
    );
    expect(selected?.id, 'period_tracking_01');
  });

  test('weekly placement remains stable throughout the ISO week', () async {
    final service = DawaVisualRotationService(sessionToken: 'test-session');
    DawaVisualRotationRequest weekly(DateTime now) => DawaVisualRotationRequest(
          placement: DawaAssetPlacement.featuredBanner,
          contextKey: 'learn-weekly',
          topics: const [
            DawaLearningTopic.cervicalCancerAwareness,
            DawaLearningTopic.screeningWithoutFear,
            DawaLearningTopic.mythsVsFact,
          ],
          cadence: DawaRotationCadence.weekly,
          now: now,
        );
    final monday = await service.select(weekly(DateTime.utc(2026, 7, 27)));
    final sunday = await service.select(weekly(DateTime.utc(2026, 8, 2)));
    expect(monday, isNotNull);
    expect(sunday?.id, monday?.id);
  });

  test('pure selector deprioritizes every recently seen candidate', () {
    final candidates = DawaLearningAssetRegistry.eligible(
      placement: DawaAssetPlacement.trackerEducation,
      topics: const [DawaLearningTopic.periodTracking],
    );
    final recentlySeen = {candidates.first.id, candidates[1].id};
    final selected = DawaVisualRotationService.selectDeterministically(
      candidates: candidates,
      seed: 'recent-history-test',
      recentlySeen: recentlySeen,
    );
    expect(recentlySeen, isNot(contains(selected.id)));
  });
}
