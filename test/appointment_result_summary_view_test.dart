import 'package:dawa_mom/features/appointments/domain/appointment_result_summary.dart';
import 'package:dawa_mom/features/appointments/presentation/appointment_result_summary_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('patient result summary is clear and responsive', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AppointmentResultSummaryView(summary: _summary()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your care summary'), findsOneWidget);
    expect(find.text('Mother’s health'), findsOneWidget);
    expect(find.text('Pregnancy and baby health'), findsOneWidget);
    expect(find.text('Recommendations and next steps'), findsOneWidget);
    expect(find.textContaining('clinician-only'), findsNothing);
    expect(tester.takeException(), isNull);

    for (final size in [
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1366, 900),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

AppointmentResultSummary _summary() => AppointmentResultSummary(
      id: '00000000-0000-4000-8000-000000000010',
      appointmentId: '00000000-0000-4000-8000-000000000011',
      version: 1,
      clinicianDisplayName: 'Dr Fae',
      clinicName: 'Dawa Mom',
      appointmentDate: DateTime(2026, 7, 22),
      completedAt: DateTime(2026, 7, 22, 14, 30),
      overallStatus: 'follow_up',
      maternalSummary: const {
        'heart_rate': ResultMeasurement(
          state: 'measured',
          value: '78',
          unit: 'bpm',
          interpretation: 'normal',
        ),
        'blood_pressure': ResultMeasurement(
          state: 'measured',
          value: '120/80',
          unit: 'mmHg',
          interpretation: 'normal',
        ),
        'hemoglobin': ResultMeasurement(
          state: 'measured',
          value: '10',
          unit: 'g/dL',
          interpretation: 'low',
        ),
      },
      pregnancySummary: const {
        'pregnancy_status': ResultMeasurement(
          state: 'recorded',
          value: 'pregnant',
          source: 'patient',
        ),
        'fetal_heartbeat': ResultMeasurement(
          state: 'measured',
          value: '140',
          unit: 'bpm',
          interpretation: 'normal',
        ),
        'heartbeat_quality': ResultMeasurement(
          state: 'recorded',
          value: 'Regular',
          interpretation: 'normal',
        ),
        'fetal_position': ResultMeasurement(
          state: 'recorded',
          value: 'Cephalic',
        ),
        'estimated_baby_size': ResultMeasurement(
          state: 'measured',
          value: '34',
          unit: 'cm',
          interpretation: 'recorded',
        ),
      },
      keyFindings: 'Your blood level was low and should be reviewed.',
      recommendations: 'Continue the treatment prescribed by your clinician.',
      followUpInstructions: 'Return to the clinic in two weeks.',
      nextAppointmentAt: DateTime(2026, 8, 5),
      generatedAt: DateTime(2026, 7, 22, 14, 30),
    );
