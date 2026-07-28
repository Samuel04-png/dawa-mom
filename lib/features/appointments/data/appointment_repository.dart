import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '/backend/supabase/supabase_database.dart';
import '../domain/appointment.dart';
import '../domain/appointment_result_summary.dart';
import 'clinician_directory_repository.dart';

class AppointmentRepository {
  AppointmentRepository({
    SupabaseClient? client,
    ClinicianDirectoryRepository? clinicianDirectory,
  })  : _client = client ?? Supabase.instance.client,
        _clinicianDirectory = clinicianDirectory ??
            SupabaseClinicianDirectoryRepository(client: client) {
    _ensureRealtime(_client);
  }

  final SupabaseClient _client;
  final ClinicianDirectoryRepository _clinicianDirectory;
  bool _lastClinicLoadUsedCache = false;
  DateTime? _lastClinicCacheAt;

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static RealtimeChannel? _appointmentsChannel;
  static String? _realtimeUserId;
  static const _clinicCachePrefix = 'dawa_mom_booking_clinics_v1';

  bool get lastClinicLoadUsedCache => _lastClinicLoadUsedCache;
  DateTime? get lastClinicCacheAt => _lastClinicCacheAt;

  static void _ensureRealtime(SupabaseClient client) {
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty || userId == _realtimeUserId) return;
    final previous = _appointmentsChannel;
    if (previous != null) {
      unawaited(client.removeChannel(previous).then<void>((_) {}));
    }
    _realtimeUserId = userId;
    _appointmentsChannel = client
        .channel('dawa-mom-appointments-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: userId,
          ),
          callback: (_) => changes.value += 1,
        )
        .subscribe();
  }

  Future<List<ClinicOption>> getClinics() async {
    final userId = _requireUserId();
    try {
      final rows = await SupabaseDatabase.instance.runWithFreshSession(
        () => _client
            .from('clinics')
            .select('id,name,address')
            .not('dawa_clinician_clinic_id', 'is', null)
            .order('name'),
      );
      final clinics = (rows as List)
          .map(
            (row) => ClinicOption.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
      _lastClinicLoadUsedCache = false;
      _lastClinicCacheAt = DateTime.now();
      await _saveClinicCache(userId, clinics, _lastClinicCacheAt!);
      return clinics;
    } catch (_) {
      final cached = await _loadClinicCache(userId);
      if (cached != null) {
        _lastClinicLoadUsedCache = true;
        _lastClinicCacheAt = cached.$1;
        return cached.$2;
      }
      rethrow;
    }
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

  Future<AppointmentResultSummary?> getAppointmentResultSummary(
    String appointmentId,
  ) async {
    _requireUserId();
    final row = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('appointment_result_summaries')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle(),
    );
    if (row == null) return null;
    return AppointmentResultSummary.fromJson(
      Map<String, dynamic>.from(row),
    );
  }

  Future<Appointment> bookAppointment({
    required String clinicId,
    required String clinicianId,
    required DateTime date,
    required AppointmentSlot slot,
    String appointmentType = 'maternal_health',
    String? reason,
    String? notes,
    String? idempotencyKey,
  }) async {
    _requireUserId();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final selectedStart =
        Appointment.dateAtTime(normalizedDate, slot.startTime);
    final requestId = idempotencyKey ?? const Uuid().v4();
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
        'The health worker is not available at this clinic.',
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

    try {
      final result = await SupabaseDatabase.instance.runWithFreshSession(
        () => _client.rpc(
          'book_dawa_mom_appointment',
          params: {
            'p_clinic_id': clinicId,
            'p_clinician_id': clinicianId,
            'p_appointment_date': _dateId(normalizedDate),
            'p_start_time': '${slot.startTime}:00',
            'p_end_time': '${slot.endTime}:00',
            'p_appointment_type': appointmentType,
            'p_reason': _nullIfBlank(reason),
            'p_notes': _nullIfBlank(notes),
            'p_idempotency_key': requestId,
          },
        ),
      );
      final row = switch (result) {
        final Map value => Map<String, dynamic>.from(value),
        final List value when value.isNotEmpty =>
          Map<String, dynamic>.from(value.first as Map),
        _ => throw const AppointmentException(
            'The booking service returned an invalid response. Please refresh before trying again.',
            retryable: true,
          ),
      };
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
          'The clinic, health worker or appointment time is no longer available.',
          retryable: true,
        );
      }
      if (error.code == 'PGRST202' || error.code == '42883') {
        throw const AppointmentException(
          'Secure booking is being updated. Please try again shortly.',
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
        clinicianName: clinician?.displayName ?? 'Health worker',
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
    _ensureRealtime(_client);
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

  Future<void> _saveClinicCache(
    String userId,
    List<ClinicOption> clinics,
    DateTime cachedAt,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_clinicCachePrefix-$userId',
        jsonEncode({
          'cached_at': cachedAt.toUtc().toIso8601String(),
          'clinics': clinics
              .map(
                (clinic) => {
                  'id': clinic.id,
                  'name': clinic.name,
                  'address': clinic.address,
                },
              )
              .toList(growable: false),
        }),
      );
    } catch (_) {
      // Clinic caching is a non-blocking resilience feature. A successful
      // authenticated directory response remains usable if local storage is
      // unavailable.
    }
  }

  Future<(DateTime, List<ClinicOption>)?> _loadClinicCache(
    String userId,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString('$_clinicCachePrefix-$userId');
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      final cachedAt = DateTime.tryParse(json['cached_at']?.toString() ?? '');
      final rows = json['clinics'];
      if (cachedAt == null || rows is! List) return null;
      final clinics = rows
          .whereType<Map>()
          .map(
            (row) => ClinicOption.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);
      return clinics.isEmpty ? null : (cachedAt, clinics);
    } catch (_) {
      return null;
    }
  }
}
