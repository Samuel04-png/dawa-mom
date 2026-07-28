import 'package:dawa_mom/design_system/dawa_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('labelled tappable cards expose one concise button node',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DawaCard(
            onTap: () {},
            semanticLabel: 'Unread notification. Appointment confirmed.',
            child: const Text('Repeated visible appointment detail'),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel(
        'Unread notification. Appointment confirmed.',
      ),
    );
    expect(node.label, 'Unread notification. Appointment confirmed.');
    expect(node.flagsCollection.isButton, isTrue);
    expect(
      find.bySemanticsLabel('Repeated visible appointment detail'),
      findsNothing,
    );
    semantics.dispose();
  });
}
