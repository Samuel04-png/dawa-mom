import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('learning completion is locally idempotent and queues server sync',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);

    final initial = await repository.load();
    final completed = await repository.complete(
      initial,
      'myth-vs-fact',
      rewardCoins: 5,
    );
    final repeated = await repository.complete(
      completed,
      'myth-vs-fact',
      rewardCoins: 5,
    );

    expect(completed.completedIds, contains('myth-vs-fact'));
    expect(completed.coins, initial.coins + 5);
    expect(repeated.coins, completed.coins);
    expect(
      preferences.getStringList('dawa_learning_pending_completions'),
      contains('myth-vs-fact'),
    );
  });

  test('saved and offline content survive repository recreation', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = DawaLearningRepository(preferences: preferences);
    final initial = await repository.load();
    final saved = await repository.toggleSaved(initial, 'pregnancy-basics');
    await repository.toggleOffline(saved, 'pregnancy-basics');

    final restored =
        await DawaLearningRepository(preferences: preferences).load();
    expect(restored.savedIds, contains('pregnancy-basics'));
    expect(restored.offlineIds, contains('pregnancy-basics'));
  });

  test('quest progress is derived from persisted completion state', () {
    expect(dawaQuestProgress(const DawaLearningState()), 0);
    expect(
      dawaQuestProgress(
        const DawaLearningState(
          completedIds: {'screening-checkpoint'},
        ),
      ),
      0.75,
    );
    expect(
      dawaQuestProgress(
        const DawaLearningState(
          completedIds: {'screening-without-fear'},
        ),
      ),
      1,
    );
  });
}
