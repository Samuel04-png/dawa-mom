import '/design_system/dawa_components.dart';

enum DawaGameAnswer { first, second }

class DawaGameQuestion {
  const DawaGameQuestion({
    required this.prompt,
    required this.firstLabel,
    required this.secondLabel,
    required this.correctAnswer,
    required this.explanation,
  });

  final String prompt;
  final String firstLabel;
  final String secondLabel;
  final DawaGameAnswer correctAnswer;
  final String explanation;
}

class DawaHealthGame {
  const DawaHealthGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.asset,
    required this.rewardCoins,
    required this.questions,
    this.eyebrow = 'HEALTH GAME',
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final String asset;
  final int rewardCoins;
  final List<DawaGameQuestion> questions;
  final String eyebrow;

  int get passingScore => (questions.length * .8).ceil();
}

abstract final class DawaHealthGameCatalog {
  static const mythMatchId = 'game-myth-match';
  static const nutritionSortId = 'game-nutrition-sort';

  static const games = <DawaHealthGame>[
    DawaHealthGame(
      id: mythMatchId,
      title: 'Myth Match',
      subtitle: 'Separate common health myths from trusted facts.',
      route: '/learn/games/myth-match',
      asset: DawaArtwork.banaExplain,
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
              'Fact. Regular visits help a clinician check progress and respond to concerns early.',
        ),
        DawaGameQuestion(
          prompt: 'Modern birth control permanently causes infertility.',
          firstLabel: 'Myth',
          secondLabel: 'Fact',
          correctAnswer: DawaGameAnswer.first,
          explanation:
              'Myth. Most methods do not cause permanent infertility. A clinician can help you choose a suitable option.',
        ),
      ],
    ),
    DawaHealthGame(
      id: nutritionSortId,
      title: 'Plate Builder',
      subtitle: 'Sort pregnancy food choices into the safest group.',
      route: '/learn/games/plate-builder',
      asset: DawaArtwork.pregnancyPhone,
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
  ];

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
