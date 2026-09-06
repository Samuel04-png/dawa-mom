import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../base_auth_user_provider.dart';

export '../base_auth_user_provider.dart';

class DawaMomSupabaseUser extends BaseAuthUser {
  DawaMomSupabaseUser(this.user);

  supabase.User? user;

  @override
  bool get loggedIn => user != null;

  Map<String, dynamic> get _metadata => user?.userMetadata ?? const {};

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
        uid: user?.id,
        email: user?.email,
        displayName: _metadata['display_name']?.toString() ??
            _metadata['full_name']?.toString() ??
            _metadata['name']?.toString(),
        photoUrl: _metadata['avatar_url']?.toString() ??
            _metadata['picture']?.toString(),
        phoneNumber: user?.phone,
      );

  @override
  Future? delete() async {
    await supabase.Supabase.instance.client.auth.signOut();
  }

  @override
  Future? updateEmail(String email) =>
      supabase.Supabase.instance.client.auth.updateUser(
        supabase.UserAttributes(email: email),
      );

  @override
  Future? updatePassword(String newPassword) =>
      supabase.Supabase.instance.client.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );

  @override
  Future? sendEmailVerification() async {
    final email = user?.email;
    if (email == null || email.isEmpty) {
      return;
    }
    await supabase.Supabase.instance.client.auth.resend(
      type: supabase.OtpType.signup,
      email: email,
    );
  }

  @override
  bool get emailVerified => user?.emailConfirmedAt != null;

  @override
  Future refreshUser() async {
    user = supabase.Supabase.instance.client.auth.currentUser;
  }

  static BaseAuthUser fromAuthResponse(supabase.AuthResponse response) =>
      DawaMomSupabaseUser(response.user);

  static BaseAuthUser fromSupabaseUser(supabase.User? user) =>
      DawaMomSupabaseUser(user);
}

Stream<BaseAuthUser> dawaMomSupabaseUserStream() async* {
  final client = supabase.Supabase.instance.client;
  currentUser = DawaMomSupabaseUser(client.auth.currentUser);
  yield currentUser!;

  await for (final state in client.auth.onAuthStateChange) {
    currentUser = DawaMomSupabaseUser(state.session?.user);
    yield currentUser!;
  }
}
