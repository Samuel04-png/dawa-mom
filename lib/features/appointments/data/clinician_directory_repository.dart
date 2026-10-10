import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_database.dart';
import '../domain/appointment.dart';

abstract class ClinicianDirectoryRepository {
  Future<List<ClinicianProfile>> getClinicians();
  Future<List<ClinicianProfile>> getCliniciansByClinic(String clinicId);
  Future<List<AppointmentSlot>> getClinicianAvailability(
    String clinicianId,
    DateTime date,
  );
  Future<void> refreshClinicianDirectory();
}

class SupabaseClinicianDirectoryRepository
    implements ClinicianDirectoryRepository {
  SupabaseClinicianDirectoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  List<ClinicianProfile>? _cachedClinicians;
  bool _usingCachedDirectory = false;

  bool get isUsingCachedDirectory => _usingCachedDirectory;

  @override
  Future<List<ClinicianProfile>> getClinicians() async {
    if (_cachedClinicians != null) {
      return _cachedClinicians!;
    }
    final clinicians = await _loadClinicians();
    _cachedClinicians = clinicians;
    return clinicians;
  }

  @override
  Future<List<ClinicianProfile>> getCliniciansByClinic(String clinicId) async {
    final remote = await _tryRemoteDirectory(clinicId);
    if (remote != null) {
      _usingCachedDirectory = false;
      return remote;
    }

    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.rpc(
        'get_bookable_clinicians',
        params: {'target_clinic_id': clinicId},
      ),
    );
    _usingCachedDirectory = true;
    return _parseClinicians(rows);
  }

  @override
  Future<List<AppointmentSlot>> getClinicianAvailability(
    String clinicianId,
    DateTime date,
  ) async {
    final remote = await _tryRemoteAvailability(clinicianId, date);
    if (remote != null) {
      return remote;
    }
    throw const AppointmentException(
      'Live appointment times are temporarily unavailable. Please retry.',
      retryable: true,
    );
  }

  @override
  Future<void> refreshClinicianDirectory() async {
    _cachedClinicians = null;
    _usingCachedDirectory = false;
    await getClinicians();
  }

  Future<List<ClinicianProfile>> _loadClinicians() async {
    final remote = await _tryRemoteDirectory(null);
    if (remote != null) {
      _usingCachedDirectory = false;
      return remote;
    }
    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client.rpc('get_bookable_clinicians'),
    );
    _usingCachedDirectory = true;
    return _parseClinicians(rows);
  }

  Future<List<ClinicianProfile>?> _tryRemoteDirectory(
    String? clinicId,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'clinician-directory',
        body: {'action': 'list', 'clinic_id': clinicId},
      );
      if (response.status != 200 || response.data is! Map) {
        return null;
      }
      return _parseClinicians((response.data as Map)['clinicians']);
    } catch (_) {
      // The cross-project endpoint is intentionally optional until the Dawa
      // Clinician phase. The local safe RPC is the readiness fallback.
      return null;
    }
  }

  Future<List<AppointmentSlot>?> _tryRemoteAvailability(
    String clinicianId,
    DateTime date,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'clinician-directory',
        body: {
          'action': 'availability',
          'clinician_id': clinicianId,
          'date': _dateId(date),
        },
      );
      if (response.status != 200 || response.data is! Map) {
        return null;
      }
      final slots = (response.data as Map)['slots'];
      if (slots is! List) {
        return null;
      }
      return slots
          .map((slot) => AppointmentSlot.fromJson(
                Map<String, dynamic>.from(slot as Map),
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static List<ClinicianProfile> _parseClinicians(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((row) => ClinicianProfile.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .where((clinician) => clinician.isActive && clinician.isBookable)
        .toList();
  }

  static String _dateId(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
