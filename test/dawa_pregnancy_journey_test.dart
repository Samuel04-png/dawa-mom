import 'package:dawa_mom/features/pregnancy/domain/dawa_pregnancy_journey.dart';
import 'package:dawa_mom/features/pregnancy/presentation/dawa_pregnancy_journey_overview.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

HealthProfileSnapshot _pregnantProfile({required DateTime dueDate}) =>
    HealthProfileSnapshot(
      profile: const {},
      mother: const {'pregnancy_status': 'pregnant'},
      pregnancy: {'estimated_due_date': dueDate.toIso8601String()},
      periodSettings: null,
    );

void main() {
  test('uses the saved due date to derive a timezone-safe journey', () {
    final journey = DawaPregnancyJourney.fromProfile(
      _pregnantProfile(dueDate: DateTime(2026, 11, 1)),
      now: DateTime(2026, 6, 1, 23, 55),
    );

    expect(journey, isNotNull);
    expect(journey!.actualWeek, 18);
    expect(journey.dayOfWeek, 2);
    expect(journey.trimester, 2);
    expect(journey.daysRemaining, 153);
  });

  test('post-due journeys retain the timeline without negative days', () {
    final journey = DawaPregnancyJourney.fromProfile(
      _pregnantProfile(dueDate: DateTime(2026, 10, 1)),
      now: DateTime(2026, 10, 5),
    );

    expect(journey!.isPastDue, isTrue);
    expect(journey.daysRemaining, 0);
    expect(journey.progress, 1);
  });

  test('development mapping avoids fetal art before week four', () {
    expect(DawaPregnancyDevelopment.forWeek(1).assetPath, isNull);
    expect(DawaPregnancyDevelopment.forWeek(4).assetPath,
        contains('10_02_52 AM-1.png'));
    expect(DawaPregnancyDevelopment.forWeek(24).assetPath,
        contains('10_03_02 AM-7.png'));
    expect(DawaPregnancyDevelopment.forWeek(42).assetPath,
        contains('10_03_06 AM-10.png'));
  });

  testWidgets('Track pregnancy journey supports safe week exploration at 320px',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    final dueDate = DateTime.now().add(const Duration(days: 120));
    final journey = DawaPregnancyJourney.fromProfile(
      _pregnantProfile(dueDate: dueDate),
    )!;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DawaPregnancyJourneyOverview(
            profile: _pregnantProfile(dueDate: dueDate),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pregnancy-development-wheel')),
        findsOneWidget);
    expect(find.text('Week ${journey.actualWeek} of 40'), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('Back to today'), findsOneWidget);
    expect(find.text('Week ${journey.actualWeek + 1} of 40'), findsOneWidget);
  });
}
