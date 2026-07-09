import '/backend/backend.dart';
import '/components/shimmer/shimmer_widget.dart';
import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'booking_bottom_sheet_model.dart';
export 'booking_bottom_sheet_model.dart';

class BookingBottomSheetWidget extends StatefulWidget {
  const BookingBottomSheetWidget({super.key});

  @override
  State<BookingBottomSheetWidget> createState() =>
      _BookingBottomSheetWidgetState();
}

class _BookingBottomSheetWidgetState extends State<BookingBottomSheetWidget> {
  late BookingBottomSheetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BookingBottomSheetModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  bool get _canBookAppointment =>
      _model.calendarSelectedDay != null &&
      _hasValue(_model.dropDownValue1) &&
      _hasValue(_model.dropDownValue2) &&
      _hasValue(_model.choiceChipsValue);

  void _clearSelectedTime() {
    _model.choiceChipsValue = null;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 3500),
        ),
      );
  }

  Widget _timeSlotMessage(String message) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 0.0),
      child: Text(
        message,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.poppins(),
              color: FlutterFlowTheme.of(context).secondaryText,
              letterSpacing: 0.0,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final canBookAppointment = _canBookAppointment;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isCompactSheet = screenSize.width < 600;
    final sheetMaxWidth = isCompactSheet ? screenSize.width : 780.0;
    final sheetMaxHeight = screenSize.height * (isCompactSheet ? 0.94 : 0.88);
    final topRadius = isCompactSheet ? 20.0 : 24.0;
    final headerHeight = isCompactSheet ? 60.0 : 68.0;
    final horizontalGutter = isCompactSheet ? 16.0 : 24.0;

    return Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: sheetMaxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(0.0),
              bottomRight: Radius.circular(0.0),
              topLeft: Radius.circular(topRadius),
              topRight: Radius.circular(topRadius),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: sheetMaxHeight,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: headerHeight,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(0.0),
                          bottomRight: Radius.circular(0.0),
                          topLeft: Radius.circular(topRadius),
                          topRight: Radius.circular(topRadius),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            horizontalGutter, 0.0, 8.0, 0.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Book an appointment',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      fontSize: isCompactSheet ? 18.0 : 22.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close_rounded,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                size: 22.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, isCompactSheet ? 14.0 : 20.0, 0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 5.0),
                                      child: Text(
                                        'Select Date: ${valueOrDefault<String>(
                                          dateTimeFormat(
                                              "EEEE",
                                              _model
                                                  .calendarSelectedDay?.start),
                                          'date',
                                        )}',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    FlutterFlowCalendar(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      iconColor: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      weekFormat: true,
                                      weekStartsMonday: true,
                                      rowHeight: isCompactSheet ? 54.0 : 64.0,
                                      onChange:
                                          (DateTimeRange? newSelectedDate) {
                                        safeSetState(() {
                                          _model.calendarSelectedDay =
                                              newSelectedDate;
                                          _clearSelectedTime();
                                        });
                                      },
                                      titleStyle: FlutterFlowTheme.of(context)
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                      dayOfWeekStyle: FlutterFlowTheme.of(
                                              context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                          ),
                                      dateStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      selectedDateStyle: FlutterFlowTheme.of(
                                              context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      inactiveDateStyle: FlutterFlowTheme.of(
                                              context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.poppins(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                                .addToStart(SizedBox(width: horizontalGutter))
                                .addToEnd(SizedBox(width: horizontalGutter)),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 5.0),
                                      child: Text(
                                        'Select Clinic',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child:
                                              StreamBuilder<List<ClinicRecord>>(
                                            stream: queryClinicRecord(),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Container(
                                                  height: 30.0,
                                                  child: ShimmerWidget(),
                                                );
                                              }
                                              List<ClinicRecord>
                                                  dropDownClinicRecordList =
                                                  snapshot.data!;

                                              return FlutterFlowDropDown<
                                                  String>(
                                                controller: _model
                                                        .dropDownValueController1 ??=
                                                    FormFieldController<String>(
                                                        null),
                                                options:
                                                    dropDownClinicRecordList
                                                        .map((e) => e.name)
                                                        .toList(),
                                                onChanged: (val) =>
                                                    safeSetState(() {
                                                  _model.dropDownValue1 = val;
                                                  _model.dropDownValue2 = null;
                                                  _model
                                                      .dropDownValueController2
                                                      ?.value = null;
                                                  _clearSelectedTime();
                                                }),
                                                width: 300.0,
                                                height: 50.0,
                                                textStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                hintText: 'Please select...',
                                                icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  size: 24.0,
                                                ),
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                elevation: 2.0,
                                                borderColor:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                borderWidth: 1.0,
                                                borderRadius: 8.0,
                                                margin: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 4.0, 16.0, 4.0),
                                                hidesUnderline: true,
                                                isSearchable: false,
                                                isMultiSelect: false,
                                              );
                                            },
                                          ),
                                        ),
                                      ]
                                          .addToStart(
                                              SizedBox(width: horizontalGutter))
                                          .addToEnd(SizedBox(
                                              width: horizontalGutter)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 5.0),
                                      child: Text(
                                        'Select Clinician',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child:
                                              StreamBuilder<List<DoctorRecord>>(
                                            stream: queryDoctorRecord(
                                              queryBuilder: (doctorRecord) =>
                                                  doctorRecord.where(
                                                'clinic_name',
                                                isEqualTo:
                                                    _model.dropDownValue1,
                                              ),
                                            ),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Container(
                                                  height: 20.0,
                                                  child: ShimmerWidget(),
                                                );
                                              }
                                              List<DoctorRecord>
                                                  dropDownDoctorRecordList =
                                                  snapshot.data!;

                                              return FlutterFlowDropDown<
                                                  String>(
                                                controller: _model
                                                        .dropDownValueController2 ??=
                                                    FormFieldController<String>(
                                                        null),
                                                options: List<String>.from(
                                                    dropDownDoctorRecordList
                                                        .map((e) =>
                                                            e.reference.id)
                                                        .toList()),
                                                optionLabels:
                                                    dropDownDoctorRecordList
                                                        .map((e) => e.name)
                                                        .toList(),
                                                onChanged: (val) =>
                                                    safeSetState(() {
                                                  _model.dropDownValue2 = val;
                                                  _clearSelectedTime();
                                                }),
                                                width: 300.0,
                                                height: 50.0,
                                                textStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                hintText: 'Please select...',
                                                icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  size: 24.0,
                                                ),
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                elevation: 2.0,
                                                borderColor:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                borderWidth: 1.0,
                                                borderRadius: 8.0,
                                                margin: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 4.0, 16.0, 4.0),
                                                hidesUnderline: true,
                                                isSearchable: false,
                                                isMultiSelect: false,
                                              );
                                            },
                                          ),
                                        ),
                                      ]
                                          .addToStart(
                                              SizedBox(width: horizontalGutter))
                                          .addToEnd(SizedBox(
                                              width: horizontalGutter)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 5.0),
                                      child: Text(
                                        'Select Time',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          if (!_hasValue(
                                                  _model.dropDownValue1) ||
                                              !_hasValue(_model.dropDownValue2))
                                            _timeSlotMessage(
                                                'Select a clinic and clinician to see available times.')
                                          else
                                            StreamBuilder<List<DoctorRecord>>(
                                              stream: queryDoctorRecord(
                                                queryBuilder: (doctorRecord) =>
                                                    doctorRecord.where(
                                                  'id',
                                                  isEqualTo:
                                                      _model.dropDownValue2,
                                                ),
                                                singleRecord: true,
                                              ),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return Container(
                                                    height: 20.0,
                                                    child: ShimmerWidget(),
                                                  );
                                                }
                                                List<DoctorRecord>
                                                    containerDoctorRecordList =
                                                    snapshot.data!;
                                                if (containerDoctorRecordList
                                                    .isEmpty) {
                                                  return _timeSlotMessage(
                                                      'No available times for this clinic/clinician/date');
                                                }
                                                final containerDoctorRecord =
                                                    containerDoctorRecordList
                                                        .first;
                                                final timeSlots = functions
                                                    .thirtyMinuteIntervals(
                                                  containerDoctorRecord
                                                      .startTime,
                                                  containerDoctorRecord.endTime,
                                                );

                                                if (timeSlots.isEmpty) {
                                                  return _timeSlotMessage(
                                                      'No available times for this clinic/clinician/date');
                                                }

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    FlutterFlowChoiceChips(
                                                      options: timeSlots
                                                          .map((label) =>
                                                              ChipData(label))
                                                          .toList(),
                                                      onChanged: (val) =>
                                                          safeSetState(() => _model
                                                                  .choiceChipsValue =
                                                              val?.firstOrNull),
                                                      selectedChipStyle:
                                                          ChipStyle(
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                        iconColor: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        iconSize: 18.0,
                                                        elevation: 0.0,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16.0),
                                                      ),
                                                      unselectedChipStyle:
                                                          ChipStyle(
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate,
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                        iconColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        iconSize: 18.0,
                                                        elevation: 0.0,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16.0),
                                                      ),
                                                      chipSpacing: 12.0,
                                                      rowSpacing: 12.0,
                                                      multiselect: false,
                                                      alignment:
                                                          WrapAlignment.start,
                                                      controller: _model
                                                              .choiceChipsValueController ??=
                                                          FormFieldController<
                                                              List<String>>(
                                                        [],
                                                      ),
                                                      wrapped: false,
                                                    ),
                                                    if (_hasValue(_model
                                                        .choiceChipsValue))
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(0.0,
                                                                8.0, 0.0, 0.0),
                                                        child: Text(
                                                          'Selected time: ${_model.choiceChipsValue}',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodySmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .poppins(),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                        ]
                                            .addToStart(SizedBox(
                                                width: horizontalGutter))
                                            .addToEnd(SizedBox(
                                                width: horizontalGutter)),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: FFButtonWidget(
                              onPressed: canBookAppointment
                                  ? () async {
                                      // checks to make sure all fields have been set or have a value
                                      if ((_model.calendarSelectedDay !=
                                              null) &&
                                          (_model.dropDownValue1 != null &&
                                              _model.dropDownValue1 != '') &&
                                          (_model.dropDownValue2 != null &&
                                              _model.dropDownValue2 != '') &&
                                          (_model.choiceChipsValue != null &&
                                              _model.choiceChipsValue != '')) {
                                        // gets reference of doctor choosen by mother
                                        _model.doctorRefFound =
                                            await queryDoctorRecordOnce(
                                          queryBuilder: (doctorRecord) =>
                                              doctorRecord.where(
                                            'id',
                                            isEqualTo: _model.dropDownValue2,
                                          ),
                                          singleRecord: true,
                                        ).then((s) => s.firstOrNull);
                                        if (_model.doctorRefFound == null) {
                                          _showSnackBar(
                                              'Selected clinician could not be found. Please choose a clinician again.');
                                          return;
                                        }
                                        _model.doctorBooked =
                                            await queryEncounterRecordOnce(
                                          queryBuilder: (encounterRecord) =>
                                              encounterRecord
                                                  .where(
                                                    'doctor_id',
                                                    isEqualTo: _model
                                                        .doctorRefFound
                                                        ?.reference,
                                                  )
                                                  .where(
                                                    'date',
                                                    isEqualTo: _model
                                                        .calendarSelectedDay
                                                        ?.start,
                                                  )
                                                  .where(
                                                    'time',
                                                    isEqualTo:
                                                        _model.choiceChipsValue,
                                                  )
                                                  .where(
                                                    'status',
                                                    isNotEqualTo: 'completed',
                                                  ),
                                          singleRecord: true,
                                        ).then((s) => s.firstOrNull);
                                        _model.motherBooked =
                                            await queryEncounterRecordOnce(
                                          queryBuilder: (encounterRecord) =>
                                              encounterRecord
                                                  .where(
                                                    'mother_id',
                                                    isEqualTo:
                                                        FFAppState().motherRef,
                                                  )
                                                  .where(
                                                    'date',
                                                    isEqualTo: _model
                                                        .calendarSelectedDay
                                                        ?.start,
                                                  )
                                                  .where(
                                                    'time',
                                                    isEqualTo:
                                                        _model.choiceChipsValue,
                                                  )
                                                  .where(
                                                    'status',
                                                    isNotEqualTo: 'completed',
                                                  ),
                                          singleRecord: true,
                                        ).then((s) => s.firstOrNull);
                                        // checks to see if either mother or doctor already has an appointment at the time and date selected
                                        if ((_model.doctorBooked != null) ||
                                            (_model.motherBooked != null)) {
                                          await showDialog(
                                            context: context,
                                            builder: (alertDialogContext) {
                                              return AlertDialog(
                                                title: Text('Unavailable slot'),
                                                content: Text(
                                                    'Either the clinician or you are booked at the time entered. Please select another time'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            alertDialogContext),
                                                    child: Text('Ok'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          await EncounterRecord.collection
                                              .doc()
                                              .set(createEncounterRecordData(
                                                doctorId: _model
                                                    .doctorRefFound?.reference,
                                                status: 'scheduled',
                                                motherId:
                                                    FFAppState().motherRef,
                                                date: _model
                                                    .calendarSelectedDay?.start,
                                                time: _model.choiceChipsValue,
                                              ));
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Appointment successfully scheduled',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                            ),
                                          );

                                          context.goNamed(
                                            EncountersWidget.routeName,
                                            extra: <String, dynamic>{
                                              kTransitionInfoKey:
                                                  TransitionInfo(
                                                hasTransition: true,
                                                transitionType:
                                                    PageTransitionType.fade,
                                              ),
                                            },
                                          );
                                        }
                                      } else {
                                        await showDialog(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return AlertDialog(
                                              title: Text('Incomplete fields'),
                                              content: Text(
                                                  'Kindly ensure that you have selected a date, clinic, clinician and time before booking an appointment'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext),
                                                  child: Text('Ok'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }

                                      safeSetState(() {});
                                    }
                                  : null,
                              text: 'Book Appointment',
                              options: FFButtonOptions(
                                height: isCompactSheet ? 44.0 : 48.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).primary,
                                disabledColor:
                                    FlutterFlowTheme.of(context).alternate,
                                disabledTextColor:
                                    FlutterFlowTheme.of(context).secondaryText,
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
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ]
                            .divide(SizedBox(width: horizontalGutter))
                            .around(SizedBox(width: horizontalGutter)),
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
  }
}
