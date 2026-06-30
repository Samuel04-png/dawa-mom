import '/backend/backend.dart';
import '/components/no_appointments_comp/no_appointments_comp_widget.dart';
import '/components/no_pregnancy_data_comp/no_pregnancy_data_comp_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_widget.dart' show HomeWidget;
import 'package:flutter/material.dart';

class HomeModel extends FlutterFlowModel<HomeWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for NoAppointmentsComp component.
  late NoAppointmentsCompModel noAppointmentsCompModel;
  // Model for NoPregnancyDataComp component.
  late NoPregnancyDataCompModel noPregnancyDataCompModel;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EncounterRecord? appointmentFound;

  @override
  void initState(BuildContext context) {
    noAppointmentsCompModel =
        createModel(context, () => NoAppointmentsCompModel());
    noPregnancyDataCompModel =
        createModel(context, () => NoPregnancyDataCompModel());
  }

  @override
  void dispose() {
    noAppointmentsCompModel.dispose();
    noPregnancyDataCompModel.dispose();
  }
}
