import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../auth/supabase_auth/auth_util.dart';

import '../flutter_flow/flutter_flow_util.dart';
import 'schema/util/firestore_util.dart';

import 'schema/user_record.dart';
import 'schema/mother_record.dart';
import 'schema/doctor_record.dart';
import 'schema/clinic_record.dart';
import 'schema/first_encounter_record.dart';
import 'schema/encounter_record.dart';
import 'schema/parity_record.dart';
import 'schema/weeks_of_pregenancy_record.dart';

export 'dart:async' show StreamSubscription;
export 'supabase/supabase_database.dart';
export 'schema/index.dart';
export 'schema/util/firestore_util.dart';
export 'schema/util/schema_util.dart';

export 'schema/user_record.dart';
export 'schema/mother_record.dart';
export 'schema/doctor_record.dart';
export 'schema/clinic_record.dart';
export 'schema/first_encounter_record.dart';
export 'schema/encounter_record.dart';
export 'schema/parity_record.dart';
export 'schema/weeks_of_pregenancy_record.dart';

/// Functions to query UserRecords (as a Stream and as a Future).
Future<int> queryUserRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UserRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UserRecord>> queryUserRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      UserRecord.collection,
      UserRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<UserRecord>> queryUserRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UserRecord.collection,
      UserRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query MotherRecords (as a Stream and as a Future).
Future<int> queryMotherRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      MotherRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<MotherRecord>> queryMotherRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      MotherRecord.collection,
      MotherRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<MotherRecord>> queryMotherRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      MotherRecord.collection,
      MotherRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query DoctorRecords (as a Stream and as a Future).
Future<int> queryDoctorRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      DoctorRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<DoctorRecord>> queryDoctorRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      DoctorRecord.collection,
      DoctorRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<DoctorRecord>> queryDoctorRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      DoctorRecord.collection,
      DoctorRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ClinicRecords (as a Stream and as a Future).
Future<int> queryClinicRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ClinicRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ClinicRecord>> queryClinicRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ClinicRecord.collection,
      ClinicRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ClinicRecord>> queryClinicRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ClinicRecord.collection,
      ClinicRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query FirstEncounterRecords (as a Stream and as a Future).
Future<int> queryFirstEncounterRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      FirstEncounterRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<FirstEncounterRecord>> queryFirstEncounterRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      FirstEncounterRecord.collection,
      FirstEncounterRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<FirstEncounterRecord>> queryFirstEncounterRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      FirstEncounterRecord.collection,
      FirstEncounterRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query EncounterRecords (as a Stream and as a Future).
Future<int> queryEncounterRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      EncounterRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<EncounterRecord>> queryEncounterRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      EncounterRecord.collection,
      EncounterRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<EncounterRecord>> queryEncounterRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      EncounterRecord.collection,
      EncounterRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ParityRecords (as a Stream and as a Future).
Future<int> queryParityRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ParityRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ParityRecord>> queryParityRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ParityRecord.collection,
      ParityRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ParityRecord>> queryParityRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ParityRecord.collection,
      ParityRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query WeeksOfPregenancyRecords (as a Stream and as a Future).
Future<int> queryWeeksOfPregenancyRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      WeeksOfPregenancyRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<WeeksOfPregenancyRecord>> queryWeeksOfPregenancyRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      WeeksOfPregenancyRecord.collection,
      WeeksOfPregenancyRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<WeeksOfPregenancyRecord>> queryWeeksOfPregenancyRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      WeeksOfPregenancyRecord.collection,
      WeeksOfPregenancyRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<int> queryCollectionCount(
  Query collection, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0) {
    query = query.limit(limit);
  }

  return query.count().get().then((value) => value.count!).catchError((err) {
    print('Error querying $collection: $err');
    return 0;
  });
}

Stream<List<T>> queryCollection<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots().handleError((err) {
    print('Error querying $collection: $err');
  }).map((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Future<List<T>> queryCollectionOnce<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.get().then((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Filter filterIn(String field, List? list) => (list?.isEmpty ?? true)
    ? Filter(field, whereIn: null)
    : Filter(field, whereIn: list);

Filter filterArrayContainsAny(String field, List? list) =>
    (list?.isEmpty ?? true)
        ? Filter(field, arrayContainsAny: null)
        : Filter(field, arrayContainsAny: list);

extension QueryExtension on Query {
  Query whereIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereIn: null)
      : where(field, whereIn: list);

  Query whereNotIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereNotIn: null)
      : where(field, whereNotIn: list);

  Query whereArrayContainsAny(String field, List? list) =>
      (list?.isEmpty ?? true)
          ? where(field, arrayContainsAny: null)
          : where(field, arrayContainsAny: list);
}

// FlutterFlow keeps these pagination names, but the queries are backed by the
// Supabase compatibility layer exported above.
class FFFirestorePage<T> {
  final List<T> data;
  final Stream<List<T>>? dataStream;
  final QueryDocumentSnapshot? nextPageMarker;

  FFFirestorePage(this.data, this.dataStream, this.nextPageMarker);
}

Future<FFFirestorePage<T>> queryCollectionPage<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection).limit(pageSize);
  if (nextPageMarker != null) {
    query = query.startAfterDocument(nextPageMarker);
  }
  Stream<QuerySnapshot>? docSnapshotStream;
  QuerySnapshot docSnapshot;
  if (isStream) {
    docSnapshotStream = query.snapshots();
    docSnapshot = await docSnapshotStream.first;
  } else {
    docSnapshot = await query.get();
  }
  final getDocs = (QuerySnapshot s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
  final data = getDocs(docSnapshot);
  final dataStream = docSnapshotStream?.map(getDocs);
  final nextPageToken = docSnapshot.docs.isEmpty ? null : docSnapshot.docs.last;
  return FFFirestorePage(data, dataStream, nextPageToken);
}

// Creates the Supabase-backed user profile row representing the logged in user
// if it doesn't yet exist.
Future maybeCreateUser(supabase.User user) async {
  final userRecord = UserRecord.collection.doc(user.id);
  final userExists = await userRecord.get().then((u) => u.exists);
  if (userExists) {
    currentUserDocument = await UserRecord.getDocumentOnce(userRecord);
    return;
  }

  final userData = createUserRecordData(
    email: user.email,
    displayName: user.userMetadata?['display_name']?.toString() ??
        user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString(),
    photoUrl: user.userMetadata?['avatar_url']?.toString() ??
        user.userMetadata?['picture']?.toString(),
    uid: user.id,
    phoneNumber: user.phone,
    createdTime: getCurrentTimestamp,
    role: user.userMetadata?['requested_role']?.toString(),
  );

  await userRecord.set(userData);
  currentUserDocument = UserRecord.getDocumentFromData(userData, userRecord);
}

Future updateUserDocument({String? email}) async {
  await currentUserDocument?.reference
      .update(createUserRecordData(email: email));
}
