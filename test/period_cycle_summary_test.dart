import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:dawa_mom/features/period_tracker/domain/period_cycle_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 15);

  test('reports not configured without cycle settings', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: null,
      history: const [],
    );

    expect(summary.status, PeriodCycleStatus.notConfigured);
    expect(summary.confidence, PeriodEstimateConfidence.unavailable);
  });

  test('recognises an active period from the configured period length', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: {
        'averageCycleLength': 28,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': DateTime(2026, 7, 13),
      },
      history: [PeriodRecord(startDate: DateTime(2026, 7, 13))],
    );

    expect(summary.status, PeriodCycleStatus.periodActive);
    expect(summary.cycleDay, 3);
  });

  test('marks an early estimate as insufficient history', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: {
        'averageCycleLength': 28,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': DateTime(2026, 7, 1),
      },
      history: [PeriodRecord(startDate: DateTime(2026, 7, 1))],
    );

    expect(summary.status, PeriodCycleStatus.insufficientHistory);
    expect(summary.confidence, PeriodEstimateConfidence.low);
    expect(summary.daysUntilNextPeriod, 14);
  });

  test('does not overstate confidence for an irregular cycle', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: {
        'averageCycleLength': 31,
        'periodLength': 6,
        'isRegular': false,
        'lastPeriodStart': DateTime(2026, 7, 1),
      },
      history: [
        PeriodRecord(startDate: DateTime(2026, 7, 1)),
        PeriodRecord(startDate: DateTime(2026, 5, 29)),
        PeriodRecord(startDate: DateTime(2026, 5, 1)),
      ],
    );

    expect(summary.status, PeriodCycleStatus.irregularCycle);
    expect(summary.confidence, PeriodEstimateConfidence.low);
  });

  test('distinguishes an estimate due today', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: {
        'averageCycleLength': 28,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': DateTime(2026, 6, 17),
      },
      history: [
        PeriodRecord(startDate: DateTime(2026, 6, 17)),
        PeriodRecord(startDate: DateTime(2026, 5, 20)),
      ],
    );

    expect(summary.status, PeriodCycleStatus.periodExpectedToday);
  });

  test('uses completed cycle history and returns an uncertainty range', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: {
        'averageCycleLength': 28,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': DateTime(2026, 7, 1),
      },
      history: [
        PeriodRecord(startDate: DateTime(2026, 7, 1)),
        PeriodRecord(startDate: DateTime(2026, 6, 1)),
        PeriodRecord(startDate: DateTime(2026, 5, 3)),
        PeriodRecord(startDate: DateTime(2026, 4, 3)),
      ],
    );

    expect(summary.averageCycleLength, 30);
    expect(summary.observedCycleCount, 3);
    expect(summary.cycleVariationDays, 1);
    expect(summary.confidence, PeriodEstimateConfidence.high);
    expect(summary.predictedWindowStart, DateTime(2026, 7, 30));
    expect(summary.predictedWindowEnd, DateTime(2026, 8, 1));
    expect(summary.predictionReason, contains('3 recent completed cycles'));
  });

  test('widens the estimate when recent cycles vary', () {
    final summary = PeriodCycleSummary.derive(
      now: now,
      settings: {
        'averageCycleLength': 30,
        'periodLength': 5,
        'isRegular': true,
        'lastPeriodStart': DateTime(2026, 7, 1),
      },
      history: [
        PeriodRecord(startDate: DateTime(2026, 7, 1)),
        PeriodRecord(startDate: DateTime(2026, 5, 27)),
        PeriodRecord(startDate: DateTime(2026, 5, 1)),
      ],
    );

    expect(summary.cycleVariationDays, 9);
    expect(summary.confidence, PeriodEstimateConfidence.low);
    expect(
      summary.predictedWindowEnd!
          .difference(summary.predictedWindowStart!)
          .inDays,
      greaterThanOrEqualTo(8),
    );
    expect(summary.predictionReason, contains('varied by 9 days'));
  });
}
