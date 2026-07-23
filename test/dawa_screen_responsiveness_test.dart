import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/auth/dawa_auth_pages.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizes = [
    Size(390, 844),
    Size(768, 1024),
    Size(1024, 768),
    Size(1366, 900),
    Size(1440, 900),
  ];

  testWidgets('welcome screen renders at every required product breakpoint',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in sizes) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: const DawaWelcomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Dawa Mom'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('learning hub renders at every required product breakpoint',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in sizes) {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: DawaLearnPage(
            repository: DawaLearningRepository(preferences: preferences),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Cervical cancer awareness'), findsOneWidget);
      expect(find.text('Audio lessons in your language'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
