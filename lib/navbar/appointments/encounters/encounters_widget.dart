import '/backend/backend.dart';
import '/components/appointment_component/appointment_component_widget.dart';
import '/components/no_appointments_comp/no_appointments_comp_widget.dart';
import '/components/shimmer/shimmer_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'encounters_model.dart';
export 'encounters_model.dart';

class EncountersWidget extends StatefulWidget {
  const EncountersWidget({super.key});

  static String routeName = 'Encounters';
  static String routePath = '/encounters';

  @override
  State<EncountersWidget> createState() => _EncountersWidgetState();
}

class _EncountersWidgetState extends State<EncountersWidget> {
  late EncountersModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EncountersModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
          title: Text(
            'My Appointments',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            child: StreamBuilder<List<EncounterRecord>>(
              stream: queryEncounterRecord(
                queryBuilder: (encounterRecord) => encounterRecord
                    .where(
                      'mother_id',
                      isEqualTo: FFAppState().motherRef,
                    )
                    // 🔴 HIDE CANCELLED APPOINTMENTS
                    .where(
                      'status',
                      isNotEqualTo: 'canceled',
                    ),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return ShimmerWidget();
                }

                final listViewEncounterRecordList = snapshot.data!;

                if (listViewEncounterRecordList.isEmpty) {
                  return const Center(
                    child: NoAppointmentsCompWidget(),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: listViewEncounterRecordList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (context, listViewIndex) {
                    final encounter =
                        listViewEncounterRecordList[listViewIndex];

                    return StreamBuilder<List<DoctorRecord>>(
                      stream: queryDoctorRecord(
                        queryBuilder: (doctorRecord) => doctorRecord.where(
                          'doctor_id',
                          isEqualTo: encounter.doctorId?.id,
                        ),
                        singleRecord: true,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return ShimmerWidget();
                        }

                        if (snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final doctor = snapshot.data!.first;

                        return InkWell(
                          onTap: () {
                            context.pushNamed(
                              AppointmentDetailsWidget.routeName,
                              queryParameters: {
                                'encounterDets': serializeParam(
                                  encounter.reference,
                                  ParamType.DocumentReference,
                                ),
                              }.withoutNulls,
                            );
                          },
                          child: wrapWithModel(
                            model: _model.appointmentComponentModels.getModel(
                              encounter.reference.id,
                              listViewIndex,
                            ),
                            updateCallback: () => safeSetState(() {}),
                            child: AppointmentComponentWidget(
                              key: Key(
                                'Key_${encounter.reference.id}',
                              ),
                              date: dateTimeFormat("MMMEd", encounter.date!),
                              time: encounter.time,
                              name: doctor.name,
                              status: encounter.status,
                              doctorID: encounter.doctorId?.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
