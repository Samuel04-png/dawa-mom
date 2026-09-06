import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/appointments/domain/appointment_result_summary.dart';
import 'package:dawa_mom/navbar/appointments/appointment_details/appointment_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completed appointment leads with clean high-level results',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: AppointmentDetailsContent(
            appointment: _appointment('completed'),
            resultSummary: _summary(),
            resultLoading: false,
            resultError: false,
            cancelling: false,
            onCancel: () {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appointment completed'), findsOneWidget);
    expect(find.text('Consultation results'), findsOneWidget);
    expect(find.text('Your care summary'), findsOneWidget);
    expect(find.text('Mother’s health'), findsOneWidget);
    expect(find.text('Pregnancy and baby health'), findsOneWidget);
    expect(find.text('Recommendations and next steps'), findsOneWidget);
    expect(find.text('Care team and clinic'), findsOneWidget);
    expect(find.text('Booking information'), findsOneWidget);
    expect(find.textContaining('clinician-only'), findsNothing);
    expect(find.textContaining('00000000-0000'), findsNothing);
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

  testWidgets('pending appointment stays focused on booking information',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: AppointmentDetailsContent(
            appointment: _appointment('pending'),
            resultLoading: false,
            resultError: false,
            cancelling: false,
            onCancel: () {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending confirmation'), findsWidgets);
    expect(find.textContaining('waiting for confirmation'), findsOneWidget);
    expect(find.text('Visit details'), findsOneWidget);
    expect(find.text('Consultation results'), findsNothing);
    expect(find.text('Your care summary'), findsNothing);
    expect(find.text('Cancel appointment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('upcoming appointment includes accessible preparation imagery',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: AppointmentDetailsContent(
            appointment: _appointment(
              'confirmed',
              date: DateTime.now().add(const Duration(days: 2)),
            ),
            resultLoading: false,
            resultError: false,
            cancelling: false,
            onCancel: () {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prepare for your visit'),
      300,
    );

    expect(find.text('Prepare for your visit'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Educational image about preparing for a clinic visit',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Appointment _appointment(String status, {DateTime? date}) => Appointment(
      id: '00000000-0000-4000-8000-000000000001',
      motherId: '00000000-0000-4000-8000-000000000002',
      patientId: '00000000-0000-4000-8000-000000000003',
      clinicianId: '00000000-0000-4000-8000-000000000004',
      clinicId: '00000000-0000-4000-8000-000000000005',
      date: date ?? DateTime(2026, 7, 22),
      startTime: '14:00',
      endTime: '14:30',
      appointmentType: 'maternal_health',
      status: status,
      source: 'dawa_mom',
      createdAt: DateTime(2026, 7, 20, 14, 12),
      integrationStatus: status == 'completed' ? 'synced' : 'pending',
      reason: 'Pregnancy confirmation',
      notes: 'Please bring previous test results.',
      clinicianName: 'Dr Fae',
      clinicianTitle: 'Physician',
      clinicianSpeciality: 'Maternal health',
      clinicName: 'DawaMom Clinic',
      clinicAddress: 'Lusaka',
    );

AppointmentResultSummary _summary() => AppointmentResultSummary(
      id: '00000000-0000-4000-8000-000000000010',
      appointmentId: '00000000-0000-4000-8000-000000000001',
      version: 1,
      clinicianDisplayName: 'Dr Fae',
      clinicName: 'DawaMom Clinic',
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
