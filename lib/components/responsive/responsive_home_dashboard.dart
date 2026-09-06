import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/backend/period_tracker_service.dart';
import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/content/dawa_content_announcement_repository.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/content/dawa_visual_rotation_service.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/games/domain/dawa_health_game.dart';
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
    this.announcementRepository,
    this.visualRotationService,
    this.onReady,
    this.journeyTourKey,
    this.rewardsTourKey,
    this.notificationsTourKey,
  });

  final VoidCallback onOpenRudo;
  final AppointmentRepository? appointmentRepository;
  final HealthProfileRepository? healthProfileRepository;
  final PeriodTrackerService? periodTrackerService;
  final DawaLearningRepository? learningRepository;
  final DawaContentAnnouncementRepository? announcementRepository;
  final DawaVisualRotationService? visualRotationService;
  final VoidCallback? onReady;
  final GlobalKey? journeyTourKey;
  final GlobalKey? rewardsTourKey;
  final GlobalKey? notificationsTourKey;

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
  late final DawaContentAnnouncementRepository _announcements;
  late final DawaVisualRotationService _visualRotation;
  late Future<_DashboardData> _data;
  List<DawaContentAnnouncement> _activeAnnouncements = const [];
  String? _announcementContext;
  DawaLearningAsset? _activeSpotlight;
  DawaLearningAsset? _activeJourneyVisual;
  String? _visualContext;
  String? _journeyVisualContext;
  bool _readyNotified = false;

  @override
  void initState() {
    super.initState();
    _appointments = widget.appointmentRepository ?? AppointmentRepository();
    _healthProfiles =
        widget.healthProfileRepository ?? HealthProfileRepository();
    _periodTracker = widget.periodTrackerService ?? PeriodTrackerService();
    _learning = widget.learningRepository ?? DawaLearningRepository();
    _announcements = widget.announcementRepository ??
        DawaContentAnnouncementRepository.tryLive();
    _visualRotation =
        widget.visualRotationService ?? DawaVisualRotationService();
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
    final profile = results[1] as HealthProfileSnapshot;
    return _DashboardData(
      appointments: results[0] as List<Appointment>,
      healthProfile: profile,
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
              child: _HomeLoadingSkeleton(),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return DawaPageScaffold(
              child: DawaErrorState(
                title: 'Your home did not load',
                message: 'Check your internet, then try again.',
                onRetry: _refresh,
              ),
            );
          }
          if (!_readyNotified) {
            _readyNotified = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onReady?.call();
            });
          }
          _ensureContextualContent(snapshot.data!.healthProfile);
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
    final journey = _homeJourney(
      profile: profile,
      cycle: cycle,
      firstName: firstName,
      openCycle: () => _openPeriodTracker(data),
      openPregnancy: () => context.push('/learn/pregnancy'),
      openLearn: () => context.go('/learn'),
      cycleVisualAssetId: _activeJourneyVisual?.id,
      activeCycleGame: _activeCycleGame(data.learningState),
      continueCycleGame: (game) => context.push(game.route),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaAppHeader(
          eyebrow: 'Good ${_dayPeriod()},',
          title: firstName,
          notificationUnread: true,
          notificationKey: widget.notificationsTourKey,
          onNotifications: () => context.push('/notifications'),
          onProfile: () => context.go('/settings'),
        ),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: widget.journeyTourKey,
          child: _HomeJourneyHeroCard(
            key: const ValueKey('home-current-journey-hero'),
            journey: journey,
          ),
        ),
        if (!profile.isComplete) ...[
          const SizedBox(height: DawaSpacing.sm),
          _ProfileCompletionBanner(
            profile: profile,
            onTap: () => context.push('/profileCompletion'),
          ),
        ],
        const SizedBox(height: DawaSpacing.sm),
        DawaResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 2,
          desktopColumns: 2,
          children: [
            _HomeMetricCard(
              icon: Icons.water_drop_rounded,
              color: DawaColors.pink,
              label: 'Next period',
              value: cycle.daysUntilNextPeriod == null
                  ? 'Not set up yet'
                  : cycle.daysUntilNextPeriod == 0
                      ? 'Estimated today'
                      : 'Estimated in ${cycle.daysUntilNextPeriod} days',
              helper: cycle.nextPeriodEstimate == null
                  ? 'Add your last period to begin'
                  : DateFormat('d MMM').format(cycle.nextPeriodEstimate!),
              onTap: () => _openPeriodTracker(data),
            ),
            _HomeMetricCard(
              icon: Icons.add_task_rounded,
              color: DawaColors.green,
              label: 'Today’s check-in',
              value: 'Ready to log',
              helper: 'Symptoms, mood and energy',
              onTap: () => _openPeriodTracker(data),
            ),
          ],
        ),
        const SizedBox(height: DawaSpacing.md),
        _HomeAppointmentCard(
          appointment: appointment,
          onBook: _book,
          onOpen:
              appointment == null ? null : () => _openAppointment(appointment),
        ),
        const SizedBox(height: DawaSpacing.md),
        _HomeQuickActionGrid(
          children: [
            _HomeQuickAction(
              icon: Icons.sync_rounded,
              label: 'Track\nCycle',
              color: DawaColors.pink,
              onTap: () => _openPeriodTracker(data),
            ),
            _HomeQuickAction(
              icon: Icons.calendar_month_rounded,
              label: 'Book\nVisit',
              color: DawaColors.greenDark,
              onTap: _book,
            ),
            _HomeQuickAction(
              icon: Icons.favorite_border_rounded,
              label: 'Ask\nRudo',
              color: DawaColors.orange,
              onTap: widget.onOpenRudo,
            ),
            _HomeQuickAction(
              icon: Icons.menu_book_outlined,
              label: 'Learn',
              color: DawaColors.purple,
              onTap: () => context.go('/learn'),
            ),
          ],
        ),
        const SizedBox(height: DawaSpacing.md),
        _HomeRewardCard(
          key: widget.rewardsTourKey,
          coins: data.learningState.coins,
          onTap: () => context.push('/learn/rewards'),
        ),
        if (_activeAnnouncements.isNotEmpty) ...[
          const SizedBox(height: DawaSpacing.md),
          _HomeAnnouncementCard(
            announcement: _activeAnnouncements.first,
            onOpen: () => context.push(_activeAnnouncements.first.deepLink),
          ),
        ],
        const SizedBox(height: DawaSpacing.md),
        _DailyTipCard(
          presentation: _spotlightPresentation(
            _activeSpotlight ?? _fallbackSpotlight(profile),
          ),
          onRead: () => context.push(
            _spotlightPresentation(
              _activeSpotlight ?? _fallbackSpotlight(profile),
            ).route,
          ),
        ),
      ],
    );
  }

  void _ensureContextualContent(HealthProfileSnapshot profile) {
    final journey = _journeyContext(profile);
    final profileState =
        profile.isComplete ? 'profile_complete' : 'profile_incomplete';
    final contextKey = '${journey.name}:$profileState';
    if (_announcementContext != contextKey) {
      _announcementContext = contextKey;
      unawaited(
        _announcements
            .load(
          journey: journey,
          placement: 'home',
          profileState: profileState,
        )
            .then((items) {
          if (mounted && _announcementContext == contextKey) {
            setState(() => _activeAnnouncements = items);
          }
        }),
      );
    }
    if (_visualContext != contextKey) {
      _visualContext = contextKey;
      unawaited(
        _visualRotation
            .select(
          DawaVisualRotationRequest(
            placement: DawaAssetPlacement.homeSpotlight,
            contextKey: 'home-spotlight',
            topics: DawaLearningAssetRegistry.topicsForJourney(journey),
            cadence: DawaRotationCadence.daily,
            userId: profile.profile['id']?.toString(),
            journey: journey,
            aspectRatio: 1,
          ),
        )
            .then((asset) {
          if (mounted && _visualContext == contextKey) {
            setState(() => _activeSpotlight = asset);
          }
        }),
      );
    }
    final heroContextKey = '${journey.name}:home-journey';
    if (_journeyVisualContext != heroContextKey) {
      _journeyVisualContext = heroContextKey;
      if (journey != DawaJourneyContext.cycle) {
        _activeJourneyVisual = null;
      } else {
        unawaited(
          _visualRotation
              .select(
            DawaVisualRotationRequest(
              placement: DawaAssetPlacement.homeHero,
              contextKey: 'home-cycle-thumbnail',
              topics: const [DawaLearningTopic.periodTracking],
              cadence: DawaRotationCadence.daily,
              userId: profile.profile['id']?.toString(),
              journey: DawaJourneyContext.cycle,
              aspectRatio: 1,
            ),
          )
              .then((asset) {
            if (mounted && _journeyVisualContext == heroContextKey) {
              setState(() => _activeJourneyVisual = asset);
            }
          }),
        );
      }
    }
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading your DawaMom home',
        liveRegion: true,
        child: ExcludeSemantics(
          child: Column(
            children: [
              const Row(
                children: [
                  DawaShimmerBox(width: 105, height: 38, radius: 12),
                  Spacer(),
                  DawaShimmerBox(width: 38, height: 38, radius: 19),
                ],
              ),
              const SizedBox(height: DawaSpacing.md),
              DawaCard(
                color: DawaColors.softBlue,
                featured: true,
                child: SizedBox(
                  height: DawaBreakpoints.isMobile(context) ? 190 : 220,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DawaShimmerBox(height: 10, widthFactor: 0.44),
                            SizedBox(height: 10),
                            DawaShimmerBox(height: 24, widthFactor: 0.72),
                            SizedBox(height: 10),
                            DawaShimmerBox(height: 11),
                            SizedBox(height: 7),
                            DawaShimmerBox(height: 11, widthFactor: 0.76),
                            SizedBox(height: 16),
                            DawaShimmerBox(
                              width: 130,
                              height: 42,
                              radius: 14,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: DawaShimmerBox(height: 152, radius: 24),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DawaSpacing.sm),
              const Row(
                children: [
                  Expanded(
                    child: DawaLoadingSkeleton(
                      layout: DawaSkeletonLayout.stat,
                      label: 'Loading health date',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DawaLoadingSkeleton(
                      layout: DawaSkeletonLayout.stat,
                      label: 'Loading cycle date',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DawaSpacing.sm),
              const DawaLoadingSkeleton(
                layout: DawaSkeletonLayout.appointment,
                label: 'Loading appointment',
              ),
              const SizedBox(height: DawaSpacing.sm),
              const DawaLoadingSkeleton(
                layout: DawaSkeletonLayout.reward,
                label: 'Loading rewards',
              ),
            ],
          ),
        ),
      );
}

class _HomeJourneyHeroCard extends StatelessWidget {
  const _HomeJourneyHeroCard({
    super.key,
    required this.journey,
  });

  final _HomeJourneyPresentation journey;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: EdgeInsets.zero,
        featured: true,
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .18),
        semanticLabel: journey.semanticLabel,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final narrowStrip =
                MediaQuery.sizeOf(context).width < 370 || textScale > 1.2;
            final tablet = constraints.maxWidth >= 600;
            final copy = Padding(
              padding: tablet
                  ? const EdgeInsets.all(DawaSpacing.lg)
                  : narrowStrip
                      ? const EdgeInsets.fromLTRB(18, 16, 18, 18)
                      : const EdgeInsets.fromLTRB(18, 0, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    journey.category,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    journey.title,
                    style: context.dawaDisplay.copyWith(fontSize: 27),
                  ),
                  const SizedBox(height: 5),
                  Text(journey.subtitle, style: context.dawaBody),
                  if (journey.progress != null) ...[
                    const SizedBox(height: DawaSpacing.sm),
                    DawaProgressBar(
                      value: journey.progress!,
                      semanticLabel:
                          journey.progressLabel ?? 'Journey progress',
                      color: DawaColors.green,
                    ),
                    if (journey.progressLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        journey.progressLabel!,
                        style: context.dawaCaption,
                      ),
                    ],
                  ],
                  const SizedBox(height: DawaSpacing.sm),
                  FilledButton(
                    onPressed: journey.onOpen,
                    child: Text(journey.actionLabel),
                  ),
                ],
              ),
            );
            if (narrowStrip) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const ValueKey('home-journey-thumbnail'),
                    height: 110,
                    child: DawaContextualImage(
                      assetId: journey.visualAssetId,
                      variant: DawaImageVariant.featuredBanner,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  copy,
                ],
              );
            }
            final imageWidth = tablet
                ? (constraints.maxWidth * .32).clamp(180.0, 240.0)
                : (constraints.maxWidth * .31).clamp(104.0, 124.0);
            return Padding(
              padding: tablet
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  SizedBox(
                    key: const ValueKey('home-journey-thumbnail'),
                    width: imageWidth,
                    child: DawaContextualImage(
                      assetId: journey.visualAssetId,
                      variant: DawaImageVariant.cardSideImage,
                      borderRadius: BorderRadius.circular(
                        tablet ? DawaRadii.feature : 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _ProfileCompletionBanner extends StatelessWidget {
  const _ProfileCompletionBanner({
    required this.profile,
    required this.onTap,
  });

  final HealthProfileSnapshot profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        onTap: onTap,
        semanticLabel:
            'Finish your health profile. ${_nextProfileStep(profile)}',
        child: Row(
          children: [
            const DawaIconBadge(
              icon: Icons.assignment_ind_outlined,
              color: DawaColors.green,
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finish your health profile',
                    style: context.dawaSectionTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _nextProfileStep(profile),
                    style: context.dawaCaption,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: const Text('Continue'),
            ),
          ],
        ),
      );
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
        padding: const EdgeInsets.all(DawaSpacing.sm),
        onTap: onTap,
        semanticLabel: '$label. $value. $helper.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DawaIconBadge(icon: icon, color: color, size: 42),
                const SizedBox(width: DawaSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DawaSpacing.sm),
            Text(
              value,
              style: context.dawaSectionTitle.copyWith(color: color),
            ),
            const SizedBox(height: DawaSpacing.xxs),
            Text(helper, style: context.dawaCaption),
          ],
        ),
      );
}

class _HomeAppointmentCard extends StatelessWidget {
  const _HomeAppointmentCard({
    required this.appointment,
    required this.onBook,
    required this.onOpen,
  });

  final Appointment? appointment;
  final VoidCallback onBook;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final item = appointment;
    final date =
        item == null ? null : Appointment.dateAtTime(item.date, item.startTime);
    return DawaCard(
      semanticLabel: item == null
          ? 'No appointment booked. Book a clinic visit.'
          : 'Next ${_appointmentTypeLabel(item.appointmentType)} at '
              '${item.clinicName ?? 'your selected clinic'}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largerText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
          final compact = constraints.maxWidth < 280 || largerText;
          final dense = constraints.maxWidth < 340;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (dense) ...[
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: DawaColors.green,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      item == null ? 'Your next visit' : 'Next appointment',
                      style: context.dawaCaption.copyWith(
                        color: DawaColors.greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DawaSpacing.xxs),
              Text(
                item == null
                    ? 'No appointment booked'
                    : _appointmentTypeLabel(item.appointmentType),
                style: context.dawaSectionTitle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: DawaSpacing.xxs),
              Text(
                item == null
                    ? 'Choose a clinic, health worker and time that suit you.'
                    : '${DateFormat('EEE, d MMM • h:mm a').format(date!)}\n'
                        '${item.clinicName ?? 'Clinic details pending'}',
                style: context.dawaBody,
              ),
            ],
          );
          final details = dense
              ? copy
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DawaIconBadge(
                      icon: Icons.calendar_month_rounded,
                      color: DawaColors.green,
                      size: 42,
                    ),
                    const SizedBox(width: DawaSpacing.sm),
                    Expanded(child: copy),
                  ],
                );
          final button = item == null
              ? FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Book visit'),
                )
              : OutlinedButton(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('View details'),
                );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: DawaSpacing.sm),
                Align(alignment: Alignment.centerRight, child: button),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: DawaSpacing.md),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _HomeRewardCard extends StatelessWidget {
  const _HomeRewardCard({
    super.key,
    required this.coins,
    required this.onTap,
  });

  final int coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const goal = 1000;
    final remaining = (goal - coins).clamp(0, goal);
    return DawaCard(
      onTap: onTap,
      semanticLabel:
          'Dawa Rewards. $coins points. $remaining points to a free scan.',
      child: Row(
        children: [
          const DawaIconBadge(
            icon: Icons.workspace_premium_rounded,
            size: 50,
          ),
          const SizedBox(width: DawaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dawa Rewards', style: context.dawaCaption),
                Text('$coins points', style: context.dawaTitle),
                const SizedBox(height: DawaSpacing.xs),
                DawaProgressBar(
                  value: coins / goal,
                  semanticLabel: 'Free scan reward progress',
                ),
                const SizedBox(height: DawaSpacing.xxs),
                Text(
                  remaining == 0
                      ? 'Your free scan reward is ready'
                      : 'Earn $remaining more points for a free scan',
                  style: context.dawaCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: DawaSpacing.xs),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DawaColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: DawaColors.greenDark,
              size: 27,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: DawaColors.primary),
        ],
      ),
    );
  }
}

class _HomeAnnouncementCard extends StatelessWidget {
  const _HomeAnnouncementCard({
    required this.announcement,
    required this.onOpen,
  });

  final DawaContentAnnouncement announcement;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => DawaCard(
        onTap: onOpen,
        semanticLabel: '${announcement.title}. ${announcement.body}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: DawaContextualImage(
                assetId: announcement.assetId,
                variant: DawaImageVariant.cardSideImage,
              ),
            ),
            const SizedBox(width: DawaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAWAMOM UPDATE',
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    announcement.title,
                    style: context.dawaSectionTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    announcement.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaCaption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DawaColors.primary,
            ),
          ],
        ),
      );
}

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({
    required this.presentation,
    required this.onRead,
  });

  final _SpotlightPresentation presentation;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final tip = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: DawaContextualImage(
                    assetId: presentation.assetId,
                    variant: DawaImageVariant.compactThumbnail,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today’s visual tip', style: context.dawaCaption),
                      Text(
                        presentation.title,
                        style: context.dawaSectionTitle,
                      ),
                      Text(
                        presentation.body,
                        style: context.dawaBody,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final action = OutlinedButton(
              onPressed: onRead,
              child: const Text('Read more'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tip,
                  const SizedBox(height: DawaSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: tip),
                const SizedBox(width: DawaSpacing.md),
                action,
              ],
            );
          },
        ),
      );
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 112,
        child: DawaCard(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          onTap: onTap,
          semanticLabel: label.replaceAll('\n', ' '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: DawaIconBadge(icon: icon, color: color, size: 40),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.ink,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _HomeQuickActionGrid extends StatelessWidget {
  const _HomeQuickActionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          // Four actions remain pleasantly compact on normal phones. Very
          // narrow handsets promote them to two columns instead of squeezing
          // icons and labels into unusable slivers.
          final columns = constraints.maxWidth < 320 ? 2 : 4;
          const spacing = 8.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final child in children)
                SizedBox(width: itemWidth, child: child),
            ],
          );
        },
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

String _appointmentTypeLabel(String value) {
  final words = value
      .split(RegExp(r'[_\s-]+'))
      .where((word) => word.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) return 'Clinic visit';
  final label = words.join(' ');
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

class _HomeJourneyPresentation {
  const _HomeJourneyPresentation({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.visualAssetId,
    required this.actionLabel,
    required this.onOpen,
    required this.semanticLabel,
    this.progress,
    this.progressLabel,
  });

  final String category;
  final String title;
  final String subtitle;
  final String visualAssetId;
  final String actionLabel;
  final VoidCallback onOpen;
  final String semanticLabel;
  final double? progress;
  final String? progressLabel;
}

_HomeJourneyPresentation _homeJourney({
  required HealthProfileSnapshot profile,
  required PeriodCycleSummary cycle,
  required String firstName,
  required VoidCallback openCycle,
  required VoidCallback openPregnancy,
  required VoidCallback openLearn,
  String? cycleVisualAssetId,
  DawaHealthGame? activeCycleGame,
  ValueChanged<DawaHealthGame>? continueCycleGame,
}) {
  final week = profile.pregnancyWeek;
  if (week != null) {
    return _HomeJourneyPresentation(
      category: 'Your pregnancy',
      title: 'Week $week',
      subtitle:
          '${profile.trimester == null ? 'Pregnancy care' : '${_ordinal(profile.trimester!)} trimester'}\n'
          'You are doing well, $firstName. Every small step matters.',
      visualAssetId: 'antenatal_stages_01',
      actionLabel: 'View pregnancy',
      onOpen: openPregnancy,
      progress: week / 40,
      progressLabel: 'Week $week of 40',
      semanticLabel: 'Pregnancy, week $week.',
    );
  }

  final cycleDay = cycle.cycleDay;
  if (cycleDay != null) {
    final cycleLength = cycle.averageCycleLength ?? 28;
    return _HomeJourneyPresentation(
      category: 'Your cycle today',
      title: 'Cycle day $cycleDay',
      subtitle: '${cycle.statusLabel}. Dates are estimates from your logs.',
      visualAssetId: cycleVisualAssetId ?? 'period_tracking_01',
      actionLabel:
          activeCycleGame == null ? 'View cycle' : 'Continue cycle game',
      onOpen: activeCycleGame == null || continueCycleGame == null
          ? openCycle
          : () => continueCycleGame(activeCycleGame),
      progress: (cycleDay / cycleLength).clamp(0, 1),
      progressLabel: 'Day $cycleDay of about $cycleLength',
      semanticLabel: 'Cycle day $cycleDay.',
    );
  }

  return _HomeJourneyPresentation(
    category: 'Your health today',
    title: 'Hello, $firstName',
    subtitle:
        'Choose one small health step for today. DawaMom is here to help.',
    visualAssetId: 'cervical_awareness_02',
    actionLabel: 'Explore Learn',
    onOpen: openLearn,
    semanticLabel: 'Your health today. Hello, $firstName.',
  );
}

DawaHealthGame? _activeCycleGame(DawaLearningState state) {
  final active = state.gameProgress.values
      .where(
        (progress) =>
            !state.completedIds.contains(progress.gameId) &&
            DawaHealthGameCatalog.cycleGames
                .any((game) => game.id == progress.gameId),
      )
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  if (active.isEmpty) return null;
  return DawaHealthGameCatalog.byId(active.first.gameId);
}

DawaJourneyContext _journeyContext(HealthProfileSnapshot profile) {
  if (profile.pregnancyStatus == 'postpartum') {
    return DawaJourneyContext.postpartum;
  }
  if (profile.pregnancyProfileStatus ==
          PregnancyProfileStatus.pregnantWithData ||
      profile.pregnancyProfileStatus ==
          PregnancyProfileStatus.pregnantMissingInformation) {
    return DawaJourneyContext.pregnancy;
  }
  if (profile.lastPeriodStart != null) return DawaJourneyContext.cycle;
  return DawaJourneyContext.general;
}

class _SpotlightPresentation {
  const _SpotlightPresentation({
    required this.assetId,
    required this.title,
    required this.body,
    required this.route,
  });

  final String assetId;
  final String title;
  final String body;
  final String route;
}

_SpotlightPresentation _spotlightPresentation(DawaLearningAsset? asset) {
  final resolved = asset ?? DawaLearningAssetRegistry.byId('myths_vs_fact_02');
  return switch (resolved.topic) {
    DawaLearningTopic.cervicalCancerAwareness => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Cervical health',
        body: 'Screening questions are worth discussing with a health worker.',
        route: '/learn/article/cervical-awareness',
      ),
    DawaLearningTopic.screeningWithoutFear => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Screening Without Fear',
        body:
            'Ask what will happen, how privacy is protected, and what comes next.',
        route: '/learn/quests/screening',
      ),
    DawaLearningTopic.pregnancyBasics => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Pregnancy basics',
        body: 'Small daily steps and regular antenatal care support wellbeing.',
        route: '/learn/topic/pregnancy-basics',
      ),
    DawaLearningTopic.secondTrimesterFoods => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Balanced pregnancy meals',
        body: 'Choose varied, safely prepared foods that are available to you.',
        route: '/learn/topic/second-trimester-foods',
      ),
    DawaLearningTopic.preparingForClinicVisit => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Prepare for your clinic visit',
        body: 'Write down symptoms, medicines, important dates, and questions.',
        route: '/learn/topic/clinic-visit',
      ),
    DawaLearningTopic.mythsVsFact => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Myth vs Fact',
        body: 'Pause and check uncertain health advice with a trusted source.',
        route: '/learn/lesson/myth-vs-fact',
      ),
    DawaLearningTopic.periodTracking => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Know your cycle',
        body:
            'Record what happened and remember that predictions are estimates.',
        route: '/learn/topic/period-tracking',
      ),
    DawaLearningTopic.antenatalVisitsAndStages => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Antenatal visits',
        body: 'Ask what was checked, what it means, and when to return.',
        route: '/learn/topic/antenatal-visits',
      ),
    DawaLearningTopic.postpartumRecovery => _SpotlightPresentation(
        assetId: resolved.id,
        title: 'Postpartum recovery',
        body:
            'Rest when possible and tell a health worker about worrying changes.',
        route: '/learn/topic/postpartum-recovery',
      ),
  };
}

DawaLearningAsset _fallbackSpotlight(HealthProfileSnapshot profile) =>
    DawaLearningAssetRegistry.byId(
      switch (_journeyContext(profile)) {
        DawaJourneyContext.pregnancy => 'pregnancy_basics_02',
        DawaJourneyContext.cycle => 'period_tracking_04',
        DawaJourneyContext.postpartum => 'postpartum_recovery_02',
        DawaJourneyContext.general => 'myths_vs_fact_02',
      },
    );

String _nextProfileStep(HealthProfileSnapshot profile) {
  if (!profile.personalComplete) {
    return 'Next step: add your name and date of birth.';
  }
  if (!profile.contactComplete) {
    return 'Next step: add a phone number and address.';
  }
  if (!profile.pregnancyComplete) {
    return 'Next step: choose your pregnancy status.';
  }
  if (!profile.periodComplete) {
    return 'Next step: add the first day of your last period.';
  }
  return 'Your health profile is ready.';
}
