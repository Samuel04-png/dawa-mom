import 'package:dawa_mom/features/appointments/domain/appointment.dart';
import 'package:dawa_mom/features/care_plan/domain/dawa_care_item.dart';
import 'package:dawa_mom/features/home/domain/dawa_home_presentation.dart';
import 'package:dawa_mom/features/period_tracker/domain/period_cycle_summary.dart';
import 'package:dawa_mom/features/profile/data/health_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

HealthProfileSnapshot _profile({
  bool complete = true,
  DateTime? dueDate,
}) =>
    HealthProfileSnapshot(
      profile: <String, dynamic>{
        if (complete) ...{
          'email': 'mother@example.test',
          'display_name': 'Chipo Banda',
          'phone_number': '+260970000000',
        },
      },
      mother: <String, dynamic>{
        if (complete) ...{
          'name': 'Chipo Banda',
          'date_of_birth': '1994-03-17',
          'address': 'Lusaka',
          'pregnancy_status': dueDate == null ? 'not_pregnant' : 'pregnant',
        },
      },
      pregnancy: dueDate == null
          ? null
          : <String, dynamic>{'estimated_due_date': dueDate.toIso8601String()},
      periodSettings: complete
          ? <String, dynamic>{'lastPeriodStart': DateTime(2026, 9, 22)}
          : null,
    );

PeriodCycleSummary _cycle({
  PeriodCycleStatus status = PeriodCycleStatus.cycleInProgress,
  int? cycleDay = 12,
  int? daysUntilNextPeriod = 16,
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
      daysUntilNextPeriod: daysUntilNextPeriod,
      confidence: PeriodEstimateConfidence.medium,
      predictionReason: 'Based on recent completed cycles.',
      observedCycleCount: 3,
      cycleVariationDays: 2,
    );

Appointment _appointment({String status = 'confirmed'}) => Appointment(
      id: 'appointment-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      clinicianId: 'clinician-1',
      clinicId: 'clinic-1',
      date: DateTime.now().add(const Duration(days: 3)),
      startTime: '10:00',
      endTime: '10:30',
      appointmentType: 'antenatal_checkup',
      status: status,
      source: 'dawa_mom',
      createdAt: DateTime.now(),
      integrationStatus: status,
      clinicName: 'Kalingalinga Clinic',
    );

DawaCareItem _care() => DawaCareItem(
      id: 'care-1',
      motherId: 'mother-1',
      patientId: 'patient-1',
      type: 'clinical_followup',
      title: 'Return to clinic',
      status: DawaCareItemStatus.due,
      priority: DawaCareItemPriority.high,
      source: 'clinician',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    );

void main() {
  test('care item leads Home ahead of all other data', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(dueDate: DateTime.now().add(const Duration(days: 120))),
      cycle: _cycle(status: PeriodCycleStatus.periodActive),
      profileAvailable: true,
      appointment: _appointment(),
      careItem: _care(),
    );

    expect(presentation.kind, DawaHomeFeaturedKind.care);
    expect(presentation.action, DawaHomeAction.care);
    expect(presentation.title, 'Care needs attention');
    expect(presentation.message, contains('Return to clinic'));
  });

  test('pending appointment is not presented as confirmed', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(),
      cycle: _cycle(),
      profileAvailable: true,
      appointment: _appointment(status: 'pending'),
    );

    expect(presentation.kind, DawaHomeFeaturedKind.appointment);
    expect(presentation.title, 'Visit request sent');
    expect(presentation.actionLabel, 'View request');
    expect(presentation.message, contains('reviewing'));
  });

  test('pregnancy leads when there is no time-sensitive care or visit', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(dueDate: DateTime.now().add(const Duration(days: 120))),
      cycle: _cycle(),
      profileAvailable: true,
    );

    expect(presentation.kind, DawaHomeFeaturedKind.pregnancy);
    expect(presentation.action, DawaHomeAction.pregnancy);
    expect(presentation.title, 'Week ${presentation.pregnancyWeek}');
  });

  test('active period leads ahead of a normal cycle estimate', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(),
      cycle: _cycle(status: PeriodCycleStatus.periodActive, cycleDay: 3),
      profileAvailable: true,
    );

    expect(presentation.kind, DawaHomeFeaturedKind.activePeriod);
    expect(presentation.action, DawaHomeAction.cycle);
    expect(presentation.title, 'Period in progress');
  });

  test('normal cycle copy describes predictions as estimates', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(),
      cycle: _cycle(cycleDay: 12, daysUntilNextPeriod: 16),
      profileAvailable: true,
    );

    expect(presentation.kind, DawaHomeFeaturedKind.cycle);
    expect(presentation.title, 'Cycle day 12');
    expect(presentation.message, 'Next period estimated in 16 days.');
  });

  test('incomplete profile gets the setup variation', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(complete: false),
      cycle: _cycle(status: PeriodCycleStatus.notConfigured, cycleDay: null),
      profileAvailable: true,
    );

    expect(presentation.kind, DawaHomeFeaturedKind.profileSetup);
    expect(presentation.action, DawaHomeAction.profile);
  });

  test('unavailable profile can retry without hiding a usable Home', () {
    final presentation = DawaHomePresentationMapper.map(
      profile: _profile(complete: false),
      cycle: _cycle(status: PeriodCycleStatus.notConfigured, cycleDay: null),
      profileAvailable: false,
    );

    expect(presentation.kind, DawaHomeFeaturedKind.profileSetup);
    expect(presentation.action, DawaHomeAction.retry);
    expect(presentation.actionLabel, 'Try again');
  });

  test('general feature owns booking so Home does not duplicate it below', () {
    const presentation = DawaHomePresentation(
      kind: DawaHomeFeaturedKind.general,
      action: DawaHomeAction.bookVisit,
      title: 'Your health today',
      message: 'Choose a simple next step for your health.',
      actionLabel: 'Book a visit',
    );

    expect(presentation.showsAppointmentSupport, isFalse);
  });
}
