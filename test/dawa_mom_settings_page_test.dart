import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:dawa_mom/features/settings/dawa_mom_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Settings renders every section at phone, tablet and desktop',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final size in const [
      Size(390, 844),
      Size(900, 900),
      Size(1200, 900),
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
      expect(find.text('Account and profile'), findsOneWidget);
      expect(find.text('Health and tracking'), findsOneWidget);
      expect(find.text('Privacy and security'), findsOneWidget);
      expect(find.text('Help and About Dawa Mom'), findsOneWidget);
      expect(find.text('Account actions'), findsOneWidget);
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
