import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/games/presentation/dawa_games_pages.dart';

class DawaVisualTopicHubPage extends StatelessWidget {
  const DawaVisualTopicHubPage({super.key});

  static const routeName = 'VisualTopicHub';
  static const routePath = '/learn/topics';

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DawaAppHeader(
              title: 'Learning topics',
              eyebrow: 'VISUAL GUIDES',
              onBack: context.pop,
            ),
            Text(
              'Choose a topic',
              style: context.dawaDisplay.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              'Nine clear, illustrated guides you can revisit at any time.',
              style: context.dawaBody,
            ),
            const SizedBox(height: DawaSpacing.md),
            DawaResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 3,
              children: [
                for (final definition in dawaVisualTopics)
                  DawaContentThumbnailCard(
                    thumbnail: DawaContextualImage(
                      assetId: DawaLearningAssetRegistry.coverFor(
                        definition.topic,
                      ).id,
                      variant: DawaImageVariant.moduleThumbnail,
                      borderRadius: BorderRadius.zero,
                    ),
                    category: definition.category,
                    title: definition.title,
                    description: definition.subtitle,
                    durationMinutes: definition.durationMinutes,
                    actionLabel:
                        definition.topic == DawaLearningTopic.periodTracking
                            ? 'Play games'
                            : 'Open guide',
                    onOpen: () =>
                        context.push('/learn/topic/${definition.routeId}'),
                  ),
              ],
            ),
          ],
        ),
      );
}

class DawaVisualTopicGuidePage extends StatelessWidget {
  const DawaVisualTopicGuidePage({
    super.key,
    required this.topicId,
  });

  static const routeName = 'VisualTopicGuide';
  static const routePath = '/learn/topic/:topicId';

  final String topicId;

  @override
  Widget build(BuildContext context) {
    if (topicId == 'period-tracking') {
      return const DawaCycleGamesHubPage();
    }
    final definition = dawaVisualTopics.firstWhere(
      (item) => item.routeId == topicId,
      orElse: () => dawaVisualTopics.first,
    );
    final images = DawaLearningAssetRegistry.forTopic(definition.topic);
    final cover = images.first;
    return DawaPageScaffold(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaAppHeader(
            title: definition.category,
            eyebrow: 'VISUAL GUIDE',
            onBack: context.pop,
            onNotifications: () => context.push('/notifications'),
          ),
          DawaContextualImage(
            assetId: cover.id,
            variant: DawaImageVariant.articleHeader,
            heroTag: 'topic-${definition.routeId}-${cover.id}',
          ),
          const SizedBox(height: DawaSpacing.md),
          Text(definition.title, style: context.dawaDisplay),
          const SizedBox(height: DawaSpacing.xs),
          Text(definition.introduction, style: context.dawaBody),
          const SizedBox(height: DawaSpacing.lg),
          DawaSectionHeader(
            title: 'Learn step by step',
            subtitle:
                'The words below explain the idea; text inside an illustration is not medical instruction.',
          ),
          const SizedBox(height: DawaSpacing.sm),
          for (var index = 1; index < images.length; index++) ...[
            DawaCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DawaContextualImage(
                    assetId: images[index].id,
                    variant: DawaImageVariant.moduleThumbnail,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DawaRadii.medium),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(DawaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sectionTitle(images[index], index),
                          style: context.dawaSectionTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _sectionCopy(definition, images[index], index),
                          style: context.dawaBody,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DawaSpacing.sm),
          ],
          DawaCard(
            color: DawaColors.softGreen,
            borderColor: DawaColors.green.withValues(alpha: .25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DawaIconBadge(
                  icon: Icons.health_and_safety_outlined,
                  color: DawaColors.green,
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use this as general education',
                          style: context.dawaSectionTitle),
                      const SizedBox(height: 3),
                      Text(
                        definition.safetyNote,
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.sm),
          FilledButton.icon(
            onPressed: () => context.go(definition.actionRoute),
            icon: Icon(definition.actionIcon),
            label: Text(definition.actionLabel),
          ),
        ],
      ),
    );
  }

  static String _sectionTitle(DawaLearningAsset asset, int index) =>
      switch (asset.role) {
        DawaAssetRole.featured => 'Start with a clear conversation',
        DawaAssetRole.section => 'What support can look like',
        DawaAssetRole.contextual => 'Prepare your questions',
        DawaAssetRole.supporting => 'Put the guidance into practice',
        DawaAssetRole.stableCover => 'Introduction',
      } +
      (index > 4 ? ' · ${index + 1}' : '');

  static String _sectionCopy(
    DawaVisualTopicDefinition definition,
    DawaLearningAsset asset,
    int index,
  ) =>
      '${asset.visibleSubject} ${definition.sectionGuidance[index % definition.sectionGuidance.length]}';
}

class DawaVisualTopicDefinition {
  const DawaVisualTopicDefinition({
    required this.routeId,
    required this.topic,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.introduction,
    required this.sectionGuidance,
    required this.safetyNote,
    required this.durationMinutes,
    required this.actionLabel,
    required this.actionRoute,
    required this.actionIcon,
  });

  final String routeId;
  final DawaLearningTopic topic;
  final String category;
  final String title;
  final String subtitle;
  final String introduction;
  final List<String> sectionGuidance;
  final String safetyNote;
  final int durationMinutes;
  final String actionLabel;
  final String actionRoute;
  final IconData actionIcon;
}

const dawaVisualTopics = <DawaVisualTopicDefinition>[
  DawaVisualTopicDefinition(
    routeId: 'cervical-awareness',
    topic: DawaLearningTopic.cervicalCancerAwareness,
    category: 'Cervical health',
    title: 'Cervical cancer awareness',
    subtitle: 'Understand screening and prepare to speak with a health worker.',
    introduction:
        'Cervical screening can find cell changes before they become more serious. A health worker can explain which screening is available locally and when it is appropriate for you.',
    sectionGuidance: [
      'Ask the health worker to explain each step in words you understand.',
      'You can ask about privacy, comfort, timing, and what happens after the test.',
    ],
    safetyNote:
        'These illustrations do not diagnose cervical cancer or replace screening. Contact a clinic for advice that fits your age, history, and local services.',
    durationMinutes: 6,
    actionLabel: 'View care options',
    actionRoute: '/encounters',
    actionIcon: Icons.health_and_safety_outlined,
  ),
  DawaVisualTopicDefinition(
    routeId: 'screening-without-fear',
    topic: DawaLearningTopic.screeningWithoutFear,
    category: 'Screening',
    title: 'Screening Without Fear',
    subtitle: 'Know what to ask and make a plan that respects your comfort.',
    introduction:
        'It is normal to have questions about screening. You can ask the clinician to explain the purpose, what may happen, how privacy is protected, and whether you can pause.',
    sectionGuidance: [
      'A calm conversation before screening can help you feel prepared.',
      'Write down questions and agree on the next step with the clinic.',
    ],
    safetyNote:
        'Screening procedures and eligibility differ by clinic. The illustrations are general education, not a promise of a particular procedure or result.',
    durationMinutes: 5,
    actionLabel: 'Start the screening quest',
    actionRoute: '/learn/quests/screening',
    actionIcon: Icons.route_outlined,
  ),
  DawaVisualTopicDefinition(
    routeId: 'pregnancy-basics',
    topic: DawaLearningTopic.pregnancyBasics,
    category: 'Pregnancy basics',
    title: 'Pregnancy basics',
    subtitle: 'Everyday wellbeing and when to seek help.',
    introduction:
        'Regular antenatal care, varied food, safe water, rest, and following your clinician’s advice can support wellbeing during pregnancy.',
    sectionGuidance: [
      'Choose gentle activity only if it feels comfortable and your clinician has not advised against it.',
      'Keep clinic questions and important dates in one place.',
    ],
    safetyNote:
        'Seek urgent care for heavy bleeding, severe pain, seizures, trouble breathing, fainting, or a severe headache with vision changes. This guide is not a diagnosis.',
    durationMinutes: 8,
    actionLabel: 'View pregnancy tracking',
    actionRoute: '/periodTracker',
    actionIcon: Icons.pregnant_woman_rounded,
  ),
  DawaVisualTopicDefinition(
    routeId: 'second-trimester-foods',
    topic: DawaLearningTopic.secondTrimesterFoods,
    category: 'Nutrition',
    title: 'Foods for the second trimester',
    subtitle: 'Build varied meals from safe, familiar foods.',
    introduction:
        'Aim for variety across the day using foods available to you. A clinician can help if nausea, food access, allergies, or another health condition makes eating difficult.',
    sectionGuidance: [
      'Combine food groups where possible and drink safe water regularly.',
      'Wash produce and cook food safely; take supplements only as advised.',
    ],
    safetyNote:
        'The pictured meals are examples, not a prescribed diet. Ask a clinician for advice that reflects your health needs, culture, budget, and available foods.',
    durationMinutes: 6,
    actionLabel: 'Browse pregnancy lessons',
    actionRoute: '/learn',
    actionIcon: Icons.menu_book_outlined,
  ),
  DawaVisualTopicDefinition(
    routeId: 'clinic-visit',
    topic: DawaLearningTopic.preparingForClinicVisit,
    category: 'Clinic visits',
    title: 'Preparing for a clinic visit',
    subtitle: 'Bring the right details and make space for your questions.',
    introduction:
        'Before a visit, note your symptoms, medicines, allergies, important dates, and questions. Bring records the clinic has asked for.',
    sectionGuidance: [
      'Confirm the date, location, transport plan, and anything the clinic asked you to bring.',
      'Ask the clinician to explain findings and next steps without relying on an illustration.',
    ],
    safetyNote:
        'The scan-like pictures are illustrative and are not your results. Only a qualified clinician with your records can interpret a test or scan.',
    durationMinutes: 5,
    actionLabel: 'Open Care',
    actionRoute: '/encounters',
    actionIcon: Icons.calendar_month_outlined,
  ),
  DawaVisualTopicDefinition(
    routeId: 'myths-vs-fact',
    topic: DawaLearningTopic.mythsVsFact,
    category: 'Myths vs fact',
    title: 'Myths versus facts',
    subtitle: 'Pause, check the source, and ask when you are unsure.',
    introduction:
        'Health advice can be shared with good intentions and still be inaccurate. Check who created it, whether a trusted clinic supports it, and whether it fits your situation.',
    sectionGuidance: [
      'Bring uncertain advice to a health worker instead of acting on it alone.',
      'A respectful conversation can correct a myth without blaming the person who shared it.',
    ],
    safetyNote:
        'The cards shown inside the illustrations are visual examples only. Use the reviewed lesson text in DawaMom and advice from a qualified clinician.',
    durationMinutes: 6,
    actionLabel: 'Play a myth game',
    actionRoute: '/learn/games',
    actionIcon: Icons.sports_esports_outlined,
  ),
  DawaVisualTopicDefinition(
    routeId: 'period-tracking',
    topic: DawaLearningTopic.periodTracking,
    category: 'Period tracking',
    title: 'Understand and track your cycle',
    subtitle: 'Record dates and symptoms without treating estimates as facts.',
    introduction:
        'Cycle tracking can help you notice patterns. Predictions are estimates based on the dates you enter and can be less reliable when cycles vary.',
    sectionGuidance: [
      'Record what happened rather than changing a date to match an estimate.',
      'Choose clean period products that are safe, comfortable, and available to you.',
      'Review changes with a clinician if they worry you.',
    ],
    safetyNote:
        'Tracking cannot confirm pregnancy, contraception, fertility, or a diagnosis. Seek care for very heavy bleeding, severe pain, fainting, or other worrying symptoms.',
    durationMinutes: 7,
    actionLabel: 'Open cycle tracking',
    actionRoute: '/periodTracker',
    actionIcon: Icons.water_drop_outlined,
  ),
  DawaVisualTopicDefinition(
    routeId: 'antenatal-visits',
    topic: DawaLearningTopic.antenatalVisitsAndStages,
    category: 'Antenatal',
    title: 'Antenatal visits and pregnancy stages',
    subtitle: 'Understand why regular checks matter through pregnancy.',
    introduction:
        'Antenatal visits help a care team check your wellbeing, discuss the baby’s growth, answer questions, and plan the next visit.',
    sectionGuidance: [
      'What happens at a visit depends on your pregnancy stage and clinical needs.',
      'Ask what was checked, what the result means, and when to return.',
    ],
    safetyNote:
        'Charts and scan-like images are illustrative, not personal results. Keep scheduled care and seek urgent help for pregnancy danger signs.',
    durationMinutes: 8,
    actionLabel: 'View pregnancy journey',
    actionRoute: '/learn/pregnancy',
    actionIcon: Icons.pregnant_woman_rounded,
  ),
  DawaVisualTopicDefinition(
    routeId: 'postpartum-recovery',
    topic: DawaLearningTopic.postpartumRecovery,
    category: 'Postpartum',
    title: 'Postpartum recovery and support',
    subtitle: 'Rest, recover, and ask for support after birth.',
    introduction:
        'Recovery after birth is different for every mother. Rest when possible, follow discharge advice, attend postnatal checks, and ask for help with feeding or emotional wellbeing.',
    sectionGuidance: [
      'Tell a health worker about pain, bleeding, fever, wound concerns, feeding difficulties, or low mood.',
      'Support can include listening, practical help, and a clear follow-up plan.',
    ],
    safetyNote:
        'Seek urgent care for very heavy bleeding, chest pain, trouble breathing, seizures, fainting, fever with feeling very unwell, or thoughts of harming yourself or the baby.',
    durationMinutes: 8,
    actionLabel: 'Find care',
    actionRoute: '/encounters',
    actionIcon: Icons.health_and_safety_outlined,
  ),
];
