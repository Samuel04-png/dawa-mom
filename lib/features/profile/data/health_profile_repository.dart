import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/period_tracker_service.dart';
import '/backend/supabase/supabase_database.dart';

class HealthProfileRepository {
  HealthProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void notifyChanged() => changes.value++;

  Future<HealthProfileSnapshot> load() async {
    if (kDebugMode) debugPrint('[HealthProfile] Loading profile snapshot.');
    final userId = _requireUserId();
    final results = await Future.wait<dynamic>([
      SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('profiles')
            .select(
              'id,email,display_name,photo_url,phone_number,period_setup_skipped_at',
            )
            .eq('id', userId)
            .single(),
      ),
      SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('mothers')
            .select(
              'id,name,phone_number,date_of_birth,occupation,address,pregnancy_status,first_encounter_id',
            )
            .eq('profile_id', userId)
            .maybeSingle(),
      ),
      PeriodTrackerService().loadUserSettings(),
    ]);

    final profile = Map<String, dynamic>.from(results[0] as Map);
    final mother = results[1] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(results[1] as Map);
    Map<String, dynamic>? pregnancy;
    final firstEncounterId = mother['first_encounter_id']?.toString();
    if (firstEncounterId != null && firstEncounterId.isNotEmpty) {
      final row = await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('first_encounters')
            .select('id,lnmp,estimated_due_date')
            .eq('id', firstEncounterId)
            .maybeSingle(),
      );
      if (row != null) pregnancy = Map<String, dynamic>.from(row);
    }

    final snapshot = HealthProfileSnapshot(
      profile: profile,
      mother: mother,
      pregnancy: pregnancy,
      periodSettings: results[2] as Map<String, dynamic>?,
    );
    if (kDebugMode) {
      debugPrint('[HealthProfile] Profile snapshot loaded successfully.');
    }
    return snapshot;
  }

  Future<void> savePregnancyInformation({
    required String status,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
  }) async {
    _requireUserId();
    if (kDebugMode) {
      debugPrint('[HealthProfile] Saving pregnancy profile section.');
    }
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.rpc(
        'upsert_patient_health_profile',
        params: {
          'p_pregnancy_status': status,
          'p_lnmp': _dateId(lastMenstrualPeriod),
          'p_estimated_due_date': _dateId(estimatedDueDate),
        },
      ),
    );
    notifyChanged();
    if (kDebugMode) {
      debugPrint('[HealthProfile] Pregnancy profile section saved.');
    }
  }

  String _requireUserId() {
    final value = _client.auth.currentUser?.id;
    if (value == null || value.isEmpty) {
      throw const HealthProfileException(
        'Please sign in to manage your health profile.',
      );
    }
    return value;
  }

  static String? _dateId(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
}

enum PregnancyProfileStatus {
  pregnantWithData,
  pregnantMissingInformation,
  notCurrentlyPregnant,
  notProvided,
}

class HealthProfileSnapshot {
  const HealthProfileSnapshot({
    required this.profile,
    required this.mother,
    required this.pregnancy,
    required this.periodSettings,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> mother;
  final Map<String, dynamic>? pregnancy;
  final Map<String, dynamic>? periodSettings;

  String get name => _firstText([mother['name'], profile['display_name']]);
  String get email => _text(profile['email']);
  String get phone =>
      _firstText([mother['phone_number'], profile['phone_number']]);
  String get occupation => _text(mother['occupation']);
  String get address => _text(mother['address']);
  DateTime? get dateOfBirth => _date(mother['date_of_birth']);
  String get pregnancyStatus => _text(mother['pregnancy_status']).isEmpty
      ? 'not_provided'
      : _text(mother['pregnancy_status']);
  DateTime? get lastMenstrualPeriod => _date(pregnancy?['lnmp']);
  DateTime? get estimatedDueDate => _date(pregnancy?['estimated_due_date']);
  DateTime? get lastPeriodStart =>
      periodSettings?['lastPeriodStart'] as DateTime?;
  bool get periodWasSkipped => profile['period_setup_skipped_at'] != null;

  PregnancyProfileStatus get pregnancyProfileStatus {
    switch (pregnancyStatus) {
      case 'pregnant':
        return hasPregnancyDetails
            ? PregnancyProfileStatus.pregnantWithData
            : PregnancyProfileStatus.pregnantMissingInformation;
      case 'not_pregnant':
        return PregnancyProfileStatus.notCurrentlyPregnant;
      default:
        return PregnancyProfileStatus.notProvided;
    }
  }

  bool get hasPregnancyDetails =>
      lastMenstrualPeriod != null || estimatedDueDate != null;
  bool get hasBookingDetails => personalComplete && contactComplete;
  DateTime? get calculatedDueDate =>
      estimatedDueDate ?? lastMenstrualPeriod?.add(const Duration(days: 280));
  DateTime? get calculatedPregnancyStart =>
      lastMenstrualPeriod ??
      estimatedDueDate?.subtract(const Duration(days: 280));
  int? get pregnancyWeek {
    final start = calculatedPregnancyStart;
    if (start == null) return null;
    final weeks = DateTime.now().difference(start).inDays ~/ 7;
    return weeks < 0 || weeks > 42 ? null : weeks;
  }

  int? get trimester {
    final week = pregnancyWeek;
    if (week == null) return null;
    if (week <= 13) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  bool get personalComplete => name.isNotEmpty && dateOfBirth != null;
  bool get contactComplete =>
      email.isNotEmpty && phone.isNotEmpty && address.isNotEmpty;
  bool get pregnancyComplete =>
      pregnancyProfileStatus == PregnancyProfileStatus.pregnantWithData ||
      pregnancyProfileStatus == PregnancyProfileStatus.notCurrentlyPregnant ||
      pregnancyStatus == 'prefer_not_to_say';
  bool get periodComplete => lastPeriodStart != null;
  bool get isComplete =>
      personalComplete &&
      contactComplete &&
      pregnancyComplete &&
      periodComplete;

  int get completedSections => [
        personalComplete,
        contactComplete,
        pregnancyComplete,
        periodComplete,
      ].where((value) => value).length;

  List<String> get missingSections => [
        if (!personalComplete || !contactComplete) 'personal',
        if (!pregnancyComplete) 'pregnancy',
        if (!periodComplete) 'period',
        if (!hasBookingDetails) 'booking',
      ];

  String get dashboardPrompt {
    final missing = [
      !personalComplete || !contactComplete,
      !pregnancyComplete,
      !periodComplete,
    ].where((value) => value).length;
    if (missing > 1) return 'Your health profile needs more information.';
    if (!personalComplete || !contactComplete) {
      return 'Complete your personal details.';
    }
    if (!periodComplete) {
      return 'Set up your Period Tracker to receive estimates.';
    }
    if (!pregnancyComplete) {
      return 'Add pregnancy information for personalised guidance.';
    }
    return 'Your health profile is up to date.';
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
  static String _firstText(List<dynamic> values) => values
      .map(_text)
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  static DateTime? _date(dynamic value) => value == null
      ? null
      : value is DateTime
          ? value
          : DateTime.tryParse(value.toString());
}

class HealthProfileException implements Exception {
  const HealthProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
