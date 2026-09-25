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
  String? _visualContext;
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
    final unavailable = <String>{};
    Future<T> loadSection<T>(
      String name,
      Future<T> Function() loader,
      T fallback,
    ) async {
      try {
        return await loader();
      } catch (_) {
        unavailable.add(name);
        return fallback;
      }
    }

    final results = await Future.wait<dynamic>([
      loadSection(
          'appointments', _appointments.getAppointments, <Appointment>[]),
      loadSection(
        'profile',
        _healthProfiles.load,
        const HealthProfileSnapshot(
          profile: <String, dynamic>{},
          mother: <String, dynamic>{},
          pregnancy: null,
          periodSettings: null,
        ),
      ),
      loadSection('cycle', _periodTracker.loadPeriodHistory, <PeriodRecord>[]),
      loadSection(
        'rewards',
        _learning.load,
        const DawaLearningState(coins: 0, streak: 0),
      ),
    ]);
    final profile = results[1] as HealthProfileSnapshot;
    return _DashboardData(
      appointments: results[0] as List<Appointment>,
      healthProfile: profile,
      periodHistory: results[2] as List<PeriodRecord>,
      learningState: results[3] as DawaLearningState,
      unavailableSections: unavailable,
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
    final journey = _homeJourney(
      profile: profile,
      cycle: cycle,
      openCycle: () => _openPeriodTracker(data),
      openPregnancy: () => context.push('/learn/pregnancy'),
      openLearn: () => context.go('/learn'),
      openProfile: () => context.push('/profileCompletion'),
      profileAvailable: !data.unavailableSections.contains('profile'),
      activeCycleGame: _activeCycleGame(data.learningState),
      continueCycleGame: (game) => context.push(game.route),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaAppHeader(
          notificationUnread: true,
          notificationKey: widget.notificationsTourKey,
          onNotifications: () => context.push('/notifications'),
          onProfile: () => context.go('/settings'),
        ),
        if (data.unavailableSections.isNotEmpty) ...[
          _HomePartialDataNotice(onRetry: _refresh),
          const SizedBox(height: DawaSpacing.xs),
        ],
        const SizedBox(height: 8),
        KeyedSubtree(
          key: widget.journeyTourKey,
          child: _HomeJourneyHeroCard(
            key: const ValueKey('home-current-journey-hero'),
            journey: journey,
          ),
        ),
        const SizedBox(height: DawaSpacing.sm),
        _HomeQuickActions(
          onTrack: () => _openPeriodTracker(data),
          onCheckIn: () => _openPeriodTracker(data),
          onBook: _book,
          onLearn: () => context.go('/learn'),
        ),
        if (!data.unavailableSections.contains('profile') &&
            !profile.isComplete) ...[
          const SizedBox(height: DawaSpacing.md),
          _ProfileCompletionBanner(
            profile: profile,
            onTap: () => context.push('/profileCompletion'),
          ),
        ],
        const SizedBox(height: DawaSpacing.md),
        _HomeAppointmentCard(
          appointment: appointment,
          available: !data.unavailableSections.contains('appointments'),
          onBook: _book,
          onOpen:
              appointment == null ? null : () => _openAppointment(appointment),
        ),
        const SizedBox(height: DawaSpacing.md),
        _HomeRewardCard(
          key: widget.rewardsTourKey,
          coins: data.learningState.coins,
          available: !data.unavailableSections.contains('rewards'),
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

class _HomePartialDataNotice extends StatelessWidget {
  const _HomePartialDataNotice({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          decoration: BoxDecoration(
            color: DawaColors.warningSurface,
            borderRadius: BorderRadius.circular(DawaRadii.small),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: DawaColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Some updates are unavailable.',
                  style: context.dawaCaption.copyWith(
                    color: DawaColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class _HomeQuickActions extends StatelessWidget {
  const _HomeQuickActions({
    required this.onTrack,
    required this.onCheckIn,
    required this.onBook,
    required this.onLearn,
  });

  final VoidCallback onTrack;
  final VoidCallback onCheckIn;
  final VoidCallback onBook;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    final actions = <_HomeQuickActionData>[
      _HomeQuickActionData(
        label: 'Log my\nperiod',
        semanticLabel: 'Log my period',
        icon: Icons.water_drop_rounded,
        color: DawaColors.pink,
        background: DawaColors.softPink,
        onTap: onTrack,
      ),
      _HomeQuickActionData(
        label: 'How I feel\ntoday',
        semanticLabel: 'How I feel today',
        icon: Icons.sentiment_satisfied_alt_rounded,
        color: DawaColors.primary,
        background: const Color(0xFFEAF6FF),
        onTap: onCheckIn,
      ),
      _HomeQuickActionData(
        label: 'Book a\nvisit',
        semanticLabel: 'Book a visit',
        icon: Icons.calendar_month_rounded,
        color: DawaColors.greenDark,
        background: DawaColors.softGreen,
        onTap: onBook,
      ),
      _HomeQuickActionData(
        label: 'Learn\nsomething',
        semanticLabel: 'Learn something',
        icon: Icons.menu_book_rounded,
        color: DawaColors.purple,
        background: DawaColors.softPurple,
        onTap: onLearn,
      ),
    ];
    return Semantics(
      container: true,
      label: 'Home quick actions',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(child: _HomeQuickAction(data: actions[index])),
            if (index != actions.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HomeQuickActionData {
  const _HomeQuickActionData({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({required this.data});

  final _HomeQuickActionData data;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: data.semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: data.background,
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          child: InkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(DawaRadii.medium),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 124),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(data.icon, color: data.color, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      data.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.dawaSectionTitle.copyWith(
                        fontSize:
                            MediaQuery.sizeOf(context).width < 380 ? 11 : 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: data.color),
                  ],
                ),
              ),
            ),
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
            final tablet = constraints.maxWidth >= 600;
            final compactStacked = constraints.maxWidth < 340;
            final stacked = textScale > 1.2 || compactStacked;
            final copy = Padding(
              padding: EdgeInsets.fromLTRB(
                tablet ? 28 : 20,
                tablet ? 24 : 18,
                tablet ? 24 : 16,
                tablet ? 22 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    journey.category,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    journey.title,
                    style: context.dawaDisplay.copyWith(
                      fontSize: tablet ? 40 : 31,
                      height: 1.02,
                    ),
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
                  if (journey.statusLine != null) ...[
                    const SizedBox(height: DawaSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 20, color: DawaColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            journey.statusLine!,
                            style: context.dawaBody.copyWith(
                              color: DawaColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DawaSpacing.sm),
                  SizedBox(
                    width: tablet ? 228 : 172,
                    child: FilledButton.icon(
                      onPressed: journey.onOpen,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(journey.actionLabel),
                    ),
                  ),
                ],
              ),
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const ValueKey('home-journey-thumbnail'),
                    height: compactStacked ? 88 : 110,
                    child: Image.asset(
                      DawaArtwork.homeHeroMama,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      excludeFromSemantics: true,
                    ),
                  ),
                  copy,
                ],
              );
            }
            // Illustration fills the right ~38% of the card while the copy owns
            // the left ~60%, so the portrait stays visible (not pushed off the
            // edge) and the card stays as compact as its content.
            final imageWidth = (constraints.maxWidth * (tablet ? .32 : .38))
                .clamp(tablet ? 190.0 : 120.0, tablet ? 320.0 : 168.0);
            final copyWidth = (constraints.maxWidth * (tablet ? .58 : .60))
                .clamp(160.0, 560.0);
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7F9FF), Color(0xFFE7EDFF)],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    key: const ValueKey('home-journey-thumbnail'),
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: imageWidth,
                    child: IgnorePointer(
                      child: ClipRect(
                        child: Image.asset(
                          DawaArtwork.homeHeroMama,
                          fit: BoxFit.cover,
                          alignment: Alignment.topRight,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: copyWidth,
                      child: copy,
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
        color: DawaColors.warningSurface,
        borderColor: DawaColors.gold.withValues(alpha: .24),
        onTap: onTap,
        semanticLabel:
            'Finish your health profile. ${_nextProfileStep(profile)}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactAction = TextButton.icon(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: DawaColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                // Keep the compact visual treatment while retaining the
                // platform's 48px minimum touch target.
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Continue'),
            );
            const icon = DawaIconBadge(
              icon: Icons.assignment_ind_outlined,
              color: DawaColors.primary,
              size: 42,
            );
            final textGroup = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your health profile',
                  style: context.dawaSectionTitle.copyWith(height: 1.25),
                ),
                const SizedBox(height: 4),
                Text(
                  _nextProfileStep(profile),
                  style: context.dawaCaption.copyWith(height: 1.3),
                ),
              ],
            );
            // Measured: side-by-side still squeezes the title to ~115-155px on
            // phones (inner card width ~308-378), even at a 430 viewport. The
            // title only fits a comfortable line next to the compact action once
            // the inner width reaches tablet territory, so phones all stack
            // (copy gets full width, action below) and the wider layout is used
            // from ~500 inner px (tablet/desktop) up.
            if (constraints.maxWidth < 500) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: textGroup),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: compactAction,
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: textGroup),
                  const SizedBox(width: 8),
                  compactAction,
                ],
              ),
            );
          },
        ),
      );
}

class _HomeAppointmentCard extends StatelessWidget {
  const _HomeAppointmentCard({
    required this.appointment,
    required this.available,
    required this.onBook,
    required this.onOpen,
  });

  final Appointment? appointment;
  final bool available;
  final VoidCallback onBook;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final item = appointment;
    final date =
        item == null ? null : Appointment.dateAtTime(item.date, item.startTime);
    return DawaCard(
      semanticLabel: !available
          ? 'Visit information is unavailable. Pull down to try again.'
          : item == null
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
                    ? available
                        ? 'No appointment yet'
                        : 'Visits unavailable'
                    : _appointmentTypeLabel(item.appointmentType),
                style: context.dawaSectionTitle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: DawaSpacing.xxs),
              Text(
                item == null
                    ? available
                        ? 'Choose a clinic and time that suit you.'
                        : 'Pull down to try again.'
                    : '${DateFormat('EEE, d MMM • h:mm a').format(date!)}\n'
                        '${item.clinicName ?? 'Clinic details pending'}',
                style: context.dawaBody,
              ),
              if (item != null) ...[
                const SizedBox(height: DawaSpacing.xxs),
                Text(
                  _appointmentStatusLabel(item.status),
                  style: context.dawaCaption.copyWith(
                    color: DawaColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
          final button = item == null && available
              ? FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Book visit'),
                )
              : item != null
                  ? OutlinedButton(
                      onPressed: onOpen,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('View details'),
                    )
                  : const SizedBox.shrink();
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
    required this.available,
    required this.onTap,
  });

  final int coins;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const goal = 1000;
    final remaining = (goal - coins).clamp(0, goal);
    return DawaCard(
      onTap: onTap,
      semanticLabel: available
          ? 'Dawa Points. $coins points. $remaining points to a free scan.'
          : 'Dawa Points are unavailable. Pull down to try again.',
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
                Text('Dawa Points', style: context.dawaCaption),
                Text(
                  available ? '$coins points' : 'Points unavailable',
                  style: context.dawaTitle,
                ),
                const SizedBox(height: DawaSpacing.xs),
                DawaProgressBar(
                  value: available ? coins / goal : 0,
                  semanticLabel: 'Free scan reward progress',
                ),
                const SizedBox(height: DawaSpacing.xxs),
                Text(
                  !available
                      ? 'Pull down to try again'
                      : remaining == 0
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
                      Text('Today’s tip', style: context.dawaCaption),
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

class _DashboardData {
  const _DashboardData({
    required this.appointments,
    required this.healthProfile,
    required this.periodHistory,
    required this.learningState,
    this.unavailableSections = const <String>{},
  });

  final List<Appointment> appointments;
  final HealthProfileSnapshot healthProfile;
  final List<PeriodRecord> periodHistory;
  final DawaLearningState learningState;
  final Set<String> unavailableSections;

  Appointment? get nextAppointment {
    final upcoming = appointments.where((item) => item.isUpcoming).toList()
      ..sort((a, b) => Appointment.dateAtTime(a.date, a.startTime)
          .compareTo(Appointment.dateAtTime(b.date, b.startTime)));
    return upcoming.isEmpty ? null : upcoming.first;
  }
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
    required this.visualAssetPath,
    required this.actionLabel,
    required this.onOpen,
    required this.semanticLabel,
    this.progress,
    this.progressLabel,
    this.statusLine,
  });

  final String category;
  final String title;
  final String subtitle;
  final String visualAssetPath;
  final String actionLabel;
  final VoidCallback onOpen;
  final String semanticLabel;
  final double? progress;
  final String? progressLabel;
  final String? statusLine;
}

_HomeJourneyPresentation _homeJourney({
  required HealthProfileSnapshot profile,
  required PeriodCycleSummary cycle,
  required VoidCallback openCycle,
  required VoidCallback openPregnancy,
  required VoidCallback openLearn,
  required VoidCallback openProfile,
  required bool profileAvailable,
  DawaHealthGame? activeCycleGame,
  ValueChanged<DawaHealthGame>? continueCycleGame,
}) {
  if (!profileAvailable) {
    return _HomeJourneyPresentation(
      category: 'Your health today',
      title: 'Health details unavailable',
      subtitle: 'Your saved sections are still here. Pull down to try again.',
      visualAssetPath: DawaArtwork.motherGreeting,
      actionLabel: 'Learn something',
      onOpen: openLearn,
      semanticLabel: 'Health details are temporarily unavailable.',
    );
  }
  final week = profile.pregnancyWeek;
  if (week != null) {
    return _HomeJourneyPresentation(
      category: 'Your pregnancy',
      title: 'Week $week',
      subtitle: profile.trimester == null
          ? 'Your pregnancy care'
          : '${_ordinal(profile.trimester!)} trimester',
      visualAssetPath: DawaArtwork.pregnancyPhone,
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
      title: 'Day $cycleDay',
      subtitle: 'of about $cycleLength days',
      visualAssetPath: DawaArtwork.cycleCalendar,
      actionLabel:
          activeCycleGame == null ? 'View my cycle' : 'Continue cycle game',
      onOpen: activeCycleGame == null || continueCycleGame == null
          ? openCycle
          : () => continueCycleGame(activeCycleGame),
      progress: (cycleDay / cycleLength).clamp(0, 1),
      statusLine: cycle.nextPeriodEstimate == null
          ? 'Add another period to improve estimates'
          : 'Next period in ${cycle.daysUntilNextPeriod ?? 0} days',
      semanticLabel: 'Cycle day $cycleDay.',
    );
  }

  if (!profile.isComplete) {
    return _HomeJourneyPresentation(
      category: 'Your health today',
      title: 'Help us personalize your care',
      subtitle: profile.dashboardPrompt,
      visualAssetPath: DawaArtwork.motherGreeting,
      actionLabel: 'Complete profile',
      onOpen: openProfile,
      semanticLabel:
          'Help us personalize your care. ${profile.dashboardPrompt}',
    );
  }

  return _HomeJourneyPresentation(
    category: 'Your cycle',
    title: 'Start tracking your cycle',
    subtitle: 'Log your period to see useful cycle estimates.',
    visualAssetPath: DawaArtwork.cycleCalendar,
    actionLabel: 'Start tracking',
    onOpen: openCycle,
    semanticLabel: 'Start tracking your cycle.',
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

String _appointmentStatusLabel(String value) => switch (value) {
      'confirmed' => 'Appointment confirmed',
      'declined' => 'Appointment declined',
      'cancelled' => 'Appointment cancelled',
      'rescheduled' => 'Appointment rescheduled',
      _ => 'Awaiting appointment confirmation',
    };
