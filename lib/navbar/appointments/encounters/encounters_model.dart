import '/components/appointment_component/appointment_component_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'encounters_widget.dart' show EncountersWidget;
import 'package:flutter/material.dart';

class EncountersModel extends FlutterFlowModel<EncountersWidget> {
  ///  State fields for stateful widgets in this page.

  // Models for AppointmentComponent dynamic component.
  late FlutterFlowDynamicModels<AppointmentComponentModel>
      appointmentComponentModels;

  @override
  void initState(BuildContext context) {
    appointmentComponentModels =
        FlutterFlowDynamicModels(() => AppointmentComponentModel());
  }

  @override
  void dispose() {
    appointmentComponentModels.dispose();
  }
}
