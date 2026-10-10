import 'dart:io';

import 'package:dawa_mom/content/dawa_learning_asset_registry.dart';
import 'package:dawa_mom/features/learning/domain/dawa_learning_content.dart';
import 'package:dawa_mom/localization/dawa_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DawaLearningAssetRegistry', () {
    test('accounts for all 49 supplied images with unique identifiers', () {
      final assets = DawaLearningAssetRegistry.assets;
      expect(assets, hasLength(49));
      expect(assets.map((asset) => asset.id).toSet(), hasLength(49));
      expect(assets.map((asset) => asset.assetPath).toSet(), hasLength(49));

      for (final topic in DawaLearningTopic.values) {
        final expected = topic == DawaLearningTopic.periodTracking ? 9 : 5;
        expect(
          DawaLearningAssetRegistry.forTopic(topic),
          hasLength(expected),
          reason: topic.name,
        );
      }
    });

    test('every optimized bundle file exists', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final asset in DawaLearningAssetRegistry.assets) {
        expect(File(asset.assetPath).existsSync(), isTrue,
            reason: asset.assetPath);
        expect(
          pubspec,
          contains('${File(asset.assetPath).parent.path}/'),
          reason: '${asset.assetPath} must be declared in the Flutter bundle',
        );
        expect(asset.width, greaterThan(0));
        expect(asset.height, greaterThan(0));
        expect(asset.aspectRatio, greaterThan(0));
      }
    });

    test('every item has complete metadata and a runtime placement', () {
      for (final asset in DawaLearningAssetRegistry.assets) {
        expect(asset.visibleSubject.trim(), isNotEmpty, reason: asset.id);
        expect(asset.accessibilityDescription.trim(), isNotEmpty,
            reason: asset.id);
        expect(asset.localizedSemanticLabel.trim(), isNotEmpty,
            reason: asset.id);
        expect(asset.tags, isNotEmpty, reason: asset.id);
        expect(asset.placements, isNotEmpty, reason: asset.id);
        expect(asset.supportedVariants, isNotEmpty, reason: asset.id);
        expect(asset.priority, greaterThan(0), reason: asset.id);
        expect(asset.enabled, isTrue, reason: asset.id);
        if (asset.isSensitive) {
          expect(
            asset.placements,
            isNot(contains(DawaAssetPlacement.notification)),
            reason: asset.id,
          );
          expect(
            asset.placements,
            isNot(contains(DawaAssetPlacement.announcement)),
            reason: asset.id,
          );
        }
      }
    });

    test('focal metadata supports role-specific editorial crops', () {
      final period = DawaLearningAssetRegistry.byId('period_tracking_01');
      final clinic = DawaLearningAssetRegistry.byId('clinic_visit_01');

      expect(period.focalX, inInclusiveRange(-1, 1));
      expect(period.focalY, inInclusiveRange(-1, 1));
      expect(
        period.alignmentFor(DawaImageVariant.journeyHero),
        isNot(period.focalAlignment),
      );
      expect(
        clinic.alignmentFor(DawaImageVariant.featuredBanner).y,
        lessThan(clinic.focalY),
      );
      expect(
        period.supportedVariants,
        contains(DawaImageVariant.journeyHero),
      );
      expect(
        clinic.supportedVariants,
        contains(DawaImageVariant.featuredBanner),
      );
    });

    test('has one stable cover for every topic', () {
      for (final topic in DawaLearningTopic.values) {
        final covers = DawaLearningAssetRegistry.forTopic(topic)
            .where((asset) => asset.role == DawaAssetRole.stableCover);
        expect(covers, hasLength(1), reason: topic.name);
        expect(DawaLearningAssetRegistry.coverFor(topic), covers.single);
      }
    });

    test('exposes exactly nine user-facing topic categories', () {
      expect(DawaLearningCatalog.topicCategories, hasLength(9));
      expect(DawaLearningCatalog.topicCategories.toSet(), hasLength(9));
    });

    test('semantic labels are connected to every supported locale', () {
      final source =
          DawaLearningAssetRegistry.assets.first.localizedSemanticLabel;
      for (final locale in DawaLanguages.locales.skip(1)) {
        expect(DawaTranslations.translate(source, locale), isNot(source));
      }
      expect(
        DawaTranslations.translate(source, const Locale('en', 'ZM')),
        source,
      );
    });

    test('journey personalization selects clinically relevant topics', () {
      expect(
        DawaLearningAssetRegistry.topicsForJourney(
          DawaJourneyContext.pregnancy,
        ),
        containsAll([
          DawaLearningTopic.pregnancyBasics,
          DawaLearningTopic.antenatalVisitsAndStages,
          DawaLearningTopic.secondTrimesterFoods,
        ]),
      );
      expect(
        DawaLearningAssetRegistry.topicsForJourney(
          DawaJourneyContext.postpartum,
        ).first,
        DawaLearningTopic.postpartumRecovery,
      );
      expect(
        DawaLearningAssetRegistry.topicsForJourney(
          DawaJourneyContext.cycle,
        ).first,
        DawaLearningTopic.periodTracking,
      );
    });
  });
}
