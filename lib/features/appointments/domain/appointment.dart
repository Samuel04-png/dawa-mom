import 'package:flutter/foundation.dart';

@immutable
class Appointment {
  const Appointment({
    required this.id,
    required this.motherId,
    required this.patientId,
    required this.clinicianId,
    required this.clinicId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.appointmentType,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.integrationStatus,
    this.serviceId = '',
    this.externalServiceIdSnapshot,
    this.serviceNameSnapshot,
    this.isPaidSnapshot = false,
    this.priceSnapshot = 0,
    this.currencySnapshot = 'ZMW',
    this.paymentMethod = 'online',
    this.paymentState = 'not_required',
    this.reason,
    this.notes,
    this.externalAppointmentId,
    this.integrationErrorCode,
    this.patientSafeStatusMessage,
    this.clinicianName,
    this.clinicName,
    this.clinicianTitle,
    this.clinicianSpeciality,
    this.clinicAddress,
  });

  final String id;
  final String motherId;
  final String patientId;
  final String clinicianId;
  final String clinicId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String appointmentType;
  final String? reason;
  final String? notes;
  final String status;
  final String source;
  final DateTime createdAt;
  final String integrationStatus;
  final String serviceId;
  final String? externalServiceIdSnapshot;
  final String? serviceNameSnapshot;
  final bool isPaidSnapshot;
  final double priceSnapshot;
  final String currencySnapshot;
  final String paymentMethod;

  /// Server-owned lifecycle state for an appointment's required payment.
  /// It is deliberately separate from the clinic's appointment [status].
  final String paymentState;
  final String? externalAppointmentId;
  final String? integrationErrorCode;
  final String? patientSafeStatusMessage;
  final String? clinicianName;
  final String? clinicName;
  final String? clinicianTitle;
  final String? clinicianSpeciality;
  final String? clinicAddress;

  bool get canPatientCancel =>
      status == 'pending' || status == 'confirmed' || status == 'rescheduled';

  bool get requiresOnlinePayment => isPaidSnapshot && paymentMethod == 'online';

  bool get paymentConfirmed => paymentState == 'successful';

  bool get paymentAwaitingResolution => const {
        'not_started',
        'pending',
        'processing',
      }.contains(paymentState);

  bool get paymentUnsuccessful => const {
        'failed',
        'cancelled',
        'expired',
        'reconciliation_required',
      }.contains(paymentState);

  bool get isUpcoming {
    final start = dateAtTime(date, startTime);
    return start.isAfter(DateTime.now()) &&
        !const {'cancelled', 'declined', 'completed', 'missed'}
            .contains(status) &&
        (!requiresOnlinePayment || paymentConfirmed);
  }

  Appointment copyWith({
    String? clinicianName,
    String? clinicName,
    String? clinicianTitle,
    String? clinicianSpeciality,
    String? clinicAddress,
  }) =>
      Appointment(
        id: id,
        motherId: motherId,
        patientId: patientId,
        clinicianId: clinicianId,
        clinicId: clinicId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        appointmentType: appointmentType,
        reason: reason,
        notes: notes,
        status: status,
        source: source,
        createdAt: createdAt,
        integrationStatus: integrationStatus,
        serviceId: serviceId,
        externalServiceIdSnapshot: externalServiceIdSnapshot,
        serviceNameSnapshot: serviceNameSnapshot,
        isPaidSnapshot: isPaidSnapshot,
        priceSnapshot: priceSnapshot,
        currencySnapshot: currencySnapshot,
        paymentMethod: paymentMethod,
        paymentState: paymentState,
        externalAppointmentId: externalAppointmentId,
        integrationErrorCode: integrationErrorCode,
        patientSafeStatusMessage: patientSafeStatusMessage,
        clinicianName: clinicianName ?? this.clinicianName,
        clinicName: clinicName ?? this.clinicName,
        clinicianTitle: clinicianTitle ?? this.clinicianTitle,
        clinicianSpeciality: clinicianSpeciality ?? this.clinicianSpeciality,
        clinicAddress: clinicAddress ?? this.clinicAddress,
      );

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'].toString(),
      motherId: json['mother_id'].toString(),
      patientId: json['patient_id'].toString(),
      clinicianId: json['clinician_id'].toString(),
      clinicId: json['clinic_id'].toString(),
      date: DateTime.parse(json['appointment_date'].toString()),
      startTime: normalizeDatabaseTime(json['start_time']),
      endTime: normalizeDatabaseTime(json['end_time']),
      appointmentType:
          json['appointment_type']?.toString() ?? 'maternal_health',
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      source: json['source']?.toString() ?? 'dawa_mom',
      createdAt: DateTime.parse(json['created_at'].toString()),
      integrationStatus: json['integration_status']?.toString() ?? 'pending',
      serviceId: json['service_id']?.toString() ?? '',
      externalServiceIdSnapshot:
          json['external_service_id_snapshot']?.toString(),
      serviceNameSnapshot: json['service_name_snapshot']?.toString(),
      isPaidSnapshot: json['is_paid_snapshot'] as bool? ?? false,
      priceSnapshot:
          double.tryParse(json['price_snapshot']?.toString() ?? '') ?? 0,
      currencySnapshot: json['currency_snapshot']?.toString() ?? 'ZMW',
      paymentMethod: json['payment_method']?.toString() ?? 'online',
      paymentState: json['payment_state']?.toString() ??
          ((json['is_paid_snapshot'] as bool? ?? false) &&
                  json['payment_method']?.toString() != 'cash'
              ? 'not_started'
              : 'not_required'),
      externalAppointmentId:
          json['dawa_clinician_appointment_id']?.toString() ??
              json['external_appointment_id']?.toString(),
      integrationErrorCode: json['integration_error_code']?.toString(),
      patientSafeStatusMessage: json['patient_safe_status_message']?.toString(),
      clinicianName: json['clinician_name']?.toString(),
      clinicName: json['clinic_name']?.toString(),
      clinicianTitle: json['clinician_title']?.toString(),
      clinicianSpeciality: json['clinician_speciality']?.toString(),
      clinicAddress: json['clinic_address']?.toString(),
    );
  }

  /// Minimal, patient-safe schedule data for a temporary offline view.
  ///
  /// Do not add notes, reasons, payment references, contact details, or other
  /// clinical information here. The snapshot is display-only: all actions
  /// that can change a booking still require a fresh server response.
  Map<String, dynamic> toOfflineSnapshot() => {
        'id': id,
        'appointment_date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'start_time': startTime,
        'end_time': endTime,
        'appointment_type': appointmentType,
        'status': status,
        'created_at': createdAt.toUtc().toIso8601String(),
        'service_name_snapshot': serviceNameSnapshot,
        'is_paid_snapshot': isPaidSnapshot,
        'payment_method': paymentMethod,
        'payment_state': paymentState,
        'patient_safe_status_message': patientSafeStatusMessage,
        'clinician_name': clinicianName,
        'clinic_name': clinicName,
      };

  factory Appointment.fromOfflineSnapshot(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['appointment_date']?.toString() ?? '');
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (date == null || createdAt == null) {
      throw const FormatException('Invalid offline appointment snapshot.');
    }
    return Appointment(
      id: json['id']?.toString() ?? '',
      // Identity and routing values are intentionally not persisted in the
      // offline snapshot. A fresh, authenticated read is required for any
      // action that needs them.
      motherId: '',
      patientId: '',
      clinicianId: '',
      clinicId: '',
      date: date,
      startTime: normalizeDatabaseTime(json['start_time']),
      endTime: normalizeDatabaseTime(json['end_time']),
      appointmentType:
          json['appointment_type']?.toString() ?? 'maternal_health',
      status: json['status']?.toString() ?? 'pending',
      source: 'offline_snapshot',
      createdAt: createdAt,
      integrationStatus: 'offline_snapshot',
      serviceNameSnapshot: json['service_name_snapshot']?.toString(),
      isPaidSnapshot: json['is_paid_snapshot'] as bool? ?? false,
      paymentMethod: json['payment_method']?.toString() ?? 'online',
      paymentState: json['payment_state']?.toString() ?? 'not_required',
      patientSafeStatusMessage: json['patient_safe_status_message']?.toString(),
      clinicianName: json['clinician_name']?.toString(),
      clinicName: json['clinic_name']?.toString(),
    );
  }

  static String normalizeDatabaseTime(dynamic value) {
    final parts = value.toString().split(':');
    if (parts.length < 2) {
      return value.toString();
    }
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  static DateTime dateAtTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = parts.isEmpty ? 0 : int.tryParse(parts[0]) ?? 0;
    final minute = parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

@immutable
class AppointmentBookingResult {
  const AppointmentBookingResult({
    required this.appointment,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentAmount,
    this.paymentCurrency,
    this.paymentReference,
  });

  final Appointment appointment;
  final String paymentStatus;
  final String paymentMethod;
  final double? paymentAmount;
  final String? paymentCurrency;
  final String? paymentReference;

  bool get paymentSucceeded => paymentStatus == 'successful';
}

@immutable
class ClinicOption {
  const ClinicOption({
    required this.id,
    required this.name,
    this.address,
    this.distanceKm,
    this.isOpen,
    this.services = const [],
    this.nextAvailableAt,
    this.openingHours,
    this.isPreferred,
    this.phone,
    this.latitude,
    this.longitude,
    this.accessibility = const [],
    this.languages = const [],
  });

  final String id;
  final String name;
  final String? address;
  final double? distanceKm;
  final bool? isOpen;
  final List<String> services;
  final DateTime? nextAvailableAt;
  final String? openingHours;
  final bool? isPreferred;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final List<String> accessibility;
  final List<String> languages;

  factory ClinicOption.fromJson(Map<String, dynamic> json) => ClinicOption(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? 'Clinic',
        address: json['address']?.toString(),
        distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
        isOpen: json['is_open'] as bool?,
        services: _stringList(json['services']),
        nextAvailableAt:
            DateTime.tryParse(json['next_available_at']?.toString() ?? ''),
        openingHours: json['opening_hours']?.toString(),
        isPreferred: json['is_preferred'] as bool?,
        phone: json['phone']?.toString(),
        latitude: double.tryParse(json['latitude']?.toString() ?? ''),
        longitude: double.tryParse(json['longitude']?.toString() ?? ''),
        accessibility: _stringList(json['accessibility']),
        languages: _stringList(json['languages']),
      );

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

@immutable
class ClinicianProfile {
  const ClinicianProfile({
    required this.id,
    required this.displayName,
    required this.clinicId,
    required this.clinicName,
    required this.isActive,
    required this.isBookable,
    this.professionalTitle,
    this.speciality,
    this.profileImageUrl,
    this.scheduleStart = '08:00',
    this.scheduleEnd = '16:00',
    this.slotMinutes = 30,
  });

  final String id;
  final String displayName;
  final String? professionalTitle;
  final String? speciality;
  final String clinicId;
  final String clinicName;
  final String? profileImageUrl;
  final bool isActive;
  final bool isBookable;
  final String scheduleStart;
  final String scheduleEnd;
  final int slotMinutes;

  String get subtitle {
    final values = [professionalTitle, speciality]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
    return values.join(' • ');
  }

  factory ClinicianProfile.fromJson(Map<String, dynamic> json) {
    final availability = Map<String, dynamic>.from(
      json['availability_summary'] as Map? ?? const {},
    );
    return ClinicianProfile(
      id: json['id'].toString(),
      displayName: json['display_name']?.toString() ?? 'Health worker',
      professionalTitle: json['professional_title']?.toString(),
      speciality: json['speciality']?.toString(),
      clinicId: json['clinic_id'].toString(),
      clinicName: json['clinic_name']?.toString() ?? 'Clinic',
      profileImageUrl: json['profile_image_url']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      isBookable: json['is_bookable'] as bool? ?? true,
      scheduleStart: Appointment.normalizeDatabaseTime(
          availability['start_time'] ?? '08:00'),
      scheduleEnd: Appointment.normalizeDatabaseTime(
          availability['end_time'] ?? '16:00'),
      slotMinutes: availability['slot_minutes'] as int? ?? 30,
    );
  }
}

@immutable
class AppointmentSlot {
  const AppointmentSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final String startTime;
  final String endTime;
  final bool isAvailable;

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) =>
      AppointmentSlot(
        startTime: Appointment.normalizeDatabaseTime(json['start_time']),
        endTime: Appointment.normalizeDatabaseTime(json['end_time']),
        isAvailable: json['is_available'] as bool? ?? true,
      );
}

class AppointmentException implements Exception {
  const AppointmentException(this.message, {this.retryable = false});

  final String message;
  final bool retryable;

  @override
  String toString() => message;
}
