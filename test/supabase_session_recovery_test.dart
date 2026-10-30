import 'dart:async';
import 'dart:convert';

import 'package:dawa_mom/backend/supabase/supabase_session_recovery.dart';
import 'package:dawa_mom/features/auth/dawa_auth_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> syntheticSession({String refresh = 'synthetic-refresh'}) {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  return {
    'access_token': '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({
          'sub': 'synthetic-user',
          'exp': expiry
        })}.synthetic',
    'refresh_token': refresh,
    'expires_in': 3600,
    'token_type': 'bearer',
    'user': {
      'id': 'synthetic-user',
      'aud': 'authenticated',
      'app_metadata': {},
      'user_metadata': {},
      'created_at': '2026-10-29T00:00:00Z'
    }
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  int signInStatus = 504;
  int migrationCalls = 0;
  int passwordCalls = 0;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
        url: 'http://127.0.0.1:54327',
        publishableKey: 'synthetic-only',
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            passwordCalls++;
            return http.Response(
                jsonEncode(signInStatus == 504
                    ? {'message': 'upstream request timeout'}
                    : {
                        'code': 'invalid_credentials',
                        'message': 'Invalid login credentials'
                      }),
                signInStatus,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          if (request.url.path.contains('firebase-auth-migrate-login')) {
            migrationCalls++;
            return http.Response('{"migrated":false}', 200,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          return http.Response('[]', 200,
              request: request, headers: {'content-type': 'application/json'});
        }));
  });
  setUp(() {
    signInStatus = 504;
    migrationCalls = 0;
    passwordCalls = 0;
  });
  test('anonymous startup does not refresh or sign out', () async {
    var calls = 0;
    final client = SupabaseClient('https://synthetic.invalid', 'synthetic-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
      calls++;
      return http.Response('{}', 500);
    }));
    await refreshSupabaseSession(client.auth);
    expect(calls, 0);
    await client.dispose();
  });
  test(
      'a timed-out 504 refresh preserves the session and later SDK recovery succeeds',
      () async {
    var unavailable = true;
    var logoutCalls = 0;
    var refreshCalls = 0;
    final client = SupabaseClient('https://synthetic.invalid', 'synthetic-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
      if (r.url.path.endsWith('/logout')) {
        logoutCalls++;
        return http.Response('', 204);
      }
      refreshCalls++;
      return http.Response(
          jsonEncode(unavailable
              ? {'message': 'upstream request timeout'}
              : syntheticSession(refresh: 'rotated-synthetic-refresh')),
          unavailable ? 504 : 200,
          request: r,
          headers: {'content-type': 'application/json'});
    }));
    await client.auth.recoverSession(jsonEncode(syntheticSession()));
    final events = <AuthChangeEvent>[];
    final sub = recoverableAuthStateChanges(client.auth.onAuthStateChange)
        .listen((s) => events.add(s.event));
    await expectLater(
        refreshSupabaseSession(client.auth,
            timeout: const Duration(milliseconds: 30)),
        throwsA(isA<TimeoutException>()));
    expect(refreshCalls, greaterThan(0));
    expect(client.auth.currentSession?.refreshToken, 'synthetic-refresh');
    expect(logoutCalls, 0);
    expect(events, isNot(contains(AuthChangeEvent.signedOut)));
    unavailable = false;
    await client.auth.refreshSession();
    expect(
        client.auth.currentSession?.refreshToken, 'rotated-synthetic-refresh');
    expect(logoutCalls, 0);
    await sub.cancel();
    await client.dispose();
  });
  test('definitively invalid refresh token still clears the session', () async {
    var logoutCalls = 0;
    final client = SupabaseClient('https://synthetic.invalid', 'synthetic-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
      if (r.url.path.endsWith('/logout')) logoutCalls++;
      return http.Response(
          '{"code":"refresh_token_not_found","message":"Invalid Refresh Token: Refresh Token Not Found"}',
          400,
          request: r,
          headers: {'content-type': 'application/json'});
    }));
    await client.auth.recoverSession(jsonEncode(syntheticSession()));
    await expectLater(
        refreshSupabaseSession(client.auth), throwsA(isA<AuthException>()));
    expect(client.auth.currentSession, isNull);
    expect(logoutCalls, 0);
    await client.dispose();
  });
  test('refresh error does not close listeners before a later sign-in/sign-out',
      () async {
    final source = StreamController<AuthState>();
    final seen = <AuthChangeEvent>[];
    final errors = <Object>[];
    final sub = recoverableAuthStateChanges(source.stream)
        .listen((state) => seen.add(state.event), onError: errors.add);
    source.addError(AuthRetryableFetchException(
        message: 'upstream request timeout', statusCode: '504'));
    source.add(AuthState(AuthChangeEvent.signedIn,
        Session.fromJson(jsonDecode(jsonEncode(syntheticSession())))));
    source.add(AuthState(AuthChangeEvent.signedOut, null));
    await source.close();
    expect(seen, [AuthChangeEvent.signedIn, AuthChangeEvent.signedOut]);
    expect(errors, isEmpty);
    await sub.cancel();
  });
  test('unexpected programming errors are not silently swallowed', () async {
    final source = StreamController<AuthState>();
    final errors = <Object>[];
    final sub = recoverableAuthStateChanges(source.stream)
        .listen((_) {}, onError: errors.add);
    source.addError(StateError('synthetic bug'));
    await source.close();
    expect(errors.single, isA<StateError>());
    await sub.cancel();
  });
  testWidgets(
      '504 sign-in displays service problem, does not migrate credentials, and enables retry',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DawaLoginPage()));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'synthetic@example.invalid');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'synthetic-password');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(authServiceUnavailableMessage), findsOneWidget);
    expect(passwordCalls, 1);
    expect(migrationCalls, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(Supabase.instance.client.auth.currentSession, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'invalid credentials remain a credentials error rather than an outage',
      (tester) async {
    signInStatus = 400;
    await tester.pumpWidget(const MaterialApp(home: DawaLoginPage()));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'synthetic@example.invalid');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'synthetic-password');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(authServiceUnavailableMessage), findsNothing);
    expect(find.textContaining('supplied auth credential'), findsOneWidget);
    expect(passwordCalls, 1);
    expect(migrationCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
