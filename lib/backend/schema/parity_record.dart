import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ParityRecord extends FirestoreRecord {
  ParityRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "weight" field.
  String? _weight;
  String get weight => _weight ?? '';
  bool hasWeight() => _weight != null;

  // "state" field.
  String? _state;
  String get state => _state ?? '';
  bool hasState() => _state != null;

  // "mode_of_delivery" field.
  String? _modeOfDelivery;
  String get modeOfDelivery => _modeOfDelivery ?? '';
  bool hasModeOfDelivery() => _modeOfDelivery != null;

  // "first_encounter_id" field.
  DocumentReference? _firstEncounterId;
  DocumentReference? get firstEncounterId => _firstEncounterId;
  bool hasFirstEncounterId() => _firstEncounterId != null;

  // "complications" field.
  List<String>? _complications;
  List<String> get complications => _complications ?? const [];
  bool hasComplications() => _complications != null;

  // "year_of_birth" field.
  String? _yearOfBirth;
  String get yearOfBirth => _yearOfBirth ?? '';
  bool hasYearOfBirth() => _yearOfBirth != null;

  void _initializeFields() {
    _weight = snapshotData['weight'] as String?;
    _state = snapshotData['state'] as String?;
    _modeOfDelivery = snapshotData['mode_of_delivery'] as String?;
    _firstEncounterId =
        snapshotData['first_encounter_id'] as DocumentReference?;
    _complications = getDataList(snapshotData['complications']);
    _yearOfBirth = snapshotData['year_of_birth'] as String?;
  }

  static CollectionReference get collection =>
      SupabaseDatabase.instance.collection('parity');

  static Stream<ParityRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ParityRecord.fromSnapshot(s));

  static Future<ParityRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ParityRecord.fromSnapshot(s));

  static ParityRecord fromSnapshot(DocumentSnapshot snapshot) => ParityRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ParityRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ParityRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ParityRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ParityRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createParityRecordData({
  String? weight,
  String? state,
  String? modeOfDelivery,
  DocumentReference? firstEncounterId,
  String? yearOfBirth,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'weight': weight,
      'state': state,
      'mode_of_delivery': modeOfDelivery,
      'first_encounter_id': firstEncounterId,
      'year_of_birth': yearOfBirth,
    }.withoutNulls,
  );

  return firestoreData;
}

class ParityRecordDocumentEquality implements Equality<ParityRecord> {
  const ParityRecordDocumentEquality();

  @override
  bool equals(ParityRecord? e1, ParityRecord? e2) {
    const listEquality = ListEquality();
    return e1?.weight == e2?.weight &&
        e1?.state == e2?.state &&
        e1?.modeOfDelivery == e2?.modeOfDelivery &&
        e1?.firstEncounterId == e2?.firstEncounterId &&
        listEquality.equals(e1?.complications, e2?.complications) &&
        e1?.yearOfBirth == e2?.yearOfBirth;
  }

  @override
  int hash(ParityRecord? e) => const ListEquality().hash([
        e?.weight,
        e?.state,
        e?.modeOfDelivery,
        e?.firstEncounterId,
        e?.complications,
        e?.yearOfBirth
      ]);

  @override
  bool isValidKey(Object? o) => o is ParityRecord;
}
