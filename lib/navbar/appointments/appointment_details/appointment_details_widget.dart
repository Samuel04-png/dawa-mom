import '/backend/backend.dart';
import '/components/no_data_generic/no_data_generic_widget.dart';
import '/components/shimmer/shimmer_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appointment_details_model.dart';
export 'appointment_details_model.dart';

class AppointmentDetailsWidget extends StatefulWidget {
  const AppointmentDetailsWidget({
    super.key,
    required this.encounterDets,
  });

  final DocumentReference? encounterDets;

  static String routeName = 'AppointmentDetails';
  static String routePath = '/appointmentDetails';

  @override
  State<AppointmentDetailsWidget> createState() =>
      _AppointmentDetailsWidgetState();
}

class _AppointmentDetailsWidgetState extends State<AppointmentDetailsWidget> {
  late AppointmentDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AppointmentDetailsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EncounterRecord>(
      stream: EncounterRecord.getDocument(widget.encounterDets!),
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

        final appointmentDetailsEncounterRecord = snapshot.data!;

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
              leading: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 60.0,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 30.0,
                ),
                onPressed: () async {
                  context.pop();
                },
              ),
              title: Text(
                'Apppointment Details',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.poppins(
                        fontWeight: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontWeight,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 22.0,
                      letterSpacing: 0.0,
                      fontWeight: FlutterFlowTheme.of(context)
                          .headlineMedium
                          .fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                    ),
              ),
              actions: [],
              centerTitle: true,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 0.0, 0.0),
                            child: StreamBuilder<DoctorRecord>(
                              stream: DoctorRecord.getDocument(
                                  appointmentDetailsEncounterRecord.doctorId!),
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Container(
                                    height: 30.0,
                                    child: ShimmerWidget(),
                                  );
                                }

                                final textDoctorRecord = snapshot.data!;

                                return Text(
                                  'Appointment with ${textDoctorRecord.name}',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 4.0, 0.0, 0.0),
                            child: Text(
                              '${dateTimeFormat("MMMMEEEEd", appointmentDetailsEncounterRecord.date)} at ${appointmentDetailsEncounterRecord.time}',
                              textAlign: TextAlign.start,
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 4.0, 0.0, 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: valueOrDefault<Color>(
                                  () {
                                    if (appointmentDetailsEncounterRecord
                                            .status ==
                                        'completed') {
                                      return Color(0xFF2DAC5C);
                                    } else if (appointmentDetailsEncounterRecord
                                            .status ==
                                        'canceled') {
                                      return FlutterFlowTheme.of(context).error;
                                    } else {
                                      return FlutterFlowTheme.of(context)
                                          .warning;
                                    }
                                  }(),
                                  FlutterFlowTheme.of(context).accent2,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  appointmentDetailsEncounterRecord.status,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            height: 32.0,
                            thickness: 1.0,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 4.0, 0.0, 12.0),
                            child: Text(
                              'Appointment Result Details',
                              textAlign: TextAlign.start,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.poppins(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Stack(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              children: [
                                if (appointmentDetailsEncounterRecord.status ==
                                    'completed')
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        if (Navigator.of(context).canPop()) {
                                          context.pop();
                                        }
                                        context.pushNamed(
                                          EncounterDetailsWidget.routeName,
                                          queryParameters: {
                                            'encounterDets': serializeParam(
                                              widget.encounterDets,
                                              ParamType.DocumentReference,
                                            ),
                                          }.withoutNulls,
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        constraints: BoxConstraints(
                                          maxWidth: 570.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 12.0, 16.0, 12.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 12.0, 0.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Next Visit: ${dateTimeFormat("MMMMEEEEd", appointmentDetailsEncounterRecord.nextVisit)}',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLarge
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    4.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          appointmentDetailsEncounterRecord
                                                              .comment,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelMedium
                                                              .override(
                                                                font: GoogleFonts
                                                                    .poppins(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
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
                                if (appointmentDetailsEncounterRecord.status !=
                                    'completed')
                                  Container(
                                    height: 200.0,
                                    decoration: BoxDecoration(),
                                    child: wrapWithModel(
                                      model: _model.noDataGenericModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: NoDataGenericWidget(
                                        message:
                                            'No encounter result available yet',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (appointmentDetailsEncounterRecord.status ==
                            'scheduled')
                          Expanded(
                            child: FFButtonWidget(
                              onPressed: () async {
                                var confirmDialogResponse =
                                    await showDialog<bool>(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return AlertDialog(
                                              title: Text('Cancel Appointment'),
                                              content: Text(
                                                  'Are you sure you want to cancel this appointment? This action cannot be undone'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext,
                                                          false),
                                                  child: Text('No. Leave it'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext,
                                                          true),
                                                  child: Text('Yes. Cancel it'),
                                                ),
                                              ],
                                            );
                                          },
                                        ) ??
                                        false;
                                if (confirmDialogResponse) {
                                  await widget.encounterDets!
                                      .update(createEncounterRecordData(
                                    status: 'canceled',
                                  ));

                                  context.pushNamed(EncountersWidget.routeName);
                                }
                              },
                              text: 'Cancel Appointment',
                              options: FFButtonOptions(
                                height: 40.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).accent3,
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
                                      color: FlutterFlowTheme.of(context).error,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
