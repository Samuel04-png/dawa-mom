import '/auth/supabase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_account_model.dart';
export 'create_account_model.dart';

class CreateAccountWidget extends StatefulWidget {
  const CreateAccountWidget({super.key});

  static String routeName = 'CreateAccount';
  static String routePath = '/createAccount';

  @override
  State<CreateAccountWidget> createState() => _CreateAccountWidgetState();
}

class _CreateAccountWidgetState extends State<CreateAccountWidget> {
  late CreateAccountModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _dateOfBirthFieldKey = GlobalKey();
  final _nameFieldKey = GlobalKey();
  final _phoneFieldKey = GlobalKey();
  final _occupationFieldKey = GlobalKey();
  final _addressFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateAccountModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();

    super.dispose();
  }

  String? _dateOfBirthErrorText() {
    final datePicked = _model.datePicked;
    if (datePicked == null) {
      return 'Date of Birth is required.';
    }
    if (datePicked.isAfter(getCurrentTimestamp)) {
      return 'Date of Birth cannot be in the future.';
    }
    return null;
  }

  _InvalidField? _firstInvalidField(BuildContext context) {
    if (_dateOfBirthErrorText() != null) {
      return _InvalidField(
        key: _dateOfBirthFieldKey,
        message: 'Please complete Date of Birth.',
      );
    }

    if (_model.textController1Validator
            ?.call(context, _model.textController1.text) !=
        null) {
      return _InvalidField(
        key: _nameFieldKey,
        focusNode: _model.textFieldFocusNode1,
        message: 'Please complete Name.',
      );
    }

    if (_model.textController2Validator
            ?.call(context, _model.textController2.text) !=
        null) {
      return _InvalidField(
        key: _phoneFieldKey,
        focusNode: _model.textFieldFocusNode2,
        message: 'Please enter a valid Mobile Number.',
      );
    }

    if (_model.textController3Validator
            ?.call(context, _model.textController3.text) !=
        null) {
      return _InvalidField(
        key: _occupationFieldKey,
        focusNode: _model.textFieldFocusNode3,
        message: 'Please complete Occupation.',
      );
    }

    if (_model.textController4Validator
            ?.call(context, _model.textController4.text) !=
        null) {
      return _InvalidField(
        key: _addressFieldKey,
        focusNode: _model.textFieldFocusNode4,
        message: 'Please complete Address.',
      );
    }

    return null;
  }

  Future<bool> _validateAndFocusFirstInvalidField(BuildContext context) async {
    safeSetState(() {
      _model.hasSubmitted = true;
      _model.dateOfBirthError = _dateOfBirthErrorText();
    });

    final formIsValid = _model.formKey.currentState?.validate() ?? false;
    final firstInvalidField = _firstInvalidField(context);
    if (firstInvalidField == null && formIsValid) {
      return true;
    }

    _showSnackBar(firstInvalidField?.message ??
        'Please complete the highlighted required fields.');

    final fieldContext = firstInvalidField?.key.currentContext;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.12,
      );
    }
    final focusNode = firstInvalidField?.focusNode;
    if (focusNode != null) {
      focusNode.requestFocus();
    }

    return false;
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) {
      return;
    }
    final theme = FlutterFlowTheme.of(context);
    final isCompactLayout = MediaQuery.sizeOf(context).width < 600;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: theme.secondaryBackground,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsetsDirectional.fromSTEB(
            isCompactLayout ? 16.0 : 32.0,
            0.0,
            isCompactLayout ? 16.0 : 32.0,
            16.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: backgroundColor ?? theme.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isSmallScreen = screenWidth < 360; // For very small phones
    final isCompactLayout = screenWidth < 600;
    final isWideLayout = screenWidth >= 900;
    final pageHorizontalPadding =
        isSmallScreen ? 12.0 : (isCompactLayout ? 16.0 : 32.0);
    final contentMaxWidth =
        isCompactLayout ? screenWidth : (isWideLayout ? 720.0 : 600.0);
    final heroImageHeight = min(
      screenHeight * (isCompactLayout ? 0.15 : 0.16),
      isCompactLayout ? 118.0 : 138.0,
    );

    return StreamBuilder<List<MotherRecord>>(
      stream: queryMotherRecord(
        queryBuilder: (motherRecord) => motherRecord.where(
          'user_Id',
          isEqualTo: currentUserReference,
        ),
        singleRecord: true,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<MotherRecord> createAccountMotherRecordList = snapshot.data!;
        final createAccountMotherRecord =
            createAccountMotherRecordList.isNotEmpty
                ? createAccountMotherRecordList.first
                : null;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              automaticallyImplyLeading: false,
              toolbarHeight: isSmallScreen ? 62.0 : 68.0,
              title: isSmallScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logged in as',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.poppins(),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12.0,
                                letterSpacing: 0.0,
                              ),
                        ),
                        Text(
                          currentUserEmail.length > 20
                              ? '${currentUserEmail.substring(0, 17)}...'
                              : currentUserEmail,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.poppins(),
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 14.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Logged in as ${currentUserEmail}',
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: isSmallScreen ? 14.0 : 18.0,
                                  letterSpacing: 0.0,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8.0 : 16.0),
                        Flexible(
                          child: FFButtonWidget(
                            onPressed: () async {
                              GoRouter.of(context).prepareAuthEvent();
                              await authManager.signOut();
                              GoRouter.of(context).clearRedirectLocation();

                              context.goNamedAuth(
                                LoginWidget.routeName,
                                context.mounted,
                                extra: <String, dynamic>{
                                  kTransitionInfoKey: TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                  ),
                                },
                              );
                            },
                            text: isSmallScreen ? 'Logout' : 'Logout',
                            options: FFButtonOptions(
                              height: isSmallScreen ? 35.0 : 40.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                isSmallScreen ? 12.0 : 24.0,
                                0.0,
                                isSmallScreen ? 12.0 : 24.0,
                                0.0,
                              ),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).error,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontSize: isSmallScreen ? 12.0 : null,
                                  ),
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: [],
              centerTitle: false,
              elevation: 0.0,
              scrolledUnderElevation: 0.0,
              surfaceTintColor: Colors.transparent,
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsetsDirectional.fromSTEB(
                  pageHorizontalPadding,
                  isSmallScreen ? 8.0 : 20.0,
                  pageHorizontalPadding,
                  (isSmallScreen ? 20.0 : 32.0) + viewInsets.bottom,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image with responsive sizing
                        SizedBox(
                          height: heroImageHeight,
                          width: double.infinity,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/images/Status_update-pana.png',
                                width: isCompactLayout ? 240.0 : 360.0,
                                height: heroImageHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 14.0 : 20.0),

                        // Title with responsive font size
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8.0 : 0.0,
                          ),
                          child: Text(
                            'Complete your account',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .displayMedium
                                .override(
                                  font: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: isSmallScreen
                                      ? 20.0
                                      : (isCompactLayout ? 23.0 : 26.0),
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 10.0 : 12.0),

                        // Description with responsive font size and padding
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 4.0 : 0.0,
                          ),
                          child: Text(
                            'From prenatal check-ups to postnatal care, create your account to access a wide range of services tailored for expectant mothers. Fill in your details below to get started.',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  font: GoogleFonts.poppins(),
                                  fontSize: isSmallScreen ? 13.0 : 14.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 18.0 : 22.0),

                        // Form section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsetsDirectional.fromSTEB(
                            isSmallScreen ? 14.0 : 24.0,
                            isSmallScreen ? 16.0 : 24.0,
                            isSmallScreen ? 14.0 : 24.0,
                            isSmallScreen ? 16.0 : 24.0,
                          ),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                            boxShadow: isCompactLayout
                                ? []
                                : [
                                    BoxShadow(
                                      blurRadius: 18.0,
                                      color: Color(0x14000000),
                                      offset: Offset(0.0, 8.0),
                                    ),
                                  ],
                          ),
                          child: Form(
                            key: _model.formKey,
                            autovalidateMode: _model.hasSubmitted
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // Date of Birth button
                                Column(
                                  key: _dateOfBirthFieldKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FFButtonWidget(
                                      onPressed: () async {
                                        final now = getCurrentTimestamp;
                                        final _datePickedDate =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: _model.datePicked ??
                                              DateTime(
                                                now.year - 25,
                                                now.month,
                                                now.day,
                                              ),
                                          firstDate: DateTime(1900),
                                          lastDate: now,
                                        );

                                        if (_datePickedDate != null) {
                                          safeSetState(() {
                                            _model.datePicked = DateTime(
                                              _datePickedDate.year,
                                              _datePickedDate.month,
                                              _datePickedDate.day,
                                            );
                                            _model.dateOfBirthError = null;
                                          });
                                        }
                                      },
                                      text: () {
                                        if (_model.datePicked != null) {
                                          return dateTimeFormat(
                                              "yMMMd", _model.datePicked);
                                        } else if (_model.datePicked == null) {
                                          return 'Date of birth';
                                        } else {
                                          return 'Date of birth';
                                        }
                                      }(),
                                      iconData: Icons.calendar_today_rounded,
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: isSmallScreen ? 45.0 : 50.0,
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                          isSmallScreen ? 16.0 : 24.0,
                                          0.0,
                                          isSmallScreen ? 16.0 : 24.0,
                                          0.0,
                                        ),
                                        iconPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.poppins(),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontSize:
                                                  isSmallScreen ? 13.0 : null,
                                            ),
                                        borderSide: BorderSide(
                                          color: _model.dateOfBirthError != null
                                              ? FlutterFlowTheme.of(context)
                                                  .error
                                              : FlutterFlowTheme.of(context)
                                                  .alternate,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    if (_model.dateOfBirthError != null)
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 6.0, 0.0, 0.0),
                                        child: Text(
                                          _model.dateOfBirthError!,
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                font: GoogleFonts.poppins(),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),

                                SizedBox(height: isSmallScreen ? 12.0 : 15.0),

                                // Name field
                                TextFormField(
                                  key: _nameFieldKey,
                                  controller: _model.textController1,
                                  focusNode: _model.textFieldFocusNode1,
                                  autofocus: false,
                                  textCapitalization: TextCapitalization.words,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    hintText: 'Jannet Kutemba',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: isSmallScreen ? 18.0 : 20.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16.0 : 20.0,
                                      vertical: isSmallScreen ? 14.0 : 16.0,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(),
                                        letterSpacing: 0.0,
                                        fontSize: isSmallScreen ? 14.0 : null,
                                      ),
                                  validator: _model.textController1Validator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.words),
                                        );
                                      }),
                                  ],
                                ),

                                SizedBox(height: isSmallScreen ? 12.0 : 15.0),

                                // Mobile Number field
                                TextFormField(
                                  key: _phoneFieldKey,
                                  controller: _model.textController2,
                                  focusNode: _model.textFieldFocusNode2,
                                  autofocus: false,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    hintText: '0977123456',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    prefixIcon: Icon(
                                      Icons.phone_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: isSmallScreen ? 18.0 : 20.0,
                                    ),
                                    counterText: '',
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16.0 : 20.0,
                                      vertical: isSmallScreen ? 14.0 : 16.0,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(),
                                        letterSpacing: 0.0,
                                        fontSize: isSmallScreen ? 14.0 : null,
                                      ),
                                  maxLength: 13,
                                  keyboardType: TextInputType.phone,
                                  validator: _model.textController2Validator
                                      .asValidator(context),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9+]'))
                                  ],
                                ),

                                SizedBox(height: isSmallScreen ? 12.0 : 15.0),

                                // Occupation field
                                TextFormField(
                                  key: _occupationFieldKey,
                                  controller: _model.textController3,
                                  focusNode: _model.textFieldFocusNode3,
                                  autofocus: false,
                                  textCapitalization: TextCapitalization.words,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Occupation',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    hintText: 'Teacher',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    prefixIcon: Icon(
                                      Icons.work_outline_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: isSmallScreen ? 18.0 : 20.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16.0 : 20.0,
                                      vertical: isSmallScreen ? 14.0 : 16.0,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(),
                                        letterSpacing: 0.0,
                                        fontSize: isSmallScreen ? 14.0 : null,
                                      ),
                                  validator: _model.textController3Validator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.words),
                                        );
                                      }),
                                  ],
                                ),

                                SizedBox(height: isSmallScreen ? 12.0 : 15.0),

                                // Address field
                                TextFormField(
                                  key: _addressFieldKey,
                                  controller: _model.textController4,
                                  focusNode: _model.textFieldFocusNode4,
                                  autofocus: false,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Address',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    hintText: 'Libala Stage 1, Lusaka, Zambia',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 13.0 : null,
                                        ),
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: isSmallScreen ? 18.0 : 20.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16.0 : 20.0,
                                      vertical: isSmallScreen ? 14.0 : 16.0,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(),
                                        letterSpacing: 0.0,
                                        fontSize: isSmallScreen ? 14.0 : null,
                                      ),
                                  validator: _model.textController4Validator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.sentences),
                                        );
                                      }),
                                  ],
                                ),

                                SizedBox(height: isSmallScreen ? 20.0 : 30.0),

                                // Submit button
                                FFButtonWidget(
                                  onPressed: _model.isSaving
                                      ? null
                                      : () async {
                                          final isValid =
                                              await _validateAndFocusFirstInvalidField(
                                                  context);
                                          if (!isValid) {
                                            return;
                                          }

                                          final userRef = currentUserReference;
                                          final authId = currentUserUid;
                                          if (userRef == null ||
                                              authId.isEmpty) {
                                            _showSnackBar(
                                                'Your session expired. Please log in again.');
                                            return;
                                          }

                                          safeSetState(() {
                                            _model.isSaving = true;
                                          });

                                          try {
                                            final existingMotherRecords =
                                                await queryMotherRecordOnce(
                                              queryBuilder: (motherRecord) =>
                                                  motherRecord.where(
                                                'user_Id',
                                                isEqualTo: userRef,
                                              ),
                                              singleRecord: true,
                                            );
                                            final motherRef =
                                                createAccountMotherRecord
                                                        ?.reference ??
                                                    (existingMotherRecords
                                                            .isNotEmpty
                                                        ? existingMotherRecords
                                                            .first.reference
                                                        : MotherRecord
                                                            .collection
                                                            .doc(authId));
                                            final name = _model
                                                .textController1.text
                                                .trim();
                                            final phoneNumber = _model
                                                .textController2.text
                                                .trim();
                                            final occupation = _model
                                                .textController3.text
                                                .trim();
                                            final address = _model
                                                .textController4.text
                                                .trim();
                                            final dateOfBirth =
                                                _model.datePicked!;

                                            await userRef
                                                .update(createUserRecordData(
                                              email: currentUserEmail,
                                              displayName: name,
                                              phoneNumber: phoneNumber,
                                            ));

                                            await motherRef.set(
                                              createMotherRecordData(
                                                dateOfBirth: dateOfBirth,
                                                occupation: occupation,
                                                address: address,
                                                userId: userRef,
                                                name: name,
                                                phoneNumber: phoneNumber,
                                                motherId: motherRef.id,
                                              ),
                                              const SetOptions(merge: true),
                                            );

                                            FFAppState().motherRef = motherRef;

                                            _showSnackBar(
                                              'Account created! Welcome to Dawa Mom $name',
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                            );

                                            if (context.mounted) {
                                              context.pushNamed(
                                                  HomeWidget.routeName);
                                            }
                                          } catch (error, stackTrace) {
                                            debugPrint(
                                                'Complete account save failed: $error');
                                            debugPrintStack(
                                                stackTrace: stackTrace);
                                            _showSnackBar(
                                              'We could not complete your account. Please try again.',
                                            );
                                          } finally {
                                            if (mounted) {
                                              safeSetState(() {
                                                _model.isSaving = false;
                                              });
                                            }
                                          }
                                        },
                                  text: _model.isSaving
                                      ? 'Completing...'
                                      : 'Complete Account',
                                  iconData: Icons.check_rounded,
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: isSmallScreen ? 45.0 : 50.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      isSmallScreen ? 16.0 : 24.0,
                                      0.0,
                                      isSmallScreen ? 16.0 : 24.0,
                                      0.0,
                                    ),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.poppins(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          letterSpacing: 0.0,
                                          fontSize: isSmallScreen ? 14.0 : null,
                                        ),
                                    borderSide: BorderSide(
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),

                                // Bottom padding for better scrollability
                                SizedBox(height: isSmallScreen ? 20.0 : 30.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InvalidField {
  const _InvalidField({
    required this.key,
    required this.message,
    this.focusNode,
  });

  final GlobalKey key;
  final String message;
  final FocusNode? focusNode;
}
