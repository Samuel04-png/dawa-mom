import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const authServiceUnavailableMessage =
    'The sign-in service is temporarily unavailable. Please try again shortly.';

bool isTemporaryAuthFailure(Object error) {
  if (error is TimeoutException ||
      error is http.ClientException ||
      error is AuthRetryableFetchException) return true;
  if (error is AuthException) {
    final status = int.tryParse(error.statusCode ?? '');
    return status == 429 || (status != null && status >= 500);
  }
  return false;
}

/// GoTrue owns refresh-token rotation and clears definitively invalid sessions.
/// Do not turn a transient refresh failure into an app-initiated sign-out.
Future<void> refreshSupabaseSession(GoTrueClient auth,
    {Duration timeout = const Duration(seconds: 8)}) async {
  if (auth.currentSession == null) return;
  final response = await auth.refreshSession().timeout(timeout);
  if (response.session == null) throw AuthSessionMissingException();
}

/// Keep application subscribers alive for a later successful refresh/sign-in.
/// Supabase's signedOut events still pass through normally.
Stream<AuthState> recoverableAuthStateChanges(Stream<AuthState> source) =>
    source.handleError((Object error, StackTrace stack) {
      debugPrint('Supabase auth update delayed (${error.runtimeType}).');
    }, test: (error) => error is Object && isTemporaryAuthFailure(error));
