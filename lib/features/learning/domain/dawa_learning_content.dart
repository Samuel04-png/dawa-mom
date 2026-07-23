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
  final IconData icon;
  final String route;
}

abstract final class DawaLearningCatalog {
  static const categories = <String>[
    'For you',
    'Pregnancy',
    'Cervical health',
    'Myths vs fact',
    'Nutrition',
    'Audio',
  ];

  static const items = <DawaLearningItem>[
    DawaLearningItem(
      id: 'cervical-awareness',
      title: 'Cervical cancer awareness',
      subtitle:
          'Early screening can save lives. Learn the facts and protect your future.',
      category: 'Cervical health',
      type: DawaLearningType.article,
      durationMinutes: 6,
      asset: DawaArtwork.cervicalAwareness,
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
      icon: Icons.fact_check_outlined,
      route: '/learn/lesson/myth-vs-fact',
    ),
    DawaLearningItem(
      id: 'clinic-visit',
      title: 'How to prepare for your clinic visit',
      subtitle: 'Make the most of your visit and know what to ask.',
      category: 'Pregnancy',
      type: DawaLearningType.guide,
      durationMinutes: 5,
      asset: DawaArtwork.clinicianDoctor,
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
      icon: Icons.restaurant_outlined,
      route: '/learn/pregnancy/second-trimester-foods',
    ),
    DawaLearningItem(
      id: 'pregnancy-basics',
      title: 'Pregnancy basics',
      subtitle:
          'Learn what happens in your body and how to care for yourself and your growing baby.',
      category: 'Audio',
      type: DawaLearningType.audio,
      durationMinutes: 11,
      asset: DawaArtwork.pregnancyPhone,
      icon: Icons.headphones_rounded,
      route: '/learn/audio/pregnancy-basics',
    ),
    DawaLearningItem(
      id: 'screening-without-fear',
      title: 'Screening Without Fear',
      subtitle: 'Learn why screening is safe, simple and life-saving.',
      category: 'Cervical health',
      type: DawaLearningType.quest,
      durationMinutes: 5,
      asset: DawaArtwork.banaWelcome,
      icon: Icons.route_outlined,
      route: '/learn/quests/screening',
    ),
  ];

  static DawaLearningItem byId(String id) =>
      items.firstWhere((item) => item.id == id);
}

const dawaPregnancyBasicsTranscript = '''
Pregnancy brings many changes to your body. Regular antenatal visits help your care team monitor your health and your baby’s growth.

Eat a balanced variety of familiar foods, drink safe water, rest when you need to, and take medicines or supplements exactly as your clinician advises.

Seek urgent medical care for heavy bleeding, severe abdominal pain, trouble breathing, seizures, a severe headache with vision changes, fever, or reduced baby movement later in pregnancy.

Every pregnancy is different. If something worries you, contact your clinic or ask Rudo for general guidance while you arrange professional care.
''';
