import 'dart:async';

import 'package:flutter_animate/flutter_animate.dart';

import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/backend/period_tracker_service.dart';
import '/config/dawa_release_features.dart';
import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/components/period_setup/period_setup_flow.dart';
import '/content/dawa_content_announcement_repository.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/content/dawa_visual_rotation_service.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_interactions.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/appointments/presentation/dawa_booking_success_dialog.dart';
import '/features/care_plan/data/dawa_care_plan_repository.dart';
import '/features/care_plan/domain/dawa_care_item.dart';
import '/features/feedback/dawa_feedback_effects.dart';
import '/features/home/domain/dawa_home_presentation.dart';
import '/features/home/presentation/dawa_adaptive_featured_card.dart';
import '/features/games/domain/dawa_health_game.dart';
import '/features/learning/data/dawa_learning_repository.dart';
import '/features/learning/domain/dawa_learning_content.dart';
import '/features/notifications/dawa_notification_counter.dart';
import '/features/notifications/dawa_notifications_page.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/period_tracker/presentation/dawa_daily_check_in_sheet.dart';
import '/features/profile/data/health_profile_repository.dart';
import '/navbar/appointments/appointment_details/appointment_details_widget.dart';
import '/navbar/period_tracker/period_tracker_widget.dart';

class DawaMomResponsiveDashboard extends StatefulWidget {
  const DawaMomResponsiveDashboard({
    super.key,
    required this.onOpenRudo,
    this.appointmentRepository,
    this.carePlanRepository,
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
  final DawaCarePlanRepository? carePlanRepository;
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
  late final DawaCarePlanRepository _carePlan;
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
  _RoutineFeedback? _routineFeedback;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _appointments = widget.appointmentRepository ?? AppointmentRepository();
    _carePlan = widget.carePlanRepository ?? DawaCarePlanRepository();
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
    DawaCarePlanRepository.changes.addListener(_onDataChanged);
    DawaLearningRepository.changes.addListener(_onDataChanged);
    _data = _load();
    DawaNotificationsRepository.ensureRealtime();
    unawaited(DawaNotificationCounter.refresh());
  }

  @override
  void dispose() {
    HealthProfileRepository.changes.removeListener(_onDataChanged);
    PeriodTrackerService.changes.removeListener(_onDataChanged);
    AppointmentRepository.changes.removeListener(_onDataChanged);
    DawaCarePlanRepository.changes.removeListener(_onDataChanged);
    DawaLearningRepository.changes.removeListener(_onDataChanged);
    _feedbackTimer?.cancel();
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

    Future<DawaCarePlanSnapshot> loadOptionalCarePlan() async {
      try {
        return await _carePlan.load();
      } catch (_) {
        // Recommended care is supplementary on Home. Care owns its specific
        // retry state while appointments and the rest of Home remain usable.
        return const DawaCarePlanSnapshot(items: [], isCached: false);
      }
    }

    final results = await Future.wait<dynamic>([
      loadSection(
          'appointments', _appointments.getAppointments, <Appointment>[]),
      loadOptionalCarePlan(),
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
      _loadTodayCheckIn(),
    ]);
    final profile = results[2] as HealthProfileSnapshot;
    return _DashboardData(
      appointments: results[0] as List<Appointment>,
      carePlan: results[1] as DawaCarePlanSnapshot,
      healthProfile: profile,
      periodHistory: results[3] as List<PeriodRecord>,
      learningState: results[4] as DawaLearningState,
      todayCheckIn: results[5] as _TodayCheckInLoad,
      unavailableSections: unavailable,
    );
  }

  /// Today's check-in only drives an optional Home prompt, so a temporary
  /// failure must not turn the entire dashboard into a partial-data error.
  /// We simply withhold the prompt until the real entry can be read.
  Future<_TodayCheckInLoad> _loadTodayCheckIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      return _TodayCheckInLoad(
        entry: await _periodTracker.loadDailyData(today),
        available: true,
      );
    } catch (_) {
      return const _TodayCheckInLoad(available: false);
    }
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _data = future);
    await future;
  }

  Future<void> _book() async {
    final result = await showModalBottomSheet<AppointmentBookingResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingBottomSheetWidget(),
    );
    if (result == null || !mounted) return;
    await _refresh();
    if (!mounted) return;
    if (!result.appointment.requiresOnlinePayment || result.paymentSucceeded) {
      unawaited(DawaFeedbackEffects.appointmentBooked());
    }
    await showDawaBookingSuccessDialog(
      context,
      result.appointment,
      result: result,
    );
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

  Future<void> _openFeatured(
    DawaHomePresentation presentation,
    _DashboardData data,
  ) async {
    switch (presentation.action) {
      case DawaHomeAction.care:
        context.go('/care');
        return;
      case DawaHomeAction.appointment:
        final appointment = presentation.appointment;
        if (appointment != null) _openAppointment(appointment);
        return;
      case DawaHomeAction.pregnancy:
        await context.push('/learn/pregnancy');
        return;
      case DawaHomeAction.cycle:
        await _openPeriodTracker(data);
        return;
      case DawaHomeAction.profile:
        await context.push('/profileCompletion');
        return;
      case DawaHomeAction.bookVisit:
        await _book();
        return;
      case DawaHomeAction.retry:
        await _refresh();
        return;
    }
  }

  Future<void> _openCheckIn() async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final existing = await _periodTracker.loadDailyData(dateOnly);
    if (!mounted) return;
    final saved = await showDawaDailyCheckInSheet(
      context,
      date: dateOnly,
      existing: existing,
      onSave: ({
        required symptoms,
        required pain,
        required feeling,
        required note,
      }) async {
        final notes = <String>[
          'Pain: ${pain.round()}/10',
          'Overall feeling: $feeling',
          if (note.trim().isNotEmpty) note.trim(),
        ];
        await _periodTracker.saveDailyData(
          date: dateOnly,
          symptoms: symptoms,
          notes: notes,
        );
      },
    );
    if (!saved || !mounted) return;
    unawaited(DawaFeedbackEffects.confirmed());
    _showRoutineFeedback(
      title: 'Check-in saved',
      message: 'Your health log has been updated for today.',
    );
    await _refresh();
  }

  void _showRoutineFeedback({
    required String title,
    required String message,
  }) {
    _feedbackTimer?.cancel();
    setState(
      () => _routineFeedback = _RoutineFeedback(
        title: title,
        message: message,
      ),
    );
    _feedbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _routineFeedback = null);
    });
  }

  void _dismissRoutineFeedback() {
    _feedbackTimer?.cancel();
    setState(() => _routineFeedback = null);
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
    final featured = DawaHomePresentationMapper.map(
      profile: profile,
      cycle: cycle,
      profileAvailable: !data.unavailableSections.contains('profile'),
      appointment: appointment,
      careItem: data.priorityCareItem,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DawaAppHeader(
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
          child: KeyedSubtree(
            key: const ValueKey('home-adaptive-featured-card'),
            child: DawaAdaptiveFeaturedCard(
              presentation: featured,
              onAction: () => _openFeatured(featured, data),
            ),
          ),
        ),
        if (_routineFeedback != null) ...[
          const SizedBox(height: DawaSpacing.sm),
          DawaActionFeedback(
            title: _routineFeedback!.title,
            message: _routineFeedback!.message,
            dismissLabel: 'Dismiss',
            onDismiss: _dismissRoutineFeedback,
          ),
        ],
        const SizedBox(height: DawaSpacing.sm),
        _HomeQuickActions(
          featured: featured,
          onTrack: () => _openPeriodTracker(data),
          onCheckIn: _openCheckIn,
          onBook: _book,
          onCare: () => context.go('/care'),
          onLearn: () => context.go('/learn'),
        ).animate().slideY(
              begin: 0.12,
              end: 0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
            ),
        if (!data.unavailableSections.contains('profile') &&
            !profile.isComplete &&
            featured.showsProfileSupport) ...[
          const SizedBox(height: DawaSpacing.md),
          _ProfileCompletionBanner(
            profile: profile,
            onTap: () => context.push('/profileCompletion'),
          ),
        ],
        const SizedBox(height: DawaSpacing.md),
        if (featured.showsAppointmentSupport) ...[
          _HomeAppointmentCard(
            appointment: appointment,
            onOpen: appointment == null
                ? null
                : () => _openAppointment(appointment),
          ),
          const SizedBox(height: DawaSpacing.md),
        ],
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
    required this.featured,
    required this.onTrack,
    required this.onCheckIn,
    required this.onBook,
    required this.onCare,
    required this.onLearn,
  });

  final DawaHomePresentation featured;
  final VoidCallback onTrack;
  final VoidCallback onCheckIn;
  final VoidCallback onBook;
  final VoidCallback onCare;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    final cycleIsFeatured = featured.action == DawaHomeAction.cycle;
    final careIsFeatured = featured.action == DawaHomeAction.bookVisit ||
        featured.kind == DawaHomeFeaturedKind.appointment;
    final actions = <_HomeQuickActionData>[
      _HomeQuickActionData(
        label: cycleIsFeatured ? 'Cycle view' : 'My cycle',
        semanticLabel:
            cycleIsFeatured ? 'Open cycle calendar' : 'Open my cycle',
        icon:
            cycleIsFeatured ? Icons.calendar_month_rounded : Icons.sync_rounded,
        color: DawaColors.pink,
        background: DawaColors.softPink,
        onTap: onTrack,
      ),
      _HomeQuickActionData(
        label: 'How I feel',
        semanticLabel: 'How I feel today',
        icon: Icons.sentiment_satisfied_alt_rounded,
        color: DawaColors.primary,
        background: const Color(0xFFEAF6FF),
        onTap: onCheckIn,
      ),
      _HomeQuickActionData(
        label: careIsFeatured ? 'Care' : 'Book visit',
        semanticLabel: careIsFeatured ? 'Open care' : 'Book a visit',
        icon: careIsFeatured
            ? Icons.health_and_safety_rounded
            : Icons.calendar_month_rounded,
        color: DawaColors.greenDark,
        background: DawaColors.softGreen,
        onTap: careIsFeatured ? onCare : onBook,
      ),
      _HomeQuickActionData(
        label: 'Learn',
        semanticLabel: 'Open learning',
        icon: Icons.menu_book_rounded,
        color: DawaColors.purple,
        background: DawaColors.softPurple,
        onTap: onLearn,
      ),
    ];
    return Semantics(
      container: true,
      label: 'Home quick actions',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Four narrow columns make both labels and icons feel cramped on a
          // phone. Two calm rows give each action a readable label and a large
          // target without changing the navigation underneath it.
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _HomeQuickAction(data: actions[0])),
                    const SizedBox(width: DawaSpacing.sm),
                    Expanded(child: _HomeQuickAction(data: actions[1])),
                  ],
                ),
                const SizedBox(height: DawaSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _HomeQuickAction(data: actions[2])),
                    const SizedBox(width: DawaSpacing.sm),
                    Expanded(child: _HomeQuickAction(data: actions[3])),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                Expanded(child: _HomeQuickAction(data: actions[index])),
                if (index != actions.length - 1)
                  const SizedBox(width: DawaSpacing.sm),
              ],
            ],
          );
        },
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
          color: DawaColors.surface,
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          elevation: 1,
          shadowColor: DawaColors.ink.withValues(alpha: .08),
          child: InkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(DawaRadii.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth <= 160;
                final icon = DawaIconBadge(
                  icon: data.icon,
                  color: data.color,
                  background: data.background,
                  size: 44,
                );
                final label = Text(
                  data.label,
                  maxLines: narrow ? 1 : 2,
                  overflow:
                      narrow ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: context.dawaSectionTitle.copyWith(
                    fontSize: 14,
                    height: 1.15,
                  ),
                );
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 92),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DawaSpacing.sm,
                      vertical: DawaSpacing.sm,
                    ),
                    child: narrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              icon,
                              const SizedBox(height: 6),
                              label,
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              icon,
                              const SizedBox(width: DawaSpacing.sm),
                              Expanded(child: label),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: data.color),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

// ignore: unused_element
class _HomeJourneyHeroCard extends StatelessWidget {
  const _HomeJourneyHeroCard({
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
  Widget build(BuildContext context) => Semantics(
        key: const ValueKey('home-profile-completion'),
        button: true,
        label: 'Add your details to personalize your care.',
        child: Material(
          color: DawaColors.warningSurface,
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DawaRadii.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.25;
                const icon = DawaIconBadge(
                  icon: Icons.assignment_ind_outlined,
                  color: DawaColors.primary,
                  background: Colors.white,
                  size: 40,
                );
                final copy = Text(
                  'Add your details',
                  style: context.dawaSectionTitle.copyWith(fontSize: 16),
                );
                final action = TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: DawaColors.primary,
                  ),
                );
                if (stacked) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(child: copy),
                          ],
                        ),
                        Align(alignment: Alignment.centerRight, child: action),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                      action,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _HomeAppointmentCard extends StatelessWidget {
  const _HomeAppointmentCard({
    required this.appointment,
    required this.onOpen,
  });

  final Appointment? appointment;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final item = appointment;
    if (item == null) return const SizedBox.shrink();
    final date = Appointment.dateAtTime(item.date, item.startTime);
    final requested = item.status == 'pending';
    return Semantics(
      button: true,
      label:
          '${requested ? 'Visit request' : 'Upcoming visit'} at ${item.clinicName ?? 'your selected clinic'}',
      child: Material(
        color: DawaColors.softGreen,
        borderRadius: BorderRadius.circular(DawaRadii.large),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(DawaRadii.large),
          child: Padding(
            padding: const EdgeInsets.all(DawaSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 72,
                  decoration: BoxDecoration(
                    color: DawaColors.surface,
                    borderRadius: BorderRadius.circular(DawaRadii.medium),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('MMM').format(date).toUpperCase(),
                          style: context.dawaCaption.copyWith(
                            color: DawaColors.greenDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          )),
                      Text('${date.day}',
                          style: context.dawaTitle.copyWith(fontSize: 24)),
                    ],
                  ),
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requested ? 'VISIT REQUEST' : 'UPCOMING VISIT',
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.greenDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.clinicName ??
                            _appointmentTypeLabel(item.appointmentType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.dawaSectionTitle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        requested
                            ? 'Clinic is reviewing your request'
                            : DateFormat('EEE, d MMM • h:mm a').format(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: DawaColors.greenDark),
              ],
            ),
          ),
        ),
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
    // Home can show earned points before a reward redemption programme has
    // completed its separate clinic-verification release.
    const goal = 1000;
    final redemptionEnabled = DawaReleaseFeatures.voucherRedemptionEnabled;
    final remaining = (goal - coins).clamp(0, goal);
    final progress = available ? (coins / goal).clamp(0, 1).toDouble() : 0.0;
    return Semantics(
      button: true,
      label: !available
          ? 'Dawa Points are unavailable. Pull down to try again.'
          : redemptionEnabled
              ? 'Dawa Points. $coins points. $remaining points to a clinic scan voucher.'
              : 'Dawa Points. $coins points. Clinic reward redemption is being prepared.',
      child: Material(
        color: DawaColors.surfaceStrong,
        borderRadius: BorderRadius.circular(DawaRadii.large),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DawaRadii.large),
          child: Padding(
            padding: const EdgeInsets.all(DawaSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DawaColors.gold.withValues(alpha: .16),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: DawaColors.warning, size: 31),
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dawa Points',
                          style: context.dawaCaption.copyWith(
                            color: DawaColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          )),
                      const SizedBox(height: 1),
                      Text(
                        available ? '$coins points' : 'Points unavailable',
                        style: context.dawaSectionTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 7),
                      DawaProgressBar(
                        value: progress,
                        semanticLabel: redemptionEnabled
                            ? 'Clinic scan voucher progress'
                            : 'Dawa Points progress',
                        color: DawaColors.gold,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        !available
                            ? 'Pull down to try again'
                            : !redemptionEnabled
                                ? 'Your points are saved'
                                : remaining == 0
                                    ? 'Clinic scan voucher available'
                                    : '$remaining points to a clinic scan voucher',
                        style: context.dawaCaption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: DawaColors.warning),
              ],
            ),
          ),
        ),
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
  Widget build(BuildContext context) => Semantics(
        key: const ValueKey('home-daily-tip'),
        button: true,
        label: 'Today’s health tip. ${presentation.title}',
        child: Material(
          color: DawaColors.softTeal,
          borderRadius: BorderRadius.circular(DawaRadii.large),
          child: InkWell(
            onTap: onRead,
            borderRadius: BorderRadius.circular(DawaRadii.large),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final height = textScale > 1.3
                    ? 152.0
                    : textScale > 1.15
                        ? 140.0
                        : 124.0;
                return SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 116,
                        height: double.infinity,
                        child: DawaContextualImage(
                          assetId: presentation.assetId,
                          variant: DawaImageVariant.cardSideImage,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(DawaRadii.large),
                          ),
                        ),
                      ),
                      const SizedBox(width: DawaSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TODAY’S TIP',
                                style: context.dawaCaption.copyWith(
                                  color: DawaColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                )),
                            const SizedBox(height: 3),
                            Text(
                              presentation.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.dawaSectionTitle
                                  .copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: onRead,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 17),
                              label: const Text('Learn'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 40),
                                foregroundColor: DawaColors.teal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
}

// ignore: unused_element
class _HomePriorityNudge extends StatelessWidget {
  const _HomePriorityNudge({required this.priority});

  final _HomePriority priority;

  @override
  Widget build(BuildContext context) => DawaCard(
        key: const ValueKey('home-priority-nudge'),
        color: priority.background,
        borderColor: priority.color.withValues(alpha: .28),
        padding: EdgeInsets.zero,
        child: DawaPressable(
          onTap: priority.onAction,
          semanticLabel:
              'For you today. ${priority.title}. ${priority.message}. ${priority.actionLabel}.',
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          child: Padding(
            padding: const EdgeInsets.all(DawaSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 390 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2;
                final copy = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaIconBadge(icon: priority.icon, color: priority.color),
                    const SizedBox(width: DawaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FOR YOU TODAY',
                            style: context.dawaCaption.copyWith(
                              color: priority.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(priority.title, style: context.dawaSectionTitle),
                          const SizedBox(height: 3),
                          Text(priority.message, style: context.dawaCaption),
                        ],
                      ),
                    ),
                  ],
                );
                final action = Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: priority.color),
                    borderRadius: BorderRadius.circular(DawaRadii.medium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        priority.actionLabel,
                        style: context.dawaCaption.copyWith(
                          color: priority.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: priority.color,
                      ),
                    ],
                  ),
                );
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      const SizedBox(height: DawaSpacing.sm),
                      Align(alignment: Alignment.centerRight, child: action),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: DawaSpacing.sm),
                    action,
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _HomePriority {
  const _HomePriority({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
}

class _DashboardData {
  const _DashboardData({
    required this.appointments,
    required this.carePlan,
    required this.healthProfile,
    required this.periodHistory,
    required this.learningState,
    required this.todayCheckIn,
    this.unavailableSections = const <String>{},
  });

  final List<Appointment> appointments;
  final DawaCarePlanSnapshot carePlan;
  final HealthProfileSnapshot healthProfile;
  final List<PeriodRecord> periodHistory;
  final DawaLearningState learningState;
  final _TodayCheckInLoad todayCheckIn;
  final Set<String> unavailableSections;

  bool get canPromptForTodayCheckIn =>
      todayCheckIn.available && !todayCheckIn.hasCheckIn;

  Appointment? get nextAppointment {
    final upcoming = appointments.where((item) => item.isUpcoming).toList()
      ..sort((a, b) => Appointment.dateAtTime(a.date, a.startTime)
          .compareTo(Appointment.dateAtTime(b.date, b.startTime)));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  DawaCareItem? get priorityCareItem {
    for (final item in carePlan.actionable) {
      if (item.shouldLeadHome) return item;
    }
    return null;
  }
}

class _TodayCheckInLoad {
  const _TodayCheckInLoad({this.entry, required this.available});

  final Map<String, dynamic>? entry;
  final bool available;

  bool get hasCheckIn {
    final current = entry;
    if (current == null) return false;
    return _hasEntryValues(current['symptoms']) ||
        _hasEntryValues(current['notes']);
  }
}

bool _hasEntryValues(Object? value) => value is Iterable && value.isNotEmpty;

class _RoutineFeedback {
  const _RoutineFeedback({required this.title, required this.message});

  final String title;
  final String message;
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

/// Selects exactly one useful, supported next action for Home. This keeps the
/// dashboard calm: the recommendation is always grounded in the records that
/// were loaded for this screen, rather than in a generic or speculative nudge.
// ignore: unused_element
_HomePriority? _homePriority({
  required Appointment? appointment,
  required DawaCareItem? careItem,
  required PeriodCycleSummary cycle,
  required DawaLearningState learning,
  required HealthProfileSnapshot profile,
  required bool profileAvailable,
  required bool canCheckIn,
  required VoidCallback? onOpenAppointment,
  required VoidCallback onOpenCare,
  required VoidCallback onOpenCycle,
  required ValueChanged<DawaLearningItem> onOpenLearning,
  required VoidCallback onOpenProfile,
  required VoidCallback onOpenCheckIn,
}) {
  final now = DateTime.now();
  if (careItem != null) {
    final urgent = careItem.priority == DawaCareItemPriority.urgent;
    final overdue = careItem.status == DawaCareItemStatus.overdue;
    final due = careItem.status == DawaCareItemStatus.due;
    return _HomePriority(
      icon:
          overdue ? Icons.event_busy_outlined : Icons.medical_services_outlined,
      color: urgent || overdue ? DawaColors.danger : DawaColors.warning,
      background: urgent || overdue
          ? DawaColors.dangerSurface
          : DawaColors.warningSurface,
      title: overdue
          ? 'Care follow-up is overdue'
          : due
              ? 'Care needs your attention'
              : careItem.title,
      message: careItem.dueAt == null
          ? 'Open Care to review this next step.'
          : 'Due ${DateFormat('d MMM').format(careItem.dueAt!)}. Open Care to review it.',
      actionLabel: 'Open care',
      onAction: onOpenCare,
    );
  }
  if (appointment != null && onOpenAppointment != null) {
    final start =
        Appointment.dateAtTime(appointment.date, appointment.startTime);
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(start.year, start.month, start.day);
    final daysAway = appointmentDay.difference(today).inDays;
    if (daysAway == 0 || daysAway == 1) {
      return _HomePriority(
        icon: Icons.calendar_month_rounded,
        color: DawaColors.greenDark,
        background: DawaColors.softGreen,
        title: daysAway == 0 ? 'Your visit is today' : 'Your visit is tomorrow',
        message:
            '${DateFormat('h:mm a').format(start)} • ${appointment.clinicName ?? 'Your clinic'}',
        actionLabel: 'View visit',
        onAction: onOpenAppointment,
      );
    }
  }

  if (cycle.status == PeriodCycleStatus.periodActive) {
    return _HomePriority(
      icon: Icons.water_drop_rounded,
      color: DawaColors.pink,
      background: DawaColors.softPink,
      title: 'Period in progress',
      message: 'Open your cycle to log how you feel or mark when it ends.',
      actionLabel: 'View cycle',
      onAction: onOpenCycle,
    );
  }

  if (cycle.status == PeriodCycleStatus.periodExpectedToday) {
    return _HomePriority(
      icon: Icons.water_drop_outlined,
      color: DawaColors.pink,
      background: DawaColors.softPink,
      title: 'Your period may start today',
      message: _cycleEstimateMessage(cycle),
      actionLabel: 'View cycle',
      onAction: onOpenCycle,
    );
  }

  if (cycle.status == PeriodCycleStatus.periodExpectedSoon) {
    final days = cycle.daysUntilNextPeriod;
    if (days != null && days > 0) {
      return _HomePriority(
        icon: Icons.water_drop_outlined,
        color: DawaColors.pink,
        background: DawaColors.softPink,
        title: days == 1
            ? 'Your period may start tomorrow'
            : 'Your period may start in $days days',
        message: _cycleEstimateMessage(cycle),
        actionLabel: 'View cycle',
        onAction: onOpenCycle,
      );
    }
  }

  if (profileAvailable && !profile.isComplete) {
    return _HomePriority(
      icon: Icons.assignment_ind_outlined,
      color: DawaColors.primary,
      background: DawaColors.softBlue,
      title: 'Finish your health profile',
      message: profile.dashboardPrompt,
      actionLabel: 'Continue',
      onAction: onOpenProfile,
    );
  }

  final savedLesson = _unfinishedSavedLesson(learning);
  if (savedLesson != null) {
    return _HomePriority(
      icon: Icons.menu_book_rounded,
      color: DawaColors.purple,
      background: DawaColors.softPurple,
      title: 'Continue learning',
      message: '${savedLesson.title} • ${savedLesson.durationMinutes} min',
      actionLabel: 'Continue',
      onAction: () => onOpenLearning(savedLesson),
    );
  }

  if (canCheckIn) {
    return _HomePriority(
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: DawaColors.primary,
      background: const Color(0xFFEAF6FF),
      title: 'Quick check-in',
      message: 'Tell us how you feel today. It only takes a moment.',
      actionLabel: 'Check in',
      onAction: onOpenCheckIn,
    );
  }

  return null;
}

String _cycleEstimateMessage(PeriodCycleSummary cycle) =>
    cycle.confidence == PeriodEstimateConfidence.high
        ? 'This is an estimate based on your recent cycle records.'
        : 'This is an estimate from the dates you logged.';

DawaLearningItem? _unfinishedSavedLesson(DawaLearningState learning) {
  for (final item in DawaLearningCatalog.items) {
    if (learning.savedIds.contains(item.id) &&
        !learning.completedIds.contains(item.id)) {
      return item;
    }
  }
  return null;
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

// ignore: unused_element
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

// ignore: unused_element
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
