import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline appointment snapshot keeps only display-safe schedule data',
      () {
    final appointment = Appointment(
      id: 'appointment-1',
      motherId: 'mother-private',
      patientId: 'patient-private',
      clinicianId: 'clinician-private',
      clinicId: 'clinic-private',
      date: DateTime(2026, 10, 21),
      startTime: '09:00',
      endTime: '09:30',
      appointmentType: 'maternal_health',
      reason: 'Private reason',
      notes: 'Private clinical note',
      status: 'confirmed',
      source: 'dawa_mom',
      createdAt: DateTime.utc(2026, 10, 14, 8),
      integrationStatus: 'synced',
      isPaidSnapshot: true,
      paymentMethod: 'online',
      paymentState: 'successful',
      clinicianName: 'Dr Mumba',
      clinicName: 'Kalingalinga Clinic',
      clinicAddress: 'Private clinic address',
    );

    final snapshot = appointment.toOfflineSnapshot();

    expect(snapshot, isNot(contains('reason')));
    expect(snapshot, isNot(contains('notes')));
    expect(snapshot, isNot(contains('mother_id')));
    expect(snapshot, isNot(contains('patient_id')));
    expect(snapshot, isNot(contains('clinician_id')));
    expect(snapshot, isNot(contains('clinic_id')));
    expect(snapshot, isNot(contains('clinic_address')));

    final restored = Appointment.fromOfflineSnapshot(snapshot);
    expect(restored.id, 'appointment-1');
    expect(restored.date, DateTime(2026, 10, 21));
    expect(restored.status, 'confirmed');
    expect(restored.paymentState, 'successful');
    expect(restored.clinicianName, 'Dr Mumba');
    expect(restored.clinicName, 'Kalingalinga Clinic');
    expect(restored.reason, isNull);
    expect(restored.notes, isNull);
    expect(restored.clinicAddress, isNull);
    expect(restored.motherId, isEmpty);
    expect(restored.patientId, isEmpty);
  });
}
