import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _motherRef = prefs.getString('ff_motherRef')?.ref ?? _motherRef;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  int _appointments = 0;
  int get appointments => _appointments;
  set appointments(int value) {
    _appointments = value;
  }

  DocumentReference? _motherRef;
  DocumentReference? get motherRef => _motherRef;
  set motherRef(DocumentReference? value) {
    _motherRef = value;
    value != null
        ? prefs.setString('ff_motherRef', value.path)
        : prefs.remove('ff_motherRef');
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}
