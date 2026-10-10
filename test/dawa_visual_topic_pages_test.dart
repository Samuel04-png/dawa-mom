import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/learning/presentation/dawa_visual_topic_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('topic hub stays complete and overflow-free at target sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(768, 1024),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          home: const DawaVisualTopicHubPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose a topic'), findsOneWidget);
      expect(find.text('Cervical cancer awareness'), findsOneWidget);
      expect(find.text('Postpartum recovery and support'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('period topic opens the cycle games hub with increased text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: const DawaVisualTopicGuidePage(topicId: 'period-tracking'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Understand Your Cycle'), findsOneWidget);
    expect(find.text('Choose a quick game'), findsOneWidget);
    expect(find.text('Cycle Phase Match'), findsOneWidget);
    expect(find.text('Calendar Detective'), findsOneWidget);
    expect(find.text('Period Products Match'), findsOneWidget);
    expect(find.text('Learn step by step'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('dawa-contextual-image-period_tracking_01'),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
