import '/features/appointments/domain/appointment.dart';
import '/features/care_plan/domain/dawa_care_item.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/pregnancy/domain/dawa_pregnancy_journey.dart';
import '/features/profile/data/health_profile_repository.dart';

enum DawaHomeFeaturedKind {
  care,
  appointment,
  pregnancy,
  activePeriod,
  cycle,
  profileSetup,
  general,
}

enum DawaHomeAction {
  care,
  appointment,
  pregnancy,
  cycle,
  profile,
  bookVisit,
  retry,
}

/// A UI-only decision derived from the dashboard's already-loaded records.
///
/// This class intentionally does not calculate clinical dates or alter any
/// source data. Cycle estimates remain the responsibility of
/// [PeriodCycleSummary], while persistence remains in the existing
/// repositories.
class DawaHomePresentation {
  const DawaHomePresentation({
    required this.kind,
    required this.action,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.cycle,
    this.appointment,
    this.careItem,
    this.pregnancyWeek,
    this.pregnancyDay,
    this.trimester,
    this.pregnancyProgress,
    this.daysUntilDue,
    this.profileAvailable = true,
  });

  final DawaHomeFeaturedKind kind;
  final DawaHomeAction action;
  final String title;
  final String message;
  final String actionLabel;
  final PeriodCycleSummary? cycle;
  final Appointment? appointment;
  final DawaCareItem? careItem;
  final int? pregnancyWeek;
  final int? pregnancyDay;
  final int? trimester;
  final double? pregnancyProgress;
  final int? daysUntilDue;
  final bool profileAvailable;

  bool get showsCyclePreview =>
      kind == DawaHomeFeaturedKind.activePeriod ||
      kind == DawaHomeFeaturedKind.cycle;

  /// A booking prompt belongs in the feature when there is no saved visit.
  /// Only show the supporting appointment surface when it adds real details
  /// that the featured card is not already presenting.
  bool get showsAppointmentSupport =>
      appointment != null && kind != DawaHomeFeaturedKind.appointment;

  bool get showsProfileSupport =>
      kind != DawaHomeFeaturedKind.profileSetup && profileAvailable;
}

abstract final class DawaHomePresentationMapper {
  static DawaHomePresentation map({
    required HealthProfileSnapshot profile,
    required PeriodCycleSummary cycle,
    required bool profileAvailable,
    Appointment? appointment,
    DawaCareItem? careItem,
  }) {
    if (careItem != null && careItem.shouldLeadHome) {
      final overdue = careItem.status == DawaCareItemStatus.overdue;
      return DawaHomePresentation(
        kind: DawaHomeFeaturedKind.care,
        action: DawaHomeAction.care,
        title: 'Care needs attention',
        message: overdue
            ? '${careItem.title} is overdue. Open Care to see the next step.'
            : '${careItem.title}. Open Care to see the next step.',
        actionLabel: 'Open care',
        careItem: careItem,
        profileAvailable: profileAvailable,
      );
    }

    if (appointment != null) {
      final pending = appointment.status == 'pending';
      final day = _calendarDaysAway(appointment.date);
      return DawaHomePresentation(
        kind: DawaHomeFeaturedKind.appointment,
        action: DawaHomeAction.appointment,
        title: pending
            ? 'Visit request sent'
            : day == 0
                ? 'Your visit is today'
                : day == 1
                    ? 'Your visit is tomorrow'
                    : 'Your next visit',
        message: pending
            ? 'Your clinic is reviewing the request.'
            : 'Your visit details are ready to review.',
        actionLabel: pending ? 'View request' : 'View visit',
        appointment: appointment,
        profileAvailable: profileAvailable,
      );
    }

    final pregnancy = DawaPregnancyJourney.fromProfile(profile);
    if (pregnancy != null) {
      return DawaHomePresentation(
        kind: DawaHomeFeaturedKind.pregnancy,
        action: DawaHomeAction.pregnancy,
        // The eyebrow and progress visual already establish the context.
        // Keeping this brief preserves a clear single-line heading on phones.
        title: 'Week ${pregnancy.actualWeek}',
        message: pregnancy.isPastDue
            ? 'Your due date has passed. Contact your health worker for guidance.'
            : 'Your ${_ordinal(pregnancy.trimester)} trimester.',
        actionLabel: 'View pregnancy',
        pregnancyWeek: pregnancy.actualWeek,
        pregnancyDay: pregnancy.dayOfWeek,
        trimester: pregnancy.trimester,
        pregnancyProgress: pregnancy.progress,
        daysUntilDue: pregnancy.daysRemaining,
        profileAvailable: profileAvailable,
      );
    }

    if (cycle.isPeriodActive) {
      return DawaHomePresentation(
        kind: DawaHomeFeaturedKind.activePeriod,
        action: DawaHomeAction.cycle,
        title: 'Period in progress',
        message: 'Open Track to log how you feel.',
        actionLabel: 'Open Track',
        cycle: cycle,
        profileAvailable: profileAvailable,
      );
    }

    if (cycle.isConfigured && cycle.cycleDay != null) {
      final days = cycle.daysUntilNextPeriod;
      return DawaHomePresentation(
        kind: DawaHomeFeaturedKind.cycle,
        action: DawaHomeAction.cycle,
        title: 'Cycle day ${cycle.cycleDay}',
        message: days == null
            ? 'Open Track for your cycle view.'
            : days == 0
                ? 'Your next period is estimated today.'
                : 'Next period estimated in $days ${days == 1 ? 'day' : 'days'}.',
        actionLabel: 'View cycle',
        cycle: cycle,
        profileAvailable: profileAvailable,
      );
    }

    if (!profileAvailable || !profile.isComplete) {
      return DawaHomePresentation(
        kind: DawaHomeFeaturedKind.profileSetup,
        action:
            profileAvailable ? DawaHomeAction.profile : DawaHomeAction.retry,
        title: profileAvailable
            ? 'Let’s personalize your care'
            : 'Your health today',
        message: profileAvailable
            ? profile.dashboardPrompt
            : 'Some health details are unavailable. You can still use DawaMom.',
        actionLabel: profileAvailable ? 'Complete profile' : 'Try again',
        profileAvailable: profileAvailable,
      );
    }

    return DawaHomePresentation(
      kind: DawaHomeFeaturedKind.general,
      action: DawaHomeAction.bookVisit,
      title: 'Your health today',
      message: 'Choose a simple next step for your health.',
      actionLabel: 'Book a visit',
      profileAvailable: profileAvailable,
    );
  }
}

String _ordinal(int value) => switch (value) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '${value}th',
    };

int _calendarDaysAway(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final appointmentDay = DateTime(date.year, date.month, date.day);
  return appointmentDay.difference(today).inDays;
}
