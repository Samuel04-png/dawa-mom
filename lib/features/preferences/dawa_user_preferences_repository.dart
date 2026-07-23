import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DawaUserPreferences {
  const DawaUserPreferences({
    this.language = 'English',
    this.lessonLanguageEnabled = true,
    this.rudoLanguageEnabled = true,
    this.appointmentNotifications = true,
    this.learningNotifications = true,
    this.cycleNotifications = true,
    this.rewardNotifications = true,
  });

  final String language;
  final bool lessonLanguageEnabled;
  final bool rudoLanguageEnabled;
  final bool appointmentNotifications;
  final bool learningNotifications;
  final bool cycleNotifications;
  final bool rewardNotifications;

  DawaUserPreferences copyWith({
    String? language,
    bool? lessonLanguageEnabled,
    bool? rudoLanguageEnabled,
    bool? appointmentNotifications,
    bool? learningNotifications,
    bool? cycleNotifications,
    bool? rewardNotifications,
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
      language: prefs.getString(_languageKey) ?? 'English',
      lessonLanguageEnabled: prefs.getBool(_lessonKey) ?? true,
      rudoLanguageEnabled: prefs.getBool(_rudoKey) ?? true,
      appointmentNotifications: prefs.getBool(_appointmentKey) ?? true,
      learningNotifications: prefs.getBool(_learningKey) ?? true,
      cycleNotifications: prefs.getBool(_cycleKey) ?? true,
      rewardNotifications: prefs.getBool(_rewardKey) ?? true,
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
        language: row['language']?.toString() ?? local.language,
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
      );
      await _saveLocal(remote);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Preferences sync unavailable: ${error.code}');
      return local;
    }
  }

  Future<DawaUserPreferences> save(DawaUserPreferences value) async {
    await _saveLocal(value);
    unawaited(_sync(value));
    changes.value += 1;
    return value;
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
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      debugPrint('Preferences remain local: ${error.code}');
    }
  }
}
