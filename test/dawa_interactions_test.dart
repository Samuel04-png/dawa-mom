import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/design_system/dawa_interactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
        theme: DawaTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: Center(child: child)),
        ),
      );

  testWidgets('action feedback remains clear with reduced motion',
      (tester) async {
    await tester.pumpWidget(
      app(
        const DawaActionFeedback(
          title: 'Saved',
          message: 'Your symptoms have been added to today’s health record.',
        ),
        reduceMotion: true,
      ),
    );

    expect(find.text('Saved'), findsOneWidget);
    expect(
      find.text('Your symptoms have been added to today’s health record.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('points feedback shows the real balance change', (tester) async {
    await tester.pumpWidget(
      app(
        const DawaPointsFeedback(
          previousPoints: 180,
          currentPoints: 185,
        ),
      ),
    );
    expect(find.text('+5'), findsOneWidget);

    await tester.pump(DawaMotion.celebration);
    expect(find.text('185 Dawa Points'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressable calls its action without needing motion',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        DawaPressable(
          semanticLabel: 'Open learning',
          onTap: () => taps++,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Open learning'),
          ),
        ),
        reduceMotion: true,
      ),
    );

    await tester.tap(find.text('Open learning'));
    expect(taps, 1);
  });
}
