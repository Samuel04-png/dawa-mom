import 'package:dawa_mom/features/auth/dawa_auth_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Zambian phone normalization accepts local and international forms', () {
    expect(normalizeZambianPhone('097 123 4567'), '+260971234567');
    expect(normalizeZambianPhone('260971234567'), '+260971234567');
    expect(normalizeZambianPhone('+260971234567'), '+260971234567');
  });

  testWidgets('registration validates the redesigned form without networking',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DawaRegistrationPage()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });
}
