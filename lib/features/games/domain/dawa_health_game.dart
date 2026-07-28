import '/design_system/dawa_components.dart';
import 'package:flutter/material.dart';

enum DawaGameAnswer { first, second, third }

enum DawaGameActivity {
  general,
  phaseMatch,
  calendarDetective,
  logMeaning,
  kitBuilder,
  mythOrFact,
  careDecision,
  patternDetective,
  productMatch,
}

class DawaGameQuestion {
  const DawaGameQuestion({
    required this.prompt,
    required this.firstLabel,
    required this.secondLabel,
    required this.correctAnswer,
    required this.explanation,
    this.thirdLabel,
    this.urgentGuidance = false,
  });

  final String prompt;
  final String firstLabel;
  final String secondLabel;
  final String? thirdLabel;
  final DawaGameAnswer correctAnswer;
  final String explanation;

  /// Urgent rounds reveal their care guidance immediately and keep points
  /// visually secondary to the safety message.
  final bool urgentGuidance;

  List<(DawaGameAnswer, String)> get answers => [
        (DawaGameAnswer.first, firstLabel),
        (DawaGameAnswer.second, secondLabel),
        if (thirdLabel != null) (DawaGameAnswer.third, thirdLabel!),
      ];
}

class DawaHealthGame {
  const DawaHealthGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.asset,
    required this.visualAssetId,
    required this.completionAssetId,
    required this.rewardCoins,
    required this.questions,
    this.eyebrow = 'HEALTH GAME',
    this.activity = DawaGameActivity.general,
    this.durationMinutes = 3,
    this.instructions = 'Choose the best answer, then read the explanation.',
    this.relatedActionLabel = 'Open Learn',
    this.relatedActionRoute = '/learn',
    this.relatedActionIcon = Icons.arrow_forward_rounded,
    this.requiresClinicalReview = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final String asset;
  final String visualAssetId;
  final String completionAssetId;
  final int rewardCoins;
  final List<DawaGameQuestion> questions;
  final String eyebrow;
  final DawaGameActivity activity;
  final int durationMinutes;
  final String instructions;
  final String relatedActionLabel;
  final String relatedActionRoute;
  final IconData relatedActionIcon;
  final bool requiresClinicalReview;

  int get passingScore => (questions.length * .8).ceil();

  bool get isCycleGame => activity != DawaGameActivity.general;
}

abstract final class DawaHealthGameCatalog {
  static const mythMatchId = 'game-myth-match';
  static const nutritionSortId = 'game-nutrition-sort';
  static const phaseMatchId = 'cycle-game-phase-match';
  static const calendarDetectiveId = 'cycle-game-calendar-detective';
  static const logMeaningId = 'cycle-game-log-meaning';
  static const periodKitId = 'cycle-game-period-kit';
  static const periodMythFactId = 'cycle-game-myth-fact';
  static const selfCareOrHelpId = 'cycle-game-self-care-or-help';
  static const symptomPatternId = 'cycle-game-pattern-detective';
  static const periodProductsId = 'cycle-game-products-match';

  static const games = <DawaHealthGame>[
    DawaHealthGame(
      id: mythMatchId,
      title: 'Myth Match',
      subtitle: 'Separate common health myths from trusted facts.',
      route: '/learn/games/myth-match',
      asset: DawaArtwork.banaExplain,
      visualAssetId: 'myths_vs_fact_01',
      completionAssetId: 'myths_vs_fact_05',
      rewardCoins: 10,
      questions: [
        DawaGameQuestion(
          prompt:
              'Cervical screening can find cell changes before symptoms appear.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Fact. Screening can find early cell changes, when care may be simpler.',
        ),
        DawaGameQuestion(
          prompt:
              'You only need cervical screening when you feel pain or notice symptoms.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. Screening is designed for people without symptoms. Follow the schedule recommended by your clinic.',
        ),
        DawaGameQuestion(
          prompt:
              'A severe headache with blurred vision during pregnancy can wait until the next routine visit.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. A severe headache with vision changes can be a danger sign. Seek urgent clinical care now.',
        ),
        DawaGameQuestion(
          prompt:
              'Antenatal check-ups help monitor the health of both mother and baby.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Fact. Regular visits help a health worker check progress and act early.',
        ),
        DawaGameQuestion(
          prompt: 'Modern birth control permanently causes infertility.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. Most methods do not stop you from having a baby later. A health worker can help you choose an option.',
        ),
      ],
    ),
    DawaHealthGame(
      id: nutritionSortId,
      title: 'Plate Builder',
      subtitle: 'Sort pregnancy food choices into the safest group.',
      route: '/learn/games/plate-builder',
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'second_trimester_foods_04',
      completionAssetId: 'second_trimester_foods_05',
      rewardCoins: 10,
      eyebrow: 'NUTRITION GAME',
      questions: [
        DawaGameQuestion(
          prompt: 'Beans with cooked vegetables',
          firstLabel: 'Balanced choice',
          secondLabel: 'Avoid for now',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Balanced choice. Beans and vegetables can add fibre, protein and useful nutrients.',
        ),
        DawaGameQuestion(
          prompt: 'Unpasteurised milk',
          firstLabel: 'Balanced choice',
          secondLabel: 'Avoid for now',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Avoid for now. Unpasteurised dairy can carry harmful germs during pregnancy.',
        ),
        DawaGameQuestion(
          prompt: 'Fruit washed under safe running water',
          firstLabel: 'Balanced choice',
          secondLabel: 'Avoid for now',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Balanced choice. Washing fruit carefully helps remove soil and germs.',
        ),
        DawaGameQuestion(
          prompt: 'Alcohol during pregnancy',
          firstLabel: 'Balanced choice',
          secondLabel: 'Avoid for now',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Avoid for now. No amount of alcohol is known to be safe during pregnancy.',
        ),
        DawaGameQuestion(
          prompt: 'Eggs cooked until both white and yolk are firm',
          firstLabel: 'Balanced choice',
          secondLabel: 'Avoid for now',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Balanced choice. Thorough cooking lowers the chance of food-borne illness.',
        ),
      ],
    ),
    DawaHealthGame(
      id: phaseMatchId,
      title: 'Cycle Phase Match',
      subtitle: 'Match each cycle phase with a simple meaning.',
      route: '/learn/games/cycle-phase-match',
      asset: DawaArtwork.banaExplain,
      visualAssetId: 'period_tracking_02',
      completionAssetId: 'period_tracking_01',
      rewardCoins: 10,
      eyebrow: 'CYCLE BASICS',
      activity: DawaGameActivity.phaseMatch,
      durationMinutes: 3,
      instructions:
          'Tap the phase that best matches each description. Dates are estimates, not guarantees.',
      relatedActionLabel: 'Open cycle calendar',
      relatedActionRoute: '/periodTracker',
      relatedActionIcon: Icons.calendar_month_outlined,
      questions: [
        DawaGameQuestion(
          prompt: 'Bleeding usually marks the start of which cycle phase?',
          firstLabel: 'Menstruation',
          secondLabel: 'Ovulation',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Menstruation is the bleeding phase and is counted as the start of a new cycle.',
        ),
        DawaGameQuestion(
          prompt:
              'Which phase usually comes after menstruation and before ovulation?',
          firstLabel: 'Follicular phase',
          secondLabel: 'Luteal phase',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'The follicular phase usually follows menstruation as the body prepares for ovulation.',
        ),
        DawaGameQuestion(
          prompt: 'Which phase refers to the release of an egg?',
          firstLabel: 'Ovulation',
          secondLabel: 'Menstruation',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Ovulation refers to the release of an egg. An app can only estimate its timing.',
        ),
        DawaGameQuestion(
          prompt:
              'Which phase usually comes after ovulation and before the next period?',
          firstLabel: 'Follicular phase',
          secondLabel: 'Luteal phase',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'The luteal phase usually follows ovulation and ends when the next period begins.',
        ),
        DawaGameQuestion(
          prompt: 'An app shows a predicted cycle phase. What does that mean?',
          firstLabel: 'It is an estimate',
          secondLabel: 'It is guaranteed',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'It is an estimate based on the dates you logged. Bodies and cycle lengths can vary.',
        ),
      ],
    ),
    DawaHealthGame(
      id: calendarDetectiveId,
      title: 'Calendar Detective',
      subtitle: 'Spot logged days, predictions and dates to correct.',
      route: '/learn/games/calendar-detective',
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'period_tracking_01',
      completionAssetId: 'period_tracking_04',
      rewardCoins: 10,
      eyebrow: 'CALENDAR CHALLENGE',
      activity: DawaGameActivity.calendarDetective,
      durationMinutes: 4,
      instructions:
          'Look for the difference between what happened and what the app estimates.',
      relatedActionLabel: 'Review cycle history',
      relatedActionRoute: '/periodTracker',
      relatedActionIcon: Icons.history_rounded,
      questions: [
        DawaGameQuestion(
          prompt: 'Which date should be marked as a logged period day?',
          firstLabel: 'A day bleeding happened',
          secondLabel: 'A day the app guessed',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Log the day bleeding actually happened. Predicted days are only estimates.',
        ),
        DawaGameQuestion(
          prompt: 'A future date is shaded as “predicted”. What does it show?',
          firstLabel: 'A possible period day',
          secondLabel: 'A confirmed period day',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'A predicted day is a possible future date calculated from earlier logs.',
        ),
        DawaGameQuestion(
          prompt: 'What does “today” mean on the cycle calendar?',
          firstLabel: 'The current date',
          secondLabel: 'The next period date',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Today marks the current date. It can be different from a logged or predicted period day.',
        ),
        DawaGameQuestion(
          prompt: 'You entered yesterday by mistake. What is the best action?',
          firstLabel: 'Edit cycle history',
          secondLabel: 'Wait for the prediction to change',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Edit the incorrect entry in cycle history so your record matches what happened.',
        ),
        DawaGameQuestion(
          prompt: 'Cycles vary from month to month. Predictions may become…',
          firstLabel: 'Less reliable',
          secondLabel: 'More certain',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Predictions can be less reliable when cycle lengths vary. Keep recording real dates.',
        ),
      ],
    ),
    DawaHealthGame(
      id: logMeaningId,
      title: 'What Does This Log Mean?',
      subtitle: 'Learn the plain-language meaning of common cycle logs.',
      route: '/learn/games/log-meaning',
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'period_tracking_04',
      completionAssetId: 'period_tracking_04',
      rewardCoins: 10,
      eyebrow: 'SYMPTOM LOGS',
      activity: DawaGameActivity.logMeaning,
      durationMinutes: 3,
      instructions:
          'Choose the plain-language meaning. A symptom log records an experience; it does not diagnose a condition.',
      relatedActionLabel: 'Log today',
      relatedActionRoute: '/periodTracker',
      relatedActionIcon: Icons.add_task_rounded,
      questions: [
        DawaGameQuestion(
          prompt: 'What does a “light flow” log describe?',
          firstLabel: 'A smaller amount of bleeding',
          secondLabel: 'A medical diagnosis',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Light flow describes the amount recorded that day. It is not a diagnosis.',
        ),
        DawaGameQuestion(
          prompt: 'What does a “cramps” log record?',
          firstLabel: 'Pain or tightening felt',
          secondLabel: 'A guaranteed cycle phase',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'A cramps log records what you felt. Severity and timing can help you notice patterns.',
        ),
        DawaGameQuestion(
          prompt: 'What does a “mood” log help you remember?',
          firstLabel: 'How you felt emotionally',
          secondLabel: 'The exact next-period date',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'A mood log records how you felt emotionally on that day.',
        ),
        DawaGameQuestion(
          prompt: 'What does a “headache” log mean?',
          firstLabel: 'You recorded head pain',
          secondLabel: 'The app found the cause',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'It records that head pain happened. The log does not identify its cause.',
        ),
        DawaGameQuestion(
          prompt: 'What does an “energy” log help compare?',
          firstLabel: 'Energy across different days',
          secondLabel: 'A pregnancy test result',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Energy logs can help you compare how energetic or tired you felt across days.',
        ),
        DawaGameQuestion(
          prompt: 'What does “spotting” usually record?',
          firstLabel: 'Small amounts of bleeding',
          secondLabel: 'A confirmed diagnosis',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Spotting records small amounts of bleeding. Seek advice if a change worries you.',
        ),
      ],
    ),
    DawaHealthGame(
      id: periodKitId,
      title: 'Build a Period Kit',
      subtitle: 'Choose useful items for a simple period-care kit.',
      route: '/learn/games/period-kit-builder',
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'period_tracking_03',
      completionAssetId: 'period_tracking_03',
      rewardCoins: 10,
      eyebrow: 'PERIOD-CARE GAME',
      activity: DawaGameActivity.kitBuilder,
      durationMinutes: 3,
      instructions:
          'Choose what may be useful to pack. Select products that are safe, comfortable and available to you.',
      relatedActionLabel: 'Open cycle tracking',
      relatedActionRoute: '/periodTracker',
      relatedActionIcon: Icons.checklist_rounded,
      questions: [
        DawaGameQuestion(
          prompt: 'Clean period products kept in a dry pouch',
          firstLabel: 'Pack it',
          secondLabel: 'Leave it',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Pack it. Clean products in a dry pouch can help you feel prepared away from home.',
        ),
        DawaGameQuestion(
          prompt: 'A clean spare pair of underwear',
          firstLabel: 'Pack it',
          secondLabel: 'Leave it',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Pack it. A spare pair can make an unexpected period easier to manage.',
        ),
        DawaGameQuestion(
          prompt:
              'A small sealable bag for used products when no bin is nearby',
          firstLabel: 'Pack it',
          secondLabel: 'Leave it',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Pack it if useful locally. It can keep used products contained until you find a suitable bin.',
        ),
        DawaGameQuestion(
          prompt: 'Strong scented cleaner for use inside the vagina',
          firstLabel: 'Pack it',
          secondLabel: 'Leave it',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Leave it. Strong scented products can irritate sensitive skin; gentle external washing is enough.',
        ),
        DawaGameQuestion(
          prompt: 'A simple reminder of when to change your chosen product',
          firstLabel: 'Pack it',
          secondLabel: 'Leave it',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Pack it. Following product instructions and changing regularly supports comfort and hygiene.',
        ),
      ],
    ),
    DawaHealthGame(
      id: periodMythFactId,
      title: 'Myth or Fact: Period Edition',
      subtitle: 'Check common period beliefs with respectful explanations.',
      route: '/learn/games/period-myth-or-fact',
      asset: DawaArtwork.banaExplain,
      visualAssetId: 'period_tracking_02',
      completionAssetId: 'period_tracking_05',
      rewardCoins: 10,
      eyebrow: 'MYTH OR FACT',
      activity: DawaGameActivity.mythOrFact,
      durationMinutes: 3,
      instructions:
          'Choose Myth or Fact. Beliefs are discussed respectfully, and the explanation uses reviewed health guidance.',
      relatedActionLabel: 'Explore cycle lessons',
      relatedActionRoute: '/learn',
      relatedActionIcon: Icons.menu_book_outlined,
      questions: [
        DawaGameQuestion(
          prompt:
              'Period predictions always show the exact day bleeding starts.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. Predictions are estimates based on earlier dates, and cycles can vary.',
        ),
        DawaGameQuestion(
          prompt: 'People can have different cycle lengths.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Fact. Cycle length can differ between people and can also change over time.',
        ),
        DawaGameQuestion(
          prompt: 'A period log can help you remember changes to discuss.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Fact. A clear record can make it easier to describe dates and symptoms to a clinician.',
        ),
        DawaGameQuestion(
          prompt: 'Severe or suddenly worse pain should always be ignored.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. Severe or worsening pain deserves advice from a qualified health worker.',
        ),
        DawaGameQuestion(
          prompt: 'One period product is best for every person.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. Comfort, access, cost, safe use and personal preference all matter.',
        ),
      ],
    ),
    DawaHealthGame(
      id: selfCareOrHelpId,
      title: 'Self-care or Get Help?',
      subtitle: 'Practise choosing a safer next step for a short scenario.',
      route: '/learn/games/self-care-or-help',
      asset: DawaArtwork.banaReassure,
      visualAssetId: 'period_tracking_05',
      completionAssetId: 'period_tracking_05',
      rewardCoins: 10,
      eyebrow: 'CARE DECISIONS',
      activity: DawaGameActivity.careDecision,
      durationMinutes: 4,
      instructions:
          'Choose simple self-care, contact a clinic, or seek urgent care. This game does not diagnose conditions.',
      relatedActionLabel: 'Find care',
      relatedActionRoute: '/encounters',
      relatedActionIcon: Icons.health_and_safety_outlined,
      requiresClinicalReview: true,
      questions: [
        DawaGameQuestion(
          prompt:
              'Mild familiar cramps improve with rest and do not stop normal activities.',
          firstLabel: 'Simple self-care',
          secondLabel: 'Contact a clinic',
          thirdLabel: 'Seek urgent care',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Gentle rest, warmth, fluids and following approved medicine advice may help familiar mild cramps.',
        ),
        DawaGameQuestion(
          prompt: 'Pain is new, keeps returning, or affects normal activities.',
          firstLabel: 'Simple self-care',
          secondLabel: 'Contact a clinic',
          thirdLabel: 'Seek urgent care',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Contact a clinic for advice. A clinician can review the pattern and decide what care is appropriate.',
        ),
        DawaGameQuestion(
          prompt: 'Bleeding is very heavy and the person feels faint or weak.',
          firstLabel: 'Simple self-care',
          secondLabel: 'Contact a clinic later',
          thirdLabel: 'Seek urgent care',
          correctAnswer: DawaGameAnswer.third,
          explanation:
              'Seek urgent care now. Very heavy bleeding with faintness or weakness needs prompt assessment.',
          urgentGuidance: true,
        ),
        DawaGameQuestion(
          prompt: 'A logged symptom changes and the person is worried.',
          firstLabel: 'Ignore it',
          secondLabel: 'Contact a clinic',
          thirdLabel: 'Always an emergency',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Contact a clinic for guidance. Being worried about a new or changing symptom is a valid reason to ask.',
        ),
        DawaGameQuestion(
          prompt: 'There is severe, sudden pain with fainting.',
          firstLabel: 'Simple self-care',
          secondLabel: 'Wait for the next visit',
          thirdLabel: 'Seek urgent care',
          correctAnswer: DawaGameAnswer.third,
          explanation:
              'Seek urgent care now. Severe sudden pain with fainting needs prompt medical assessment.',
          urgentGuidance: true,
        ),
      ],
    ),
    DawaHealthGame(
      id: symptomPatternId,
      title: 'Symptom Pattern Detective',
      subtitle: 'Notice repeated logs without treating them as a diagnosis.',
      route: '/learn/games/pattern-detective',
      asset: DawaArtwork.pregnancyPhone,
      visualAssetId: 'period_tracking_04',
      completionAssetId: 'period_tracking_02',
      rewardCoins: 10,
      eyebrow: 'PATTERN CHALLENGE',
      activity: DawaGameActivity.patternDetective,
      durationMinutes: 4,
      instructions:
          'Compare sample logs and choose what repeated. A pattern can guide a conversation but is not a diagnosis.',
      relatedActionLabel: 'Prepare a cycle summary',
      relatedActionRoute: '/periodTracker',
      relatedActionIcon: Icons.summarize_outlined,
      questions: [
        DawaGameQuestion(
          prompt:
              'Sample logs show cramps on days 1, 1 and 2 across three cycles. What repeated?',
          firstLabel: 'Cramps near the start',
          secondLabel: 'A confirmed condition',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Cramps repeated near the start. This observation is useful, but it is not a diagnosis.',
        ),
        DawaGameQuestion(
          prompt:
              'Headache appears once in three sample cycles. Is that a repeated pattern yet?',
          firstLabel: 'Not from this sample',
          secondLabel: 'Definitely yes',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Not from this small sample. Keep logging what happens rather than guessing missing days.',
        ),
        DawaGameQuestion(
          prompt: 'What belongs in a clinician summary?',
          firstLabel: 'Dates, severity and impact',
          secondLabel: 'A self-diagnosis',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Dates, severity and how symptoms affect daily life can help a clinician understand the concern.',
        ),
        DawaGameQuestion(
          prompt: 'A symptom pattern proves the cause of the symptom.',
          firstLabel: 'True',
          secondLabel: 'Not true',
          correctAnswer: DawaGameAnswer.second,
          explanation:
              'Not true. A pattern shows repetition, but a qualified clinician assesses possible causes.',
        ),
        DawaGameQuestion(
          prompt: 'What should you do when a repeated change worries you?',
          firstLabel: 'Discuss it with a clinician',
          secondLabel: 'Delete the logs',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Discuss the record with a clinician. Keeping accurate logs can support the conversation.',
        ),
      ],
    ),
    DawaHealthGame(
      id: periodProductsId,
      title: 'Period Products Match',
      subtitle: 'Match products with basic safe-use descriptions.',
      route: '/learn/games/period-products-match',
      asset: DawaArtwork.banaExplain,
      visualAssetId: 'period_tracking_03',
      completionAssetId: 'period_tracking_03',
      rewardCoins: 10,
      eyebrow: 'PRODUCT MATCH',
      activity: DawaGameActivity.productMatch,
      durationMinutes: 4,
      instructions:
          'Match each product with a simple description. No one option is best for everyone.',
      relatedActionLabel: 'Set a care reminder',
      relatedActionRoute: '/periodTracker',
      relatedActionIcon: Icons.notifications_active_outlined,
      requiresClinicalReview: true,
      questions: [
        DawaGameQuestion(
          prompt: 'A disposable pad is usually worn…',
          firstLabel: 'Attached inside underwear',
          secondLabel: 'Inside the vagina',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'A disposable pad attaches inside underwear and should be changed according to its instructions and your flow.',
        ),
        DawaGameQuestion(
          prompt: 'A reusable cloth pad should be…',
          firstLabel: 'Washed and dried fully',
          secondLabel: 'Stored damp',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Wash it with safe water and soap as approved locally, then dry it fully before reuse.',
        ),
        DawaGameQuestion(
          prompt: 'Period underwear is designed to…',
          firstLabel: 'Absorb menstrual flow',
          secondLabel: 'Predict the next period',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Period underwear is designed to absorb flow. Follow its washing and changing instructions.',
        ),
        DawaGameQuestion(
          prompt: 'A menstrual cup is…',
          firstLabel: 'An internal reusable product',
          secondLabel: 'A disposable pad',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'A menstrual cup is an internal reusable product. Correct fit, cleaning and instructions are important.',
        ),
        DawaGameQuestion(
          prompt: 'How should someone choose a period product?',
          firstLabel: 'Safe use, comfort and access',
          secondLabel: 'One product is best for all',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Choose an approved option that is safe, comfortable, affordable and available to you.',
        ),
      ],
    ),
  ];

  static List<DawaHealthGame> get cycleGames =>
      games.where((game) => game.isCycleGame).toList(growable: false);

  static DawaHealthGame byId(String id) =>
      games.firstWhere((game) => game.id == id);

  static DawaHealthGame byRouteSlug(String slug) => games.firstWhere(
        (game) => game.route.endsWith('/$slug'),
        orElse: () => games.first,
      );

  static bool isGameId(String id) => games.any((game) => game.id == id);

  static int rewardFor(String id) {
    for (final game in games) {
      if (game.id == id) return game.rewardCoins;
    }
    return 0;
  }

  static String titleFor(String id) {
    for (final game in games) {
      if (game.id == id) return game.title;
    }
    return id;
  }
}
