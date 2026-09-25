import 'package:flutter/material.dart';

/// The nine visual learning topics supplied for DawaMom.
enum DawaLearningTopic {
  cervicalCancerAwareness,
  screeningWithoutFear,
  pregnancyBasics,
  secondTrimesterFoods,
  preparingForClinicVisit,
  mythsVsFact,
  periodTracking,
  antenatalVisitsAndStages,
  postpartumRecovery,
}

enum DawaAssetPlacement {
  learnCard,
  featuredBanner,
  lessonHeader,
  articleSection,
  contextualTip,
  relatedContent,
  audioLesson,
  homeHero,
  homeSpotlight,
  trackHero,
  trackerEducation,
  careHero,
  carePreparation,
  questStep,
  gameCover,
  completion,
  notification,
  announcement,
  emptyState,
}

enum DawaAssetRole {
  stableCover,
  featured,
  section,
  contextual,
  supporting,
}

enum DawaJourneyContext {
  general,
  cycle,
  pregnancy,
  postpartum,
}

/// Intentional editorial treatments used by DawaMom image placements.
///
/// Widgets choose a role instead of inventing a local size or crop. An asset
/// can provide a focal override for any role whose crop needs special care.
enum DawaImageVariant {
  journeyHero,
  featuredBanner,
  moduleThumbnail,
  compactThumbnail,
  cardSideImage,
  articleHeader,
  announcementBanner,
  emptyState,
  avatarIllustration,
}

@immutable
class DawaCropSuitability {
  const DawaCropSuitability({
    required this.landscape,
    required this.square,
    required this.portrait,
    required this.wide,
  });

  final bool landscape;
  final bool square;
  final bool portrait;
  final bool wide;

  bool supports(double aspectRatio) {
    if (aspectRatio >= 1.65) return wide;
    if (aspectRatio >= 1.1) return landscape;
    if (aspectRatio >= .82) return square;
    return portrait;
  }
}

@immutable
class DawaLearningAsset {
  const DawaLearningAsset({
    required this.id,
    required this.topic,
    required this.role,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.visibleSubject,
    required this.accessibilityDescription,
    required this.localizedSemanticLabel,
    required this.placements,
    required this.tags,
    required this.focalAlignment,
    required this.variantAlignments,
    required this.supportedVariants,
    required this.cropSuitability,
    required this.isSensitive,
    required this.enabled,
    required this.priority,
  });

  final String id;
  final DawaLearningTopic topic;
  final DawaAssetRole role;
  final String assetPath;
  final int width;
  final int height;
  final String visibleSubject;
  final String accessibilityDescription;

  /// English source text passed through DawaMom's localization layer.
  final String localizedSemanticLabel;
  final Set<DawaAssetPlacement> placements;
  final Set<String> tags;
  final Alignment focalAlignment;
  final Map<DawaImageVariant, Alignment> variantAlignments;
  final Set<DawaImageVariant> supportedVariants;
  final DawaCropSuitability cropSuitability;
  final bool isSensitive;
  final bool enabled;
  final int priority;

  double get aspectRatio => width / height;

  double get focalX => focalAlignment.x;

  double get focalY => focalAlignment.y;

  Alignment alignmentFor(DawaImageVariant variant) =>
      variantAlignments[variant] ?? focalAlignment;
}

@immutable
class _AssetSource {
  const _AssetSource(
    this.width,
    this.height,
    this.visibleSubject,
    this.accessibilityDescription, {
    this.alignment = Alignment.topCenter,
    this.variantAlignments = const <DawaImageVariant, Alignment>{},
    this.sensitive = false,
    this.extraTags = const <String>{},
  });

  final int width;
  final int height;
  final String visibleSubject;
  final String accessibilityDescription;
  final Alignment alignment;
  final Map<DawaImageVariant, Alignment> variantAlignments;
  final bool sensitive;
  final Set<String> extraTags;
}

@immutable
class _TopicSource {
  const _TopicSource({
    required this.slug,
    required this.outputFolder,
    required this.semanticLabel,
    required this.tags,
    required this.images,
  });

  final String slug;
  final String outputFolder;
  final String semanticLabel;
  final Set<String> tags;
  final List<_AssetSource> images;
}

/// Single source of truth for every image in the July 2026 learning collection.
///
/// The source collection contains 49 images: eight topics contain five images
/// and Period Tracking contains nine. No runtime screen should construct a raw
/// `assets/dawa_learning_assets/...` path outside this registry.
abstract final class DawaLearningAssetRegistry {
  static final List<DawaLearningAsset> assets = _buildAssets();

  static final Map<String, DawaLearningAsset> _byId = {
    for (final asset in assets) asset.id: asset,
  };

  static DawaLearningAsset byId(String id) {
    final asset = _byId[id];
    if (asset == null) {
      throw ArgumentError.value(id, 'id', 'Unknown Dawa learning asset');
    }
    return asset;
  }

  static DawaLearningAsset? maybeById(String? id) =>
      id == null ? null : _byId[id];

  static List<DawaLearningAsset> forTopic(
    DawaLearningTopic topic, {
    DawaAssetPlacement? placement,
    double? aspectRatio,
    bool includeSensitive = true,
  }) =>
      assets
          .where(
            (asset) =>
                asset.enabled &&
                asset.topic == topic &&
                (placement == null || asset.placements.contains(placement)) &&
                (aspectRatio == null ||
                    asset.cropSuitability.supports(aspectRatio)) &&
                (includeSensitive || !asset.isSensitive),
          )
          .toList(growable: false);

  static List<DawaLearningAsset> eligible({
    required DawaAssetPlacement placement,
    Iterable<DawaLearningTopic>? topics,
    double? aspectRatio,
    bool includeSensitive = true,
  }) {
    final topicSet = topics?.toSet();
    return assets
        .where(
          (asset) =>
              asset.enabled &&
              asset.placements.contains(placement) &&
              (topicSet == null || topicSet.contains(asset.topic)) &&
              (aspectRatio == null ||
                  asset.cropSuitability.supports(aspectRatio)) &&
              (includeSensitive || !asset.isSensitive),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final priority = b.priority.compareTo(a.priority);
        return priority == 0 ? a.id.compareTo(b.id) : priority;
      });
  }

  static DawaLearningAsset coverFor(DawaLearningTopic topic) =>
      forTopic(topic).firstWhere(
        (asset) => asset.role == DawaAssetRole.stableCover,
      );

  static List<DawaLearningTopic> topicsForJourney(
    DawaJourneyContext journey,
  ) =>
      switch (journey) {
        DawaJourneyContext.cycle => const [
            DawaLearningTopic.periodTracking,
            DawaLearningTopic.mythsVsFact,
            DawaLearningTopic.preparingForClinicVisit,
          ],
        DawaJourneyContext.pregnancy => const [
            DawaLearningTopic.antenatalVisitsAndStages,
            DawaLearningTopic.pregnancyBasics,
            DawaLearningTopic.secondTrimesterFoods,
            DawaLearningTopic.preparingForClinicVisit,
            DawaLearningTopic.mythsVsFact,
          ],
        DawaJourneyContext.postpartum => const [
            DawaLearningTopic.postpartumRecovery,
            DawaLearningTopic.mythsVsFact,
            DawaLearningTopic.preparingForClinicVisit,
          ],
        DawaJourneyContext.general => const [
            DawaLearningTopic.cervicalCancerAwareness,
            DawaLearningTopic.screeningWithoutFear,
            DawaLearningTopic.mythsVsFact,
            DawaLearningTopic.preparingForClinicVisit,
          ],
      };

  static List<DawaLearningAsset> _buildAssets() {
    final result = <DawaLearningAsset>[];
    for (final entry in _topics.entries) {
      final topic = entry.key;
      final definition = entry.value;
      for (var index = 0; index < definition.images.length; index++) {
        final ordinal = index + 1;
        final image = definition.images[index];
        final id = '${definition.slug}_${ordinal.toString().padLeft(2, '0')}';
        final ratio = image.width / image.height;
        final placements = {..._placementsFor(topic, ordinal)};
        if (image.sensitive) {
          placements
            ..remove(DawaAssetPlacement.notification)
            ..remove(DawaAssetPlacement.announcement);
        }
        result.add(
          DawaLearningAsset(
            id: id,
            topic: topic,
            role: _roleFor(ordinal),
            assetPath:
                'assets/dawa_learning_assets/${definition.outputFolder}/$id.webp',
            width: image.width,
            height: image.height,
            visibleSubject: image.visibleSubject,
            accessibilityDescription: image.accessibilityDescription,
            localizedSemanticLabel: definition.semanticLabel,
            placements: Set.unmodifiable(placements),
            tags: {
              ...definition.tags,
              ...image.extraTags,
              _roleFor(ordinal).name,
            },
            focalAlignment: image.alignment,
            variantAlignments: Map.unmodifiable(image.variantAlignments),
            supportedVariants: Set.unmodifiable(
              _supportedVariantsFor(placements),
            ),
            cropSuitability: DawaCropSuitability(
              landscape: ratio >= 1.08,
              square: ratio >= .80,
              portrait: ratio <= 1.12,
              wide: ratio >= 1.22,
            ),
            isSensitive: image.sensitive,
            enabled: true,
            priority: 110 - ordinal,
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  static DawaAssetRole _roleFor(int ordinal) => switch (ordinal) {
        1 => DawaAssetRole.stableCover,
        2 => DawaAssetRole.featured,
        3 => DawaAssetRole.section,
        4 => DawaAssetRole.contextual,
        _ => DawaAssetRole.supporting,
      };

  static Set<DawaImageVariant> _supportedVariantsFor(
    Set<DawaAssetPlacement> placements,
  ) {
    final variants = <DawaImageVariant>{
      DawaImageVariant.moduleThumbnail,
      DawaImageVariant.compactThumbnail,
      DawaImageVariant.cardSideImage,
    };
    if (placements.any(
      {
        DawaAssetPlacement.homeHero,
        DawaAssetPlacement.trackHero,
      }.contains,
    )) {
      variants.add(DawaImageVariant.journeyHero);
    }
    if (placements.any(
      {
        DawaAssetPlacement.featuredBanner,
        DawaAssetPlacement.careHero,
      }.contains,
    )) {
      variants.add(DawaImageVariant.featuredBanner);
    }
    if (placements.any(
      {
        DawaAssetPlacement.lessonHeader,
        DawaAssetPlacement.articleSection,
        DawaAssetPlacement.questStep,
        DawaAssetPlacement.gameCover,
      }.contains,
    )) {
      variants.add(DawaImageVariant.articleHeader);
    }
    if (placements.any(
      {
        DawaAssetPlacement.announcement,
        DawaAssetPlacement.homeSpotlight,
      }.contains,
    )) {
      variants.add(DawaImageVariant.announcementBanner);
    }
    if (placements.contains(DawaAssetPlacement.emptyState)) {
      variants.add(DawaImageVariant.emptyState);
    }
    return variants;
  }

  static Set<DawaAssetPlacement> _placementsFor(
    DawaLearningTopic topic,
    int ordinal,
  ) {
    final shared = switch (ordinal) {
      1 => <DawaAssetPlacement>{
          DawaAssetPlacement.learnCard,
          DawaAssetPlacement.lessonHeader,
        },
      2 => <DawaAssetPlacement>{
          DawaAssetPlacement.featuredBanner,
          DawaAssetPlacement.homeSpotlight,
          DawaAssetPlacement.announcement,
        },
      3 => <DawaAssetPlacement>{
          DawaAssetPlacement.articleSection,
          DawaAssetPlacement.questStep,
        },
      4 => <DawaAssetPlacement>{
          DawaAssetPlacement.contextualTip,
          DawaAssetPlacement.gameCover,
        },
      _ => <DawaAssetPlacement>{
          DawaAssetPlacement.relatedContent,
          DawaAssetPlacement.notification,
          DawaAssetPlacement.completion,
        },
    };
    final specific = switch (topic) {
      DawaLearningTopic.cervicalCancerAwareness => switch (ordinal) {
          1 => {DawaAssetPlacement.homeHero},
          3 || 4 => {DawaAssetPlacement.carePreparation},
          _ => const <DawaAssetPlacement>{},
        },
      DawaLearningTopic.screeningWithoutFear => {
          DawaAssetPlacement.questStep,
          if (ordinal == 1) DawaAssetPlacement.homeHero,
        },
      DawaLearningTopic.pregnancyBasics => {
          if (ordinal == 1) DawaAssetPlacement.audioLesson,
          if (ordinal == 2) DawaAssetPlacement.homeHero,
          if (ordinal == 5) DawaAssetPlacement.emptyState,
        },
      DawaLearningTopic.secondTrimesterFoods => {
          if (ordinal == 1) DawaAssetPlacement.homeSpotlight,
          if (ordinal == 4) DawaAssetPlacement.gameCover,
        },
      DawaLearningTopic.preparingForClinicVisit => {
          if (ordinal == 1 || ordinal == 2) DawaAssetPlacement.careHero,
          if (ordinal >= 3) DawaAssetPlacement.carePreparation,
          if (ordinal == 5) DawaAssetPlacement.emptyState,
        },
      DawaLearningTopic.mythsVsFact => {
          if (ordinal == 1) DawaAssetPlacement.gameCover,
          if (ordinal >= 2) DawaAssetPlacement.questStep,
        },
      DawaLearningTopic.periodTracking => {
          if (ordinal <= 5) DawaAssetPlacement.homeHero,
          if (ordinal == 1) DawaAssetPlacement.trackHero,
          if (ordinal >= 2) DawaAssetPlacement.trackerEducation,
          if (ordinal == 3 || ordinal == 7) DawaAssetPlacement.emptyState,
          if (ordinal == 8) DawaAssetPlacement.announcement,
          if (ordinal == 9) DawaAssetPlacement.gameCover,
        },
      DawaLearningTopic.antenatalVisitsAndStages => {
          if (ordinal <= 2) DawaAssetPlacement.trackHero,
          if (ordinal == 1) DawaAssetPlacement.homeHero,
          if (ordinal >= 3) DawaAssetPlacement.carePreparation,
        },
      DawaLearningTopic.postpartumRecovery => {
          if (ordinal == 1 || ordinal == 2) DawaAssetPlacement.homeHero,
          if (ordinal == 1) DawaAssetPlacement.lessonHeader,
          if (ordinal >= 3) DawaAssetPlacement.carePreparation,
        },
    };
    return Set.unmodifiable({...shared, ...specific});
  }

  static const _topics = <DawaLearningTopic, _TopicSource>{
    DawaLearningTopic.cervicalCancerAwareness: _TopicSource(
      slug: 'cervical_awareness',
      outputFolder: 'cervical_cancer_awareness',
      semanticLabel: 'Educational image about cervical health and screening',
      tags: {'cervical-health', 'screening', 'clinic', 'adult'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A woman and nurse review a uterus illustration on a tablet.',
          'A patient and nurse discussing cervical health using an educational tablet illustration.',
        ),
        _AssetSource(
          1448,
          1086,
          'A clinician leads a small community cervical-health discussion.',
          'A clinician sharing cervical-health information with a small group of women.',
        ),
        _AssetSource(
          1448,
          1086,
          'A patient and clinician review a cervical-health tablet image.',
          'A patient and clinician reviewing cervical-health information together.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse reassures a seated patient during a clinic conversation.',
          'A nurse offering reassurance during a private cervical-health conversation.',
        ),
        _AssetSource(
          1448,
          1086,
          'A patient and clinician discuss information shown on a tablet.',
          'A clinician explaining cervical-health information to a patient.',
        ),
      ],
    ),
    DawaLearningTopic.screeningWithoutFear: _TopicSource(
      slug: 'screening_without_fear',
      outputFolder: 'screening_without_fear',
      semanticLabel: 'Educational image about preparing for health screening',
      tags: {'screening', 'reassurance', 'clinic', 'cervical-health'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A patient and nurse discuss an anatomy illustration.',
          'A nurse calmly explaining a screening anatomy illustration to a patient.',
        ),
        _AssetSource(
          1448,
          1086,
          'A patient and clinician review a screening illustration.',
          'A patient and clinician talking through what screening may involve.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse shares a simple preparation checklist with a patient.',
          'A nurse and patient reviewing a screening preparation checklist.',
        ),
        _AssetSource(
          1448,
          1086,
          'A clinician reassures a patient in a private clinic setting.',
          'A clinician listening and offering reassurance before screening.',
        ),
        _AssetSource(
          1448,
          1086,
          'A clinician and patient make a care plan using a clipboard.',
          'A patient and clinician agreeing on the next screening step.',
        ),
      ],
    ),
    DawaLearningTopic.pregnancyBasics: _TopicSource(
      slug: 'pregnancy_basics',
      outputFolder: 'pregnancy_basics',
      semanticLabel: 'Educational image about pregnancy wellbeing',
      tags: {'pregnancy', 'wellbeing', 'antenatal', 'adult'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A smiling pregnant woman rests at home.',
          'A pregnant woman smiling and resting in a bright home setting.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman and nurse discuss a pregnancy chart.',
          'A nurse sharing pregnancy education with a pregnant woman.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman walks outdoors.',
          'A pregnant woman taking a gentle outdoor walk for wellbeing.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman reads and writes in a notebook at home.',
          'A pregnant woman planning and reading pregnancy information at home.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman sits with fruit, water, notes, and baby supplies.',
          'A pregnant woman preparing healthy food, water, and notes for pregnancy.',
        ),
      ],
    ),
    DawaLearningTopic.secondTrimesterFoods: _TopicSource(
      slug: 'second_trimester_foods',
      outputFolder: 'second_trimester_foods',
      semanticLabel: 'Educational image about balanced food during pregnancy',
      tags: {'pregnancy', 'nutrition', 'second-trimester', 'food'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A pregnant woman eats a balanced meal with vegetables nearby.',
          'A pregnant woman enjoying a varied balanced meal.',
        ),
        _AssetSource(
          1448,
          1086,
          'A clinician uses a plate guide during nutrition counselling.',
          'A clinician and pregnant woman discussing a balanced plate guide.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman sits at a table with varied familiar foods.',
          'A pregnant woman choosing from a variety of nutritious foods.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman prepares a fresh salad.',
          'A pregnant woman preparing a colourful salad at home.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman holds a balanced meal beside fresh produce.',
          'A pregnant woman with a balanced meal and a variety of fresh produce.',
        ),
      ],
    ),
    DawaLearningTopic.preparingForClinicVisit: _TopicSource(
      slug: 'clinic_visit',
      outputFolder: 'preparing_for_clinic_visit',
      semanticLabel: 'Educational image about preparing for a clinic visit',
      tags: {'clinic', 'appointment', 'preparation', 'pregnancy'},
      images: [
        _AssetSource(
          688,
          557,
          'A pregnant patient and nurse review a visit checklist.',
          'A pregnant patient and nurse preparing for a clinic visit with a checklist.',
          alignment: Alignment(0, -.2),
          variantAlignments: {
            DawaImageVariant.featuredBanner: Alignment(0, -.42),
            DawaImageVariant.announcementBanner: Alignment(0, -.36),
          },
        ),
        _AssetSource(
          705,
          557,
          'A nurse and pregnant patient review a visit calendar.',
          'A nurse and pregnant patient planning the timing of a clinic visit.',
          alignment: Alignment(0, -.18),
          variantAlignments: {
            DawaImageVariant.featuredBanner: Alignment(0, -.38),
            DawaImageVariant.announcementBanner: Alignment(0, -.3),
          },
        ),
        _AssetSource(
          458,
          556,
          'A pregnant patient shares questions with a clinician.',
          'A pregnant patient and clinician reviewing questions to ask during a visit.',
        ),
        _AssetSource(
          461,
          556,
          'A clinician shows illustrative scan images to a patient.',
          'A clinician explaining illustrative pregnancy scan images; these are not personal results.',
          sensitive: true,
          extraTags: {'illustrative-scan'},
        ),
        _AssetSource(
          465,
          556,
          'A patient and nurse make a plan using a tablet and clipboard.',
          'A patient and nurse making a clear plan for a clinic visit.',
        ),
      ],
    ),
    DawaLearningTopic.mythsVsFact: _TopicSource(
      slug: 'myths_vs_fact',
      outputFolder: 'myths_vs_fact',
      semanticLabel:
          'Educational image about discussing health myths and facts',
      tags: {'myth', 'fact', 'conversation', 'health-literacy'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A mother and nurse discuss an illustrated myth-and-fact card.',
          'A mother and nurse discussing a health myth and fact using illustrated cards.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse leads a small discussion with mothers.',
          'A nurse sharing clear health information with a small group of mothers.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse and mother compare illustrated myth and fact examples.',
          'A nurse helping a mother compare health myths with safer information.',
        ),
        _AssetSource(
          1448,
          1086,
          'A pregnant woman and nurse review illustrated examples.',
          'A pregnant woman and nurse discussing common pregnancy myths and facts.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse reassures a mother while explaining a fact card.',
          'A nurse listening to a mother and explaining reliable health information.',
        ),
      ],
    ),
    DawaLearningTopic.periodTracking: _TopicSource(
      slug: 'period_tracking',
      outputFolder: 'period_tracking',
      semanticLabel: 'Educational image about periods and cycle tracking',
      tags: {'period', 'cycle', 'tracking', 'menstrual-health'},
      images: [
        _AssetSource(
          596,
          538,
          'A woman records information beside a cycle wheel.',
          'A woman recording cycle information with an illustrated cycle wheel.',
          alignment: Alignment(0, -.12),
          variantAlignments: {
            DawaImageVariant.journeyHero: Alignment(0, -.24),
            DawaImageVariant.moduleThumbnail: Alignment(0, -.18),
            DawaImageVariant.compactThumbnail: Alignment(.12, -.2),
          },
        ),
        _AssetSource(
          837,
          538,
          'A clinician explains the menstrual cycle using a chart.',
          'A clinician explaining the phases of the menstrual cycle to a patient.',
          sensitive: true,
          alignment: Alignment.center,
          extraTags: {'anatomy'},
        ),
        _AssetSource(
          421,
          533,
          'Reusable pads, disposable pads, underwear, and a menstrual cup.',
          'A selection of period-care products arranged beside a small pouch.',
          alignment: Alignment.center,
        ),
        _AssetSource(
          507,
          533,
          'A woman uses a cycle-tracking app on her phone.',
          'A woman logging cycle information in a phone app.',
          alignment: Alignment.center,
        ),
        _AssetSource(
          492,
          533,
          'A woman rests with a drink beside a self-care poster.',
          'A woman resting while considering gentle menstrual self-care options.',
          alignment: Alignment(.18, -.08),
          variantAlignments: {
            DawaImageVariant.compactThumbnail: Alignment(.28, -.16),
          },
        ),
        _AssetSource(
          695,
          518,
          'A clinician explains a menstrual-cycle wheel to a patient.',
          'A clinician and patient discussing the phases of the menstrual cycle.',
          sensitive: true,
          extraTags: {'anatomy'},
        ),
        _AssetSource(
          737,
          518,
          'A cycle calendar and simple tracking reminders.',
          'A menstrual-cycle calendar with reminders to track, notice symptoms, and plan ahead.',
          alignment: Alignment.center,
        ),
        _AssetSource(
          695,
          552,
          'A health educator speaks with a small group about period health.',
          'A health educator leading a supportive group conversation about period health.',
        ),
        _AssetSource(
          737,
          552,
          'A woman organises period-care products beside a care checklist.',
          'A woman preparing period-care products and reviewing general care reminders.',
        ),
      ],
    ),
    DawaLearningTopic.antenatalVisitsAndStages: _TopicSource(
      slug: 'antenatal_stages',
      outputFolder: 'antenatal_visits_and_pregnancy_stages',
      semanticLabel:
          'Educational image about antenatal visits and pregnancy stages',
      tags: {'pregnancy', 'antenatal', 'stages', 'clinic'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A clinician explains pregnancy stages using a chart.',
          'A pregnant patient and clinician discussing pregnancy stages with an educational chart.',
        ),
        _AssetSource(
          1448,
          1086,
          'A clinician checks a pregnant patient with a stethoscope.',
          'A clinician carrying out a routine illustrative antenatal check.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse explains pregnancy development using a chart.',
          'A nurse and pregnant patient discussing how pregnancy changes across stages.',
        ),
        _AssetSource(
          1448,
          1086,
          'A clinician points to an illustrative ultrasound display.',
          'A clinician discussing an illustrative ultrasound display; it is not a personal scan result.',
          sensitive: true,
          extraTags: {'illustrative-scan'},
        ),
        _AssetSource(
          1448,
          1086,
          'A midwife leads a small antenatal education discussion.',
          'A midwife discussing pregnancy stages with two pregnant women.',
        ),
      ],
    ),
    DawaLearningTopic.postpartumRecovery: _TopicSource(
      slug: 'postpartum_recovery',
      outputFolder: 'postpartum_recovery',
      semanticLabel: 'Educational image about postpartum recovery and support',
      tags: {'postpartum', 'newborn', 'recovery', 'support'},
      images: [
        _AssetSource(
          1448,
          1086,
          'A new mother holding her baby speaks with a health worker.',
          'A new mother and health worker discussing postpartum recovery and support.',
        ),
        _AssetSource(
          1448,
          1086,
          'A mother rests in bed with her sleeping newborn.',
          'A mother resting safely with her newborn and water nearby.',
        ),
        _AssetSource(
          1448,
          1086,
          'A health worker checks in with a mother holding her baby.',
          'A health worker listening to a new mother during a postpartum check-in.',
        ),
        _AssetSource(
          1448,
          1086,
          'A nurse supports a mother feeding her newborn.',
          'A nurse offering respectful feeding support to a mother and newborn.',
          sensitive: true,
          extraTags: {'feeding-support'},
        ),
        _AssetSource(
          1448,
          1086,
          'A mother holding her baby talks with a clinician.',
          'A mother and clinician making a postpartum recovery plan.',
        ),
      ],
    ),
  };
}
