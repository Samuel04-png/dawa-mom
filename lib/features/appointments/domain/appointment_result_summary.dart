import 'package:flutter/foundation.dart';

@immutable
class AppointmentResultSummary {
  const AppointmentResultSummary({
    required this.id,
    required this.appointmentId,
    required this.version,
    required this.clinicianDisplayName,
    required this.clinicName,
    required this.appointmentDate,
    required this.completedAt,
    required this.overallStatus,
    required this.maternalSummary,
    required this.pregnancySummary,
    required this.generatedAt,
    this.keyFindings,
    this.recommendations,
    this.followUpInstructions,
    this.referralSummary,
    this.nextAppointmentAt,
    this.urgentCareInstruction,
  });

  final String id;
  final String appointmentId;
  final int version;
  final String clinicianDisplayName;
  final String clinicName;
  final DateTime appointmentDate;
  final DateTime completedAt;
  final String overallStatus;
  final Map<String, ResultMeasurement> maternalSummary;
  final Map<String, ResultMeasurement> pregnancySummary;
  final String? keyFindings;
  final String? recommendations;
  final String? followUpInstructions;
  final String? referralSummary;
  final DateTime? nextAppointmentAt;
  final String? urgentCareInstruction;
  final DateTime generatedAt;

  factory AppointmentResultSummary.fromJson(Map<String, dynamic> json) {
    return AppointmentResultSummary(
      id: json['id']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? '',
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      clinicianDisplayName:
          json['clinician_display_name']?.toString() ?? 'Your clinician',
      clinicName: json['clinic_name']?.toString() ?? 'Your clinic',
      appointmentDate: DateTime.tryParse(
            json['appointment_date']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      overallStatus: json['overall_status']?.toString() ?? 'follow_up',
      maternalSummary: _measurements(json['maternal_summary']),
      pregnancySummary: _measurements(json['pregnancy_summary']),
      keyFindings: _optionalText(json['key_findings']),
      recommendations: _optionalText(json['recommendations']),
      followUpInstructions: _optionalText(json['follow_up_instructions']),
      referralSummary: _optionalText(json['referral_summary']),
      nextAppointmentAt:
          DateTime.tryParse(json['next_appointment_at']?.toString() ?? ''),
      urgentCareInstruction: _optionalText(json['urgent_care_instruction']),
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static Map<String, ResultMeasurement> _measurements(dynamic value) {
    if (value is! Map) return const {};
    final result = <String, ResultMeasurement>{};
    for (final entry in value.entries) {
      if (entry.value is Map) {
        result[entry.key.toString()] = ResultMeasurement.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return result;
  }

  static String? _optionalText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

@immutable
class ResultMeasurement {
  const ResultMeasurement({
    required this.state,
    this.value,
    this.unit,
    this.interpretation,
    this.source,
  });

  final String state;
  final String? value;
  final String? unit;
  final String? interpretation;
  final String? source;

  bool get hasContent =>
      state.isNotEmpty || value != null || interpretation != null;

  factory ResultMeasurement.fromJson(Map<String, dynamic> json) {
    return ResultMeasurement(
      state: json['state']?.toString() ?? '',
      value: AppointmentResultSummary._optionalText(json['value']),
      unit: AppointmentResultSummary._optionalText(json['unit']),
      interpretation:
          AppointmentResultSummary._optionalText(json['interpretation']),
      source: AppointmentResultSummary._optionalText(json['source']),
    );
  }
}
