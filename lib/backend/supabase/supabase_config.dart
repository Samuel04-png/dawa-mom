import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_session_recovery.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://himbfndvsuwiudtzjojh.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_u4mv5Z9nyV8yb4Oyf-hySg_FDMEZEGY',
);

Future<void> initSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError('Supabase URL and anon key must be configured.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );
  await _refreshPersistedSession();
}

Future<void> _refreshPersistedSession() async {
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    return;
  }

  try {
    await refreshSupabaseSession(auth);
  } catch (error) {
    // Invalid refresh tokens are cleared by GoTrue. An outage is not a logout.
    debugPrint('Persisted session refresh unavailable (${error.runtimeType}).');
  }
}
