import 'package:dawa_mom/auth/base_auth_user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthUserInfo stores profile fields', () {
    const userInfo = AuthUserInfo(
      uid: 'test-user',
      email: 'test@example.com',
      displayName: 'Test User',
      phoneNumber: '+260000000000',
    );

    expect(userInfo.uid, 'test-user');
    expect(userInfo.email, 'test@example.com');
    expect(userInfo.displayName, 'Test User');
    expect(userInfo.phoneNumber, '+260000000000');
  });
}
