import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class SupabaseDatabase {
  SupabaseDatabase._();

  static final instance = SupabaseDatabase._();

  SupabaseClient get client => Supabase.instance.client;

  Future<T> runWithFreshSession<T>(Future<T> Function() action) async {
    await _refreshSessionIfExpiringSoon();
    try {
      return await action();
    } catch (error) {
      if (!_isExpiredJwtError(error)) {
        rethrow;
      }
      await _forceRefreshSession();
      return action();
    }
  }

  Future<void> _refreshSessionIfExpiringSoon() async {
    final session = client.auth.currentSession;
    if (session == null) {
      return;
    }

    final expiresAt = session.expiresAt;
    if (expiresAt == null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expiresAt <= now + 60) {
      await _forceRefreshSession();
    }
  }

  Future<void> _forceRefreshSession() async {
    try {
      final response = await client.auth
          .refreshSession()
          .timeout(const Duration(seconds: 8));
      if (response.session == null) {
        await client.auth.signOut(scope: SignOutScope.local);
      }
    } catch (_) {
      await client.auth.signOut(scope: SignOutScope.local);
      rethrow;
    }
  }

  bool _isExpiredJwtError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      return error.code == 'PGRST303' || message.contains('jwt expired');
    }
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      return message.contains('jwt expired') ||
          message.contains('refresh token') ||
          message.contains('expired');
    }
    return false;
  }

  CollectionReference collection(String path) {
    final segments = _cleanPath(path).split('/');
    if (segments.isEmpty) {
      throw ArgumentError.value(path, 'path', 'Collection path is empty');
    }
    final collectionName =
        segments.length.isOdd ? segments.last : segments[segments.length - 2];
    final parent = segments.length > 1
        ? DocumentReference._(
            database: this,
            collectionName: segments[segments.length - 2],
            id: segments.last,
            parent: null,
          )
        : null;
    return CollectionReference._(
      database: this,
      collectionName: collectionName,
      parent: parent,
      path: _cleanPath(path),
    );
  }

  DocumentReference doc(String path) {
    final segments = _cleanPath(path).split('/');
    if (segments.length < 2) {
      throw ArgumentError.value(
          path, 'path', 'Document path must contain collection and id');
    }
    return DocumentReference._(
      database: this,
      collectionName: segments[segments.length - 2],
      id: segments.last,
      parent: CollectionReference._(
        database: this,
        collectionName: segments[segments.length - 2],
        parent: null,
        path: segments.take(segments.length - 1).join('/'),
      ),
    );
  }

  String tableForCollection(String collectionName) =>
      _collectionMappings[collectionName] ?? collectionName;

  String collectionForTable(String tableName) =>
      _collectionMappings.entries
          .firstWhereOrNull((entry) => entry.value == tableName)
          ?.key ??
      tableName;

  Map<String, dynamic> rowToLegacyData(
      String collectionName, Map<String, dynamic> row) {
    final normalized = <String, dynamic>{};
    row.forEach((key, value) {
      final legacyKey = _legacyFieldName(collectionName, key);
      normalized[legacyKey] = _legacyValue(collectionName, legacyKey, value);
    });

    normalized['id'] ??= row['id'];
    if (collectionName == 'user') {
      normalized['uid'] ??= row['id'];
      normalized['created_time'] ??= _dateTimeFrom(row['created_at']);
    }
    if (collectionName == 'mother') {
      normalized['user_Id'] ??= _referenceFromId('user', row['profile_id']);
      normalized['mother_id'] ??= row['legacy_mother_id'] ?? row['id'];
      normalized['first_encounter_id'] ??=
          _referenceFromId('first_encounter', row['first_encounter_id']);
    }
    if (collectionName == 'doctor') {
      normalized['user_Id'] ??= _referenceFromId('user', row['profile_id']);
      normalized['doctor_id'] ??= row['legacy_doctor_id'] ?? row['id'];
      normalized['clinic_name'] ??= row['clinic_name_legacy'];
    }
    if (collectionName == 'first_encounter') {
      normalized['mother_Id'] ??= _referenceFromId('mother', row['mother_id']);
    }
    if (collectionName == 'encounter') {
      normalized['doctor_id'] ??= _referenceFromId('doctor', row['doctor_id']);
      normalized['mother_id'] ??= _referenceFromId('mother', row['mother_id']);
      normalized['date'] ??= _dateTimeFrom(row['appointment_date']);
      normalized['time'] ??= row['appointment_time'];
    }
    return normalized;
  }

  Map<String, dynamic> legacyDataToRow(
    String collectionName,
    Map<String, dynamic> data, {
    String? id,
    bool includeNulls = false,
  }) {
    final row = <String, dynamic>{};
    if (id != null) {
      row['id'] = id;
    }
    data.forEach((legacyKey, value) {
      if (value == null && !includeNulls) {
        return;
      }
      if (value is FieldValue && value.isDelete) {
        row[_columnName(collectionName, legacyKey)] = null;
        return;
      }
      if (value is FieldValue && value.isServerTimestamp) {
        row[_columnName(collectionName, legacyKey)] =
            DateTime.now().toUtc().toIso8601String();
        return;
      }
      final column = _columnName(collectionName, legacyKey);
      final converted = _rowValue(collectionName, legacyKey, value);
      if (converted != null || includeNulls) {
        row[column] = converted;
      }
    });
    return row;
  }

  DocumentReference? _referenceFromId(String collectionName, dynamic id) {
    if (id == null) {
      return null;
    }
    return collection(collectionName).doc(id.toString());
  }

  String _columnName(String collectionName, String legacyKey) =>
      _fieldMappings[collectionName]?[legacyKey] ?? legacyKey;

  String _legacyFieldName(String collectionName, String column) =>
      _fieldMappings[collectionName]
          ?.entries
          .firstWhereOrNull((entry) => entry.value == column)
          ?.key ??
      column;

  dynamic _legacyValue(String collectionName, String legacyKey, dynamic value) {
    if (value == null) {
      return null;
    }
    if (_dateFields[collectionName]?.contains(legacyKey) ?? false) {
      return _dateTimeFrom(value);
    }
    if (_referenceFields[collectionName]?[legacyKey]
        case final refCollection?) {
      return _referenceFromId(refCollection, value);
    }
    return value;
  }

  dynamic _rowValue(String collectionName, String legacyKey, dynamic value) {
    if (value is DocumentReference) {
      return value.id;
    }
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      if (collectionName == 'encounter' && legacyKey == 'date') {
        return _dateOnly(value);
      }
      if (collectionName == 'mother' && legacyKey == 'dateOfBirth') {
        return _dateOnly(value);
      }
      return value.toUtc().toIso8601String();
    }
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is Iterable) {
      return value
          .map((item) => _rowValue(collectionName, legacyKey, item))
          .toList();
    }
    if (value is Map) {
      return value.map((key, item) =>
          MapEntry(key.toString(), _rowValue(collectionName, legacyKey, item)));
    }
    return value;
  }
}

class CollectionReference extends Query {
  CollectionReference._({
    required SupabaseDatabase database,
    required String collectionName,
    required this.path,
    this.parent,
  }) : super._(
          database: database,
          collectionName: collectionName,
        );

  final String path;
  final DocumentReference? parent;

  DocumentReference doc([String? id]) => DocumentReference._(
        database: database,
        collectionName: collectionName,
        id: id ?? _newId(),
        parent: this,
      );

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final ref = doc();
    await ref.set(data);
    return ref;
  }
}

class DocumentReference {
  DocumentReference._({
    required this.database,
    required this.collectionName,
    required this.id,
    this.parent,
  });

  final SupabaseDatabase database;
  final String collectionName;
  final String id;
  final CollectionReference? parent;

  String get path => '${parent?.path ?? collectionName}/$id';

  CollectionReference collection(String childPath) => CollectionReference._(
        database: database,
        collectionName: childPath,
        parent: this,
        path: '$path/$childPath',
      );

  Stream<DocumentSnapshot> snapshots() => Stream.fromFuture(get());

  Future<DocumentSnapshot> get() async {
    final table = database.tableForCollection(collectionName);
    final response = await database.runWithFreshSession(
      () => database.client.from(table).select().eq('id', id).maybeSingle(),
    );
    final data = response == null
        ? null
        : database.rowToLegacyData(
            collectionName, Map<String, dynamic>.from(response as Map));
    return DocumentSnapshot._(reference: this, data: data);
  }

  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final row = database.legacyDataToRow(
      collectionName,
      data,
      id: id,
      includeNulls: options?.merge != true,
    );
    await database.runWithFreshSession(
      () => database.client
          .from(database.tableForCollection(collectionName))
          .upsert(row),
    );
  }

  Future<void> update(Map<String, dynamic> data) async {
    final row = database.legacyDataToRow(collectionName, data);
    if (row.isEmpty) {
      return;
    }
    await database.runWithFreshSession(
      () => database.client
          .from(database.tableForCollection(collectionName))
          .update(row)
          .eq('id', id),
    );
  }

  Future<void> delete() async {
    await database.runWithFreshSession(
      () => database.client
          .from(database.tableForCollection(collectionName))
          .delete()
          .eq('id', id),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentReference &&
      other.collectionName == collectionName &&
      other.id == id;

  @override
  int get hashCode => Object.hash(collectionName, id);

  @override
  String toString() => path;
}

class Query {
  Query._({
    required this.database,
    required this.collectionName,
    List<_QueryFilter>? filters,
    List<_QueryOrder>? orders,
    int? limitValue,
    DocumentSnapshot? startAfter,
  })  : _filters = filters ?? const [],
        _orders = orders ?? const [],
        _limit = limitValue,
        _startAfter = startAfter;

  final SupabaseDatabase database;
  final String collectionName;
  final List<_QueryFilter> _filters;
  final List<_QueryOrder> _orders;
  final int? _limit;
  final DocumentSnapshot? _startAfter;

  Query where(
    Object fieldOrFilter, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (fieldOrFilter is Filter) {
      return _copyWith(filters: [..._filters, ...fieldOrFilter.filters]);
    }
    final field = fieldOrFilter.toString();
    final nextFilters = [..._filters];
    if (isNull == true) {
      nextFilters.add(_QueryFilter(field, _FilterOperator.isNull, null));
    }
    if (isEqualTo != null) {
      nextFilters.add(_QueryFilter(field, _FilterOperator.equals, isEqualTo));
    }
    if (isNotEqualTo != null) {
      nextFilters
          .add(_QueryFilter(field, _FilterOperator.notEquals, isNotEqualTo));
    }
    if (isLessThan != null) {
      nextFilters
          .add(_QueryFilter(field, _FilterOperator.lessThan, isLessThan));
    }
    if (isLessThanOrEqualTo != null) {
      nextFilters.add(_QueryFilter(
          field, _FilterOperator.lessThanOrEqual, isLessThanOrEqualTo));
    }
    if (isGreaterThan != null) {
      nextFilters
          .add(_QueryFilter(field, _FilterOperator.greaterThan, isGreaterThan));
    }
    if (isGreaterThanOrEqualTo != null) {
      nextFilters.add(_QueryFilter(
          field, _FilterOperator.greaterThanOrEqual, isGreaterThanOrEqualTo));
    }
    if (arrayContains != null) {
      nextFilters.add(
          _QueryFilter(field, _FilterOperator.arrayContains, arrayContains));
    }
    if (arrayContainsAny != null) {
      nextFilters.add(_QueryFilter(
          field, _FilterOperator.arrayContainsAny, arrayContainsAny.toList()));
    }
    if (whereIn != null) {
      nextFilters
          .add(_QueryFilter(field, _FilterOperator.whereIn, whereIn.toList()));
    }
    if (whereNotIn != null) {
      nextFilters.add(
          _QueryFilter(field, _FilterOperator.whereNotIn, whereNotIn.toList()));
    }
    return _copyWith(filters: nextFilters);
  }

  Query orderBy(String field, {bool descending = false}) =>
      _copyWith(orders: [..._orders, _QueryOrder(field, descending)]);

  Query limit(int limit) => _copyWith(limitValue: limit);

  Query startAfterDocument(DocumentSnapshot snapshot) =>
      _copyWith(startAfter: snapshot);

  Stream<QuerySnapshot> snapshots() => Stream.fromFuture(get());

  Future<QuerySnapshot> get() async {
    final rows = await _fetchRows();
    final docs = rows
        .map((data) => QueryDocumentSnapshot._(
              reference: database
                  .collection(collectionName)
                  .doc(data['id']?.toString()),
              data: data,
            ))
        .toList();
    return QuerySnapshot._(
      docs: docs,
      docChanges: docs
          .map((doc) => DocumentChange(
                doc: doc,
                type: DocumentChangeType.added,
              ))
          .toList(),
    );
  }

  AggregateQuery count() => AggregateQuery(this);

  Future<List<Map<String, dynamic>>> _fetchRows() async {
    final table = database.tableForCollection(collectionName);
    final response = await database.runWithFreshSession(
      () => database.client.from(table).select(),
    );
    final rawRows = (response as List)
        .map((row) => database.rowToLegacyData(
            collectionName, Map<String, dynamic>.from(row as Map)))
        .toList();

    Iterable<Map<String, dynamic>> rows = rawRows.where(_matchesFilters);
    for (final order in _orders.reversed) {
      rows = rows.sorted((a, b) {
        final comparison = _compareValues(a[order.field], b[order.field]);
        return order.descending ? -comparison : comparison;
      });
    }
    if (_startAfter != null) {
      final startIndex =
          rows.toList().indexWhere((row) => row['id'] == _startAfter!.id);
      if (startIndex >= 0) {
        rows = rows.skip(startIndex + 1);
      }
    }
    if (_limit != null && _limit! >= 0) {
      rows = rows.take(_limit!);
    }
    return rows.toList();
  }

  bool _matchesFilters(Map<String, dynamic> row) =>
      _filters.every((filter) => filter.matches(row[filter.field]));

  Query _copyWith({
    List<_QueryFilter>? filters,
    List<_QueryOrder>? orders,
    int? limitValue,
    DocumentSnapshot? startAfter,
  }) =>
      Query._(
        database: database,
        collectionName: collectionName,
        filters: filters ?? _filters,
        orders: orders ?? _orders,
        limitValue: limitValue ?? _limit,
        startAfter: startAfter ?? _startAfter,
      );

  @override
  String toString() => 'SupabaseQuery($collectionName)';
}

class DocumentSnapshot {
  DocumentSnapshot._(
      {required this.reference, required Map<String, dynamic>? data})
      : _data = data;

  final DocumentReference reference;
  final Map<String, dynamic>? _data;

  String get id => reference.id;
  bool get exists => _data != null;

  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.from(_data!);
}

class QueryDocumentSnapshot extends DocumentSnapshot {
  QueryDocumentSnapshot._({
    required DocumentReference reference,
    required Map<String, dynamic> data,
  }) : super._(
          reference: reference,
          data: data,
        );

  @override
  Map<String, dynamic> data() =>
      Map<String, dynamic>.from(super.data() ?? const {});
}

class QuerySnapshot {
  QuerySnapshot._({required this.docs, required this.docChanges});

  final List<QueryDocumentSnapshot> docs;
  final List<DocumentChange> docChanges;
}

class DocumentChange {
  const DocumentChange({required this.doc, required this.type});

  final QueryDocumentSnapshot doc;
  final DocumentChangeType type;
}

enum DocumentChangeType { added, modified, removed }

class AggregateQuery {
  const AggregateQuery(this.query);

  final Query query;

  Future<AggregateQuerySnapshot> get() async =>
      AggregateQuerySnapshot((await query.get()).docs.length);
}

class AggregateQuerySnapshot {
  const AggregateQuerySnapshot(this.count);

  final int? count;
}

class SetOptions {
  const SetOptions({this.merge = false});

  final bool merge;
}

class FieldValue {
  const FieldValue._({this.isDelete = false, this.isServerTimestamp = false});

  final bool isDelete;
  final bool isServerTimestamp;

  static FieldValue delete() => const FieldValue._(isDelete: true);
  static FieldValue serverTimestamp() =>
      const FieldValue._(isServerTimestamp: true);
}

class Timestamp {
  const Timestamp._(this._dateTime);

  final DateTime _dateTime;

  static Timestamp fromDate(DateTime dateTime) => Timestamp._(dateTime);
  DateTime toDate() => _dateTime;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class Filter {
  Filter(
    String field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    Iterable<Object?>? arrayContainsAny,
  }) : filters = [
          if (isEqualTo != null)
            _QueryFilter(field, _FilterOperator.equals, isEqualTo),
          if (isNotEqualTo != null)
            _QueryFilter(field, _FilterOperator.notEquals, isNotEqualTo),
          if (whereIn != null)
            _QueryFilter(field, _FilterOperator.whereIn, whereIn.toList()),
          if (whereNotIn != null)
            _QueryFilter(
                field, _FilterOperator.whereNotIn, whereNotIn.toList()),
          if (arrayContainsAny != null)
            _QueryFilter(field, _FilterOperator.arrayContainsAny,
                arrayContainsAny.toList()),
        ];

  const Filter._(this.filters);

  final List<_QueryFilter> filters;

  static Filter and(Filter left, Filter right) =>
      Filter._([...left.filters, ...right.filters]);
}

class _QueryOrder {
  const _QueryOrder(this.field, this.descending);

  final String field;
  final bool descending;
}

class _QueryFilter {
  const _QueryFilter(this.field, this.operator, this.value);

  final String field;
  final _FilterOperator operator;
  final Object? value;

  bool matches(Object? rowValue) {
    final left = _comparable(rowValue);
    final right = _comparable(value);
    return switch (operator) {
      _FilterOperator.equals => left == right,
      _FilterOperator.notEquals => left != right,
      _FilterOperator.lessThan => _compareValues(left, right) < 0,
      _FilterOperator.lessThanOrEqual => _compareValues(left, right) <= 0,
      _FilterOperator.greaterThan => _compareValues(left, right) > 0,
      _FilterOperator.greaterThanOrEqual => _compareValues(left, right) >= 0,
      _FilterOperator.whereIn => (right as Iterable).contains(left),
      _FilterOperator.whereNotIn => !(right as Iterable).contains(left),
      _FilterOperator.arrayContains =>
        rowValue is Iterable && rowValue.map(_comparable).contains(right),
      _FilterOperator.arrayContainsAny => rowValue is Iterable &&
          (right as Iterable).any(
              (item) => rowValue.map(_comparable).contains(_comparable(item))),
      _FilterOperator.isNull => rowValue == null,
    };
  }
}

enum _FilterOperator {
  equals,
  notEquals,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  whereIn,
  whereNotIn,
  arrayContains,
  arrayContainsAny,
  isNull,
}

const _collectionMappings = {
  'user': 'profiles',
  'mother': 'mothers',
  'doctor': 'doctors',
  'clinic': 'clinics',
  'first_encounter': 'first_encounters',
  'encounter': 'encounters',
  'parity': 'parities',
  'weeks_of_pregenancy': 'pregnancy_weeks',
};

const _fieldMappings = {
  'user': {
    'uid': 'id',
    'created_time': 'created_at',
  },
  'mother': {
    'user_Id': 'profile_id',
    'dateOfBirth': 'date_of_birth',
    'mother_id': 'legacy_mother_id',
    'first_encounter_id': 'first_encounter_id',
  },
  'doctor': {
    'user_Id': 'profile_id',
    'doctor_id': 'legacy_doctor_id',
    'clinic_name': 'clinic_name_legacy',
  },
  'first_encounter': {
    'mother_Id': 'mother_id',
  },
  'encounter': {
    'date': 'appointment_date',
    'time': 'appointment_time',
  },
};

const _referenceFields = {
  'mother': {
    'user_Id': 'user',
    'first_encounter_id': 'first_encounter',
  },
  'doctor': {
    'user_Id': 'user',
  },
  'first_encounter': {
    'mother_Id': 'mother',
  },
  'encounter': {
    'doctor_id': 'doctor',
    'mother_id': 'mother',
  },
};

const _dateFields = {
  'user': {'created_time'},
  'mother': {'dateOfBirth', 'created_at', 'updated_at'},
  'doctor': {'created_at', 'updated_at'},
  'first_encounter': {'created_at', 'updated_at'},
  'encounter': {'date', 'created_at', 'updated_at'},
  'period_tracker_settings': {'last_period_start', 'created_at', 'updated_at'},
  'period_tracker_entries': {'entry_date', 'created_at', 'updated_at'},
};

String _cleanPath(String path) => path.replaceAll(RegExp(r'^/+|/+$'), '');

String _newId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

DateTime? _dateTimeFrom(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.tryParse(value.toString());
}

String _dateOnly(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

Object? _comparable(Object? value) {
  if (value is DocumentReference) {
    return value.id;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Iterable) {
    return value.map(_comparable).toList();
  }
  return value;
}

int _compareValues(Object? left, Object? right) {
  final comparableLeft = _comparable(left);
  final comparableRight = _comparable(right);
  if (comparableLeft == null && comparableRight == null) {
    return 0;
  }
  if (comparableLeft == null) {
    return -1;
  }
  if (comparableRight == null) {
    return 1;
  }
  if (comparableLeft is num && comparableRight is num) {
    return comparableLeft.compareTo(comparableRight);
  }
  if (comparableLeft is Comparable && comparableRight is Comparable) {
    return comparableLeft.compareTo(comparableRight);
  }
  return comparableLeft.toString().compareTo(comparableRight.toString());
}
