import 'package:dawa_mom/components/period_setup/period_setup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(PeriodSetupForm form) => MaterialApp(
      home: Scaffold(body: form),
    );

void main() {
  testWidgets('registration period setup can be skipped', (tester) async {
    var skipped = false;
    await tester.pumpWidget(
      _host(
        PeriodSetupForm(
          registration: true,
          onBack: () {},
          onSkip: () async => skipped = true,
          onSave: ({
            required startDate,
            required endDate,
            required cycleLength,
            required periodLength,
            required isRegular,
          }) async {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('skip-period-setup')));
    await tester.pump();

    expect(skipped, isTrue);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('registration period setup saves valid existing values',
      (tester) async {
    DateTime? savedStart;
    int? savedCycle;
    await tester.pumpWidget(
      _host(
        PeriodSetupForm(
          registration: true,
          initialStartDate: DateTime(2026, 7, 1),
          onBack: () {},
          onSkip: () async {},
          onSave: ({
            required startDate,
            required endDate,
            required cycleLength,
            required periodLength,
            required isRegular,
          }) async {
            savedStart = startDate;
            savedCycle = cycleLength;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('continue-period-setup')));
    await tester.pump();

    expect(savedStart, DateTime(2026, 7, 1));
    expect(savedCycle, 28);
  });
}
