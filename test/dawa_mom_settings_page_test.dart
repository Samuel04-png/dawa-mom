import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:dawa_mom/features/settings/dawa_mom_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Profile and compact settings remain accessible at every size',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: DawaMomSettingsPage(
            profileRepository: _FakeHealthProfileRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at $size');
      expect(find.text('My profile'), findsOneWidget);
      expect(find.text('Health summary'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About DawaMom'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Take the app tour again'), findsOneWidget);
      expect(find.text('Health profile'), findsOneWidget);
      expect(find.text('View care records'), findsOneWidget);
      expect(find.text('Danger zone'), findsNothing);
      expect(find.text('Delete account'), findsNothing);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-logout')), findsOneWidget);
      final logoutBottom =
          tester.getRect(find.byKey(const ValueKey('profile-logout'))).bottom;
      expect(
        size.height - logoutBottom,
        lessThan(100),
        reason: 'Profile left an excessive trailing gap at $size',
      );
    }
  });
}

class _FakeHealthProfileRepository implements HealthProfileRepository {
  @override
  Future<HealthProfileSnapshot> load() async => const HealthProfileSnapshot(
        profile: {
          'display_name': 'Test Mom',
          'email': 'test@example.com',
          'phone_number': '+260 000 000 000',
        },
        mother: {
          'name': 'Test Mom',
          'phone_number': '+260 000 000 000',
          'date_of_birth': '1995-01-01',
          'occupation': 'Tester',
          'address': 'Lusaka',
          'pregnancy_status': 'not_pregnant',
        },
        pregnancy: null,
        periodSettings: {
          'lastPeriodStart': null,
          'averageCycleLength': 28,
          'periodLength': 5,
          'isRegular': true,
        },
      );

  @override
  Future<void> retryPatientSync() async {}

  @override
  Future<void> savePregnancyInformation({
    required String status,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
  }) async {}
}
