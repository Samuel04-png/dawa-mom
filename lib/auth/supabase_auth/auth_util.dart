import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '/backend/backend.dart';
import 'supabase_auth_manager.dart';

export 'supabase_auth_manager.dart';

final _authManager = SupabaseAuthManager();
SupabaseAuthManager get authManager => _authManager;

String get currentUserEmail =>
    currentUserDocument?.email ?? currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName =>
    currentUserDocument?.displayName ?? currentUser?.displayName ?? '';

String get currentUserPhoto =>
    currentUserDocument?.photoUrl ?? currentUser?.photoUrl ?? '';

String get currentPhoneNumber =>
    currentUserDocument?.phoneNumber ?? currentUser?.phoneNumber ?? '';

String get currentJwtToken =>
    supabase.Supabase.instance.client.auth.currentSession?.accessToken ??
    _currentJwtToken ??
    '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

String? _currentJwtToken =
    supabase.Supabase.instance.client.auth.currentSession?.accessToken;

final jwtTokenStream = supabase.Supabase.instance.client.auth.onAuthStateChange
    .map((state) => _currentJwtToken = state.session?.accessToken)
    .asBroadcastStream();

DocumentReference? get currentUserReference =>
    loggedIn ? UserRecord.collection.doc(currentUser!.uid) : null;

UserRecord? currentUserDocument;

final authenticatedUserStream = _authenticatedUserStream().asBroadcastStream();

Stream<UserRecord?> _authenticatedUserStream() async* {
  final initialUser = supabase.Supabase.instance.client.auth.currentUser;
  yield await _loadUserRecord(initialUser);

  await for (final state
      in supabase.Supabase.instance.client.auth.onAuthStateChange) {
    yield await _loadUserRecord(state.session?.user);
  }
}

Future<UserRecord?> _loadUserRecord(supabase.User? user) async {
  if (user == null) {
    currentUserDocument = null;
    return null;
  }
  final ref = UserRecord.collection.doc(user.id);
  try {
    currentUserDocument = await UserRecord.getDocumentOnce(ref);
  } catch (_) {
    currentUserDocument = null;
  }
  return currentUserDocument;
}

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => builder(context),
      );
}
