import 'package:supabase_flutter/supabase_flutter.dart';

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
    anonKey: supabaseAnonKey,
  );
  await _refreshPersistedSession();
}

Future<void> _refreshPersistedSession() async {
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    return;
  }

  try {
    final response =
        await auth.refreshSession().timeout(const Duration(seconds: 8));
    if (response.session == null) {
      await auth.signOut(scope: SignOutScope.local);
    }
  } catch (_) {
    await auth.signOut(scope: SignOutScope.local);
  }
}
