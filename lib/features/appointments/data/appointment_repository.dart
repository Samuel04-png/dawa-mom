import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_database.dart';
import '../domain/appointment.dart';
import 'clinician_directory_repository.dart';

class AppointmentRepository {
  AppointmentRepository({
    SupabaseClient? client,
    ClinicianDirectoryRepository? clinicianDirectory,
  })  : _client = client ?? Supabase.instance.client,
        _clinicianDirectory = clinicianDirectory ??
            SupabaseClinicianDirectoryRepository(client: client);

  final SupabaseClient _client;
  final ClinicianDirectoryRepository _clinicianDirectory;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<ClinicOption>> getClinics() async {
    _requireUserId();
    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('clinics').select('id,name,address').order('name'),
    );
    return (rows as List)
        .map((row) => ClinicOption.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  Future<List<Appointment>> getAppointments() async {
    _requireUserId();
    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('appointments')
          .select()
          .order('appointment_date')
          .order('start_time'),
    );
    final appointments = (rows as List)
        .map((row) => Appointment.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
    return _decorateAppointments(appointments);
  }

  Future<Appointment?> getNextAppointment() async {
    final appointments = await getAppointments();
    final upcoming = appointments.where((item) => item.isUpcoming).toList()
      ..sort((a, b) => Appointment.dateAtTime(a.date, a.startTime)
          .compareTo(Appointment.dateAtTime(b.date, b.startTime)));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<Appointment?> getAppointment(String id) async {
    _requireUserId();
    final row = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.from('appointments').select().eq('id', id).maybeSingle(),
    );
    if (row == null) {
      return null;
    }
    final decorated = await _decorateAppointments([
      Appointment.fromJson(Map<String, dynamic>.from(row)),
    ]);
    return decorated.first;
  }

  Future<Appointment> bookAppointment({
    required String clinicId,
    required String clinicianId,
    required DateTime date,
    required AppointmentSlot slot,
    String appointmentType = 'maternal_health',
    String? reason,
    String? notes,
  }) async {
    final userId = _requireUserId();
    final mother = await _getCurrentMother(userId);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final selectedStart =
        Appointment.dateAtTime(normalizedDate, slot.startTime);
    if (!selectedStart.isAfter(DateTime.now())) {
      throw const AppointmentException(
        'Please choose an appointment time in the future.',
      );
    }

    final clinicians =
        await _clinicianDirectory.getCliniciansByClinic(clinicId);
    final clinicianMatches = clinicians.any(
      (clinician) =>
          clinician.id == clinicianId &&
          clinician.clinicId == clinicId &&
          clinician.isActive &&
          clinician.isBookable,
    );
    if (!clinicianMatches) {
      throw const AppointmentException(
        'The selected clinician is not available at this clinic.',
      );
    }

    final latestSlots = await _clinicianDirectory.getClinicianAvailability(
      clinicianId,
      normalizedDate,
    );
    final slotStillAvailable = latestSlots.any(
      (candidate) =>
          candidate.startTime == slot.startTime && candidate.isAvailable,
    );
    if (!slotStillAvailable) {
      throw const AppointmentException(
        'That appointment time was just taken. Please choose another time.',
        retryable: true,
      );
    }

    final duplicate = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('appointments')
          .select('id')
          .eq('mother_id', mother['id'])
          .eq('appointment_date', _dateId(normalizedDate))
          .eq('start_time', '${slot.startTime}:00')
          .not('status', 'in', '(cancelled,declined)')
          .limit(1),
    );
    if ((duplicate as List).isNotEmpty) {
      throw const AppointmentException(
        'You already have an appointment at this time.',
      );
    }

    try {
      final row = await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('appointments')
            .insert({
              'mother_id': mother['id'],
              'patient_id': userId,
              'clinician_id': clinicianId,
              'clinic_id': clinicId,
              'appointment_date': _dateId(normalizedDate),
              'start_time': '${slot.startTime}:00',
              'end_time': '${slot.endTime}:00',
              'appointment_type': appointmentType,
              'reason': _nullIfBlank(reason),
              'notes': _nullIfBlank(notes),
              'status': 'pending',
              'source': 'dawa_mom',
              'created_by': userId,
              'integration_status': 'pending',
            })
            .select()
            .single(),
      );
      final appointment = Appointment.fromJson(Map<String, dynamic>.from(row));
      final decorated = await _decorateAppointments([appointment]);
      changes.value += 1;
      return decorated.first;
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const AppointmentException(
          'That appointment time was just taken. Please choose another time.',
          retryable: true,
        );
      }
      if (error.code == '42501' || error.code == 'PGRST301') {
        throw const AppointmentException(
          'Your session or profile could not be verified. Please sign in again.',
        );
      }
      if (error.code == '23514') {
        throw const AppointmentException(
          'The clinic, clinician, or appointment time is no longer valid.',
          retryable: true,
        );
      }
      throw const AppointmentException(
        'We could not book your appointment. Please try again.',
        retryable: true,
      );
    }
  }

  Future<Appointment> cancelAppointment(String id) async {
    _requireUserId();
    try {
      final row = await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('appointments')
            .update({'status': 'cancelled'})
            .eq('id', id)
            .select()
            .single(),
      );
      final appointment = Appointment.fromJson(Map<String, dynamic>.from(row));
      final decorated = await _decorateAppointments([appointment]);
      changes.value += 1;
      return decorated.first;
    } on PostgrestException {
      throw const AppointmentException(
        'This appointment could not be cancelled. Refresh and try again.',
        retryable: true,
      );
    }
  }

  Future<Map<String, dynamic>> _getCurrentMother(String userId) async {
    final row = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('mothers')
          .select('id,profile_id,name')
          .eq('profile_id', userId)
          .maybeSingle(),
    );
    if (row == null) {
      throw const AppointmentException(
        'Complete your health profile before booking an appointment.',
      );
    }
    return Map<String, dynamic>.from(row);
  }

  Future<List<Appointment>> _decorateAppointments(
    List<Appointment> appointments,
  ) async {
    if (appointments.isEmpty) {
      return appointments;
    }
    List<ClinicianProfile> clinicians;
    List<ClinicOption> clinics;
    try {
      final directory = await Future.wait<dynamic>([
        _clinicianDirectory.getClinicians(),
        getClinics(),
      ]);
      clinicians = directory[0] as List<ClinicianProfile>;
      clinics = directory[1] as List<ClinicOption>;
    } catch (_) {
      clinicians = const [];
      clinics = const [];
    }
    final clinicianById = {for (final item in clinicians) item.id: item};
    final clinicById = {for (final item in clinics) item.id: item};
    return appointments.map((appointment) {
      final clinician = clinicianById[appointment.clinicianId];
      final clinic = clinicById[appointment.clinicId];
      return appointment.copyWith(
        clinicianName: clinician?.displayName ?? 'Clinician',
        clinicianTitle: clinician?.professionalTitle,
        clinicianSpeciality: clinician?.speciality,
        clinicName: clinician?.clinicName ?? clinic?.name ?? 'Clinic',
        clinicAddress: clinic?.address,
      );
    }).toList();
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AppointmentException(
        'Please sign in before booking an appointment.',
      );
    }
    return userId;
  }

  static String _dateId(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
