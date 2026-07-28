import 'package:dawa_mom/design_system/dawa_components.dart';
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared button variants wrap long labels without overflow',
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
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DawaPrimaryButton(
                      label:
                          'Pitilizani kukonzekera ulendo wanu wa kuchipatala',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    DawaSecondaryButton(
                      label: 'Onani zambiri zokhudza nthawi ya ku chipatala',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DawaCompactButton(
                          label: 'Set reminder',
                          onPressed: () {},
                        ),
                        DawaDestructiveButton(
                          label: 'Cancel appointment',
                          onPressed: () {},
                        ),
                        DawaTextButton(
                          label: 'Browse clinics',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at ${scale}x');
      for (final type in [
        DawaPrimaryButton,
        DawaSecondaryButton,
        DawaCompactButton,
        DawaDestructiveButton,
        DawaTextButton,
      ]) {
        final finder = find.byType(type);
        expect(finder, findsWidgets);
        for (var index = 0; index < finder.evaluate().length; index++) {
          expect(
            tester.getSize(finder.at(index)).height,
            greaterThanOrEqualTo(48),
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('busy shared button blocks repeat submission', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: DawaTheme.light(),
        home: Scaffold(
          body: DawaPrimaryButton(
            label: 'Book appointment',
            busy: true,
            onPressed: () => presses++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DawaPrimaryButton));
    await tester.pump();
    expect(presses, 0);
    expect(find.text('Please wait'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
