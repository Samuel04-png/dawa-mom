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
              'id,name,phone_number,date_of_birth,occupation,address,pregnancy_status,first_encounter_id,dawa_clinician_patient_id,dawa_clinician_synced_at,dawa_clinician_sync_error_code',
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

  /// Persists the two personal-profile records as one user-facing operation.
  /// `mothers.profile_id` is unique, so an upsert prevents a second maternal
  /// row when a saved form is retried or two devices save close together.
  Future<HealthProfilePersonalSave> savePersonalInformation({
    required String name,
    required DateTime dateOfBirth,
    required String phone,
    required String address,
    String? occupation,
  }) async {
    final userId = _requireUserId();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    final cleanAddress = address.trim();
    if (cleanName.length < 2) {
      throw const HealthProfileException('Enter your full name.');
    }
    if (cleanPhone.replaceAll(RegExp(r'\D'), '').length < 8) {
      throw const HealthProfileException('Enter a valid mobile number.');
    }
    if (cleanAddress.length < 3) {
      throw const HealthProfileException('Enter your address.');
    }
    final today = DateTime.now();
    if (dateOfBirth.isAfter(DateTime(today.year, today.month, today.day))) {
      throw const HealthProfileException(
          'Date of birth cannot be in the future.');
    }

    try {
      if (kDebugMode) debugPrint('[HealthProfile] Saving personal section.');
      final results = await Future.wait<dynamic>([
        SupabaseDatabase.instance.runWithFreshSession(
          () => _client
              .from('profiles')
              .update({
                'display_name': cleanName,
                'phone_number': cleanPhone,
              })
              .eq('id', userId)
              .select('id,display_name,phone_number')
              .single(),
        ),
        SupabaseDatabase.instance.runWithFreshSession(
          () => _client
              .from('mothers')
              .upsert(
                {
                  'profile_id': userId,
                  'name': cleanName,
                  'phone_number': cleanPhone,
                  'date_of_birth': _dateId(dateOfBirth),
                  'occupation': _nullIfBlank(occupation),
                  'address': cleanAddress,
                },
                onConflict: 'profile_id',
              )
              .select(
                'id,profile_id,name,phone_number,date_of_birth,occupation,address,pregnancy_status',
              )
              .single(),
        ),
      ]);
      notifyChanged();
      if (kDebugMode) debugPrint('[HealthProfile] Personal section saved.');
      return HealthProfilePersonalSave(
        profile: Map<String, dynamic>.from(results[0] as Map),
        mother: Map<String, dynamic>.from(results[1] as Map),
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[HealthProfile] Personal section save failed '
          '(${error.code ?? 'unknown'}): ${error.message}',
        );
      }
      throw const HealthProfileException(
        'Your details could not be saved. Check your connection and try again.',
      );
    }
  }

  Future<void> savePregnancyInformation({
    required String status,
    DateTime? lastMenstrualPeriod,
    DateTime? estimatedDueDate,
  }) async {
    _requireUserId();
    if (!const {
      'not_provided',
      'pregnant',
      'not_pregnant',
      'prefer_not_to_say',
    }.contains(status)) {
      throw const HealthProfileException('Choose a valid pregnancy option.');
    }
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    if (lastMenstrualPeriod != null && lastMenstrualPeriod.isAfter(dateOnly)) {
      throw const HealthProfileException(
        'Last menstrual period cannot be in the future.',
      );
    }
    if (estimatedDueDate != null && estimatedDueDate.isBefore(dateOnly)) {
      throw const HealthProfileException('Due date cannot be in the past.');
    }
    if (kDebugMode) {
      debugPrint('[HealthProfile] Saving pregnancy profile section.');
    }
    try {
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
    } catch (error, stackTrace) {
      _logPregnancySaveFailure(error, stackTrace);
      throw HealthProfileException(_pregnancySaveMessage(error));
    }
    notifyChanged();
    if (kDebugMode) {
      debugPrint('[HealthProfile] Pregnancy profile section saved.');
    }
  }

  Future<void> retryPatientSync() async {
    _requireUserId();
    await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.rpc('retry_own_dawa_clinician_patient_sync'),
    );
    notifyChanged();
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

  static String? _nullIfBlank(String? value) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? null : clean;
  }

  /// Keeps the UI useful without exposing raw database diagnostics to a user.
  /// This particular RPC intentionally requires the maternal profile row that
  /// is created by the personal-details step.
  @visibleForTesting
  static String pregnancySaveMessage(Object error) =>
      _pregnancySaveMessage(error);

  static String _pregnancySaveMessage(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('complete your personal profile first')) {
        return 'Add your personal details before saving pregnancy information.';
      }
      if (message.contains('authentication is required')) {
        return 'Please sign in again before saving pregnancy information.';
      }
    }
    return 'Pregnancy information could not be saved. Please try again.';
  }

  static void _logPregnancySaveFailure(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    if (error is PostgrestException) {
      debugPrint(
        '[HealthProfile] operation=save_pregnancy stage=rpc '
        'error_type=PostgrestException code=${error.code ?? 'unknown'} '
        'message=${error.message}',
      );
    } else {
      debugPrint(
        '[HealthProfile] operation=save_pregnancy stage=rpc '
        'error_type=${error.runtimeType}',
      );
    }
    debugPrintStack(
      label: '[HealthProfile] save_pregnancy/rpc',
      stackTrace: stackTrace,
      maxFrames: 5,
    );
  }
}

@immutable
class HealthProfilePersonalSave {
  const HealthProfilePersonalSave({
    required this.profile,
    required this.mother,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> mother;
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

  HealthProfileSnapshot copyWith({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? mother,
    Map<String, dynamic>? pregnancy,
    Map<String, dynamic>? periodSettings,
    bool clearPregnancy = false,
  }) =>
      HealthProfileSnapshot(
        profile: profile ?? this.profile,
        mother: mother ?? this.mother,
        pregnancy: clearPregnancy ? null : pregnancy ?? this.pregnancy,
        periodSettings: periodSettings ?? this.periodSettings,
      );

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
  bool get isMappedToDawaClinician =>
      _text(mother['dawa_clinician_patient_id']).isNotEmpty;
  bool get patientSyncNeedsAttention =>
      _text(mother['dawa_clinician_sync_error_code']).isNotEmpty;
  bool get hasMaternalProfile => _text(mother['id']).isNotEmpty;

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

  /// An explicitly saved due date is the source of truth for all pregnancy
  /// presentation dates. When both dates exist, deriving the start from the
  /// due date keeps the displayed week, day, progress, and countdown aligned.
  /// If only an LMP is saved, the established 280-day estimate still applies.
  DateTime? get calculatedPregnancyStart =>
      estimatedDueDate?.subtract(const Duration(days: 280)) ??
      lastMenstrualPeriod;
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
    if (missing > 1) return 'Finish your profile to see tips made for you.';
    if (!personalComplete || !contactComplete) {
      return 'Complete your personal details.';
    }
    if (!periodComplete) {
      return 'Add your last period to see cycle dates.';
    }
    if (!pregnancyComplete) {
      return 'Add your pregnancy choice to see the right tips.';
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
