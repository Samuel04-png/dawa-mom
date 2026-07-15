import 'package:flutter/material.dart';

import '/backend/period_tracker_service.dart';
import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/features/profile/profile_completion_page.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/period_tracker/presentation/period_cycle_status_card.dart';
import '/features/pregnancy/presentation/pregnancy_what_to_expect.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'responsive_layout.dart';
import 'upcoming_appointment_section.dart';

class DawaMomResponsiveDashboard extends StatefulWidget {
  const DawaMomResponsiveDashboard({
    super.key,
    required this.onOpenRudo,
  });

  final VoidCallback onOpenRudo;

  @override
  State<DawaMomResponsiveDashboard> createState() =>
      _DawaMomResponsiveDashboardState();
}

class _DawaMomResponsiveDashboardState
    extends State<DawaMomResponsiveDashboard> {
  final _appointments = AppointmentRepository();
  final _healthProfiles = HealthProfileRepository();
  final _periodTracker = PeriodTrackerService();
  late Future<_DashboardData> _data;

  @override
  void initState() {
    super.initState();
    HealthProfileRepository.changes.addListener(_onProfileChanged);
    PeriodTrackerService.changes.addListener(_onProfileChanged);
    _data = _load();
  }

  @override
  void dispose() {
    HealthProfileRepository.changes.removeListener(_onProfileChanged);
    PeriodTrackerService.changes.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) _refresh();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait<dynamic>([
      _appointments.getAppointments(),
      _healthProfiles.load(),
      _periodTracker.loadPeriodHistory(),
    ]);
    return _DashboardData(
      appointments: results[0] as List<Appointment>,
      healthProfile: results[1] as HealthProfileSnapshot,
      periodHistory: results[2] as List<PeriodRecord>,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _data = future);
    await future;
  }

  Future<void> _book() async {
    final result = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingBottomSheetWidget(),
    );
    if (result != null && mounted) await _refresh();
  }

  Future<void> _openPeriodTracker(_DashboardData data) async {
    if (data.healthProfile.periodSettings?['lastPeriodStart'] != null) {
      context.pushNamed(PeriodTrackerWidget.routeName);
      return;
    }
    final result = await showPeriodSetupFlow(context, allowSkip: true);
    if (result != null && result != PeriodSetupOutcome.back && mounted) {
      await _refresh();
    }
  }

  void _openAppointment(Appointment appointment) {
    context.pushNamed(
      AppointmentDetailsWidget.routeName,
      queryParameters: {'appointmentId': appointment.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContainer(
              child: FutureBuilder<_DashboardData>(
                future: _data,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 520,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _DashboardError(onRetry: _refresh);
                  }
                  return _buildDashboard(context, snapshot.data!);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, _DashboardData data) {
    final theme = FlutterFlowTheme.of(context);
    final nextAppointment = data.nextAppointment;
    final profileComplete = data.healthProfile.isComplete;
    final cycleSummary = PeriodCycleSummary.derive(
      now: DateTime.now(),
      settings: data.healthProfile.periodSettings,
      history: data.periodHistory,
    );
    final nextPeriod = cycleSummary.nextPeriodEstimate;
    final cycleLength = cycleSummary.averageCycleLength ?? 28;
    final pregnancyStatus = data.healthProfile.pregnancyProfileStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/Frame_41.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${data.healthProfile.name.isEmpty ? 'there' : data.healthProfile.name}',
                    style: theme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _book,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book appointment'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        ResponsiveContentGrid(
          minItemWidth: 245,
          children: [
            _SummaryCard(
              icon: Icons.event_available_rounded,
              iconColor: theme.primary,
              label: 'Next appointment',
              value: nextAppointment == null
                  ? 'Nothing scheduled'
                  : DateFormat('d MMM, h:mm a').format(
                      Appointment.dateAtTime(
                        nextAppointment.date,
                        nextAppointment.startTime,
                      ),
                    ),
              helper: nextAppointment == null
                  ? 'Book when you are ready'
                  : nextAppointment.clinicianName ?? 'Clinician',
              onTap: nextAppointment == null
                  ? _book
                  : () => _openAppointment(nextAppointment),
            ),
            _SummaryCard(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFFE2557B),
              label: 'Period tracker',
              value: nextPeriod == null
                  ? 'Period Tracker not set up'
                  : 'Estimated around ${DateFormat('d MMM').format(nextPeriod)}',
              helper: nextPeriod == null
                  ? 'Add your last period to see estimates'
                  : 'Estimate based on a $cycleLength-day cycle',
              onTap: () => _openPeriodTracker(data),
            ),
            _SummaryCard(
              icon: pregnancyStatus == PregnancyProfileStatus.pregnantWithData
                  ? Icons.pregnant_woman_rounded
                  : profileComplete
                      ? Icons.verified_user_outlined
                      : Icons.person_outline_rounded,
              iconColor: profileComplete ? theme.success : theme.warning,
              label: 'Pregnancy / health',
              value: _pregnancyStatusValue(data.healthProfile),
              helper: _pregnancyStatusHelper(data.healthProfile),
              onTap: () => context.pushNamed(ProfileCompletionPage.routeName),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const DashboardSectionHeader(
          title: 'Your care overview',
          subtitle: 'Appointments and personalised maternal health information',
        ),
        const SizedBox(height: 14),
        ResponsiveContentGrid(
          minItemWidth: 420,
          children: [
            DawaMomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next appointment',
                    style: theme.titleMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  UpcomingAppointmentSection(compact: true),
                ],
              ),
            ),
            DawaMomCard(
              child: PeriodCycleStatusCard(
                summary: cycleSummary,
                onOpenTracker: () => _openPeriodTracker(data),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const DashboardSectionHeader(
          title: 'What to expect',
          subtitle: 'Pregnancy information based on your health profile',
        ),
        const SizedBox(height: 14),
        DawaMomCard(
          child: PregnancyWhatToExpectCard(
            profile: data.healthProfile,
            onOpenProfile: () =>
                context.pushNamed(ProfileCompletionPage.routeName),
          ),
        ),
        const SizedBox(height: 30),
        const DashboardSectionHeader(
          title: 'Quick actions',
          subtitle: 'Common tasks and support',
        ),
        const SizedBox(height: 14),
        ResponsiveContentGrid(
          minItemWidth: 210,
          children: [
            _QuickAction(
              icon: Icons.calendar_month_rounded,
              title: 'Book appointment',
              description: 'Choose a clinic, clinician and time',
              onTap: _book,
            ),
            _QuickAction(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Ask Rudo',
              description: 'Get maternal health guidance',
              onTap: widget.onOpenRudo,
            ),
            _QuickAction(
              icon: Icons.person_outline_rounded,
              title: 'Review profile',
              description: 'Keep your health details current',
              onTap: () => context.pushNamed(ProfileCompletionPage.routeName),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const DashboardSectionHeader(
          title: 'Recent activity',
          subtitle: 'Your latest appointment requests and updates',
        ),
        const SizedBox(height: 14),
        DawaMomCard(
          child: data.appointments.isEmpty
              ? const DawaMomEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No recent health activity',
                  description:
                      'Your appointment requests and updates will appear here.',
                  compact: true,
                )
              : Column(
                  children: data.appointments
                      .take(4)
                      .map((appointment) => _ActivityRow(
                            appointment: appointment,
                            onTap: () => _openAppointment(appointment),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  String _pregnancyStatusValue(HealthProfileSnapshot profile) {
    switch (profile.pregnancyProfileStatus) {
      case PregnancyProfileStatus.pregnantWithData:
        final week = profile.pregnancyWeek;
        return week == null
            ? 'Pregnancy profile ready'
            : 'Pregnancy week $week';
      case PregnancyProfileStatus.pregnantMissingInformation:
        return 'Pregnancy details incomplete';
      case PregnancyProfileStatus.notCurrentlyPregnant:
        return 'Not currently pregnant';
      case PregnancyProfileStatus.notProvided:
        return profile.pregnancyStatus == 'prefer_not_to_say'
            ? 'Status kept private'
            : 'Status not provided';
    }
  }

  String _pregnancyStatusHelper(HealthProfileSnapshot profile) {
    switch (profile.pregnancyProfileStatus) {
      case PregnancyProfileStatus.pregnantWithData:
        final dueDate = profile.calculatedDueDate;
        return dueDate == null
            ? 'Pregnancy guidance is available'
            : 'Estimated due ${DateFormat('d MMM y').format(dueDate)}';
      case PregnancyProfileStatus.pregnantMissingInformation:
        return 'Add dates for relevant guidance';
      case PregnancyProfileStatus.notCurrentlyPregnant:
        return 'Cycle and appointment support available';
      case PregnancyProfileStatus.notProvided:
        return 'Review your health profile at any time';
    }
  }
}

class _DashboardData {
  const _DashboardData({
    required this.appointments,
    required this.healthProfile,
    required this.periodHistory,
  });

  final List<Appointment> appointments;
  final HealthProfileSnapshot healthProfile;
  final List<PeriodRecord> periodHistory;

  Appointment? get nextAppointment {
    final upcoming = appointments.where((item) => item.isUpcoming).toList()
      ..sort((a, b) => Appointment.dateAtTime(a.date, a.startTime)
          .compareTo(Appointment.dateAtTime(b.date, b.startTime)));
    return upcoming.firstOrNull;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.helper,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String helper;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final content = DawaMomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  helper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        canRequestFocus: true,
        borderRadius: BorderRadius.circular(14),
        hoverColor: theme.primary.withValues(alpha: 0.04),
        focusColor: theme.primary.withValues(alpha: 0.1),
        child: content,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: theme.primary.withValues(alpha: 0.04),
        focusColor: theme.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: theme.alternate),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style:
                          theme.bodySmall.copyWith(color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final start = Appointment.dateAtTime(
      appointment.date,
      appointment.startTime,
    );
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.event_note_outlined, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appointment.clinicianName ?? 'Clinician'} - ${appointment.status}',
                    style:
                        theme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    DateFormat('d MMM y, h:mm a').format(start),
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: DawaMomEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Dashboard could not be loaded',
        description: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
