import 'package:dawa_mom/features/period_tracker/presentation/dawa_cycle_tracker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('daily check-in saves symptoms, pain, feeling and note',
      (tester) async {
    List<String>? capturedSymptoms;
    double? capturedPain;
    String? capturedFeeling;
    String? capturedNote;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDawaDailyCheckInSheet(
                context,
                date: DateTime(2026, 7, 23),
                existing: null,
                onSave: ({
                  required symptoms,
                  required pain,
                  required feeling,
                  required note,
                }) async {
                  capturedSymptoms = symptoms;
                  capturedPain = pain;
                  capturedFeeling = feeling;
                  capturedNote = note;
                },
              ),
              child: const Text('Open check-in'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cramps'));
    await tester.ensureVisible(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a note (optional)'),
      'Felt better after resting.',
    );
    await tester.ensureVisible(find.text('Save log'));
    await tester.tap(find.text('Save log'));
    await tester.pumpAndSettle();

    expect(capturedSymptoms, contains('Cramps'));
    expect(capturedPain, 1);
    expect(capturedFeeling, 'Great');
    expect(capturedNote, 'Felt better after resting.');
  });
}
