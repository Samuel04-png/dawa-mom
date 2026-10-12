import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  test('pregnancy save explains the required personal-profile record', () {
    final message = HealthProfileRepository.pregnancySaveMessage(
      const PostgrestException(
        message: 'Complete your personal profile first',
        code: 'P0001',
      ),
    );

    expect(
      message,
      'Add your personal details before saving pregnancy information.',
    );
  });

  test('pregnancy data reports whether the required maternal record exists',
      () {
    const missingMother = HealthProfileSnapshot(
      profile: {'email': 'member@example.test'},
      mother: {},
      pregnancy: null,
      periodSettings: null,
    );
    const savedMother = HealthProfileSnapshot(
      profile: {'email': 'member@example.test'},
      mother: {'id': '4fe4fd1c-bb51-4aa9-b264-c78b6a27639f'},
      pregnancy: null,
      periodSettings: null,
    );

    expect(missingMother.hasMaternalProfile, isFalse);
    expect(savedMother.hasMaternalProfile, isTrue);
  });

  test('a confirmed personal save can update completion before refresh', () {
    const before = HealthProfileSnapshot(
      profile: {'email': 'chipo@example.test'},
      mother: {'pregnancy_status': 'not_pregnant'},
      pregnancy: null,
      periodSettings: {'lastPeriodStart': null},
    );
    final after = before.copyWith(
      profile: {'email': 'chipo@example.test', 'display_name': 'Chipo'},
      mother: {
        'name': 'Chipo',
        'phone_number': '+260 970000000',
        'date_of_birth': '1995-01-01',
        'address': 'Lusaka',
        'pregnancy_status': 'not_pregnant',
      },
    );

    expect(before.personalComplete, isFalse);
    expect(after.personalComplete, isTrue);
    expect(after.contactComplete, isTrue);
    expect(after.completedSections, 3);
  });
}
