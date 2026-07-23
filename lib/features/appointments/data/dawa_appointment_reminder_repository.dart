import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class DawaAppointmentReminder {
  const DawaAppointmentReminder({
    required this.appointmentId,
    this.enabled = true,
    this.daysBefore = 1,
    this.appNotification = true,
    this.smsNotification = false,
    this.emailNotification = false,
  });

  final String appointmentId;
  final bool enabled;
  final int daysBefore;
  final bool appNotification;
  final bool smsNotification;
  final bool emailNotification;

  DawaAppointmentReminder copyWith({
    bool? enabled,
    int? daysBefore,
    bool? appNotification,
    bool? smsNotification,
    bool? emailNotification,
  }) =>
      DawaAppointmentReminder(
        appointmentId: appointmentId,
        enabled: enabled ?? this.enabled,
        daysBefore: daysBefore ?? this.daysBefore,
        appNotification: appNotification ?? this.appNotification,
        smsNotification: smsNotification ?? this.smsNotification,
        emailNotification: emailNotification ?? this.emailNotification,
      );
}

class DawaAppointmentReminderRepository {
  DawaAppointmentReminderRepository({
    SharedPreferences? preferences,
    SupabaseClient? client,
  })  : _preferences = preferences,
        _client = client;

  SharedPreferences? _preferences;
  SupabaseClient? _client;

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

  String _key(String appointmentId, String field) =>
      'dawa_appointment_reminder_${appointmentId}_$field';

  Future<DawaAppointmentReminder> load(String appointmentId) async {
    final prefs = await _prefs;
    final local = DawaAppointmentReminder(
      appointmentId: appointmentId,
      enabled: prefs.getBool(_key(appointmentId, 'enabled')) ?? true,
      daysBefore: prefs.getInt(_key(appointmentId, 'days')) ?? 1,
      appNotification: prefs.getBool(_key(appointmentId, 'app')) ?? true,
      smsNotification: prefs.getBool(_key(appointmentId, 'sms')) ?? false,
      emailNotification: prefs.getBool(_key(appointmentId, 'email')) ?? false,
    );
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return local;
    try {
      final row = await client
          .from('dawa_mom_appointment_reminders')
          .select()
          .eq('profile_id', userId)
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      if (row == null) return local;
      final remote = DawaAppointmentReminder(
        appointmentId: appointmentId,
        enabled: row['enabled'] as bool? ?? local.enabled,
        daysBefore: row['days_before'] as int? ?? local.daysBefore,
        appNotification:
            row['app_notification'] as bool? ?? local.appNotification,
        smsNotification:
            row['sms_notification'] as bool? ?? local.smsNotification,
        emailNotification:
            row['email_notification'] as bool? ?? local.emailNotification,
      );
      await _saveLocal(remote);
      return remote;
    } on PostgrestException catch (error) {
      debugPrint('Appointment reminder sync unavailable: ${error.code}');
      return local;
    }
  }

  Future<DawaAppointmentReminder> save(DawaAppointmentReminder value) async {
    final normalized = value.enabled &&
            !value.appNotification &&
            !value.smsNotification &&
            !value.emailNotification
        ? value.copyWith(appNotification: true)
        : value;
    await _saveLocal(normalized);
    unawaited(_sync(normalized));
    return normalized;
  }

  Future<void> _saveLocal(DawaAppointmentReminder value) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setBool(_key(value.appointmentId, 'enabled'), value.enabled),
      prefs.setInt(_key(value.appointmentId, 'days'), value.daysBefore),
      prefs.setBool(
        _key(value.appointmentId, 'app'),
        value.appNotification,
      ),
      prefs.setBool(
        _key(value.appointmentId, 'sms'),
        value.smsNotification,
      ),
      prefs.setBool(
        _key(value.appointmentId, 'email'),
        value.emailNotification,
      ),
    ]);
  }

  Future<void> _sync(DawaAppointmentReminder value) async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client.from('dawa_mom_appointment_reminders').upsert({
        'profile_id': userId,
        'appointment_id': value.appointmentId,
        'enabled': value.enabled,
        'days_before': value.daysBefore,
        'app_notification': value.appNotification,
        'sms_notification': value.smsNotification,
        'email_notification': value.emailNotification,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id,appointment_id');
    } on PostgrestException catch (error) {
      debugPrint('Appointment reminder remains local: ${error.code}');
    }
  }
}
