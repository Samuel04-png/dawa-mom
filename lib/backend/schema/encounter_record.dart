import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EncounterRecord extends FirestoreRecord {
  EncounterRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "bp" field.
  String? _bp;
  String get bp => _bp ?? '';
  bool hasBp() => _bp != null;

  // "pulse" field.
  int? _pulse;
  int get pulse => _pulse ?? 0;
  bool hasPulse() => _pulse != null;

  // "next_visit" field.
  DateTime? _nextVisit;
  DateTime? get nextVisit => _nextVisit;
  bool hasNextVisit() => _nextVisit != null;

  // "comment" field.
  String? _comment;
  String get comment => _comment ?? '';
  bool hasComment() => _comment != null;

  // "us_obstetrics" field.
  String? _usObstetrics;
  String get usObstetrics => _usObstetrics ?? '';
  bool hasUsObstetrics() => _usObstetrics != null;

  // "leucocytes_esterase" field.
  String? _leucocytesEsterase;
  String get leucocytesEsterase => _leucocytesEsterase ?? '';
  bool hasLeucocytesEsterase() => _leucocytesEsterase != null;

  // "nitrates" field.
  String? _nitrates;
  String get nitrates => _nitrates ?? '';
  bool hasNitrates() => _nitrates != null;

  // "urologobulin" field.
  String? _urologobulin;
  String get urologobulin => _urologobulin ?? '';
  bool hasUrologobulin() => _urologobulin != null;

  // "protein" field.
  String? _protein;
  String get protein => _protein ?? '';
  bool hasProtein() => _protein != null;

  // "ph" field.
  String? _ph;
  String get ph => _ph ?? '';
  bool hasPh() => _ph != null;

  // "blood" field.
  String? _blood;
  String get blood => _blood ?? '';
  bool hasBlood() => _blood != null;

  // "ketones" field.
  String? _ketones;
  String get ketones => _ketones ?? '';
  bool hasKetones() => _ketones != null;

  // "bilirubin" field.
  String? _bilirubin;
  String get bilirubin => _bilirubin ?? '';
  bool hasBilirubin() => _bilirubin != null;

  // "glucose" field.
  String? _glucose;
  String get glucose => _glucose ?? '';
  bool hasGlucose() => _glucose != null;

  // "color" field.
  String? _color;
  String get color => _color ?? '';
  bool hasColor() => _color != null;

  // "clarity" field.
  String? _clarity;
  String get clarity => _clarity ?? '';
  bool hasClarity() => _clarity != null;

  // "odor" field.
  String? _odor;
  String get odor => _odor ?? '';
  bool hasOdor() => _odor != null;

  // "casts" field.
  String? _casts;
  String get casts => _casts ?? '';
  bool hasCasts() => _casts != null;

  // "refer_for_anemia" field.
  String? _referForAnemia;
  String get referForAnemia => _referForAnemia ?? '';
  bool hasReferForAnemia() => _referForAnemia != null;

  // "mother_id" field.
  DocumentReference? _motherId;
  DocumentReference? get motherId => _motherId;
  bool hasMotherId() => _motherId != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "hemocheck" field.
  int? _hemocheck;
  int get hemocheck => _hemocheck ?? 0;
  bool hasHemocheck() => _hemocheck != null;

  // "specific_gravity" field.
  String? _specificGravity;
  String get specificGravity => _specificGravity ?? '';
  bool hasSpecificGravity() => _specificGravity != null;

  // "heart_beat" field.
  int? _heartBeat;
  int get heartBeat => _heartBeat ?? 0;
  bool hasHeartBeat() => _heartBeat != null;

  // "heart_beat_quality" field.
  String? _heartBeatQuality;
  String get heartBeatQuality => _heartBeatQuality ?? '';
  bool hasHeartBeatQuality() => _heartBeatQuality != null;

  // "womb_position" field.
  String? _wombPosition;
  String get wombPosition => _wombPosition ?? '';
  bool hasWombPosition() => _wombPosition != null;

  // "estimated_baby_size" field.
  int? _estimatedBabySize;
  int get estimatedBabySize => _estimatedBabySize ?? 0;
  bool hasEstimatedBabySize() => _estimatedBabySize != null;

  // "foetal_hemocheck" field.
  int? _foetalHemocheck;
  int get foetalHemocheck => _foetalHemocheck ?? 0;
  bool hasFoetalHemocheck() => _foetalHemocheck != null;

  // "clinic_id" field.
  DocumentReference? _clinicId;
  DocumentReference? get clinicId => _clinicId;
  bool hasClinicId() => _clinicId != null;

  // "doctor_id" field.
  DocumentReference? _doctorId;
  DocumentReference? get doctorId => _doctorId;
  bool hasDoctorId() => _doctorId != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "is_instant" field.
  bool? _isInstant;
  bool get isInstant => _isInstant ?? false;
  bool hasIsInstant() => _isInstant != null;

  // "time" field.
  String? _time;
  String get time => _time ?? '';
  bool hasTime() => _time != null;

  void _initializeFields() {
    _bp = snapshotData['bp'] as String?;
    _pulse = castToType<int>(snapshotData['pulse']);
    _nextVisit = snapshotData['next_visit'] as DateTime?;
    _comment = snapshotData['comment'] as String?;
    _usObstetrics = snapshotData['us_obstetrics'] as String?;
    _leucocytesEsterase = snapshotData['leucocytes_esterase'] as String?;
    _nitrates = snapshotData['nitrates'] as String?;
    _urologobulin = snapshotData['urologobulin'] as String?;
    _protein = snapshotData['protein'] as String?;
    _ph = snapshotData['ph'] as String?;
    _blood = snapshotData['blood'] as String?;
    _ketones = snapshotData['ketones'] as String?;
    _bilirubin = snapshotData['bilirubin'] as String?;
    _glucose = snapshotData['glucose'] as String?;
    _color = snapshotData['color'] as String?;
    _clarity = snapshotData['clarity'] as String?;
    _odor = snapshotData['odor'] as String?;
    _casts = snapshotData['casts'] as String?;
    _referForAnemia = snapshotData['refer_for_anemia'] as String?;
    _motherId = snapshotData['mother_id'] as DocumentReference?;
    _date = snapshotData['date'] as DateTime?;
    _hemocheck = castToType<int>(snapshotData['hemocheck']);
    _specificGravity = snapshotData['specific_gravity'] as String?;
    _heartBeat = castToType<int>(snapshotData['heart_beat']);
    _heartBeatQuality = snapshotData['heart_beat_quality'] as String?;
    _wombPosition = snapshotData['womb_position'] as String?;
    _estimatedBabySize = castToType<int>(snapshotData['estimated_baby_size']);
    _foetalHemocheck = castToType<int>(snapshotData['foetal_hemocheck']);
    _clinicId = snapshotData['clinic_id'] as DocumentReference?;
    _doctorId = snapshotData['doctor_id'] as DocumentReference?;
    _status = snapshotData['status'] as String?;
    _isInstant = snapshotData['is_instant'] as bool?;
    _time = snapshotData['time'] as String?;
  }

  static CollectionReference get collection =>
      SupabaseDatabase.instance.collection('encounter');

  static Stream<EncounterRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EncounterRecord.fromSnapshot(s));

  static Future<EncounterRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EncounterRecord.fromSnapshot(s));

  static EncounterRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EncounterRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EncounterRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EncounterRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EncounterRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EncounterRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEncounterRecordData({
  String? bp,
  int? pulse,
  DateTime? nextVisit,
  String? comment,
  String? usObstetrics,
  String? leucocytesEsterase,
  String? nitrates,
  String? urologobulin,
  String? protein,
  String? ph,
  String? blood,
  String? ketones,
  String? bilirubin,
  String? glucose,
  String? color,
  String? clarity,
  String? odor,
  String? casts,
  String? referForAnemia,
  DocumentReference? motherId,
  DateTime? date,
  int? hemocheck,
  String? specificGravity,
  int? heartBeat,
  String? heartBeatQuality,
  String? wombPosition,
  int? estimatedBabySize,
  int? foetalHemocheck,
  DocumentReference? clinicId,
  DocumentReference? doctorId,
  String? status,
  bool? isInstant,
  String? time,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'bp': bp,
      'pulse': pulse,
      'next_visit': nextVisit,
      'comment': comment,
      'us_obstetrics': usObstetrics,
      'leucocytes_esterase': leucocytesEsterase,
      'nitrates': nitrates,
      'urologobulin': urologobulin,
      'protein': protein,
      'ph': ph,
      'blood': blood,
      'ketones': ketones,
      'bilirubin': bilirubin,
      'glucose': glucose,
      'color': color,
      'clarity': clarity,
      'odor': odor,
      'casts': casts,
      'refer_for_anemia': referForAnemia,
      'mother_id': motherId,
      'date': date,
      'hemocheck': hemocheck,
      'specific_gravity': specificGravity,
      'heart_beat': heartBeat,
      'heart_beat_quality': heartBeatQuality,
      'womb_position': wombPosition,
      'estimated_baby_size': estimatedBabySize,
      'foetal_hemocheck': foetalHemocheck,
      'clinic_id': clinicId,
      'doctor_id': doctorId,
      'status': status,
      'is_instant': isInstant,
      'time': time,
    }.withoutNulls,
  );

  return firestoreData;
}

class EncounterRecordDocumentEquality implements Equality<EncounterRecord> {
  const EncounterRecordDocumentEquality();

  @override
  bool equals(EncounterRecord? e1, EncounterRecord? e2) {
    return e1?.bp == e2?.bp &&
        e1?.pulse == e2?.pulse &&
        e1?.nextVisit == e2?.nextVisit &&
        e1?.comment == e2?.comment &&
        e1?.usObstetrics == e2?.usObstetrics &&
        e1?.leucocytesEsterase == e2?.leucocytesEsterase &&
        e1?.nitrates == e2?.nitrates &&
        e1?.urologobulin == e2?.urologobulin &&
        e1?.protein == e2?.protein &&
        e1?.ph == e2?.ph &&
        e1?.blood == e2?.blood &&
        e1?.ketones == e2?.ketones &&
        e1?.bilirubin == e2?.bilirubin &&
        e1?.glucose == e2?.glucose &&
        e1?.color == e2?.color &&
        e1?.clarity == e2?.clarity &&
        e1?.odor == e2?.odor &&
        e1?.casts == e2?.casts &&
        e1?.referForAnemia == e2?.referForAnemia &&
        e1?.motherId == e2?.motherId &&
        e1?.date == e2?.date &&
        e1?.hemocheck == e2?.hemocheck &&
        e1?.specificGravity == e2?.specificGravity &&
        e1?.heartBeat == e2?.heartBeat &&
        e1?.heartBeatQuality == e2?.heartBeatQuality &&
        e1?.wombPosition == e2?.wombPosition &&
        e1?.estimatedBabySize == e2?.estimatedBabySize &&
        e1?.foetalHemocheck == e2?.foetalHemocheck &&
        e1?.clinicId == e2?.clinicId &&
        e1?.doctorId == e2?.doctorId &&
        e1?.status == e2?.status &&
        e1?.isInstant == e2?.isInstant &&
        e1?.time == e2?.time;
  }

  @override
  int hash(EncounterRecord? e) => const ListEquality().hash([
        e?.bp,
        e?.pulse,
        e?.nextVisit,
        e?.comment,
        e?.usObstetrics,
        e?.leucocytesEsterase,
        e?.nitrates,
        e?.urologobulin,
        e?.protein,
        e?.ph,
        e?.blood,
        e?.ketones,
        e?.bilirubin,
        e?.glucose,
        e?.color,
        e?.clarity,
        e?.odor,
        e?.casts,
        e?.referForAnemia,
        e?.motherId,
        e?.date,
        e?.hemocheck,
        e?.specificGravity,
        e?.heartBeat,
        e?.heartBeatQuality,
        e?.wombPosition,
        e?.estimatedBabySize,
        e?.foetalHemocheck,
        e?.clinicId,
        e?.doctorId,
        e?.status,
        e?.isInstant,
        e?.time
      ]);

  @override
  bool isValidKey(Object? o) => o is EncounterRecord;
}
