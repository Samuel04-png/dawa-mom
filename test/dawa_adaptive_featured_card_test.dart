import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/home/domain/dawa_home_presentation.dart';
import 'package:dawa_mom/features/home/presentation/dawa_adaptive_featured_card.dart';
import 'package:dawa_mom/features/period_tracker/domain/period_cycle_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PeriodCycleSummary _cycle({
  PeriodCycleStatus status = PeriodCycleStatus.cycleInProgress,
  int cycleDay = 12,
}) =>
    PeriodCycleSummary(
      status: status,
      averageCycleLength: 28,
      averagePeriodLength: 5,
      historyCount: 3,
      isRegular: true,
      lastPeriodStart: DateTime(2026, 9, 22),
      nextPeriodEstimate: DateTime(2026, 10, 20),
      predictedWindowStart: DateTime(2026, 10, 19),
      predictedWindowEnd: DateTime(2026, 10, 21),
      cycleDay: cycleDay,
      daysUntilNextPeriod: 16,
      confidence: PeriodEstimateConfidence.medium,
      predictionReason: 'Based on recent completed cycles.',
      observedCycleCount: 3,
      cycleVariationDays: 2,
    );

Appointment _appointment() => Appointment(
      id: 'appointment-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime(2026, 10, 14),
      startTime: '10:00',
      endTime: '10:30',
      appointmentType: 'antenatal_checkup',
      status: 'confirmed',
      source: 'dawa_mom',
      createdAt: DateTime(2026, 10, 9),
      integrationStatus: 'confirmed',
      clinicName: 'Kalingalinga Clinic',
    );

Future<void> _pumpFeatured(
  WidgetTester tester,
  DawaHomePresentation presentation,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 420);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DawaTheme.light(),
      home: Material(
        color: DawaColors.canvas,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DawaAdaptiveFeaturedCard(
            presentation: presentation,
            onAction: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('active period featured card matches the approved visual capture',
      (tester) async {
    await _pumpFeatured(
      tester,
      DawaHomePresentation(
        kind: DawaHomeFeaturedKind.activePeriod,
        action: DawaHomeAction.cycle,
        title: 'Period in progress',
        message: 'Open Track to log how you feel.',
        actionLabel: 'Open Track',
        cycle: _cycle(status: PeriodCycleStatus.periodActive, cycleDay: 3),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-featured-activePeriod')),
      matchesGoldenFile('goldens/home_featured_active_period.png'),
    );
  });

  testWidgets('pregnancy featured card matches the approved visual capture',
      (tester) async {
    await _pumpFeatured(
      tester,
      const DawaHomePresentation(
        kind: DawaHomeFeaturedKind.pregnancy,
        action: DawaHomeAction.pregnancy,
        title: 'Week 24',
        message: 'Your 2nd trimester.',
        actionLabel: 'View pregnancy',
        pregnancyWeek: 24,
        trimester: 2,
      ),
    );

    expect(
      find.byKey(const ValueKey('home-featured-pregnancy')),
      matchesGoldenFile('goldens/home_featured_pregnancy.png'),
    );
  });

  testWidgets('appointment featured card matches the approved visual capture',
      (tester) async {
    await _pumpFeatured(
      tester,
      DawaHomePresentation(
        kind: DawaHomeFeaturedKind.appointment,
        action: DawaHomeAction.appointment,
        title: 'Your next visit',
        message: 'Your visit details are ready to review.',
        actionLabel: 'View visit',
        appointment: _appointment(),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-featured-appointment')),
      matchesGoldenFile('goldens/home_featured_appointment.png'),
    );
  });

  testWidgets('general featured card matches the approved visual capture',
      (tester) async {
    await _pumpFeatured(
      tester,
      const DawaHomePresentation(
        kind: DawaHomeFeaturedKind.general,
        action: DawaHomeAction.bookVisit,
        title: 'Your health today',
        message: 'Choose a simple next step for your health.',
        actionLabel: 'Book a visit',
      ),
    );

    expect(
      find.byKey(const ValueKey('home-featured-general')),
      matchesGoldenFile('goldens/home_featured_general.png'),
    );
  });
}
