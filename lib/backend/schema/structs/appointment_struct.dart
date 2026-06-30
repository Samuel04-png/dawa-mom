// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AppointmentStruct extends FFSupabaseStruct {
  AppointmentStruct({
    DateTime? date,
    List<String>? time,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _date = date,
        _time = time,
        super(firestoreUtilData);

  // "Date" field.
  DateTime? _date;
  DateTime? get date => _date;
  set date(DateTime? val) => _date = val;

  bool hasDate() => _date != null;

  // "Time" field.
  List<String>? _time;
  List<String> get time => _time ?? const [];
  set time(List<String>? val) => _time = val;

  void updateTime(Function(List<String>) updateFn) {
    updateFn(_time ??= []);
  }

  bool hasTime() => _time != null;

  static AppointmentStruct fromMap(Map<String, dynamic> data) =>
      AppointmentStruct(
        date: data['Date'] as DateTime?,
        time: getDataList(data['Time']),
      );

  static AppointmentStruct? maybeFromMap(dynamic data) => data is Map
      ? AppointmentStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'Date': _date,
        'Time': _time,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'Date': serializeParam(
          _date,
          ParamType.DateTime,
        ),
        'Time': serializeParam(
          _time,
          ParamType.String,
          isList: true,
        ),
      }.withoutNulls;

  static AppointmentStruct fromSerializableMap(Map<String, dynamic> data) =>
      AppointmentStruct(
        date: deserializeParam(
          data['Date'],
          ParamType.DateTime,
          false,
        ),
        time: deserializeParam<String>(
          data['Time'],
          ParamType.String,
          true,
        ),
      );

  @override
  String toString() => 'AppointmentStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is AppointmentStruct &&
        date == other.date &&
        listEquality.equals(time, other.time);
  }

  @override
  int get hashCode => const ListEquality().hash([date, time]);
}

AppointmentStruct createAppointmentStruct({
  DateTime? date,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AppointmentStruct(
      date: date,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AppointmentStruct? updateAppointmentStruct(
  AppointmentStruct? appointment, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    appointment
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAppointmentStructData(
  Map<String, dynamic> firestoreData,
  AppointmentStruct? appointment,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (appointment == null) {
    return;
  }
  if (appointment.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && appointment.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final appointmentData =
      getAppointmentFirestoreData(appointment, forFieldValue);
  final nestedData =
      appointmentData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = appointment.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAppointmentFirestoreData(
  AppointmentStruct? appointment, [
  bool forFieldValue = false,
]) {
  if (appointment == null) {
    return {};
  }
  final firestoreData = mapToFirestore(appointment.toMap());

  // Add any Firestore field values
  appointment.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAppointmentListFirestoreData(
  List<AppointmentStruct>? appointments,
) =>
    appointments?.map((e) => getAppointmentFirestoreData(e, true)).toList() ??
    [];
