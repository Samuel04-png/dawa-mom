import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/backend/period_tracker_service.dart';
import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/navbar/appointments/appointment_details/appointment_details_widget.dart';
import '/navbar/period_tracker/period_tracker_widget.dart';

class DawaMomResponsiveDashboard extends StatefulWidget {
  const DawaMomResponsiveDashboard({
    super.key,
    required this.onOpenRudo,
    this.appointmentRepository,
    this.healthProfileRepository,
    this.periodTrackerService,
    this.learningRepository,
  });

  final VoidCallback onOpenRudo;
  final AppointmentRepository? appointmentRepository;
  final HealthProfileRepository? healthProfileRepository;
  final PeriodTrackerService? periodTrackerService;
  final DawaLearningRepository? learningRepository;

  @override
  State<DawaMomResponsiveDashboard> createState() =>
      _DawaMomResponsiveDashboardState();
}

class _DawaMomResponsiveDashboardState
    extends State<DawaMomResponsiveDashboard> {
  late final AppointmentRepository _appointments;
  late final HealthProfileRepository _healthProfiles;
  late final PeriodTrackerService _periodTracker;
  late final DawaLearningRepository _learning;
  late Future<_DashboardData> _data;

  @override
  void initState() {
    super.initState();
    _appointments = widget.appointmentRepository ?? AppointmentRepository();
    _healthProfiles =
        widget.healthProfileRepository ?? HealthProfileRepository();
    _periodTracker = widget.periodTrackerService ?? PeriodTrackerService();
    _learning = widget.learningRepository ?? DawaLearningRepository();
    HealthProfileRepository.changes.addListener(_onDataChanged);
    PeriodTrackerService.changes.addListener(_onDataChanged);
    AppointmentRepository.changes.addListener(_onDataChanged);
    DawaLearningRepository.changes.addListener(_onDataChanged);
    _data = _load();
  }

  @override
  void dispose() {
    HealthProfileRepository.changes.removeListener(_onDataChanged);
    PeriodTrackerService.changes.removeListener(_onDataChanged);
    AppointmentRepository.changes.removeListener(_onDataChanged);
    DawaLearningRepository.changes.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _refresh();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait<dynamic>([
      _appointments.getAppointments(),
      _healthProfiles.load(),
      _periodTracker.loadPeriodHistory(),
      _learning.load(),
    ]);
    return _DashboardData(
      appointments: results[0] as List<Appointment>,
      healthProfile: results[1] as HealthProfileSnapshot,
      periodHistory: results[2] as List<PeriodRecord>,
      learningState: results[3] as DawaLearningState,
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
      context.go(PeriodTrackerWidget.routePath);
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
  Widget build(BuildContext context) => FutureBuilder<_DashboardData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const DawaPageScaffold(
              scrollable: false,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return DawaPageScaffold(
              child: DawaCard(
                child: Column(
                  children: [
                    const DawaIconBadge(
                      icon: Icons.cloud_off_rounded,
                      size: 58,
                    ),
                    const SizedBox(height: 10),
                    Text('Dashboard could not be loaded',
                        style: context.dawaSectionTitle),
                    const SizedBox(height: 5),
                    Text(
                      'Check your connection and try again.',
                      style: context.dawaCaption,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: DawaPageScaffold(
              child: _buildDashboard(context, snapshot.data!),
            ),
          );
        },
      );

  Widget _buildDashboard(BuildContext context, _DashboardData data) {
    final profile = data.healthProfile;
    final cycle = PeriodCycleSummary.derive(
      now: DateTime.now(),
      settings: profile.periodSettings,
      history: data.periodHistory,
    );
    final appointment = data.nextAppointment;
    final firstName = profile.name.trim().isEmpty
        ? 'Mama'
        : profile.name.trim().split(RegExp(r'\s+')).first;
    final week = profile.pregnancyWeek;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaAppHeader(
          eyebrow: 'Good ${_dayPeriod()},',
          title: '$firstName ♥',
          notificationUnread: true,
          onNotifications: () => context.push('/notifications'),
          onProfile: () => context.go('/settings'),
        ),
        const SizedBox(height: 8),
        DawaCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: DawaBreakpoints.isMobile(context) ? 205 : 245,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DawaColors.softBlue,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
                Positioned(
                  right: DawaBreakpoints.isMobile(context) ? 8 : 48,
                  bottom: 0,
                  width: DawaBreakpoints.isMobile(context) ? 138 : 190,
                  height: DawaBreakpoints.isMobile(context) ? 194 : 232,
                  child: Image.asset(
                    week == null
                        ? DawaArtwork.motherGreeting
                        : DawaArtwork.pregnancyPhone,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    excludeFromSemantics: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(19),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          week == null
                              ? 'Your health journey'
                              : 'Your pregnancy',
                          style: context.dawaCaption,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          week == null
                              ? _profileHeadline(profile)
                              : 'Week $week',
                          style: context.dawaDisplay.copyWith(fontSize: 31),
                        ),
                        if (week != null)
                          Text(
                            profile.trimester == null
                                ? 'Pregnancy guidance'
                                : '${_ordinal(profile.trimester!)} Trimester',
                            style: const TextStyle(
                              color: DawaColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          week == null
                              ? profile.dashboardPrompt
                              : 'You’re doing amazing, $firstName. Every little step matters.',
                          style: context.dawaCaption,
                        ),
                        const SizedBox(height: 11),
                        FilledButton(
                          onPressed: week == null
                              ? () => context.push('/profileCompletion')
                              : () => context.push('/learn/pregnancy'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(44, 42),
                          ),
                          child: Text(week == null
                              ? 'Complete profile'
                              : 'View journey'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        DawaResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 2,
          desktopColumns: 4,
          children: [
            _HomeMetricCard(
              icon: Icons.water_drop_rounded,
              color: DawaColors.pink,
              label: 'Next period',
              value: cycle.daysUntilNextPeriod == null
                  ? 'Not set up'
                  : cycle.daysUntilNextPeriod == 0
                      ? 'Today'
                      : '${cycle.daysUntilNextPeriod} days',
              helper: cycle.nextPeriodEstimate == null
                  ? 'Add your last period'
                  : DateFormat('d MMM').format(cycle.nextPeriodEstimate!),
              onTap: () => _openPeriodTracker(data),
            ),
            _HomeMetricCard(
              icon: Icons.sync_rounded,
              color: DawaColors.purple,
              label: 'Cycle day',
              value: cycle.cycleDay == null
                  ? 'Not available'
                  : '${cycle.cycleDay} / ${cycle.averageCycleLength ?? 28}',
              helper: cycle.statusLabel,
              onTap: () => _openPeriodTracker(data),
            ),
            _HomeMetricCard(
              icon: Icons.calendar_month_rounded,
              color: DawaColors.green,
              label: 'Next appointment',
              value: appointment == null
                  ? 'Nothing booked'
                  : DateFormat('d MMM • h:mm a').format(
                      Appointment.dateAtTime(
                        appointment.date,
                        appointment.startTime,
                      ),
                    ),
              helper: appointment?.clinicName ?? 'Book when you are ready',
              onTap: appointment == null
                  ? _book
                  : () => _openAppointment(appointment),
            ),
            _HomeMetricCard(
              icon: Icons.workspace_premium_rounded,
              color: DawaColors.primary,
              label: 'Dawa rewards',
              value: '${data.learningState.coins} points',
              helper: 'Healthy actions',
              onTap: () => context.push('/learn/quests'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (appointment != null)
          DawaCard(
            color: DawaColors.softGreen,
            borderColor: DawaColors.green.withValues(alpha: 0.28),
            onTap: () => _openAppointment(appointment),
            semanticLabel:
                'Next appointment at ${appointment.clinicName ?? 'your clinic'}',
            child: Row(
              children: [
                const DawaIconBadge(
                  icon: Icons.calendar_month_rounded,
                  color: DawaColors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next appointment', style: context.dawaCaption),
                      Text(
                        DateFormat('EEE, d MMM • h:mm a').format(
                          Appointment.dateAtTime(
                            appointment.date,
                            appointment.startTime,
                          ),
                        ),
                        style: context.dawaSectionTitle,
                      ),
                      Text(
                        appointment.clinicName ?? 'Dawa clinic',
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
                const DawaStatusPill(
                  label: 'View details',
                  icon: Icons.chevron_right_rounded,
                  color: DawaColors.green,
                ),
              ],
            ),
          ),
        if (appointment != null) const SizedBox(height: 12),
        DawaResponsiveGrid(
          mobileColumns: 4,
          tabletColumns: 4,
          desktopColumns: 4,
          spacing: 8,
          children: [
            _HomeQuickAction(
              icon: Icons.sync_rounded,
              label: 'Track\nCycle',
              onTap: () => _openPeriodTracker(data),
            ),
            _HomeQuickAction(
              icon: Icons.calendar_month_rounded,
              label: 'Book\nVisit',
              onTap: _book,
            ),
            _HomeQuickAction(
              icon: Icons.favorite_border_rounded,
              label: 'Ask\nRudo',
              onTap: widget.onOpenRudo,
            ),
            _HomeQuickAction(
              icon: Icons.menu_book_outlined,
              label: 'Learn',
              onTap: () => context.go('/learn'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DawaCard(
          onTap: () => context.push('/learn/quests'),
          semanticLabel:
              'Dawa Rewards, ${data.learningState.coins} points toward a free scan',
          color: DawaColors.softBlue,
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.workspace_premium_rounded,
                size: 50,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dawa Rewards', style: context.dawaCaption),
                    Text('${data.learningState.coins} points',
                        style: context.dawaTitle),
                    const SizedBox(height: 6),
                    DawaProgressBar(
                      value: data.learningState.coins / 1000,
                      semanticLabel: 'Free scan reward progress',
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(1000 - data.learningState.coins).clamp(0, 1000)} more points for a free scan',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.redeem_rounded,
                  color: DawaColors.primary, size: 38),
              const Icon(Icons.chevron_right_rounded,
                  color: DawaColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DawaCard(
          child: Row(
            children: [
              const DawaIconBadge(
                icon: Icons.lightbulb_outline_rounded,
                color: DawaColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today’s tip', style: context.dawaCaption),
                    Text('Myth vs Fact', style: context.dawaSectionTitle),
                    Text(
                      'Pregnancy changes can be normal, but new or worrying symptoms deserve qualified care.',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/learn/lesson/myth-vs-fact'),
                child: const Text('Read more'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeMetricCard extends StatelessWidget {
  const _HomeMetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.helper,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        semanticLabel: '$label. $value. $helper.',
        child: Row(
          children: [
            DawaIconBadge(icon: icon, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.dawaCaption),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaSectionTitle.copyWith(color: color),
                  ),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaCaption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
        onTap: onTap,
        semanticLabel: label.replaceAll('\n', ' '),
        child: Column(
          children: [
            Icon(icon, color: DawaColors.primary, size: 27),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.dawaCaption.copyWith(
                color: DawaColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _DashboardData {
  const _DashboardData({
    required this.appointments,
    required this.healthProfile,
    required this.periodHistory,
    required this.learningState,
  });

  final List<Appointment> appointments;
  final HealthProfileSnapshot healthProfile;
  final List<PeriodRecord> periodHistory;
  final DawaLearningState learningState;

  Appointment? get nextAppointment {
    final upcoming = appointments.where((item) => item.isUpcoming).toList()
      ..sort((a, b) => Appointment.dateAtTime(a.date, a.startTime)
          .compareTo(Appointment.dateAtTime(b.date, b.startTime)));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

String _dayPeriod() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}

String _ordinal(int value) => switch (value) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '${value}th',
    };

String _profileHeadline(HealthProfileSnapshot profile) {
  return switch (profile.pregnancyProfileStatus) {
    PregnancyProfileStatus.pregnantMissingInformation =>
      'Add pregnancy details',
    PregnancyProfileStatus.notCurrentlyPregnant => 'Care made simple',
    PregnancyProfileStatus.notProvided => 'Welcome to Dawa Mom',
    PregnancyProfileStatus.pregnantWithData => 'Your pregnancy',
  };
}
