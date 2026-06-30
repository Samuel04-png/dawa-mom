import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'forgot_password_widget.dart' show ForgotPasswordWidget;
import 'package:flutter/material.dart';

class ForgotPasswordModel extends FlutterFlowModel<ForgotPasswordWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for userEmail widget.
  FocusNode? userEmailFocusNode;
  TextEditingController? userEmailTextController;
  String? Function(BuildContext, String?)? userEmailTextControllerValidator;
  // State field(s) for supportEmail widget.
  FocusNode? supportEmailFocusNode;
  TextEditingController? supportEmailTextController;
  String? Function(BuildContext, String?)? supportEmailTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    userEmailFocusNode?.dispose();
    userEmailTextController?.dispose();

    supportEmailFocusNode?.dispose();
    supportEmailTextController?.dispose();
  }
}
