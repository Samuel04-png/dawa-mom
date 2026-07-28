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
    required this.predictedWindowStart,
    required this.predictedWindowEnd,
    required this.cycleDay,
    required this.daysUntilNextPeriod,
    required this.confidence,
    required this.predictionReason,
    required this.observedCycleCount,
    required this.cycleVariationDays,
  });

  final PeriodCycleStatus status;
  final int? averageCycleLength;
  final int? averagePeriodLength;
  final int historyCount;
  final bool? isRegular;
  final DateTime? lastPeriodStart;
  final DateTime? nextPeriodEstimate;
  final DateTime? predictedWindowStart;
  final DateTime? predictedWindowEnd;
  final int? cycleDay;
  final int? daysUntilNextPeriod;
  final PeriodEstimateConfidence confidence;
  final String predictionReason;
  final int observedCycleCount;
  final int? cycleVariationDays;

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
    final observedLengths = <int>[];
    for (var index = 0; index < ordered.length - 1; index++) {
      final newer = _dateOnly(ordered[index].startDate);
      final older = _dateOnly(ordered[index + 1].startDate);
      final length = newer.difference(older).inDays;
      if (length >= 15 && length <= 60) observedLengths.add(length);
    }
    final observedAverage = observedLengths.isEmpty
        ? null
        : (observedLengths.reduce((a, b) => a + b) / observedLengths.length)
            .round();
    final effectiveCycleLength = observedAverage ?? cycleLength;
    final variation = observedLengths.length < 2
        ? null
        : observedLengths.reduce((a, b) => a > b ? a : b) -
            observedLengths.reduce((a, b) => a < b ? a : b);

    if (effectiveCycleLength == null ||
        periodLength == null ||
        latest == null) {
      return PeriodCycleSummary(
        status: PeriodCycleStatus.notConfigured,
        averageCycleLength: effectiveCycleLength,
        averagePeriodLength: periodLength,
        historyCount: ordered.length,
        isRegular: isRegular,
        lastPeriodStart: latest,
        nextPeriodEstimate: null,
        predictedWindowStart: null,
        predictedWindowEnd: null,
        cycleDay: null,
        daysUntilNextPeriod: null,
        confidence: PeriodEstimateConfidence.unavailable,
        predictionReason:
            'Add a period start and usual cycle details to create an estimate.',
        observedCycleCount: observedLengths.length,
        cycleVariationDays: variation,
      );
    }

    final lastStart = DateTime(latest.year, latest.month, latest.day);
    final rawCycleDay = today.difference(lastStart).inDays + 1;
    final cycleDay = rawCycleDay < 1 ? null : rawCycleDay;
    var nextEstimate = lastStart.add(Duration(days: effectiveCycleLength));
    while (nextEstimate.isBefore(today)) {
      nextEstimate = nextEstimate.add(Duration(days: effectiveCycleLength));
    }
    final daysUntil = nextEstimate.difference(today).inDays;
    final explicitEnd = ordered.firstOrNull?.endDate;
    final expectedEnd = lastStart.add(Duration(days: periodLength - 1));
    final periodEnd = explicitEnd == null
        ? expectedEnd
        : DateTime(explicitEnd.year, explicitEnd.month, explicitEnd.day);
    final periodActive =
        !today.isBefore(lastStart) && !today.isAfter(periodEnd);

    final confidence = isRegular != true || (variation != null && variation > 8)
        ? PeriodEstimateConfidence.low
        : observedLengths.length >= 3 && (variation ?? 0) <= 4
            ? PeriodEstimateConfidence.high
            : observedLengths.isNotEmpty
                ? PeriodEstimateConfidence.medium
                : PeriodEstimateConfidence.low;
    final windowRadius = switch (confidence) {
      PeriodEstimateConfidence.high => 1,
      PeriodEstimateConfidence.medium => 2,
      PeriodEstimateConfidence.low => ((variation ?? 8) / 2).ceil().clamp(4, 7),
      PeriodEstimateConfidence.unavailable => 0,
    };
    final predictedWindowStart =
        nextEstimate.subtract(Duration(days: windowRadius));
    final predictedWindowEnd = nextEstimate.add(Duration(days: windowRadius));
    final predictionReason = switch (confidence) {
      PeriodEstimateConfidence.high =>
        'Based on ${observedLengths.length} recent completed cycles with similar lengths.',
      PeriodEstimateConfidence.medium =>
        'Based on ${observedLengths.length} recent completed ${observedLengths.length == 1 ? 'cycle' : 'cycles'}. More logs can narrow this range.',
      PeriodEstimateConfidence.low when isRegular == false =>
        'Your cycles are marked as variable, so this date may change.',
      PeriodEstimateConfidence.low when variation != null && variation > 8 =>
        'Your recent cycle lengths varied by $variation days, so this is a broad estimate.',
      PeriodEstimateConfidence.low =>
        'This early estimate uses your usual cycle length. Log more periods to improve it.',
      PeriodEstimateConfidence.unavailable =>
        'There is not enough information for an estimate yet.',
    };

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
    } else if (cycleDay != null && cycleDay <= effectiveCycleLength) {
      status = PeriodCycleStatus.cycleInProgress;
    } else {
      status = PeriodCycleStatus.estimateAvailable;
    }

    return PeriodCycleSummary(
      status: status,
      averageCycleLength: effectiveCycleLength,
      averagePeriodLength: periodLength,
      historyCount: ordered.length,
      isRegular: isRegular,
      lastPeriodStart: lastStart,
      nextPeriodEstimate: nextEstimate,
      predictedWindowStart: predictedWindowStart,
      predictedWindowEnd: predictedWindowEnd,
      cycleDay: cycleDay,
      daysUntilNextPeriod: daysUntil,
      confidence: confidence,
      predictionReason: predictionReason,
      observedCycleCount: observedLengths.length,
      cycleVariationDays: variation,
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

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
