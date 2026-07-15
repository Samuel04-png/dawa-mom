import 'package:dawa_mom/features/onboarding/dawa_mom_walkthrough.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Future<void> Function() onComplete) => MaterialApp(
      home: Scaffold(
        body: DawaMomWalkthrough(onComplete: onComplete),
      ),
    );

void main() {
  testWidgets('walkthrough can be skipped', (tester) async {
    var completions = 0;
    await tester.pumpWidget(_host(() async => completions++));

    expect(find.text('Welcome to Dawa Mom'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip-app-tour')));
    await tester.pump();

    expect(completions, 1);
  });

  testWidgets('walkthrough reaches Get started and persists completion',
      (tester) async {
    var completions = 0;
    await tester.pumpWidget(_host(() async => completions++));

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const ValueKey('next-app-tour')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Ask Rudo'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-app-tour')));
    await tester.pump();
    expect(completions, 1);
  });
}
