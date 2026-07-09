import 'package:dawa_mom/flutter_flow/flutter_flow_calendar.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'period_tracker_widget.dart' show PeriodTrackerWidget;
import 'package:flutter/material.dart';

class PeriodTrackerModel extends FlutterFlowModel<PeriodTrackerWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Calendar widget.
  DateTimeRange? calendarSelectedDay;
  // State field(s) for TextField widget.
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for Switch widget.
  bool? switchValue;

  @override
  void initState(BuildContext context) {
    calendarSelectedDay = DateTimeRange(
      start: DateTime.now().startOfDay,
      end: DateTime.now().endOfDay,
    );
  }

  @override
  void dispose() {
    textController?.dispose();
  }
}
