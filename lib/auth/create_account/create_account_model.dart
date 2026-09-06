import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_account_widget.dart' show CreateAccountWidget;
import 'package:flutter/material.dart';

class CreateAccountModel extends FlutterFlowModel<CreateAccountWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  DateTime? datePicked;
  String? dateOfBirthError;
  bool hasSubmitted = false;
  bool isSaving = false;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  String? _textController1Validator(BuildContext context, String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.length < 2 || !RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Please enter a valid name.';
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  String? _textController2Validator(BuildContext context, String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) {
      return 'Please enter your mobile number.';
    }

    final normalized = value.replaceAll(RegExp(r'[\s-]'), '');
    final isLocalNumber = RegExp(r'^0\d{9}$').hasMatch(normalized);
    final isInternationalNumber = RegExp(r'^\+260\d{9}$').hasMatch(normalized);
    if (!isLocalNumber && !isInternationalNumber) {
      return 'Enter a valid phone number, e.g. 0977123456.';
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  String? _textController3Validator(BuildContext context, String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) {
      return 'Please enter your occupation.';
    }
    if (value.length < 2) {
      return 'Please enter a valid occupation.';
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  String? _textController4Validator(BuildContext context, String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) {
      return 'Please enter your address.';
    }
    if (value.length < 5) {
      return 'Please enter a complete address.';
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    textController1Validator = _textController1Validator;
    textController2Validator = _textController2Validator;
    textController3Validator = _textController3Validator;
    textController4Validator = _textController4Validator;
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();
  }
}
