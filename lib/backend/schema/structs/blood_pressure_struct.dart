// ignore_for_file: unnecessary_getters_setters

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class BloodPressureStruct extends FFSupabaseStruct {
  BloodPressureStruct({
    int? systolic,
    int? diastolic,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _systolic = systolic,
        _diastolic = diastolic,
        super(firestoreUtilData);

  // "systolic" field.
  int? _systolic;
  int get systolic => _systolic ?? 0;
  set systolic(int? val) => _systolic = val;

  void incrementSystolic(int amount) => systolic = systolic + amount;

  bool hasSystolic() => _systolic != null;

  // "diastolic" field.
  int? _diastolic;
  int get diastolic => _diastolic ?? 0;
  set diastolic(int? val) => _diastolic = val;

  void incrementDiastolic(int amount) => diastolic = diastolic + amount;

  bool hasDiastolic() => _diastolic != null;

  static BloodPressureStruct fromMap(Map<String, dynamic> data) =>
      BloodPressureStruct(
        systolic: castToType<int>(data['systolic']),
        diastolic: castToType<int>(data['diastolic']),
      );

  static BloodPressureStruct? maybeFromMap(dynamic data) => data is Map
      ? BloodPressureStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'systolic': _systolic,
        'diastolic': _diastolic,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'systolic': serializeParam(
          _systolic,
          ParamType.int,
        ),
        'diastolic': serializeParam(
          _diastolic,
          ParamType.int,
        ),
      }.withoutNulls;

  static BloodPressureStruct fromSerializableMap(Map<String, dynamic> data) =>
      BloodPressureStruct(
        systolic: deserializeParam(
          data['systolic'],
          ParamType.int,
          false,
        ),
        diastolic: deserializeParam(
          data['diastolic'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'BloodPressureStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is BloodPressureStruct &&
        systolic == other.systolic &&
        diastolic == other.diastolic;
  }

  @override
  int get hashCode => const ListEquality().hash([systolic, diastolic]);
}

BloodPressureStruct createBloodPressureStruct({
  int? systolic,
  int? diastolic,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    BloodPressureStruct(
      systolic: systolic,
      diastolic: diastolic,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

BloodPressureStruct? updateBloodPressureStruct(
  BloodPressureStruct? bloodPressure, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    bloodPressure
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addBloodPressureStructData(
  Map<String, dynamic> firestoreData,
  BloodPressureStruct? bloodPressure,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (bloodPressure == null) {
    return;
  }
  if (bloodPressure.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && bloodPressure.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final bloodPressureData =
      getBloodPressureFirestoreData(bloodPressure, forFieldValue);
  final nestedData =
      bloodPressureData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = bloodPressure.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getBloodPressureFirestoreData(
  BloodPressureStruct? bloodPressure, [
  bool forFieldValue = false,
]) {
  if (bloodPressure == null) {
    return {};
  }
  final firestoreData = mapToFirestore(bloodPressure.toMap());

  // Add any Firestore field values
  bloodPressure.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getBloodPressureListFirestoreData(
  List<BloodPressureStruct>? bloodPressures,
) =>
    bloodPressures
        ?.map((e) => getBloodPressureFirestoreData(e, true))
        .toList() ??
    [];
