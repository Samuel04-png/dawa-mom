import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'booking_bottom_sheet_widget.dart' show BookingBottomSheetWidget;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BookingBottomSheetModel
    extends FlutterFlowModel<BookingBottomSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Calendar widget.
  DateTimeRange? calendarSelectedDay;
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  DoctorRecord? doctorRefFound;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EncounterRecord? doctorBooked;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EncounterRecord? motherBooked;

  @override
  void initState(BuildContext context) {
    calendarSelectedDay = DateTimeRange(
      start: DateTime.now().startOfDay,
      end: DateTime.now().endOfDay,
    );
  }

  @override
  void dispose() {}
}
