// A manual visual-QA target for the adaptive Home feature. It is not linked
// from the production router; run it with:
// flutter run -d chrome -t test/support/home_featured_capture_app.dart
import 'package:dawa_mom/design_system/dawa_design_tokens.dart';
import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/home/domain/dawa_home_presentation.dart';
import 'package:dawa_mom/features/home/presentation/dawa_adaptive_featured_card.dart';
import 'package:dawa_mom/features/period_tracker/domain/period_cycle_summary.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _HomeFeaturedCaptureApp());

class _HomeFeaturedCaptureApp extends StatefulWidget {
  const _HomeFeaturedCaptureApp();

  @override
  State<_HomeFeaturedCaptureApp> createState() =>
      _HomeFeaturedCaptureAppState();
}

class _HomeFeaturedCaptureAppState extends State<_HomeFeaturedCaptureApp> {
  late int _selected;

  static final _presentations = <DawaHomePresentation>[
    DawaHomePresentation(
      kind: DawaHomeFeaturedKind.activePeriod,
      action: DawaHomeAction.cycle,
      title: 'Period in progress',
      message: 'Open Track to log how you feel.',
      actionLabel: 'Open Track',
      cycle: _cycle(status: PeriodCycleStatus.periodActive, cycleDay: 3),
    ),
    DawaHomePresentation(
      kind: DawaHomeFeaturedKind.cycle,
      action: DawaHomeAction.cycle,
      title: 'Cycle day 12',
      message: 'Next period estimated in 16 days.',
      actionLabel: 'View cycle',
      cycle: _cycle(status: PeriodCycleStatus.cycleInProgress, cycleDay: 12),
    ),
    const DawaHomePresentation(
      kind: DawaHomeFeaturedKind.pregnancy,
      action: DawaHomeAction.pregnancy,
      title: 'Week 24',
      message: 'Your 2nd trimester.',
      actionLabel: 'View pregnancy',
      pregnancyWeek: 24,
      trimester: 2,
    ),
    DawaHomePresentation(
      kind: DawaHomeFeaturedKind.appointment,
      action: DawaHomeAction.appointment,
      title: 'Your next visit',
      message: 'Your visit details are ready to review.',
      actionLabel: 'View visit',
      appointment: _appointment(),
    ),
    const DawaHomePresentation(
      kind: DawaHomeFeaturedKind.general,
      action: DawaHomeAction.bookVisit,
      title: 'Your health today',
      message: 'Choose a simple next step for your health.',
      actionLabel: 'Book a visit',
    ),
  ];

  static const _labels = ['Period', 'Cycle', 'Pregnancy', 'Visit', 'Welcome'];

  @override
  void initState() {
    super.initState();
    _selected = switch (Uri.base.queryParameters['state']) {
      'cycle' => 1,
      'pregnancy' => 2,
      'appointment' => 3,
      'general' => 4,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: DawaTheme.light(),
        home: Scaffold(
          backgroundColor: DawaColors.canvas,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DawaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home feature preview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: DawaSpacing.xs),
                  Text(
                    'Batch 1 visual QA',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DawaSpacing.md),
                  DawaAdaptiveFeaturedCard(
                    presentation: _presentations[_selected],
                    onAction: () {},
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selected,
            onDestinationSelected: (value) => setState(() => _selected = value),
            destinations: List.generate(
              _labels.length,
              (index) => NavigationDestination(
                icon: const Icon(Icons.circle_outlined),
                selectedIcon: const Icon(Icons.circle),
                label: _labels[index],
              ),
            ),
          ),
        ),
      );
}

PeriodCycleSummary _cycle({
  required PeriodCycleStatus status,
  required int cycleDay,
}) =>
    PeriodCycleSummary(
      status: status,
      averageCycleLength: 28,
      averagePeriodLength: 5,
      historyCount: 3,
      isRegular: true,
      lastPeriodStart: DateTime(2026, 9, 22),
      nextPeriodEstimate: DateTime(2026, 10, 20),
      predictedWindowStart: DateTime(2026, 10, 19),
      predictedWindowEnd: DateTime(2026, 10, 21),
      cycleDay: cycleDay,
      daysUntilNextPeriod: 16,
      confidence: PeriodEstimateConfidence.medium,
      predictionReason: 'Based on recent completed cycles.',
      observedCycleCount: 3,
      cycleVariationDays: 2,
    );

Appointment _appointment() => Appointment(
      id: 'appointment-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime(2026, 10, 14),
      startTime: '10:00',
      endTime: '10:30',
      appointmentType: 'antenatal_checkup',
      status: 'confirmed',
      source: 'dawa_mom',
      createdAt: DateTime(2026, 10, 9),
      integrationStatus: 'confirmed',
      clinicName: 'Kalingalinga Clinic',
    );
