import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('health profile completion reflects actual missing sections', () {
    final profile = HealthProfileSnapshot(
      profile: const {
        'email': 'joshua@example.com',
        'display_name': 'Joshua',
      },
      mother: const {
        'name': 'Joshua',
        'phone_number': '+260123456789',
        'date_of_birth': '1995-06-10',
        'address': 'Lusaka',
        'pregnancy_status': 'not_pregnant',
      },
      pregnancy: null,
      periodSettings: {
        'lastPeriodStart': DateTime(2026, 7, 1),
      },
    );

    expect(profile.personalComplete, isTrue);
    expect(profile.contactComplete, isTrue);
    expect(profile.pregnancyComplete, isTrue);
    expect(profile.periodComplete, isTrue);
    expect(profile.isComplete, isTrue);
  });

  test('missing period setup produces a specific dashboard prompt', () {
    const profile = HealthProfileSnapshot(
      profile: {
        'email': 'joshua@example.com',
        'display_name': 'Joshua',
        'period_setup_skipped_at': '2026-07-15T00:00:00Z',
      },
      mother: {
        'name': 'Joshua',
        'phone_number': '+260123456789',
        'date_of_birth': '1995-06-10',
        'address': 'Lusaka',
        'pregnancy_status': 'not_pregnant',
      },
      pregnancy: null,
      periodSettings: null,
    );

    expect(profile.periodWasSkipped, isTrue);
    expect(
      profile.dashboardPrompt,
      'Add your last period to see cycle dates.',
    );
  });

  test('pregnant users with dates have a complete pregnancy section', () {
    final start = DateTime.now().subtract(const Duration(days: 154));
    final profile = HealthProfileSnapshot(
      profile: const {'email': 'member@example.com'},
      mother: const {
        'name': 'Member',
        'phone_number': '+260123456789',
        'date_of_birth': '1995-06-10',
        'address': 'Lusaka',
        'pregnancy_status': 'pregnant',
      },
      pregnancy: {'lnmp': start.toIso8601String()},
      periodSettings: null,
    );

    expect(
      profile.pregnancyProfileStatus,
      PregnancyProfileStatus.pregnantWithData,
    );
    expect(profile.pregnancyComplete, isTrue);
    expect(profile.pregnancyWeek, 22);
    expect(profile.trimester, 2);
  });

  test('pregnant users without dates are prompted for pregnancy details', () {
    const profile = HealthProfileSnapshot(
      profile: {'email': 'member@example.com'},
      mother: {
        'name': 'Member',
        'phone_number': '+260123456789',
        'date_of_birth': '1995-06-10',
        'address': 'Lusaka',
        'pregnancy_status': 'pregnant',
      },
      pregnancy: null,
      periodSettings: null,
    );

    expect(
      profile.pregnancyProfileStatus,
      PregnancyProfileStatus.pregnantMissingInformation,
    );
    expect(profile.pregnancyComplete, isFalse);
    expect(profile.missingSections, contains('pregnancy'));
  });

  test('not-pregnant and missing-period states stay independent', () {
    const profile = HealthProfileSnapshot(
      profile: {'email': 'member@example.com'},
      mother: {
        'name': 'Member',
        'phone_number': '+260123456789',
        'date_of_birth': '1995-06-10',
        'address': 'Lusaka',
        'pregnancy_status': 'not_pregnant',
      },
      pregnancy: null,
      periodSettings: null,
    );

    expect(
      profile.pregnancyProfileStatus,
      PregnancyProfileStatus.notCurrentlyPregnant,
    );
    expect(profile.pregnancyComplete, isTrue);
    expect(profile.periodComplete, isFalse);
    expect(profile.dashboardPrompt, contains('last period'));
    expect(profile.dashboardPrompt, isNot(contains('pregnancy')));
  });

  test('profile change notifications invalidate dashboard snapshots', () {
    final before = HealthProfileRepository.changes.value;
    HealthProfileRepository.notifyChanged();
    expect(HealthProfileRepository.changes.value, before + 1);
  });
}
