import 'dart:async';

import 'package:dawa_mom/navbar/appointments/appointment_details/appointment_details_widget.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/components/branding/dawa_mom_logo.dart';
import '/components/responsive/responsive_home_dashboard.dart';
import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/components/responsive/upcoming_appointment_section.dart';
import '/components/shimmer/shimmer_widget.dart';
import '/features/settings/dawa_mom_settings_page.dart';
import '/features/pregnancy/presentation/pregnancy_what_to_expect.dart';
import '/features/period_tracker/presentation/period_cycle_status_card.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/voice_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'home_model.dart';
export 'home_model.dart';
import 'dart:math' as math;

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'Home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> with TickerProviderStateMixin {
  late HomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  bool get _usesDedicatedAppointments => true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {});

    animationsMap.addAll({
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 150.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 150.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 450.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 1050.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 1200.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 1200.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        applyInitialState: true,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 900.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 1500.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnActionTriggerAnimation': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(1.02, 1.02),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: Offset(1.02, 1.02),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'buttonOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 1000.0.ms,
            duration: 1000.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

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
        List<MotherRecord> homeMotherRecordList = snapshot.data!;
        final homeMotherRecord =
            homeMotherRecordList.isNotEmpty ? homeMotherRecordList.first : null;
        final currentMotherRef = homeMotherRecord?.reference;
        if (FFAppState().motherRef != currentMotherRef) {
          FFAppState().motherRef = currentMotherRef;
        }

        if (_usesDedicatedAppointments) {
          return DawaMomResponsiveDashboard(
            onOpenRudo: () => DawaMomResponsiveShell.openRudo(context),
          );
        }

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(70.0),
              child: AppBar(
                backgroundColor:
                    FlutterFlowTheme.of(context).secondaryBackground,
                automaticallyImplyLeading: false,
                title: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(DawaMomSettingsPage.routeName);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100.0),
                            child: Image.asset(
                              'assets/images/transparent assets/Frame_41.png',
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        RichText(
                          textScaler: MediaQuery.of(context).textScaler,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Hi, ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextSpan(
                                text: valueOrDefault<String>(
                                  homeMotherRecord?.name,
                                  'there',
                                ),
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18.0,
                                  fontFamily: 'Poppins',
                                ),
                              )
                            ],
                            style: TextStyle(
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 10.0)),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      // Show confirmation dialog
                      bool? confirmLogout = await showDialog<bool>(
                        context: context,
                        builder: (alertDialogContext) {
                          return AlertDialog(
                            title: Text('Logout'),
                            content: Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(alertDialogContext, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(alertDialogContext, true),
                                child: Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmLogout == true) {
                        // Sign out from Supabase authentication
                        GoRouter.of(context).prepareAuthEvent();
                        await authManager.signOut();
                        GoRouter.of(context).clearRedirectLocation();

                        // Redirect to login page
                        context.goNamedAuth(
                          'Login',
                          context.mounted,
                          extra: <String, dynamic>{
                            kTransitionInfoKey: TransitionInfo(
                              hasTransition: true,
                              transitionType: PageTransitionType.fade,
                            ),
                          },
                        );
                      }
                    },
                  ),
                ],
                centerTitle: false,
                toolbarHeight: 70.0,
                elevation: 0.0,
              ),
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 20.0),
                      child: Text(
                        dateTimeFormat("yMMMd", getCurrentTimestamp),
                        style: FlutterFlowTheme.of(context).titleLarge.copyWith(
                              letterSpacing: 0.0,
                              fontFamily: 'Poppins',
                            ),
                      ).animateOnPageLoad(
                          animationsMap['textOnPageLoadAnimation1']!),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      child: _usesDedicatedAppointments
                          ? UpcomingAppointmentSection(compact: true)
                          : Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Appointment',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.0,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animateOnPageLoad(
                                    animationsMap['textOnPageLoadAnimation2']!),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child:
                                          StreamBuilder<List<EncounterRecord>>(
                                        stream: queryEncounterRecord(
                                          queryBuilder: (encounterRecord) =>
                                              encounterRecord
                                                  .where(
                                                    'mother_id',
                                                    isEqualTo:
                                                        FFAppState().motherRef,
                                                  )
                                                  .where(
                                                    'status',
                                                    isEqualTo: 'scheduled',
                                                  ),
                                          singleRecord: true,
                                        ),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return ShimmerWidget();
                                          }

                                          List<EncounterRecord>
                                              containerEncounterRecordList =
                                              snapshot.data!;
                                          final containerEncounterRecord =
                                              containerEncounterRecordList
                                                      .isNotEmpty
                                                  ? containerEncounterRecordList
                                                      .first
                                                  : null;

                                          // Show no data image when there's no appointment
                                          if (containerEncounterRecord ==
                                              null) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  height:
                                                      200.0, // Adjust height as needed
                                                  width: double.infinity,
                                                  child: ClipRect(
                                                    child: Image.asset(
                                                      'assets/images/transparent assets/No_data-pana.png',
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Center(
                                                          child: Text(
                                                            'No upcoming appointments',
                                                            style: TextStyle(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              fontSize: 14.0,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'No upcoming appointments',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    fontSize: 14.0,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ],
                                            );
                                          }

                                          // Show appointment details when there is data
                                          return Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Expanded(
                                                  child: StreamBuilder<
                                                      DoctorRecord>(
                                                    stream: DoctorRecord
                                                        .getDocument(
                                                            containerEncounterRecord
                                                                .doctorId!),
                                                    builder:
                                                        (context, snapshot) {
                                                      // Customize what your widget looks like when it's loading.
                                                      if (!snapshot.hasData) {
                                                        return ShimmerWidget();
                                                      }

                                                      final containerDoctorRecord =
                                                          snapshot.data!;

                                                      return InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          context.pushNamed(
                                                            AppointmentDetailsWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'encounterDets':
                                                                  serializeParam(
                                                                containerEncounterRecord
                                                                    .reference,
                                                                ParamType
                                                                    .DocumentReference,
                                                              ),
                                                            }.withoutNulls,
                                                          );
                                                        },
                                                        child: Container(
                                                          constraints:
                                                              BoxConstraints(
                                                            maxWidth: 400.0,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            border: Border.all(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .alternate,
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    16.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    // LEFT SIDE (Avatar + Name)
                                                                    Expanded(
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          const DawaMomLogo(
                                                                            variant:
                                                                                DawaMomLogoVariant.compact,
                                                                            size:
                                                                                30,
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 8),

                                                                          // 🔑 THIS IS THE IMPORTANT PART
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              containerDoctorRecord.name,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: const TextStyle(
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),

                                                                    const SizedBox(
                                                                        width:
                                                                            10),

                                                                    // RIGHT SIDE (Status badge)
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: valueOrDefault<
                                                                            Color>(
                                                                          () {
                                                                            if (containerEncounterRecord.status ==
                                                                                'completed') {
                                                                              return const Color(0xFF2DAC5C);
                                                                            } else if (containerEncounterRecord.status ==
                                                                                'canceled') {
                                                                              return FlutterFlowTheme.of(context).error;
                                                                            } else {
                                                                              return FlutterFlowTheme.of(context).warning;
                                                                            }
                                                                          }(),
                                                                          FlutterFlowTheme.of(context)
                                                                              .accent2,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            containerEncounterRecord.status,
                                                                            'Pending',
                                                                          ),
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondaryBackground,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Divider(
                                                                  thickness:
                                                                      1.0,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .alternate,
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .calendar_month_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                    RichText(
                                                                      textScaler:
                                                                          MediaQuery.of(context)
                                                                              .textScaler,
                                                                      text:
                                                                          TextSpan(
                                                                        children: [
                                                                          TextSpan(
                                                                            text:
                                                                                dateTimeFormat(
                                                                              "MMMMEEEEd",
                                                                              containerEncounterRecord.date!,
                                                                            ),
                                                                            style:
                                                                                TextStyle(
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.w600,
                                                                              fontFamily: 'Poppins',
                                                                            ),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                ' - ',
                                                                            style:
                                                                                TextStyle(),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                containerEncounterRecord.time,
                                                                            style:
                                                                                TextStyle(),
                                                                          )
                                                                        ],
                                                                        style:
                                                                            TextStyle(
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontFamily:
                                                                              'Poppins',
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ).animateOnPageLoad(
                                                          animationsMap[
                                                              'containerOnPageLoadAnimation1']!);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(-1.0, 0.0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 0.0, 0.0),
                        child: Text(
                          'What to expect',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                            fontFamily: 'Poppins',
                          ),
                        ).animateOnPageLoad(
                            animationsMap['textOnPageLoadAnimation3']!),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: PregnancyWhatToExpectLoader(compact: true),
                    ),
                    const SizedBox(height: 14.0),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: PeriodCycleStatusLoader(),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 20.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  _model.appointmentFound =
                                      await queryEncounterRecordOnce(
                                    queryBuilder: (encounterRecord) =>
                                        encounterRecord
                                            .where(
                                              'mother_id',
                                              isEqualTo: FFAppState().motherRef,
                                            )
                                            .where(
                                              'status',
                                              isEqualTo: 'scheduled',
                                            ),
                                    singleRecord: true,
                                  ).then((s) => s.firstOrNull);
                                  if (_model.appointmentFound != null) {
                                    await showDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: Text(
                                              'Cannot schedule multiple appointments'),
                                          content: Text(
                                              'You currently have an appointment scheduled. Please cancel or fulfil the appointment to book another'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  alertDialogContext),
                                              child: Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return GestureDetector(
                                          onTap: () {
                                            FocusScope.of(context).unfocus();
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                          },
                                          child: Padding(
                                            padding: MediaQuery.viewInsetsOf(
                                                context),
                                            child: BookingBottomSheetWidget(),
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  }

                                  safeSetState(() {});
                                },
                                text: 'Schedule Appointment',
                                options: FFButtonOptions(
                                  height: 40.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      24.0, 0.0, 24.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: FlutterFlowTheme.of(context).primary,
                                  textStyle: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontFamily: 'Poppins',
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.transparent,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ).animateOnPageLoad(
                                  animationsMap['buttonOnPageLoadAnimation']!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ].addToStart(SizedBox(height: 15.0)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// AI Chat Modal Widget
class AIChatModal extends StatefulWidget {
  final String userPhoneNumber;
  final String userName;

  const AIChatModal({
    super.key,
    required this.userPhoneNumber,
    required this.userName,
    this.onClose,
    this.onMinimize,
  });

  final VoidCallback? onClose;
  final VoidCallback? onMinimize;

  @override
  State<AIChatModal> createState() => _SupabaseAIChatModalState();
}

enum _VoiceModeState { idle, listening, processing, speaking }

class _SupabaseAIChatModalState extends State<AIChatModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _messageHashes = {};
  final VoiceService _voiceService = VoiceService();
  late final AnimationController _voiceController;
  bool _isHandlingVoiceTranscript = false;

  bool _isLoading = false;
  bool _isConnected = true;
  bool _isInitializing = true;
  bool _isSending = false;
  bool _isVoiceMode = false;
  _VoiceModeState _voiceState = _VoiceModeState.idle;
  String _voiceTranscriptPreview = '';
  String? _voiceErrorMessage;
  String? _sessionId;

  SupabaseDatabase get _database => SupabaseDatabase.instance;

  static const _suggestions = [
    'What symptoms are normal this week?',
    'How can I prepare for my next appointment?',
    'What foods should I focus on today?',
    'Help me understand my period tracker.',
  ];

  @override
  void initState() {
    super.initState();
    _voiceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _messageController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _initializeChat();
  }

  @override
  void dispose() {
    unawaited(_voiceService.dispose());
    _voiceController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      setState(() {
        _isConnected = false;
        _isInitializing = false;
      });
      return;
    }

    try {
      await _loadCurrentSession(userId);
      setState(() {
        _isConnected = true;
        _isInitializing = false;
      });
      _scrollToBottom();
    } catch (error) {
      debugPrint('Rudo Supabase initialization failed: $error');
      setState(() {
        _isConnected = false;
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadCurrentSession(String userId) async {
    final sessions = await _database.client
        .from('chat_sessions')
        .select()
        .eq('profile_id', userId)
        .order('updated_at', ascending: false)
        .limit(1);

    if ((sessions as List).isEmpty) {
      return;
    }

    final session = Map<String, dynamic>.from(sessions.first as Map);
    _sessionId = session['id']?.toString();
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }

    final rows = await _database.client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    final loadedMessages = (rows as List)
        .map((row) {
          final data = Map<String, dynamic>.from(row as Map);
          return ChatMessage(
            id: data['id']?.toString() ?? '',
            text: data['content']?.toString() ?? '',
            isUser: data['role'] == 'user',
            timestamp:
                DateTime.tryParse(data['created_at']?.toString() ?? '') ??
                    DateTime.now(),
          );
        })
        .where((message) => message.text.isNotEmpty)
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _messages
        ..clear()
        ..addAll(loadedMessages);
      _messageHashes
        ..clear()
        ..addAll(loadedMessages.map(_generateMessageHash));
    });
  }

  Future<String?> _sendMessage(String message) async {
    if (_isSending || _isInitializing) {
      return null;
    }

    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      await _enterVoiceMode();
      return null;
    }

    final userId = currentUserUid;
    if (userId.isEmpty) {
      setState(() => _isConnected = false);
      return null;
    }

    final clientMessageId = '${DateTime.now().microsecondsSinceEpoch}-$userId';
    final localUserMessage = ChatMessage(
      id: clientMessageId,
      text: trimmedMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isSending = true;
      _isLoading = true;
    });
    _messageController.clear();
    _addMessage(localUserMessage);
    _scrollToBottom();

    try {
      final response = await _database.client.functions.invoke(
        'rudo-chat',
        body: {
          'message': trimmedMessage,
          if (_sessionId != null) 'session_id': _sessionId,
          'client_message_id': clientMessageId,
          'metadata': {
            'phone_number': widget.userPhoneNumber,
            'user_name': widget.userName,
            'source': 'flutter',
          },
        },
      ).timeout(const Duration(seconds: 45));

      final responseData = response.data;
      final data = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : <String, dynamic>{};

      if (data['session_id'] != null) {
        _sessionId = data['session_id'].toString();
      }

      final reply =
          data['reply']?.toString() ?? data['response']?.toString() ?? '';
      if (reply.isNotEmpty) {
        _addMessage(ChatMessage(
          id: '${clientMessageId}-assistant',
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }

      await _loadMessages();
      if (mounted) {
        setState(() => _isConnected = true);
      }
      return reply.isNotEmpty ? reply : null;
    } catch (error) {
      debugPrint('Rudo message send failed: $error');
      _addMessage(ChatMessage(
        id: '$clientMessageId-error',
        text:
            'Rudo is having trouble reaching the assistant service. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      if (mounted) {
        setState(() => _isConnected = false);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isLoading = false;
          _voiceState = _VoiceModeState.idle;
        });
      }
      _scrollToBottom();
    }
  }

  void _addMessage(ChatMessage message) {
    final hash = _generateMessageHash(message);
    if (_messageHashes.contains(hash) || !mounted) {
      return;
    }
    setState(() {
      _messageHashes.add(hash);
      _messages.add(message);
    });
  }

  String _generateMessageHash(ChatMessage message) {
    final second = message.timestamp.millisecondsSinceEpoch ~/ 1000;
    return '${message.text.hashCode}_${message.isUser}_$second';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enterVoiceMode() async {
    if (_isInitializing || _isSending) {
      return;
    }
    setState(() {
      _isVoiceMode = true;
      _voiceState = _VoiceModeState.listening;
      _voiceTranscriptPreview = '';
      _voiceErrorMessage = null;
    });
    try {
      await _voiceService.startListening(
        language: _currentVoiceLanguage(),
        onFinalResult: _handleVoiceTranscript,
        onPartialResult: _updateVoiceTranscriptPreview,
      );
    } catch (error) {
      debugPrint('Voice listening failed: $error');
      _showVoiceError(
        'Voice mode could not start. Please check microphone permission.',
      );
      if (mounted) {
        setState(() {
          _isVoiceMode = false;
          _voiceState = _VoiceModeState.idle;
          _voiceErrorMessage = null;
        });
      }
    }
  }

  Future<void> _exitVoiceMode() async {
    if (mounted) {
      setState(() {
        _isVoiceMode = false;
        _voiceState = _VoiceModeState.idle;
        _voiceTranscriptPreview = '';
        _voiceErrorMessage = null;
      });
    }
    await _voiceService.stopPlayback();
    await _voiceService.stopAndTranscribe();
  }

  Future<void> _handleVoiceTranscript(String recognizedText) async {
    if (!mounted ||
        !_isVoiceMode ||
        _isHandlingVoiceTranscript ||
        recognizedText.trim().isEmpty) {
      return;
    }
    _isHandlingVoiceTranscript = true;
    try {
      setState(() {
        _voiceState = _VoiceModeState.processing;
        _voiceTranscriptPreview = recognizedText.trim();
        _voiceErrorMessage = null;
      });
      await _voiceService.stopAndTranscribe();
      if (!mounted || !_isVoiceMode) {
        return;
      }
      final reply = await _sendMessage(recognizedText);
      if (reply != null && reply.isNotEmpty) {
        await _speakVoiceReply(reply);
      }
      if (mounted && _isVoiceMode) {
        await _restartVoiceListening();
      }
    } finally {
      _isHandlingVoiceTranscript = false;
    }
  }

  void _updateVoiceTranscriptPreview(String recognizedText) {
    if (!mounted || !_isVoiceMode || recognizedText.trim().isEmpty) {
      return;
    }
    setState(() {
      _voiceTranscriptPreview = recognizedText.trim();
      _voiceErrorMessage = null;
    });
  }

  Future<void> _speakVoiceReply(String reply) async {
    if (!mounted || !_isVoiceMode) {
      return;
    }
    setState(() => _voiceState = _VoiceModeState.speaking);
    try {
      await _voiceService.speakText(
        reply,
        _currentVoiceLanguage(),
      );
    } catch (error) {
      debugPrint('Rudo voice playback failed: $error');
      if (mounted) {
        setState(() {
          _voiceState = _VoiceModeState.idle;
          _voiceErrorMessage =
              'Rudo replied, but the voice audio could not play yet.';
        });
      }
      _addMessage(ChatMessage(
        id: 'voice-playback-error-${DateTime.now().microsecondsSinceEpoch}',
        text:
            'Rudo answered, but voice playback is not ready yet. Please check the ElevenLabs Supabase function and secret.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _restartVoiceListening() async {
    if (!mounted || !_isVoiceMode) {
      return;
    }
    setState(() => _voiceState = _VoiceModeState.listening);
    try {
      await _voiceService.startListening(
        language: _currentVoiceLanguage(),
        onFinalResult: _handleVoiceTranscript,
        onPartialResult: _updateVoiceTranscriptPreview,
      );
    } catch (error) {
      debugPrint('Voice listening restart failed: $error');
      _showVoiceError(
        'Voice mode could not restart. Please check microphone permission.',
      );
      if (mounted) {
        setState(() {
          _isVoiceMode = false;
          _voiceState = _VoiceModeState.idle;
          _voiceErrorMessage = null;
        });
      }
    }
  }

  void _showVoiceError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _currentVoiceLanguage() {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return switch (code) {
      'sn' => 'shona',
      'nd' => 'ndebele',
      'toi' => 'tonga',
      'bem' => 'bemba',
      'loz' => 'lozi',
      'ny' => 'chinyanja',
      _ => 'english',
    };
  }

  Widget _buildMessageList() {
    if (_isInitializing) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary),
        ),
      );
    }

    if (_isVoiceMode) {
      return _buildVoiceMode();
    }

    if (_messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _RudoAvatar(size: 74),
                const SizedBox(height: 18),
                Text(
                  "Hi, I'm Rudo",
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I can help you understand maternal health, prepare for appointments, and find information about your cycle.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose a suggestion below or type your question.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          return _ChatBubble(message: _messages[index]);
        }
        return _TypingIndicator();
      },
    );
  }

  Widget _buildVoiceMode() {
    final statusLabel = switch (_voiceState) {
      _VoiceModeState.processing => 'Thinking...',
      _VoiceModeState.speaking => 'Speaking...',
      _VoiceModeState.idle || _VoiceModeState.listening => 'Listening...',
    };
    final voiceDetail = _voiceErrorMessage ?? _voiceTranscriptPreview.trim();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _VoiceOrb(
                      controller: _voiceController,
                      state: _voiceState,
                    ),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        statusLabel,
                        key: ValueKey(statusLabel),
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (voiceDetail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: ConstrainedBox(
                          key: ValueKey(voiceDetail),
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            voiceDetail,
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _voiceErrorMessage == null
                                  ? FlutterFlowTheme.of(context).secondaryText
                                  : FlutterFlowTheme.of(context).error,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.keyboard),
                label: const Text('End voice mode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FlutterFlowTheme.of(context).primary,
                  side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _exitVoiceMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_isVoiceMode) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestions
              .map((suggestion) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        suggestion,
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primary,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      disabledColor: FlutterFlowTheme.of(context).alternate,
                      side: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      shape: const StadiumBorder(),
                      onPressed: _isInitializing || _isSending
                          ? null
                          : () => _sendMessage(suggestion),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusColor = _isInitializing
        ? Colors.orange
        : _isConnected
            ? Colors.green
            : Colors.red;
    final statusText = _isInitializing
        ? 'Initializing...'
        : _isConnected
            ? 'Connected'
            : 'Limited mode';

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).alternate,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlutterFlowTheme.of(context)
                        .primary
                        .withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/images/female-doctor.png'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rudo',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.onMinimize != null)
                  IconButton(
                    tooltip: 'Minimize',
                    icon: Icon(
                      Icons.remove_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                    onPressed: widget.onMinimize,
                  ),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(
                    Icons.close,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                  onPressed:
                      widget.onClose ?? () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool hasText) {
    final canSend = !_isInitializing && !_isSending;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border(
            top: BorderSide(
              color: FlutterFlowTheme.of(context).alternate,
              width: 1,
            ),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: canSend,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      unawaited(_sendMessage(value));
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ),
              IconButton(
                tooltip: hasText ? 'Send' : 'Start voice',
                constraints: const BoxConstraints.tightFor(
                  width: 46,
                  height: 46,
                ),
                icon: Icon(
                  hasText ? Icons.send : Icons.mic,
                  color: canSend
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).secondaryText,
                ),
                onPressed: !canSend
                    ? null
                    : () {
                        if (hasText) {
                          unawaited(_sendMessage(_messageController.text));
                        } else {
                          unawaited(_enterVoiceMode());
                        }
                      },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNotice() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        border: Border(
          top: BorderSide(
            color: FlutterFlowTheme.of(context).alternate,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 12,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Rudo provides general health information and is not a substitute for professional medical advice.',
              style: TextStyle(
                fontSize: 10,
                color: FlutterFlowTheme.of(context).secondaryText,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isConnected && !_isInitializing)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Rudo assistant service is unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _isInitializing = true);
                      _initializeChat();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildMessageList()),
          if (!_isVoiceMode) _buildSuggestions(),
          if (!_isVoiceMode) _buildInputBar(hasText),
          if (!_isVoiceMode) _buildFooterNotice(),
        ],
      ),
    );
  }
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({
    required this.controller,
    required this.state,
  });

  final AnimationController controller;
  final _VoiceModeState state;

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    final isListening = state == _VoiceModeState.listening;
    final isProcessing = state == _VoiceModeState.processing;
    final isSpeaking = state == _VoiceModeState.speaking;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final eased = Curves.easeInOut.transform(controller.value);
        final listeningScale = 1 + (math.sin(eased * math.pi * 2) * 0.07);
        final speakingScale =
            1 + (math.sin(controller.value * math.pi * 6) * 0.16);
        final restingScale = 1 + (math.sin(eased * math.pi * 2) * 0.035);
        final scale = isSpeaking
            ? speakingScale
            : isListening
                ? listeningScale
                : restingScale;

        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isListening || isSpeaking)
                ...List.generate(3, (index) {
                  final progress = (controller.value + (index * 0.24)) % 1;
                  final pulseSize = isSpeaking ? 92.0 : 76.0;
                  return Transform.scale(
                    scale: 0.65 + (progress * (isSpeaking ? 1.2 : 0.95)),
                    child: Opacity(
                      opacity: (isSpeaking ? 0.42 : 0.32) * (1 - progress),
                      child: Container(
                        width: pulseSize,
                        height: pulseSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              if (isProcessing)
                Transform.rotate(
                  angle: controller.value * math.pi * 2,
                  child: CustomPaint(
                    size: const Size(136, 136),
                    painter: _VoiceSpinnerPainter(primary),
                  ),
                ),
              Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSpeaking ? 96 : 88,
                  height: isSpeaking ? 96 : 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSpeaking ? 30 : 60),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        primary.withValues(alpha: 0.72),
                        FlutterFlowTheme.of(context).secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(
                          alpha: isSpeaking
                              ? 0.38
                              : isListening
                                  ? 0.34
                                  : 0.22,
                        ),
                        blurRadius: isSpeaking || isListening ? 28 : 16,
                        spreadRadius: isSpeaking || isListening ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSpeaking
                        ? Icons.graphic_eq
                        : isProcessing
                            ? Icons.auto_awesome
                            : isListening
                                ? Icons.mic
                                : Icons.graphic_eq,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VoiceSpinnerPainter extends CustomPainter {
  const _VoiceSpinnerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 4.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 1.35,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VoiceSpinnerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// Chat message bubble
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = FlutterFlowTheme.of(context);

    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 52 : 0,
        right: isUser ? 0 : 52,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const _RudoAvatar(size: 30),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? theme.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.grey.shade900,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.secondaryText.withValues(alpha: 0.75),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _RudoAvatar extends StatelessWidget {
  const _RudoAvatar({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: Image.asset('assets/images/female-doctor.png'),
      ),
    );
  }
}

// Typing indicator
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _RudoAvatar(size: 30),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .effect(
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    )
                    .slideY(
                      begin: 0,
                      end: -0.1,
                    ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .effect(
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                      delay: 100.ms,
                    )
                    .slideY(
                      begin: 0,
                      end: -0.1,
                    ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .effect(
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                      delay: 200.ms,
                    )
                    .slideY(
                      begin: 0,
                      end: -0.1,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
