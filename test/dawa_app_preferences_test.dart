import 'package:dawa_mom/features/preferences/dawa_app_preferences_page.dart';
import 'package:dawa_mom/features/preferences/dawa_user_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  test('app feedback preferences persist locally', () async {
    final repository = DawaUserPreferencesRepository(preferences: preferences);

    await repository.save(
      const DawaUserPreferences().copyWith(
        soundEffectsEnabled: false,
        reducedAnimations: true,
        hapticFeedbackEnabled: false,
      ),
    );
    final restored = await repository.load();

    expect(restored.soundEffectsEnabled, isFalse);
    expect(restored.reducedAnimations, isTrue);
    expect(restored.hapticFeedbackEnabled, isFalse);
  });

  testWidgets('app preferences exposes all three feedback controls',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: DawaAppPreferencesPage(
          repository: DawaUserPreferencesRepository(preferences: preferences),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Animations'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);

    final vibration = find.ancestor(
      of: find.text('Vibration'),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(vibration);
    await tester.pumpAndSettle();

    expect(
        (await DawaUserPreferencesRepository(preferences: preferences).load())
            .hapticFeedbackEnabled,
        isFalse);
    expect(tester.takeException(), isNull);
  });
}
