import 'package:dawa_mom/backend/period_tracker_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodTrackerService', () {
    test('formatDateId normalizes dates to yyyy-MM-dd', () {
      final date = DateTime(2026, 5, 4, 23, 59, 12);

      expect(PeriodTrackerService.formatDateId(date), '2026-05-04');
    });

    test('entryToLegacyMap converts Supabase row shape for UI state', () {
      final mapped = PeriodTrackerService.entryToLegacyMap({
        'entry_date': '2026-05-04',
        'symptoms': ['Cramps', 'Fatigue'],
        'notes': ['Felt better after resting'],
        'sexual_activity': [
          {
            'protected': true,
            'time': '2026-05-04T10:30:00.000',
          },
        ],
      });

      expect(mapped['date'], DateTime(2026, 5, 4));
      expect(mapped['symptoms'], ['Cramps', 'Fatigue']);
      expect(mapped['notes'], ['Felt better after resting']);

      final activity = mapped['sexualActivity'] as List;
      expect(activity, hasLength(1));
      expect(activity.single['protected'], isTrue);
      expect(activity.single['time'], DateTime(2026, 5, 4, 10, 30));
    });

    test('validateSettings accepts supported cycle values', () {
      expect(
        () => PeriodTrackerService.validateSettings(
          averageCycleLength: 28,
          periodLength: 5,
        ),
        returnsNormally,
      );
    });

    test('validateSettings rejects database-invalid values before saving', () {
      expect(
        () => PeriodTrackerService.validateSettings(
          averageCycleLength: 14,
          periodLength: 5,
        ),
        throwsA(isA<PeriodTrackerException>()),
      );
      expect(
        () => PeriodTrackerService.validateSettings(
          averageCycleLength: 20,
          periodLength: 20,
        ),
        throwsA(isA<PeriodTrackerException>()),
      );
    });

    test('period record validation rejects future and impossible ranges', () {
      final today = DateTime(2026, 7, 27);

      expect(
        () => PeriodTrackerService.validatePeriodRecord(
          startDate: DateTime(2026, 7, 28),
          today: today,
        ),
        throwsA(isA<PeriodTrackerException>()),
      );
      expect(
        () => PeriodTrackerService.validatePeriodRecord(
          startDate: DateTime(2026, 7, 20),
          endDate: DateTime(2026, 7, 19),
          today: today,
        ),
        throwsA(isA<PeriodTrackerException>()),
      );
      expect(
        () => PeriodTrackerService.validatePeriodRecord(
          startDate: DateTime(2026, 7, 20),
          endDate: DateTime(2026, 7, 28),
          today: today,
        ),
        throwsA(isA<PeriodTrackerException>()),
      );
      expect(
        () => PeriodTrackerService.validatePeriodRecord(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 16),
          today: today,
        ),
        throwsA(isA<PeriodTrackerException>()),
      );
      expect(
        () => PeriodTrackerService.validatePeriodRecord(
          startDate: DateTime(2026, 7, 23),
          endDate: DateTime(2026, 7, 27),
          today: today,
        ),
        returnsNormally,
      );
    });
  });
}
