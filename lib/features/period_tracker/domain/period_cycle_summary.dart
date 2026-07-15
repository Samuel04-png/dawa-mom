import '/backend/period_tracker_service.dart';

enum PeriodCycleStatus {
  notConfigured,
  insufficientHistory,
  periodActive,
  periodExpectedToday,
  periodExpectedSoon,
  cycleInProgress,
  estimateAvailable,
  irregularCycle,
}

enum PeriodEstimateConfidence { unavailable, low, medium, high }

class PeriodCycleSummary {
  const PeriodCycleSummary({
    required this.status,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.historyCount,
    required this.isRegular,
    required this.lastPeriodStart,
    required this.nextPeriodEstimate,
    required this.cycleDay,
    required this.daysUntilNextPeriod,
    required this.confidence,
  });

  final PeriodCycleStatus status;
  final int? averageCycleLength;
  final int? averagePeriodLength;
  final int historyCount;
  final bool? isRegular;
  final DateTime? lastPeriodStart;
  final DateTime? nextPeriodEstimate;
  final int? cycleDay;
  final int? daysUntilNextPeriod;
  final PeriodEstimateConfidence confidence;

  bool get isConfigured => status != PeriodCycleStatus.notConfigured;
  bool get isPeriodActive => status == PeriodCycleStatus.periodActive;

  factory PeriodCycleSummary.derive({
    required DateTime now,
    required Map<String, dynamic>? settings,
    required List<PeriodRecord> history,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final cycleLength = settings?['averageCycleLength'] as int?;
    final periodLength = settings?['periodLength'] as int?;
    final isRegular = settings?['isRegular'] as bool?;
    final ordered = [...history]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final configuredStart = settings?['lastPeriodStart'] as DateTime?;
    final latest = ordered.firstOrNull?.startDate ?? configuredStart;

    if (cycleLength == null || periodLength == null || latest == null) {
      return PeriodCycleSummary(
        status: PeriodCycleStatus.notConfigured,
        averageCycleLength: cycleLength,
        averagePeriodLength: periodLength,
        historyCount: ordered.length,
        isRegular: isRegular,
        lastPeriodStart: latest,
        nextPeriodEstimate: null,
        cycleDay: null,
        daysUntilNextPeriod: null,
        confidence: PeriodEstimateConfidence.unavailable,
      );
    }

    final lastStart = DateTime(latest.year, latest.month, latest.day);
    final rawCycleDay = today.difference(lastStart).inDays + 1;
    final cycleDay = rawCycleDay < 1 ? null : rawCycleDay;
    var nextEstimate = lastStart.add(Duration(days: cycleLength));
    while (nextEstimate.isBefore(today)) {
      nextEstimate = nextEstimate.add(Duration(days: cycleLength));
    }
    final daysUntil = nextEstimate.difference(today).inDays;
    final explicitEnd = ordered.firstOrNull?.endDate;
    final expectedEnd = lastStart.add(Duration(days: periodLength - 1));
    final periodEnd = explicitEnd == null
        ? expectedEnd
        : DateTime(explicitEnd.year, explicitEnd.month, explicitEnd.day);
    final periodActive =
        !today.isBefore(lastStart) && !today.isAfter(periodEnd);

    final confidence = isRegular != true
        ? PeriodEstimateConfidence.low
        : ordered.length >= 4
            ? PeriodEstimateConfidence.high
            : ordered.length >= 2
                ? PeriodEstimateConfidence.medium
                : PeriodEstimateConfidence.low;

    final PeriodCycleStatus status;
    if (periodActive) {
      status = PeriodCycleStatus.periodActive;
    } else if (daysUntil == 0) {
      status = PeriodCycleStatus.periodExpectedToday;
    } else if (daysUntil <= 5) {
      status = PeriodCycleStatus.periodExpectedSoon;
    } else if (isRegular == false) {
      status = PeriodCycleStatus.irregularCycle;
    } else if (ordered.length < 2) {
      status = PeriodCycleStatus.insufficientHistory;
    } else if (cycleDay != null && cycleDay <= cycleLength) {
      status = PeriodCycleStatus.cycleInProgress;
    } else {
      status = PeriodCycleStatus.estimateAvailable;
    }

    return PeriodCycleSummary(
      status: status,
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
      historyCount: ordered.length,
      isRegular: isRegular,
      lastPeriodStart: lastStart,
      nextPeriodEstimate: nextEstimate,
      cycleDay: cycleDay,
      daysUntilNextPeriod: daysUntil,
      confidence: confidence,
    );
  }

  String get statusLabel {
    switch (status) {
      case PeriodCycleStatus.notConfigured:
        return 'Cycle tracking not set up';
      case PeriodCycleStatus.insufficientHistory:
        return 'Building your cycle picture';
      case PeriodCycleStatus.periodActive:
        return 'Period in progress';
      case PeriodCycleStatus.periodExpectedToday:
        return 'Period estimated today';
      case PeriodCycleStatus.periodExpectedSoon:
        return 'Period estimated soon';
      case PeriodCycleStatus.cycleInProgress:
        return 'Cycle in progress';
      case PeriodCycleStatus.estimateAvailable:
        return 'Cycle estimate available';
      case PeriodCycleStatus.irregularCycle:
        return 'Irregular cycle tracking';
    }
  }

  String get confidenceLabel {
    switch (confidence) {
      case PeriodEstimateConfidence.unavailable:
        return 'No estimate yet';
      case PeriodEstimateConfidence.low:
        return 'Early estimate';
      case PeriodEstimateConfidence.medium:
        return 'Growing confidence';
      case PeriodEstimateConfidence.high:
        return 'Higher confidence';
    }
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
