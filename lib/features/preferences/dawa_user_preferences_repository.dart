import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/localization/dawa_localizations.dart';

class DawaUserPreferences {
  const DawaUserPreferences({
    this.language = 'English',
    this.lessonLanguageEnabled = true,
    this.rudoLanguageEnabled = true,
    this.appointmentNotifications = true,
    this.learningNotifications = true,
    this.cycleNotifications = true,
    this.rewardNotifications = true,
    this.weeklySummary = false,
    this.quietHoursEnabled = true,
    this.quietHoursStart = '21:00',
    this.quietHoursEnd = '07:00',
    this.privateLockScreen = true,
  });

  final String language;
  final bool lessonLanguageEnabled;
  final bool rudoLanguageEnabled;
  final bool appointmentNotifications;
  final bool learningNotifications;
  final bool cycleNotifications;
  final bool rewardNotifications;
  final bool weeklySummary;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool privateLockScreen;

  DawaUserPreferences copyWith({
    String? language,
    bool? lessonLanguageEnabled,
    bool? rudoLanguageEnabled,
    bool? appointmentNotifications,
    bool? learningNotifications,
    bool? cycleNotifications,
    bool? rewardNotifications,
    bool? weeklySummary,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? privateLockScreen,
  }) =>
      DawaUserPreferences(
        language: language ?? this.language,
        lessonLanguageEnabled:
            lessonLanguageEnabled ?? this.lessonLanguageEnabled,
        rudoLanguageEnabled: rudoLanguageEnabled ?? this.rudoLanguageEnabled,
        appointmentNotifications:
            appointmentNotifications ?? this.appointmentNotifications,
        learningNotifications:
            learningNotifications ?? this.learningNotifications,
        cycleNotifications: cycleNotifications ?? this.cycleNotifications,
        rewardNotifications: rewardNotifications ?? this.rewardNotifications,
        weeklySummary: weeklySummary ?? this.weeklySummary,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
        privateLockScreen: privateLockScreen ?? this.privateLockScreen,
      );
}

class DawaUserPreferencesRepository {
  DawaUserPreferencesRepository({
    SharedPreferences? preferences,
    SupabaseClient? client,
  })  : _preferences = preferences,
        _client = client;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  SharedPreferences? _preferences;
  SupabaseClient? _client;

  static const _languageKey = 'dawa_preference_language';
  static const _lessonKey = 'dawa_preference_lesson_language';
  static const _rudoKey = 'dawa_preference_rudo_language';
  static const _appointmentKey = 'dawa_notify_appointments';
  static const _learningKey = 'dawa_notify_learning';
  static const _cycleKey = 'dawa_notify_cycle';
  static const _rewardKey = 'dawa_notify_rewards';
  static const _weeklySummaryKey = 'dawa_notify_weekly_summary';
  static const _quietHoursEnabledKey = 'dawa_notify_quiet_hours_enabled';
  static const _quietHoursStartKey = 'dawa_notify_quiet_hours_start';
  static const _quietHoursEndKey = 'dawa_notify_quiet_hours_end';
  static const _privateLockScreenKey = 'dawa_notify_private_lock_screen';

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return _client = Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<DawaUserPreferences> load() async {
    final prefs = await _prefs;
    final local = DawaUserPreferences(
      language: _normalizeLanguage(
        prefs.getString(_languageKey) ?? DawaLanguages.english,
      ),
      lessonLanguageEnabled: prefs.getBool(_lessonKey) ?? true,
      rudoLanguageEnabled: prefs.getBool(_rudoKey) ?? true,
      appointmentNotifications: prefs.getBool(_appointmentKey) ?? true,
      learningNotifications: prefs.getBool(_learningKey) ?? true,
      cycleNotifications: prefs.getBool(_cycleKey) ?? true,
      rewardNotifications: prefs.getBool(_rewardKey) ?? true,
      weeklySummary: prefs.getBool(_weeklySummaryKey) ?? false,
      quietHoursEnabled: prefs.getBool(_quietHoursEnabledKey) ?? true,
      quietHoursStart: prefs.getString(_quietHoursStartKey) ?? '21:00',
      quietHoursEnd: prefs.getString(_quietHoursEndKey) ?? '07:00',
      privateLockScreen: prefs.getBool(_privateLockScreenKey) ?? true,
    );
    await DawaLocaleController.instance.setLanguage(
      local.language,
      persist: false,
    );
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return local;
    try {
      final row = await client
          .from('dawa_mom_user_preferences')
          .select()
          .eq('profile_id', userId)
          .maybeSingle();
      if (row == null) return local;
      final remote = DawaUserPreferences(
        language: _normalizeLanguage(
          row['language']?.toString() ?? local.language,
        ),
        lessonLanguageEnabled: row['lesson_language_enabled'] as bool? ??
            local.lessonLanguageEnabled,
        rudoLanguageEnabled:
            row['rudo_language_enabled'] as bool? ?? local.rudoLanguageEnabled,
        appointmentNotifications: row['appointment_notifications'] as bool? ??
            local.appointmentNotifications,
        learningNotifications: row['learning_notifications'] as bool? ??
            local.learningNotifications,
        cycleNotifications:
            row['cycle_notifications'] as bool? ?? local.cycleNotifications,
        rewardNotifications:
            row['reward_notifications'] as bool? ?? local.rewardNotifications,
        weeklySummary: row['weekly_summary'] as bool? ?? local.weeklySummary,
        quietHoursEnabled:
            row['quiet_hours_enabled'] as bool? ?? local.quietHoursEnabled,
        quietHoursStart: _normalizePreferenceTime(
          row['quiet_hours_start'],
          local.quietHoursStart,
        ),
        quietHoursEnd: _normalizePreferenceTime(
          row['quiet_hours_end'],
          local.quietHoursEnd,
        ),
        privateLockScreen:
            row['private_lock_screen'] as bool? ?? local.privateLockScreen,
      );
      await _saveLocal(remote);
      await DawaLocaleController.instance.setLanguage(remote.language);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Preferences sync unavailable: ${error.code}');
      return local;
    }
  }

  Future<DawaUserPreferences> save(DawaUserPreferences value) async {
    final normalized = value.copyWith(
      language: _normalizeLanguage(value.language),
    );
    await _saveLocal(normalized);
    await DawaLocaleController.instance.setLanguage(normalized.language);
    unawaited(_sync(normalized));
    changes.value += 1;
    return normalized;
  }

  Future<void> _saveLocal(DawaUserPreferences value) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_languageKey, value.language),
      prefs.setBool(_lessonKey, value.lessonLanguageEnabled),
      prefs.setBool(_rudoKey, value.rudoLanguageEnabled),
      prefs.setBool(_appointmentKey, value.appointmentNotifications),
      prefs.setBool(_learningKey, value.learningNotifications),
      prefs.setBool(_cycleKey, value.cycleNotifications),
      prefs.setBool(_rewardKey, value.rewardNotifications),
      prefs.setBool(_weeklySummaryKey, value.weeklySummary),
      prefs.setBool(_quietHoursEnabledKey, value.quietHoursEnabled),
      prefs.setString(_quietHoursStartKey, value.quietHoursStart),
      prefs.setString(_quietHoursEndKey, value.quietHoursEnd),
      prefs.setBool(_privateLockScreenKey, value.privateLockScreen),
    ]);
  }

  Future<void> _sync(DawaUserPreferences value) async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client.from('dawa_mom_user_preferences').upsert({
        'profile_id': userId,
        'language': value.language,
        'lesson_language_enabled': value.lessonLanguageEnabled,
        'rudo_language_enabled': value.rudoLanguageEnabled,
        'appointment_notifications': value.appointmentNotifications,
        'learning_notifications': value.learningNotifications,
        'cycle_notifications': value.cycleNotifications,
        'reward_notifications': value.rewardNotifications,
        'weekly_summary': value.weeklySummary,
        'quiet_hours_enabled': value.quietHoursEnabled,
        'quiet_hours_start': value.quietHoursStart,
        'quiet_hours_end': value.quietHoursEnd,
        'private_lock_screen': value.privateLockScreen,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      debugPrint('Preferences remain local: ${error.code}');
    }
  }
}

String _normalizePreferenceTime(dynamic value, String fallback) {
  final text = value?.toString();
  if (text == null || !RegExp(r'^\d{2}:\d{2}').hasMatch(text)) {
    return fallback;
  }
  return text.substring(0, 5);
}

String _normalizeLanguage(String value) => DawaLanguages.nameForLocale(
      DawaLanguages.localeForName(value),
    );
