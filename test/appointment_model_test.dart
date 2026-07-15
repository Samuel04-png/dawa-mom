import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment', () {
    test('maps the dedicated Supabase appointment row', () {
      final appointment = Appointment.fromJson({
        'id': 'appointment-id',
        'mother_id': 'mother-id',
        'patient_id': 'patient-id',
        'clinician_id': 'clinician-id',
        'clinic_id': 'clinic-id',
        'appointment_date': '2099-07-20',
        'start_time': '09:00:00',
        'end_time': '09:30:00',
        'appointment_type': 'maternal_health',
        'status': 'pending',
        'source': 'dawa_mom',
        'created_at': '2026-07-15T06:00:00Z',
        'integration_status': 'pending',
      });

      expect(appointment.startTime, '09:00');
      expect(appointment.endTime, '09:30');
      expect(appointment.status, 'pending');
      expect(appointment.canPatientCancel, isTrue);
      expect(appointment.isUpcoming, isTrue);
    });

    test('normalizes a date and time into a local DateTime', () {
      expect(
        Appointment.dateAtTime(DateTime(2026, 7, 20), '14:30'),
        DateTime(2026, 7, 20, 14, 30),
      );
    });
  });

  test('ClinicianProfile maps only booking-directory fields', () {
    final clinician = ClinicianProfile.fromJson({
      'id': 'clinician-id',
      'display_name': 'Dr Jane Banda',
      'professional_title': 'Medical Doctor',
      'speciality': 'Maternal Health',
      'clinic_id': 'clinic-id',
      'clinic_name': 'Kabulonga Clinic',
      'is_active': true,
      'is_bookable': true,
      'availability_summary': {
        'start_time': '08:00:00',
        'end_time': '16:00:00',
        'slot_minutes': 30,
      },
    });

    expect(clinician.displayName, 'Dr Jane Banda');
    expect(clinician.subtitle, 'Medical Doctor • Maternal Health');
    expect(clinician.scheduleStart, '08:00');
    expect(clinician.slotMinutes, 30);
  });
}
