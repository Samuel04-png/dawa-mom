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

/// Supported languages for the "Pregnancy basics" audio lesson.
///
/// This list drives both the ChoiceChip options shown to the user and the
/// keys used in [dawaPregnancyBasicsTranscripts] below. Keep them in sync:
/// every entry here must have a corresponding entry in the map (or the
/// lesson will silently fall back to English for that language).
const dawaPregnancyBasicsLanguages = <String>[
  'English',
  'Nyanja',
  'Bemba',
  'Tonga',
  'Shona',
  'Ndebele',
];

/// Locale-keyed transcripts for the "Pregnancy basics" audio lesson.
///
/// IMPORTANT -- DRAFT TRANSLATIONS, NOT YET REVIEWED:
/// Only the English entry is final. The Nyanja, Bemba, Tonga, Shona, and
/// Ndebele entries below are AI-assisted DRAFT translations and have not
/// been checked by a fluent speaker or a health-content reviewer. This
/// content includes urgent-care guidance (the third paragraph in every
/// language), so an inaccurate translation could genuinely mislead someone
/// in a health situation. Do not ship any of these until a native speaker
/// -- ideally with maternal-health-content experience -- has reviewed them
/// line by line, with particular attention to:
///   - "seizures" (kept descriptive rather than a single term in most
///     languages below, since a wrong single-word choice could be read as
///     something else entirely)
///   - "reduced baby movement" (a specific, actionable emergency sign)
///   - "severe headache with vision changes" (a pre-eclampsia warning sign)
/// Translation confidence, roughly: Shona and Ndebele are more likely to
/// be fluent overall; Nyanja is moderate; Bemba and Tonga are the weakest
/// and should get the closest review.
const dawaPregnancyBasicsTranscripts = <String, String>{
  'English': '''
Pregnancy brings many changes to your body. Regular antenatal visits help your care team monitor your health and your baby’s growth.

Eat a balanced variety of familiar foods, drink safe water, rest when you need to, and take medicines or supplements exactly as your clinician advises.

Seek urgent medical care for heavy bleeding, severe abdominal pain, trouble breathing, seizures, a severe headache with vision changes, fever, or reduced baby movement later in pregnancy.

Every pregnancy is different. If something worries you, contact your clinic. You can also ask Rudo for basic help while you arrange care.
''',
  // DRAFT -- needs native-speaker + clinical review before shipping.
  'Nyanja': '''
Pakati pamabweretsa kusintha kwakukulu m’thupi mwanu. Kupita ku zipatala za pakati nthawi zonse kumathandiza gulu lanu la chithandizo kuyang’anira thanzi lanu ndi kukula kwa mwana wanu.

Idyani zakudya zosiyanasiyana zomwe mumazidziwa, mwamwa madzi oyera, pumulani mukafunika, ndipo mumwe mankhwala kapena zowonjezera monga momwe dokotala wanu akunenera.

Funani chithandizo chamankhwala mwachangu ngati muli ndi kutuluka magazi kwambiri, kupweteka kwakukulu m’mimba, kuvutika kupuma, kukomoka kapena kugwedezeka kwa thupi (ma-seizures), mutu kupweteka kwambiri pamodzi ndi kusintha kwa maso, malungo, kapena kuchepa kwa kuyenda kwa mwana kumapeto kwa pakati.

Pakati paliponse ndi posiyana. Ngati pali chinthu chomwe chikukudetsani nkhawa, lumikizanani ndi chipatala chanu. Mutha kufunsanso Rudo kuti akuthandizeni pang’ono pamene mukukonzekera chithandizo.
''',
  // DRAFT -- lower confidence than the others; needs close native-speaker
  // + clinical review before shipping.
  'Bemba': '''
Ukwimita kuleta ukwaluka kwingi mu mubili obe. Ukuya ku ma klinik ya bakashana banono lyonse kulafwa ba team bakusakamana ukumona ubumi bobe no kukula kwa mwana obe.

Ilyani ifyakulya ifyapusanapusana ifyo mwaishibe, munwe amenshi ayasanguka, tuusheni ilyo mufwaikwa, kabili munweko imiti ukulingana ne fyo umuganga wenu akwebele.

Fwaisha ukwafwilishiwa kwa ndwalo mu kwangufyanya nga cakuti mulefuma umulopa ukwingi, ukulwala kwa mu mala ukwangi, ukukanya kupema bwino, ukuzungaana kwa mubili (ma-seizures), ukulwala mumutwe ukukalamba pamo no kwaluka kwa kumona, ilyeka, nangu ukucepa kwa kunyanta kwa mwana panuma mu bwimini.

Ubwimini bulapusana pa muntu na muntu. Nga cakuti kwaba icimulenga ukusakamana, landeni na kliniki yenu. Kuti mwipushako na Rudo ukukwafwako panono ilyo mulepekanya ubwafwilisho.
''',
  // DRAFT -- lower confidence than the others; needs close native-speaker
  // + clinical review before shipping.
  'Tonga': '''
Kwimita kuleta zintu zinji zichincha mumubili wako. Kuya kuzipatala zya kulanga-langa mimba lyonse kulagwasya nkamu njenu kulanga bulamfu bwako abukkomana bwa mwana wako.

Lya zilyo zisiyene-siyene nzimuzi, nywa maanzi asalala, lyokezye na kuyandika, alimwi munywe misamu naa zimwi mbuli mbwamwaambidwa a mung’anga wenu.

Yandaula lugwasyo lwabusena bwaziya cakufwambaana na kuli kutila bulowa bwingi, kuciswa kwa mala kwiindilide, kukachilwa kuumya, kuzungaana kwa mubili (ma-seizures), mutwe kuciswa kapati ampoyo kuchincha kwakubona, mupasu, naa kucepa kwakuyoba kwa mwana kumamanino aabwimi.

Kwimita takweelanide kumuntu kuya kumuntu. Na kwaba cimukatazya, amwaambe kucipatala cenu. Mulakonzya alimwi kubuzya Rudo lugwasyo luniini nomupanga bugwasyo.
''',
  // DRAFT -- needs native-speaker + clinical review before shipping.
  'Shona': '''
Pamuviri panounza shanduko dzakawanda mumuviri wako. Kuenda kudzidziso dzepamuviri (antenatal) nguva dzose kunobatsira vanokuchengeta kuti vaone hutano hwako nekukura kwemwana wako.

Idya zvokudya zvakasiyana-siyana zvaunoziva, unwe mvura yakachena, uzorore kana uchida, uye utore mishonga kana zvinowedzera sekurayirwa kwauinako nachiremba wako.

Tsvaga rubatsiro rwekurapa nekukurumidza kana paine kubuda ropa zvakanyanya, kurwadziwa nedumbu zvakanyanya, kutadza kufema zvakanaka, kudedzera kana kuzungaira kwemuviri (ma-seizures), kurwadziwa nemusoro zvakanyanya nekuchinja kwekuona, fivha, kana kudzikira kwekufamba kwemwana panguva yekupedzisira yepamuviri.

Pamuviri hunosiyana pane mumwe nomumwe. Kana pane chinokunetsa, taura nechipatara chako. Unogonawo kubvunza Rudo rubatsiro rwepakati-kati apo uchironga rubatsiro.
''',
  // DRAFT -- needs native-speaker + clinical review before shipping.
  'Ndebele': '''
Ukukhulelwa kuletha izinguquko ezinengi emzimbeni wakho. Ukuya emitholampilo yokuhlolwa kokukhulelwa njalonjalo kusiza ithimba lakho lokunakekela ukuqapha impilakahle yakho lokukhula komntwana wakho.

Dlana ukudla okuhlukahlukeneyo okujayelekileyo, unathe amanzi ahlanzekileyo, uphumule nxa kudingeka, njalo uthathe imithi loba okunye njengoba udokotela wakho ekutshela.

Dinga usizo lwezokwelapha ngokuphangisa nxa kulokopha okunengi, ubuhlungu obukhulu esiswini, ukungakwazi ukuphefumula kuhle, ukudonseka loba ukuzamazama komzimba (ama-seizures), ikhanda elibuhlungu kakhulu kanye lokuguquka kokubona, umkhuhlane, loba ukunyamalala kokunyakaza komntwana ngesikhathi sokuphela kokukhulelwa.

Ukukhulelwa akufani kumuntu lomuntu. Nxa kukhona okukukhathazayo, xhumana lomtholampilo wakho. Ungabuza njalo uRudo ukuthola usizo oluncane nxa usalungisa usizo.
''',
};