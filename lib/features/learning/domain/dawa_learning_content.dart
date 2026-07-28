import 'package:flutter/material.dart';

import '/design_system/dawa_components.dart';

enum DawaLearningType { article, audio, quest, guide }

class DawaLearningItem {
  const DawaLearningItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.type,
    required this.durationMinutes,
    required this.asset,
    required this.visualAssetId,
    required this.icon,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final DawaLearningType type;
  final int durationMinutes;
  final String asset;
  final String visualAssetId;
  final IconData icon;
  final String route;
}

abstract final class DawaLearningCatalog {
  static const topicCategories = <String>[
    'Pregnancy basics',
    'Nutrition',
    'Clinic visits',
    'Cervical health',
    'Screening',
    'Myths vs fact',
    'Period tracking',
    'Antenatal',
    'Postpartum',
  ];

  static const categories = <String>[
    'For you',
    ...topicCategories,
    'Audio',
  ];

  static const items = <DawaLearningItem>[
    DawaLearningItem(
      id: 'cervical-awareness',
      title: 'Cervical cancer awareness',
      subtitle:
          'Screening can find cell changes early. Learn what to expect and how to seek local care.',
      category: 'Cervical health',
      type: DawaLearningType.article,
      durationMinutes: 6,
      asset: DawaArtwork.cervicalAwareness,
      visualAssetId: 'cervical_awareness_01',
      icon: Icons.health_and_safety_outlined,
      route: '/learn/article/cervical-awareness',
    ),
    DawaLearningItem(
      id: 'myth-vs-fact',
      title: 'Myth vs Fact: Foods and labour myths',
      subtitle:
          'Separate community myths from facts so you can make confident choices.',
      category: 'Myths vs fact',
      type: DawaLearningType.article,
      durationMinutes: 6,
      asset: DawaArtwork.motherLearning,
      visualAssetId: 'myths_vs_fact_01',
      icon: Icons.fact_check_outlined,
      route: '/learn/lesson/myth-vs-fact',
    ),
    DawaLearningItem(
      id: 'clinic-visit',
      title: 'How to prepare for your clinic visit',
      subtitle: 'Make the most of your visit and know what to ask.',
      category: 'Clinic visits',
      type: DawaLearningType.guide,
      durationMinutes: 5,
      asset: DawaArtwork.clinicianDoctor,
      visualAssetId: 'clinic_visit_01',
      icon: Icons.medical_services_outlined,
      route: '/learn/pregnancy/clinic-visit',
    ),
    DawaLearningItem(
      id: 'second-trimester-foods',
      title: 'Foods to eat in your second trimester',
      subtitle: 'Support your baby’s growth with nutrient-rich foods.',
      category: 'Nutrition',
      type: DawaLearningType.article,
      durationMinutes: 6,
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'second_trimester_foods_01',
      icon: Icons.restaurant_outlined,
      route: '/learn/pregnancy/second-trimester-foods',
    ),
    DawaLearningItem(
      id: 'pregnancy-basics',
      title: 'Pregnancy basics',
      subtitle:
          'Learn what happens in your body and how to care for yourself and your growing baby.',
      category: 'Pregnancy basics',
      type: DawaLearningType.audio,
      durationMinutes: 11,
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'pregnancy_basics_01',
      icon: Icons.headphones_rounded,
      route: '/learn/audio/pregnancy-basics',
    ),
    DawaLearningItem(
      id: 'screening-without-fear',
      title: 'Screening Without Fear',
      subtitle:
          'Learn how screening can find cell changes early and what a clinic visit may involve.',
      category: 'Screening',
      type: DawaLearningType.quest,
      durationMinutes: 5,
      asset: DawaArtwork.banaWelcome,
      visualAssetId: 'screening_without_fear_01',
      icon: Icons.route_outlined,
      route: '/learn/quests/screening',
    ),
    DawaLearningItem(
      id: 'period-tracking-guide',
      title: 'Understand and track your cycle',
      subtitle:
          'Learn the cycle phases, what to record, and practical period care.',
      category: 'Period tracking',
      type: DawaLearningType.guide,
      durationMinutes: 7,
      asset: DawaArtwork.cycleCalendar,
      visualAssetId: 'period_tracking_01',
      icon: Icons.water_drop_outlined,
      route: '/learn/topic/period-tracking',
    ),
    DawaLearningItem(
      id: 'antenatal-visits',
      title: 'Antenatal visits and pregnancy stages',
      subtitle:
          'See why regular visits matter and what may happen as pregnancy progresses.',
      category: 'Antenatal',
      type: DawaLearningType.guide,
      durationMinutes: 8,
      asset: DawaArtwork.pregnancyEarly,
      visualAssetId: 'antenatal_stages_01',
      icon: Icons.pregnant_woman_rounded,
      route: '/learn/topic/antenatal-visits',
    ),
    DawaLearningItem(
      id: 'postpartum-recovery',
      title: 'Postpartum recovery and support',
      subtitle:
          'Gentle recovery guidance, newborn support, and signs that need urgent care.',
      category: 'Postpartum',
      type: DawaLearningType.guide,
      durationMinutes: 8,
      asset: DawaArtwork.clinicianMidwife,
      visualAssetId: 'postpartum_recovery_01',
      icon: Icons.child_care_rounded,
      route: '/learn/topic/postpartum-recovery',
    ),
  ];

  static DawaLearningItem byId(String id) =>
      items.firstWhere((item) => item.id == id);
}

const dawaPregnancyBasicsTranscript = '''
Pregnancy brings many changes to your body. Regular antenatal visits help your care team monitor your health and your baby’s growth.

Eat a balanced variety of familiar foods, drink safe water, rest when you need to, and take medicines or supplements exactly as your clinician advises.

Seek urgent medical care for heavy bleeding, severe abdominal pain, trouble breathing, seizures, a severe headache with vision changes, fever, or reduced baby movement later in pregnancy.

Every pregnancy is different. If something worries you, contact your clinic. You can also ask Rudo for basic help while you arrange care.
''';
