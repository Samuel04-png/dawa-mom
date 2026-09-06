import '/components/no_data_generic/no_data_generic_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'appointment_details_widget.dart' show AppointmentDetailsWidget;
import 'package:flutter/material.dart';

class AppointmentDetailsModel
    extends FlutterFlowModel<AppointmentDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for NoDataGeneric component.
  late NoDataGenericModel noDataGenericModel;

  @override
  void initState(BuildContext context) {
    noDataGenericModel = createModel(context, () => NoDataGenericModel());
  }

  @override
  void dispose() {
    noDataGenericModel.dispose();
  }
}
