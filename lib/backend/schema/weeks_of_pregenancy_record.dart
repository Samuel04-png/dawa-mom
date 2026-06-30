import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class WeeksOfPregenancyRecord extends FirestoreRecord {
  WeeksOfPregenancyRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "week" field.
  String? _week;
  String get week => _week ?? '';
  bool hasWeek() => _week != null;

  // "week_plan" field.
  String? _weekPlan;
  String get weekPlan => _weekPlan ?? '';
  bool hasWeekPlan() => _weekPlan != null;

  // "tips" field.
  String? _tips;
  String get tips => _tips ?? '';
  bool hasTips() => _tips != null;

  // "body_changes" field.
  String? _bodyChanges;
  String get bodyChanges => _bodyChanges ?? '';
  bool hasBodyChanges() => _bodyChanges != null;

  // "general_info" field.
  String? _generalInfo;
  String get generalInfo => _generalInfo ?? '';
  bool hasGeneralInfo() => _generalInfo != null;

  // "baby_development" field.
  String? _babyDevelopment;
  String get babyDevelopment => _babyDevelopment ?? '';
  bool hasBabyDevelopment() => _babyDevelopment != null;

  void _initializeFields() {
    _week = snapshotData['week'] as String?;
    _weekPlan = snapshotData['week_plan'] as String?;
    _tips = snapshotData['tips'] as String?;
    _bodyChanges = snapshotData['body_changes'] as String?;
    _generalInfo = snapshotData['general_info'] as String?;
    _babyDevelopment = snapshotData['baby_development'] as String?;
  }

  static CollectionReference get collection =>
      SupabaseDatabase.instance.collection('weeks_of_pregenancy');

  static Stream<WeeksOfPregenancyRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => WeeksOfPregenancyRecord.fromSnapshot(s));

  static Future<WeeksOfPregenancyRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => WeeksOfPregenancyRecord.fromSnapshot(s));

  static WeeksOfPregenancyRecord fromSnapshot(DocumentSnapshot snapshot) =>
      WeeksOfPregenancyRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static WeeksOfPregenancyRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      WeeksOfPregenancyRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'WeeksOfPregenancyRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is WeeksOfPregenancyRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createWeeksOfPregenancyRecordData({
  String? week,
  String? weekPlan,
  String? tips,
  String? bodyChanges,
  String? generalInfo,
  String? babyDevelopment,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'week': week,
      'week_plan': weekPlan,
      'tips': tips,
      'body_changes': bodyChanges,
      'general_info': generalInfo,
      'baby_development': babyDevelopment,
    }.withoutNulls,
  );

  return firestoreData;
}

class WeeksOfPregenancyRecordDocumentEquality
    implements Equality<WeeksOfPregenancyRecord> {
  const WeeksOfPregenancyRecordDocumentEquality();

  @override
  bool equals(WeeksOfPregenancyRecord? e1, WeeksOfPregenancyRecord? e2) {
    return e1?.week == e2?.week &&
        e1?.weekPlan == e2?.weekPlan &&
        e1?.tips == e2?.tips &&
        e1?.bodyChanges == e2?.bodyChanges &&
        e1?.generalInfo == e2?.generalInfo &&
        e1?.babyDevelopment == e2?.babyDevelopment;
  }

  @override
  int hash(WeeksOfPregenancyRecord? e) => const ListEquality().hash([
        e?.week,
        e?.weekPlan,
        e?.tips,
        e?.bodyChanges,
        e?.generalInfo,
        e?.babyDevelopment
      ]);

  @override
  bool isValidKey(Object? o) => o is WeeksOfPregenancyRecord;
}
