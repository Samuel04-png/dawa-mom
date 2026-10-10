import 'package:flutter/foundation.dart';

enum DawaCareItemStatus {
  recommended,
  due,
  scheduled,
  completed,
  overdue,
  cancelled,
  dismissed;

  static DawaCareItemStatus fromWire(String? value) =>
      DawaCareItemStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => DawaCareItemStatus.recommended,
      );
}

enum DawaCareItemPriority {
  routine,
  standard,
  high,
  urgent;

  static DawaCareItemPriority fromWire(String? value) =>
      DawaCareItemPriority.values.firstWhere(
        (priority) => priority.name == value,
        orElse: () => DawaCareItemPriority.routine,
      );
}

@immutable
class DawaCareItem {
  const DawaCareItem({
    required this.id,
    required this.motherId,
    required this.patientId,
    required this.type,
    required this.title,
    required this.status,
    required this.priority,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueAt,
    this.scheduledAt,
    this.completedAt,
    this.sourceRecordId,
    this.clinicId,
    this.appointmentId,
  });

  final String id;
  final String motherId;
  final String patientId;
  final String type;
  final String title;
  final String? description;
  final DawaCareItemStatus status;
  final DawaCareItemPriority priority;
  final DateTime? dueAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String source;
  final String? sourceRecordId;
  final String? clinicId;
  final String? appointmentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => switch (status) {
        DawaCareItemStatus.completed ||
        DawaCareItemStatus.cancelled ||
        DawaCareItemStatus.dismissed =>
          true,
        _ => false,
      };

  bool get isActionable => !isTerminal;

  bool get shouldLeadHome =>
      isActionable &&
      (priority == DawaCareItemPriority.urgent ||
          priority == DawaCareItemPriority.high ||
          status == DawaCareItemStatus.due ||
          status == DawaCareItemStatus.overdue);

  DateTime? get relevantAt => dueAt ?? scheduledAt;

  factory DawaCareItem.fromJson(Map<String, dynamic> json) => DawaCareItem(
        id: json['id'].toString(),
        motherId: json['mother_id'].toString(),
        patientId: json['patient_id'].toString(),
        type: json['care_type']?.toString() ?? 'other',
        title: json['title']?.toString() ?? 'Care item',
        description: _optionalText(json['description']),
        status: DawaCareItemStatus.fromWire(json['status']?.toString()),
        priority: DawaCareItemPriority.fromWire(json['priority']?.toString()),
        dueAt: _optionalDate(json['due_at']),
        scheduledAt: _optionalDate(json['scheduled_at']),
        completedAt: _optionalDate(json['completed_at']),
        source: json['source']?.toString() ?? 'system',
        sourceRecordId: _optionalText(json['source_record_id']),
        clinicId: _optionalText(json['clinic_id']),
        appointmentId: _optionalText(json['appointment_id']),
        createdAt: _optionalDate(json['created_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: _optionalDate(json['updated_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _optionalDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();
