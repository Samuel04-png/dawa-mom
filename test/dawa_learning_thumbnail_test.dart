import 'package:dawa_mom/components/responsive/dawa_mom_responsive_shell.dart';
import 'package:dawa_mom/design_system/dawa_components.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/learning/data/dawa_learning_repository.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_learn_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _destinations = [
  DawaMomShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  DawaMomShellDestination(
    label: 'Track',
    icon: Icons.sync_outlined,
    selectedIcon: Icons.sync_rounded,
  ),
  DawaMomShellDestination(
    label: 'Care',
    icon: Icons.health_and_safety_outlined,
    selectedIcon: Icons.health_and_safety_rounded,
  ),
  DawaMomShellDestination(
    label: 'Learn',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  DawaMomShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('successful lesson thumbnail is one clean image with no overlays',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: DawaLessonThumbnail(
              topic: DawaLessonVisual.nutrition,
              assetPath: DawaArtwork.nutritionCounselling,
              aspectRatio: 4 / 3,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final thumbnail = find.byType(DawaLessonThumbnail);
    expect(
      find.descendant(of: thumbnail, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: thumbnail, matching: find.byType(Positioned)),
      findsNothing,
    );
    expect(
      find.descendant(of: thumbnail, matching: find.byType(DawaIconBadge)),
      findsNothing,
    );
    final aspectRatio = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('lesson-thumbnail-aspect-ratio')),
    );
    expect(aspectRatio.aspectRatio, 4 / 3);
  });

  testWidgets('lesson thumbnail replaces a failed asset with a safe fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: DawaLessonThumbnail(
              topic: DawaLessonVisual.pregnancy,
              assetPath: 'assets/images/not-a-real-learning-image.png',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lesson-thumbnail-fallback')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Learn card actions remain scrollable above navigation at target sizes and text scales',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final configuration in const [
      (Size(360, 800), 1.0),
      (Size(390, 844), 1.0),
      (Size(412, 915), 1.0),
      (Size(360, 800), 1.3),
      (Size(412, 915), 1.5),
    ]) {
      tester.view.physicalSize = configuration.$1;
      final preferences = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(configuration.$2),
            ),
            child: child!,
          ),
          home: DawaMomResponsiveShell(
            currentIndex: 3,
            destinations: _destinations,
            onDestinationSelected: (_) {},
            onLogout: () async {},
            child: DawaLearnPage(
              repository: DawaLearningRepository(preferences: preferences),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$configuration');
      expect(find.byTooltip('Save to library'), findsNWidgets(3));
      expect(find.textContaining('min read'), findsWidgets);

      final nutritionCard = find.ancestor(
        of: find.text('Foods to eat in your second trimester'),
        matching: find.byType(DawaContentThumbnailCard),
      );
      final clinicCard = find.ancestor(
        of: find.text('How to prepare for your clinic visit'),
        matching: find.byType(DawaContentThumbnailCard),
      );
      expect(
        (tester.getSize(nutritionCard).height -
                tester.getSize(clinicCard).height)
            .abs(),
        lessThan(48),
        reason:
            'Content-driven two-column cards diverged excessively at $configuration',
      );

      final actions = find.widgetWithText(TextButton, 'Read now');
      expect(actions, findsWidgets);
      for (var index = 0; index < actions.evaluate().length; index++) {
        await tester.ensureVisible(actions.at(index));
        await tester.pumpAndSettle();
        final actionRect = tester.getRect(actions.at(index));
        final navigationRect = tester.getRect(find.byType(BottomNavigationBar));
        expect(
          actionRect.bottom,
          lessThanOrEqualTo(navigationRect.top),
          reason: 'Read now was hidden at $configuration',
        );
      }

      await tester.pumpWidget(const SizedBox());
    }
  });
}
