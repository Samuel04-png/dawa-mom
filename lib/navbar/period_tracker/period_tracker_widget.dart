import '/auth/supabase_auth/auth_util.dart';
import '/backend/period_tracker_service.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'period_tracker_model.dart';
export 'period_tracker_model.dart';

class PeriodTrackerWidget extends StatefulWidget {
  const PeriodTrackerWidget({super.key});

  static String routeName = 'PeriodTracker';
  static String routePath = '/periodTracker';

  @override
  State<PeriodTrackerWidget> createState() => _PeriodTrackerWidgetState();
}

class _PeriodTrackerWidgetState extends State<PeriodTrackerWidget>
    with TickerProviderStateMixin {
  late PeriodTrackerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  final _periodTrackerService = PeriodTrackerService();

  final animationsMap = <String, AnimationInfo>{};

  // Calendar variables
  late DateTime _focusedDay;
  DateTime? _selectedPeriodStart;
  DateTime? _lastPeriodStart;
  DateTime? _nextPredictedPeriod;
  int _averageCycleLength = 28;
  int _periodLength = 5;
  bool _isRegular = true;
  List<DateTime> _currentPeriodDays = [];
  List<DateTime> _fertileWindowDays = [];
  DateTime? _ovulationDay;
  bool _isPeriodLate = false;
  Map<DateTime, List<String>> _dailySymptoms = {};
  Map<DateTime, List<String>> _dailyNotes = {};
  Map<DateTime, List<Map<String, dynamic>>> _sexualActivity =
      {}; // {date: [{protected: bool, time: DateTime}]}
  List<String> _availableSymptoms = [
    'Cramps',
    'Headache',
    'Fatigue',
    'Mood swings',
    'Bloating',
    'Breast tenderness',
    'Acne',
    'Food cravings',
    'Insomnia',
    'Nausea'
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PeriodTrackerModel());
    _model.textController = TextEditingController();

    _focusedDay = DateTime.now();

    // Initialize with default values
    _initializeUserData();

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _loadUserData();
    });

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 150.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 150.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 10.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'calendarOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 450.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 450.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
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

  void _initializeUserData() {
    _averageCycleLength = 28;
    _periodLength = 5;
    _isRegular = true;
  }

  Future<void> _loadUserData() async {
    if (currentUserUid.isEmpty) {
      return;
    }

    final userSettings = await _periodTrackerService.loadUserSettings();
    if (!mounted) {
      return;
    }

    if (userSettings != null) {
      setState(() {
        _averageCycleLength = userSettings['averageCycleLength'] as int? ?? 28;
        _periodLength = userSettings['periodLength'] as int? ?? 5;
        _isRegular = userSettings['isRegular'] as bool? ?? true;
        _lastPeriodStart = userSettings['lastPeriodStart'] is DateTime
            ? userSettings['lastPeriodStart'] as DateTime
            : null;
        _recalculatePredictions();
      });
    }

    await _loadTodaysData();
  }

  Future<void> _loadTodaysData() async {
    if (currentUserUid.isEmpty) {
      return;
    }
    final today = _normalizeDate(DateTime.now());
    final dailyData = await _periodTrackerService.loadDailyData(today);
    if (!mounted || dailyData == null) {
      return;
    }

    setState(() {
      _dailyNotes[today] = List<String>.from(dailyData['notes'] ?? const []);
      _dailySymptoms[today] =
          List<String>.from(dailyData['symptoms'] ?? const []);
      _sexualActivity[today] =
          (dailyData['sexualActivity'] as List? ?? const [])
              .map((activity) => Map<String, dynamic>.from(activity as Map))
              .toList();
      if (_dailyNotes[today]!.isNotEmpty) {
        _model.textController.text = _dailyNotes[today]!.join('\n');
      }
    });
  }

  Future<void> _saveUserData() async {
    if (currentUserUid.isEmpty) {
      return;
    }
    await _periodTrackerService.saveUserSettings(
      averageCycleLength: _averageCycleLength,
      periodLength: _periodLength,
      isRegular: _isRegular,
      lastPeriodStart: _lastPeriodStart,
    );
  }

  Future<void> _saveDailyData(DateTime date) async {
    if (currentUserUid.isEmpty) {
      return;
    }
    final normalizedDate = _normalizeDate(date);
    await _periodTrackerService.saveDailyData(
      date: normalizedDate,
      symptoms: _dailySymptoms[normalizedDate] ?? const [],
      notes: _dailyNotes[normalizedDate] ?? const [],
      sexualActivity: _sexualActivity[normalizedDate] ?? const [],
    );
  }

  void _saveUserDataInBackground() {
    _saveUserData().catchError(
      (error) => debugPrint('Period tracker settings save failed: $error'),
    );
  }

  void _saveDailyDataInBackground(DateTime date) {
    _saveDailyData(date).catchError(
      (error) => debugPrint('Period tracker daily save failed: $error'),
    );
  }

  void _recalculatePredictions() {
    if (_lastPeriodStart != null) {
      // Calculate next predicted period
      _nextPredictedPeriod =
          _lastPeriodStart!.add(Duration(days: _averageCycleLength));

      // Calculate ovulation (approx 14 days before next period for regular cycles)
      _ovulationDay = _nextPredictedPeriod!.subtract(Duration(days: 14));

      // Calculate fertile window (5 days before ovulation + ovulation day)
      _fertileWindowDays = [];
      if (_ovulationDay != null) {
        for (int i = 5; i >= 1; i--) {
          _fertileWindowDays.add(_ovulationDay!.subtract(Duration(days: i)));
        }
        _fertileWindowDays.add(_ovulationDay!);
      }

      // Check if period is late
      final today = DateTime.now();
      final lastPeriodStart = _lastPeriodStart!;
      final daysSinceLastPeriod = today.difference(lastPeriodStart).inDays;

      _isPeriodLate = daysSinceLastPeriod > _averageCycleLength + 3;
    } else {
      _nextPredictedPeriod = null;
      _ovulationDay = null;
      _fertileWindowDays = [];
      _isPeriodLate = false;
    }
  }

  void _updatePeriodStart(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    setState(() {
      _selectedPeriodStart = normalizedDate;
      _lastPeriodStart = normalizedDate;
      _currentPeriodDays = [];
      for (int i = 0; i < _periodLength; i++) {
        _currentPeriodDays.add(normalizedDate.add(Duration(days: i)));
      }
      _recalculatePredictions();
    });
    _saveUserDataInBackground();
  }

  void _addSexualActivity(DateTime date, bool isProtected) {
    final normalizedDate = _normalizeDate(date);
    setState(() {
      if (!_sexualActivity.containsKey(normalizedDate)) {
        _sexualActivity[normalizedDate] = [];
      }
      _sexualActivity[normalizedDate]!.add({
        'protected': isProtected,
        'time': DateTime.now(),
      });
    });
    _saveDailyDataInBackground(normalizedDate);
  }

  void _addNoteForToday(String note) {
    final today = _normalizeDate(DateTime.now());
    if (note.trim().isNotEmpty) {
      setState(() {
        if (!_dailyNotes.containsKey(today)) {
          _dailyNotes[today] = [];
        }
        // Clear existing notes and add the new one (or you could append)
        _dailyNotes[today]!.clear();
        _dailyNotes[today]!.add(note.trim());
      });
    } else {
      setState(() {
        _dailyNotes.remove(today);
      });
    }
    _saveDailyDataInBackground(today);
  }

  Widget _buildDayContent(DateTime day, DateTime focusedDay) {
    final isToday = isSameDay(day, DateTime.now());
    final isSelectedPeriodStart = isSameDay(day, _selectedPeriodStart);
    final isPeriodDay =
        _currentPeriodDays.any((periodDay) => isSameDay(periodDay, day));
    final isFertileDay =
        _fertileWindowDays.any((fertileDay) => isSameDay(fertileDay, day));
    final isOvulationDay = isSameDay(day, _ovulationDay);
    final hasSymptoms = _dailySymptoms.containsKey(_normalizeDate(day)) &&
        _dailySymptoms[_normalizeDate(day)]!.isNotEmpty;
    final hasSexualActivity = _sexualActivity.containsKey(_normalizeDate(day));
    final hasNotes = _dailyNotes.containsKey(_normalizeDate(day)) &&
        _dailyNotes[_normalizeDate(day)]!.isNotEmpty;

    // Background color based on cycle phase
    Color backgroundColor = Colors.transparent;
    if (isPeriodDay) {
      backgroundColor = Color(0xFFFF6B6B).withValues(alpha: 0.2);
    } else if (isOvulationDay) {
      backgroundColor = Color(0xFF9D4EDD).withValues(alpha: 0.2);
    } else if (isFertileDay) {
      backgroundColor = Color(0xFF4ECDC4).withValues(alpha: 0.2);
    }

    // Emoji indicators
    String emoji = '';
    if (isPeriodDay) emoji = '🩸';
    if (isOvulationDay) emoji = '🥚';
    if (isFertileDay && !isOvulationDay) emoji = '🌱';
    if (hasSymptoms) emoji += '😷';
    if (hasSexualActivity) emoji += '💝';
    if (hasNotes) emoji += '📝';

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isToday ? Color(0xFF1226AB) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.day.toString(),
              style: TextStyle(
                color: isSelectedPeriodStart ? Colors.white : Colors.black,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (emoji.isNotEmpty)
              Text(
                emoji,
                style: TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    _model.dispose();
    _unfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _getCurrentCycleDay();
    final daysUntilNextPeriod = _getDaysUntilNextPeriod();

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
          automaticallyImplyLeading: true,
          title: Text(
            'Period Tracker',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.settings,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
              onPressed: () async {
                await _showSettingsDialog(context);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 24.0,
              ),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (alertDialogContext) {
                    return AlertDialog(
                      title: Text('Cycle Information'),
                      content: Text(
                          'Track your menstrual cycle to understand patterns, predict periods, and identify fertile windows.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(alertDialogContext),
                          child: Text('Got it'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Cycle Overview
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 16.0, 16.0, 0.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _isPeriodLate
                                  ? Color(0xFFFF6B6B)
                                  : Color(0xFF1226AB),
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x33000000),
                                  offset: Offset(0.0, 4.0),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Current Cycle',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                      if (_isPeriodLate)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.warning,
                                                  color: Colors.white,
                                                  size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'Period Late',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 8.0, 0.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _lastPeriodStart != null
                                                  ? 'Day ${currentDay.toString()}'
                                                  : '--',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .displaySmall
                                                  .override(
                                                    font: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .displaySmall
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    fontSize: 32.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .displaySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                            Text(
                                              'of $_averageCycleLength day cycle',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: Color(0xB3FFFFFF),
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Color(0x4CFFFFFF),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Icon(
                                                      Icons.favorite_border,
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      size: 16.0,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  4.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        _isFertileWindow()
                                                            ? 'Fertile Window'
                                                            : 'Not Fertile',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 4.0, 0.0, 0.0),
                                              child: Text(
                                                _nextPredictedPeriod != null
                                                    ? 'Next period in ${daysUntilNextPeriod.toString()} days'
                                                    : 'Set period start date',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xB3FFFFFF),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ),
                                            if (_nextPredictedPeriod != null)
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 4.0, 0.0, 0.0),
                                                child: Text(
                                                  DateFormat('MMM dd').format(
                                                      _nextPredictedPeriod!),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animateOnPageLoad(
                              animationsMap['containerOnPageLoadAnimation1']!),
                        ),

                        // Cycle Stats
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 16.0, 16.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cycle Statistics',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _showSettingsDialog(context),
                                  ),
                                ],
                              ).animateOnPageLoad(
                                  animationsMap['textOnPageLoadAnimation']!),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 8.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Avg. Cycle',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                '$_averageCycleLength days',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.0),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Period Length',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                '$_periodLength days',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.0),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Regularity',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                _isRegular
                                                    ? 'Regular'
                                                    : 'Irregular',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Calendar Section
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 24.0, 16.0, 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMMM y')
                                            .format(_focusedDay),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.chevron_left,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _focusedDay = DateTime(
                                                    _focusedDay.year,
                                                    _focusedDay.month - 1);
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.chevron_right,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _focusedDay = DateTime(
                                                    _focusedDay.year,
                                                    _focusedDay.month + 1);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 16.0, 0.0, 0.0),
                                    child: Container(
                                      height:
                                          350.0, // Fixed height for calendar
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: SingleChildScrollView(
                                        physics: NeverScrollableScrollPhysics(),
                                        child: TableCalendar(
                                          firstDay: DateTime.utc(2020, 1, 1),
                                          lastDay: DateTime.utc(2030, 12, 31),
                                          focusedDay: _focusedDay,
                                          selectedDayPredicate: (day) =>
                                              isSameDay(
                                                  _selectedPeriodStart, day),
                                          onDaySelected:
                                              (selectedDay, focusedDay) {
                                            if (!isSameDay(_selectedPeriodStart,
                                                selectedDay)) {
                                              setState(() {
                                                _selectedPeriodStart =
                                                    selectedDay;
                                                _focusedDay = focusedDay;
                                              });
                                              _updatePeriodStart(selectedDay);
                                            }
                                          },
                                          onPageChanged: (focusedDay) {
                                            _focusedDay = focusedDay;
                                          },
                                          calendarStyle: CalendarStyle(
                                            defaultTextStyle: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                            ),
                                            weekendTextStyle: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                            ),
                                            selectedDecoration: BoxDecoration(
                                              color: Color(0xFF1226AB),
                                              shape: BoxShape.circle,
                                            ),
                                            todayDecoration: BoxDecoration(
                                              color: Color(0xFF1226AB)
                                                  .withValues(alpha: 0.3),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          headerStyle: HeaderStyle(
                                            formatButtonVisible: false,
                                            titleCentered: true,
                                          ),
                                          calendarBuilders: CalendarBuilders(
                                            defaultBuilder:
                                                (context, day, focusedDay) =>
                                                    _buildDayContent(
                                                        day, focusedDay),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectedPeriodStart != null)
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 16.0, 0.0, 0.0),
                                      child: Text(
                                        'Period started: ${DateFormat('MMM dd, yyyy').format(_selectedPeriodStart!)}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ).animateOnPageLoad(
                              animationsMap['calendarOnPageLoadAnimation']!),
                        ),

                        // Legend & Notes
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 24.0, 16.0, 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cycle Legend',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 8.0, 0.0, 16.0),
                                  child: Wrap(
                                    spacing: 12.0,
                                    runSpacing: 8.0,
                                    children: [
                                      _buildLegendItem(
                                          'Period', Color(0xFFFF6B6B)),
                                      _buildLegendItem(
                                          'Fertile', Color(0xFF4ECDC4)),
                                      _buildLegendItem(
                                          'Ovulation', Color(0xFF9D4EDD)),
                                      _buildLegendItem(
                                          'Sexual Activity', Color(0xFF9D4EDD)),
                                      _buildLegendItem(
                                          'Symptoms', Color(0xFFFFD166)),
                                      _buildLegendItem(
                                          'Notes', Color(0xFF06D6A0)),
                                    ],
                                  ),
                                ),

                                // Symptom Tracker
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Today\'s Tracking',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    font: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.favorite_border,
                                                    color: Color(0xFF1226AB),
                                                    size: 24.0,
                                                  ),
                                                  onPressed: () async {
                                                    await _showSexualActivityDialog(
                                                        context);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.add_circle_outline,
                                                    color: Color(0xFF1226AB),
                                                    size: 24.0,
                                                  ),
                                                  onPressed: () async {
                                                    await _showSymptomDialog(
                                                        context);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // Today's Symptoms
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 8.0, 0.0, 0.0),
                                          child: Text(
                                            'Symptoms:',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 4.0, 0.0, 12.0),
                                          child: Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: _buildTodaySymptoms(),
                                          ),
                                        ),
                                        // Today's Sexual Activity
                                        if (_hasTodaySexualActivity())
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Sexual Activity:',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                ..._buildTodaySexualActivity(),
                                              ],
                                            ),
                                          ),
                                        // Today's Notes
                                        if (_hasTodaysNotes())
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Saved Notes:',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 4.0, 0.0, 0.0),
                                                  child: _buildTodaysNotes(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        // Notes Input
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 16.0, 0.0, 0.0),
                                          child: TextFormField(
                                            controller: _model.textController,
                                            obscureText: false,
                                            onChanged: (value) {
                                              // Optional: You could save on every change or just on submit
                                            },
                                            onFieldSubmitted: (value) {
                                              _addNoteForToday(value);
                                            },
                                            onEditingComplete: () {
                                              _addNoteForToday(
                                                  _model.textController.text);
                                              FocusScope.of(context).unfocus();
                                            },
                                            decoration: InputDecoration(
                                              labelText:
                                                  'Add notes for today...',
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                              hintText: _getTodaysNotesHint(),
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                              suffixIcon: _model.textController
                                                      .text.isNotEmpty
                                                  ? IconButton(
                                                      icon: Icon(Icons.save,
                                                          size: 20),
                                                      onPressed: () {
                                                        _addNoteForToday(_model
                                                            .textController
                                                            .text);
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                      },
                                                    )
                                                  : null,
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFF1226AB),
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              contentPadding:
                                                  EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 16.0,
                                                          16.0, 16.0),
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                            maxLines: 3,
                                            validator: _model
                                                .textControllerValidator
                                                .asValidator(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animateOnPageLoad(animationsMap[
                                    'containerOnPageLoadAnimation3']!),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper Methods

  int _getCurrentCycleDay() {
    if (_lastPeriodStart == null) return 0;
    final today = DateTime.now();
    final difference = today.difference(_lastPeriodStart!).inDays;
    return difference + 1; // Day 1 is the first day of period
  }

  int _getDaysUntilNextPeriod() {
    if (_nextPredictedPeriod == null) return 0;
    final today = DateTime.now();
    final difference = _nextPredictedPeriod!.difference(today).inDays;
    return difference > 0 ? difference : 0;
  }

  bool _isFertileWindow() {
    final today = _normalizeDate(DateTime.now());
    return _fertileWindowDays.any((day) => isSameDay(day, today));
  }

  bool _hasTodaySexualActivity() {
    final today = _normalizeDate(DateTime.now());
    return _sexualActivity.containsKey(today) &&
        _sexualActivity[today]!.isNotEmpty;
  }

  bool _hasTodaysNotes() {
    final today = _normalizeDate(DateTime.now());
    return _dailyNotes.containsKey(today) &&
        _dailyNotes[today]!.isNotEmpty &&
        _dailyNotes[today]!.any((note) => note.trim().isNotEmpty);
  }

  List<Widget> _buildTodaySymptoms() {
    final today = _normalizeDate(DateTime.now());
    final symptoms = _dailySymptoms[today] ?? [];
    return symptoms.map((symptom) => _buildSymptomChip(symptom, true)).toList();
  }

  List<Widget> _buildTodaySexualActivity() {
    final today = _normalizeDate(DateTime.now());
    final activities = _sexualActivity[today] ?? [];
    return activities.map((activity) {
      return Padding(
        padding: EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Icon(
              Icons.favorite,
              color: activity['protected'] ? Colors.green : Colors.red,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              '${DateFormat('HH:mm').format((activity['time'] as DateTime))} - ${activity['protected'] ? 'Protected' : 'Unprotected'}',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTodaysNotes() {
    final today = _normalizeDate(DateTime.now());
    final notes = _dailyNotes[today] ?? [];

    if (notes.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: notes.map((note) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note,
                color: Color(0xFF1226AB),
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 14,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getTodaysNotesHint() {
    final today = _normalizeDate(DateTime.now());
    final hasNotes =
        _dailyNotes.containsKey(today) && _dailyNotes[today]!.isNotEmpty;

    if (hasNotes) {
      return 'Edit today\'s notes...';
    } else {
      return 'Add notes for today (e.g., mood, flow intensity, any concerns)...';
    }
  }

  // Dialog Methods

  Future<void> _showSettingsDialog(BuildContext context) async {
    TextEditingController cycleController =
        TextEditingController(text: _averageCycleLength.toString());
    TextEditingController periodController =
        TextEditingController(text: _periodLength.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cycle Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cycleController,
                  decoration: InputDecoration(
                    labelText: 'Average Cycle Length (days)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: 'Period Length (days)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text('Regular Cycle:'),
                    SizedBox(width: 12),
                    Switch(
                      value: _isRegular,
                      onChanged: (value) {
                        setState(() {
                          _isRegular = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _averageCycleLength =
                      int.tryParse(cycleController.text) ?? 28;
                  _periodLength = int.tryParse(periodController.text) ?? 5;
                  _recalculatePredictions();
                });
                _saveUserDataInBackground();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSymptomDialog(BuildContext context) async {
    final today = _normalizeDate(DateTime.now());
    final currentSymptoms = _dailySymptoms[today] ?? [];
    List<String> selectedSymptoms = List.from(currentSymptoms);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Track Symptoms'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _availableSymptoms.map((symptom) {
                    return CheckboxListTile(
                      title: Text(symptom),
                      value: selectedSymptoms.contains(symptom),
                      onChanged: (value) {
                        // Use the setState from StatefulBuilder to update the dialog
                        setState(() {
                          if (value == true) {
                            selectedSymptoms.add(symptom);
                          } else {
                            selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Update the main widget state
                    this.setState(() {
                      if (selectedSymptoms.isNotEmpty) {
                        _dailySymptoms[today] = selectedSymptoms;
                      } else {
                        _dailySymptoms.remove(today);
                      }
                    });
                    _saveDailyDataInBackground(today);
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSexualActivityDialog(BuildContext context) async {
    bool isProtected = true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Track Sexual Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Was protection used?'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      isProtected = true;
                      Navigator.pop(context);
                      _addSexualActivity(
                          _normalizeDate(DateTime.now()), isProtected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Protected'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      isProtected = false;
                      Navigator.pop(context);
                      _addSexualActivity(
                          _normalizeDate(DateTime.now()), isProtected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Unprotected'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
          child: Text(
            label,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.poppins(
                    fontWeight: FontWeight.normal,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomChip(String symptom, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF1226AB).withValues(alpha: 0.1)
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isSelected
              ? Color(0xFF1226AB)
              : FlutterFlowTheme.of(context).alternate,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSymptomIcon(symptom),
              color: isSelected
                  ? Color(0xFF1226AB)
                  : FlutterFlowTheme.of(context).secondaryText,
              size: 16.0,
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
              child: Text(
                symptom,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: isSelected
                          ? Color(0xFF1226AB)
                          : FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSymptomIcon(String symptom) {
    switch (symptom.toLowerCase()) {
      case 'cramps':
        return Icons.favorite_border;
      case 'headache':
        return Icons.health_and_safety;
      case 'fatigue':
        return Icons.bedtime_outlined;
      case 'mood swings':
        return Icons.mood;
      case 'bloating':
        return Icons.incomplete_circle;
      case 'breast tenderness':
        return Icons.favorite;
      case 'acne':
        return Icons.wb_sunny;
      case 'food cravings':
        return Icons.restaurant;
      case 'insomnia':
        return Icons.nightlight;
      case 'nausea':
        return Icons.sick;
      default:
        return Icons.circle_outlined;
    }
  }
}
