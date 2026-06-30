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
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360; // For very small phones

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
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
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
                                color: FlutterFlowTheme.of(context).primaryText,
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
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
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
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : 20.0,
                  vertical: isSmallScreen ? 8.0 : 0.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image with responsive sizing
                    Container(
                      height: isSmallScreen
                          ? screenHeight * 0.2
                          : screenHeight * 0.25,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/Status_update-pana.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                    
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
                              fontSize: isSmallScreen ? 20.0 : 24.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                    
                    // Description with responsive font size and padding
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4.0 : 0.0,
                      ),
                      child: Text(
                        'From prenatal check-ups to postnatal care, create your account to access a wide range of services tailored for expectant mothers. Fill in your details below to get started.',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.poppins(),
                              fontSize: isSmallScreen ? 13.0 : 15.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 20.0 : 24.0),
                    
                    // Form section
                    Form(
                      key: _model.formKey,
                      autovalidateMode: AutovalidateMode.always,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Date of Birth button
                          FFButtonWidget(
                            onPressed: () async {
                              final _datePickedDate = await showDatePicker(
                                context: context,
                                initialDate: getCurrentTimestamp,
                                firstDate: DateTime(1900),
                                lastDate: getCurrentTimestamp,
                              );

                              if (_datePickedDate != null) {
                                safeSetState(() {
                                  _model.datePicked = DateTime(
                                    _datePickedDate.year,
                                    _datePickedDate.month,
                                    _datePickedDate.day,
                                  );
                                });
                              } else if (_model.datePicked != null) {
                                safeSetState(() {
                                  _model.datePicked = getCurrentTimestamp;
                                });
                              }
                            },
                            text: () {
                              if (_model.datePicked != null) {
                                return dateTimeFormat("yMMMd", _model.datePicked);
                              } else if (_model.datePicked == null) {
                                return 'Date of birth';
                              } else {
                                return 'Date of birth';
                              }
                            }(),
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
                              color:
                                  FlutterFlowTheme.of(context).primaryBackground,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.poppins(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontSize: isSmallScreen ? 13.0 : null,
                                  ),
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 12.0 : 15.0),
                          
                          // Name field
                          TextFormField(
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
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor:
                                  FlutterFlowTheme.of(context).primaryBackground,
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
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor:
                                  FlutterFlowTheme.of(context).primaryBackground,
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
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            validator: _model.textController2Validator
                                .asValidator(context),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                            ],
                          ),
                          
                          SizedBox(height: isSmallScreen ? 12.0 : 15.0),
                          
                          // Occupation field
                          TextFormField(
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
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor:
                                  FlutterFlowTheme.of(context).primaryBackground,
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
                            controller: _model.textController4,
                            focusNode: _model.textFieldFocusNode4,
                            autofocus: false,
                            textCapitalization: TextCapitalization.sentences,
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
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor:
                                  FlutterFlowTheme.of(context).primaryBackground,
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
                            onPressed: () async {
                              if (_model.formKey.currentState == null ||
                                  !_model.formKey.currentState!.validate()) {
                                return;
                              }
                              if (_model.datePicked == null) {
                                return;
                              }
                              if ((_model.datePicked != null) &&
                                  (_model.textController1.text != '') &&
                                  (_model.textController2.text != '') &&
                                  (_model.textController3.text != '') &&
                                  (_model.textController4.text != '')) {
                                await createAccountMotherRecord!.reference
                                    .update(createMotherRecordData(
                                  dateOfBirth: _model.datePicked,
                                  occupation: _model.textController3.text,
                                  address: _model.textController4.text,
                                  name: _model.textController1.text,
                                  phoneNumber: _model.textController2.text,
                                  motherId: createAccountMotherRecord.reference.id,
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Account created! Welcome to Dawa Mom ${_model.textController1.text}',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 4000),
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).secondary,
                                  ),
                                );

                                context.pushNamed(HomeWidget.routeName);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please make sure that you have entered all the fields as well as entered in your date of birth',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                    ),
                                    duration: Duration(milliseconds: 4000),
                                    backgroundColor: Color(0xFFF1385A),
                                  ),
                                );
                              }
                            },
                            text: 'Submit',
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
                              textStyle:
                                  FlutterFlowTheme.of(context).titleSmall.override(
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}