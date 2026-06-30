import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../auth_manager.dart';
import '/backend/backend.dart';
import '/backend/supabase/supabase_config.dart';
import 'supabase_user_provider.dart';

export '../base_auth_user_provider.dart';

class SupabasePhoneAuthManager extends ChangeNotifier {
  bool? _triggerOnCodeSent;
  String? phoneAuthError;
  String? pendingPhoneNumber;
  void Function(BuildContext)? _onCodeSent;

  bool get triggerOnCodeSent => _triggerOnCodeSent ?? false;
  set triggerOnCodeSent(bool val) => _triggerOnCodeSent = val;

  void Function(BuildContext) get onCodeSent =>
      _onCodeSent == null ? (_) {} : _onCodeSent!;
  set onCodeSent(void Function(BuildContext) func) => _onCodeSent = func;

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}

class SupabaseAuthManager extends AuthManager
    with
        EmailSignInManager,
        GoogleSignInManager,
        AppleSignInManager,
        AnonymousSignInManager,
        JwtSignInManager,
        GithubSignInManager,
        PhoneSignInManager {
  SupabasePhoneAuthManager phoneAuthManager = SupabasePhoneAuthManager();

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  @override
  Future signOut() => _client.auth.signOut();

  @override
  Future deleteUser(BuildContext context) async {
    if (!loggedIn) {
      debugPrint('Error: delete user attempted with no logged in user');
      return;
    }
    final uid = currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await UserRecord.collection.doc(uid).delete();
    }
    await _client.auth.signOut();
  }

  @override
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await currentUser?.updateEmail(email);
      await updateUserDocument(email: email);
    } on supabase.AuthException catch (e) {
      _showAuthError(context, e.message);
    }
  }

  @override
  Future updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on supabase.AuthException catch (e) {
      _showAuthError(context, e.message);
    }
  }

  @override
  Future resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    final normalizedEmail = email.trim();
    try {
      final redirectTo = _passwordResetRedirectUrl();
      try {
        await _client.auth
            .resetPasswordForEmail(
              normalizedEmail,
              redirectTo: redirectTo,
            )
            .timeout(const Duration(seconds: 8));
      } on TimeoutException {
        debugPrint(
          'Supabase SDK password reset timed out; retrying through recover endpoint.',
        );
        await _sendPasswordResetThroughRecoverEndpoint(
          normalizedEmail,
          redirectTo,
        );
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for this email, a password reset link has been sent.',
          ),
        ),
      );
    } on TimeoutException {
      _showAuthError(
        context,
        'The password reset request timed out. Check your connection and try again.',
      );
    } on supabase.AuthException catch (e) {
      _showAuthError(context, e.message);
    } catch (e) {
      _showAuthError(context, 'Could not send password reset email.');
    }
  }

  Future<void> _sendPasswordResetThroughRecoverEndpoint(
    String email,
    String? redirectTo,
  ) async {
    final uri = Uri.parse('$supabaseUrl/auth/v1/recover').replace(
      queryParameters: redirectTo == null ? null : {'redirect_to': redirectTo},
    );

    final response = await http
        .post(
          uri,
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw supabase.AuthException(
      _passwordResetErrorMessage(response.body),
      statusCode: response.statusCode.toString(),
    );
  }

  String _passwordResetErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map) {
        final message =
            decoded['msg'] ?? decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Keep the generic message when the API response is not JSON.
    }
    return 'Could not send password reset email.';
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => _signInWithFirebaseMigrationFallback(email, password),
      );

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInOrCreateAccount(
        context,
        () => _client.auth.signUp(
          email: email,
          password: password,
          data: {'requested_role': 'patient'},
        ),
      );

  @override
  Future<BaseAuthUser?> signInAnonymously(BuildContext context) async {
    try {
      final response = await _client.auth.signInAnonymously();
      if (response.user != null) {
        await maybeCreateUser(response.user!);
      }
      return DawaMomSupabaseUser.fromAuthResponse(response);
    } on supabase.AuthException catch (e) {
      _showAuthError(context, e.message);
      return null;
    }
  }

  @override
  Future<BaseAuthUser?> signInWithApple(BuildContext context) =>
      _oauthSignIn(context, supabase.OAuthProvider.apple);

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) =>
      _oauthSignIn(context, supabase.OAuthProvider.google);

  @override
  Future<BaseAuthUser?> signInWithGithub(BuildContext context) =>
      _oauthSignIn(context, supabase.OAuthProvider.github);

  @override
  Future<BaseAuthUser?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  ) async {
    _showAuthError(
        context, 'Custom JWT sign-in must be handled by the Supabase backend.');
    return null;
  }

  void handlePhoneAuthStateChanges(BuildContext context) {
    phoneAuthManager.addListener(() {
      if (!context.mounted) {
        return;
      }
      if (phoneAuthManager.triggerOnCodeSent) {
        phoneAuthManager.onCodeSent(context);
        phoneAuthManager
            .update(() => phoneAuthManager.triggerOnCodeSent = false);
      } else if (phoneAuthManager.phoneAuthError != null) {
        _showAuthError(context, phoneAuthManager.phoneAuthError!);
        phoneAuthManager.update(() => phoneAuthManager.phoneAuthError = null);
      }
    });
  }

  @override
  Future beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  }) async {
    phoneAuthManager.update(() {
      phoneAuthManager.onCodeSent = onCodeSent;
      phoneAuthManager.pendingPhoneNumber = phoneNumber;
    });
    try {
      await _client.auth.signInWithOtp(phone: phoneNumber);
      phoneAuthManager.update(() {
        phoneAuthManager.triggerOnCodeSent = true;
        phoneAuthManager.phoneAuthError = null;
      });
      return true;
    } on supabase.AuthException catch (e) {
      phoneAuthManager.update(() {
        phoneAuthManager.triggerOnCodeSent = false;
        phoneAuthManager.phoneAuthError = e.message;
      });
      return false;
    }
  }

  @override
  Future verifySmsCode({
    required BuildContext context,
    required String smsCode,
  }) async {
    final phone = phoneAuthManager.pendingPhoneNumber;
    if (phone == null || phone.isEmpty) {
      _showAuthError(
          context, 'Phone number is missing. Start phone sign-in again.');
      return null;
    }
    return _signInOrCreateAccount(
      context,
      () => _client.auth.verifyOTP(
        phone: phone,
        token: smsCode,
        type: supabase.OtpType.sms,
      ),
    );
  }

  Future<BaseAuthUser?> _oauthSignIn(
    BuildContext context,
    supabase.OAuthProvider provider,
  ) async {
    try {
      final started = await _client.auth.signInWithOAuth(provider);
      if (!started) {
        _showAuthError(context, 'Could not start OAuth sign-in.');
        return null;
      }
      return DawaMomSupabaseUser.fromSupabaseUser(_client.auth.currentUser);
    } on supabase.AuthException catch (e) {
      _showAuthError(context, e.message);
      return null;
    }
  }

  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<supabase.AuthResponse> Function() signInFunc,
  ) async {
    try {
      final response = await signInFunc();
      if (response.user != null) {
        await maybeCreateUser(response.user!);
      }
      return DawaMomSupabaseUser.fromAuthResponse(response);
    } on supabase.AuthException catch (e) {
      _showAuthError(context, _friendlyError(e));
      return null;
    }
  }

  Future<supabase.AuthResponse> _signInWithFirebaseMigrationFallback(
    String email,
    String password,
  ) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on supabase.AuthException catch (e) {
      if (!_isInvalidLogin(e)) {
        rethrow;
      }

      final migrated = await _tryMigrateFirebasePassword(email, password);
      if (!migrated) {
        rethrow;
      }

      return _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    }
  }

  Future<bool> _tryMigrateFirebasePassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'firebase-auth-migrate-login',
        body: {
          'email': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 20));

      final data = response.data;
      return data is Map && data['migrated'] == true;
    } catch (error) {
      debugPrint('Firebase password migration failed: $error');
      return false;
    }
  }

  String _friendlyError(supabase.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Error: The email is already in use by a different account';
    }
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Error: The supplied auth credential is incorrect, malformed or has expired';
    }
    return 'Error: ${e.message}';
  }

  bool _isInvalidLogin(supabase.AuthException e) {
    final message = e.message.toLowerCase();
    return message.contains('invalid login') ||
        message.contains('invalid credentials');
  }

  String? _passwordResetRedirectUrl() {
    final base = Uri.base;
    if ((base.scheme != 'http' && base.scheme != 'https') ||
        base.host.isEmpty) {
      return null;
    }

    return base
        .replace(
          path: '/login',
          queryParameters: const {},
          fragment: '',
        )
        .toString();
  }

  void _showAuthError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
