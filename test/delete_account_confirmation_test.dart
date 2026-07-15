import 'package:dawa_mom/features/settings/dawa_mom_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delete account requires exact confirmation text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DeleteAccountConfirmationDialog()),
      ),
    );

    FilledButton button() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('confirm-delete-account')),
        );

    expect(button().onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation')),
      'delete',
    );
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation')),
      'DELETE',
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });
}
