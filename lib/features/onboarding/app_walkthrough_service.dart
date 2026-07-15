import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_database.dart';

class AppWalkthroughService {
  AppWalkthroughService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> shouldShow() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    final key = _key(userId);
    if (preferences.getBool(key) == true) return false;

    try {
      final row = await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('profiles')
            .select('has_completed_app_walkthrough')
            .eq('id', userId)
            .maybeSingle(),
      );
      final complete = row?['has_completed_app_walkthrough'] == true;
      if (complete) await preferences.setBool(key, true);
      return !complete;
    } catch (_) {
      // The tour must never block app access when the preference cannot load.
      return preferences.getBool(key) != true;
    }
  }

  Future<void> complete() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key(userId), true);
    try {
      await SupabaseDatabase.instance.runWithFreshSession(
        () => _client.from('profiles').update({
          'has_completed_app_walkthrough': true,
          'app_walkthrough_completed_at':
              DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId),
      );
    } catch (_) {
      // Local completion prevents a failed sync from reopening on every login.
      // A later profile update can safely reconcile the server preference.
    }
  }

  static String _key(String userId) => 'dawa_mom_walkthrough_$userId';
}
