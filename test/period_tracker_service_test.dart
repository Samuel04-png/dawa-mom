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
  });
}
