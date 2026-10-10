import 'package:dawa_mom/design_system/dawa_components.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lesson cards stay content-driven and keep actions attached',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    for (final scale in const [1.0, 1.3, 1.5]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: DawaTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DawaContentThumbnailCard(
                thumbnail: const AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ColoredBox(color: DawaColors.softGreen),
                ),
                category: 'Pregnancy',
                title:
                    'Foods to eat in your second trimester without repeating the category',
                description:
                    'Practical, locally relevant guidance that remains readable in longer translations.',
                durationMinutes: 11,
                actionLabel: 'Pitilizani kuwerenga zambiri',
                audioAvailable: true,
                completed: true,
                onSave: () {},
                onOpen: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at ${scale}x');
      final card = find.byType(DawaContentThumbnailCard);
      expect(tester.getSize(card).height, lessThan(700));
      final title = tester.widget<Text>(
        find.text(
          'Foods to eat in your second trimester without repeating the category',
        ),
      );
      final description = tester.widget<Text>(
        find.text(
          'Practical, locally relevant guidance that remains readable in longer translations.',
        ),
      );
      expect(title.overflow, isNot(TextOverflow.ellipsis));
      expect(description.overflow, isNot(TextOverflow.ellipsis));
      expect(find.text('Pitilizani kuwerenga zambiri'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
