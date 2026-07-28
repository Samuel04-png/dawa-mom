import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_database.dart';
import '/design_system/dawa_design_tokens.dart';

enum DawaMainAppTourTarget {
  homeJourney,
  track,
  care,
  learn,
  rewards,
  notifications,
  profile,
}

class DawaMainAppTourStep {
  const DawaMainAppTourStep({
    required this.target,
    required this.title,
    required this.message,
  });

  final DawaMainAppTourTarget target;
  final String title;
  final String message;
}

const dawaMainAppTourSteps = <DawaMainAppTourStep>[
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.homeJourney,
    title: 'Your health journey',
    message: 'See your cycle or pregnancy, visits, learning and rewards here.',
  ),
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.track,
    title: 'Track daily wellbeing',
    message:
        'Track your period, symptoms, mood, pain and daily wellbeing here.',
  ),
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.care,
    title: 'Find and book care',
    message: 'Find a clinic, book a visit and manage appointments here.',
  ),
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.learn,
    title: 'Learn in small steps',
    message: 'Read, listen, play health games and earn points.',
  ),
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.rewards,
    title: 'Healthy actions earn points',
    message: 'Your points bring you closer to useful Dawa rewards.',
  ),
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.notifications,
    title: 'Stay up to date',
    message:
        'Appointment reminders, learning updates and check-ins appear here.',
  ),
  DawaMainAppTourStep(
    target: DawaMainAppTourTarget.profile,
    title: 'Make DawaMom yours',
    message:
        'Complete your profile, change language, manage reminders and get support.',
  ),
];

int dawaMainAppTourTabFor(DawaMainAppTourTarget target) => switch (target) {
      DawaMainAppTourTarget.homeJourney ||
      DawaMainAppTourTarget.rewards ||
      DawaMainAppTourTarget.notifications =>
        0,
      DawaMainAppTourTarget.track => 1,
      DawaMainAppTourTarget.care => 2,
      DawaMainAppTourTarget.learn => 3,
      DawaMainAppTourTarget.profile => 4,
    };

/// Versioned, local-first completion state for the main-app coach tour.
///
/// Local state is written before the optional profile sync so a temporary
/// network failure never causes the tour to reopen at every sign-in.
class MainAppTourService {
  MainAppTourService({
    SupabaseClient? client,
    Future<SharedPreferences> Function()? preferencesLoader,
    String? userIdOverride,
    DateTime Function()? clock,
  })  : _client = client,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _userIdOverride = userIdOverride,
        _clock = clock ?? DateTime.now;

  static const currentVersion = 1;

  final SupabaseClient? _client;
  final Future<SharedPreferences> Function() _preferencesLoader;
  final String? _userIdOverride;
  final DateTime Function() _clock;

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId {
    final value = _userIdOverride ?? _supabase?.auth.currentUser?.id;
    return value == null || value.isEmpty ? null : value;
  }

  Future<bool> shouldShow() async {
    final userId = _userId;
    if (userId == null) return false;
    final preferences = await _preferencesLoader();
    final completedVersion =
        preferences.getInt(completedVersionKey(userId)) ?? 0;
    if (completedVersion >= currentVersion) return false;

    final client = _supabase;
    if (client == null) return true;
    try {
      final row = await SupabaseDatabase.instance.runWithFreshSession(
        () => client
            .from('profiles')
            .select(
              'main_app_tour_completed_version, main_app_tour_completed_at',
            )
            .eq('id', userId)
            .maybeSingle(),
      );
      final remoteVersion =
          row?['main_app_tour_completed_version'] as int? ?? 0;
      if (remoteVersion < currentVersion) return true;
      await preferences.setInt(completedVersionKey(userId), remoteVersion);
      final completedAt = row?['main_app_tour_completed_at'] as String?;
      if (completedAt != null) {
        await preferences.setString(completedAtKey(userId), completedAt);
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> complete() async {
    final userId = _userId;
    if (userId == null) return;
    final completedAt = _clock().toUtc().toIso8601String();
    final preferences = await _preferencesLoader();
    await preferences.setInt(
      completedVersionKey(userId),
      currentVersion,
    );
    await preferences.setString(completedAtKey(userId), completedAt);

    final client = _supabase;
    if (client == null) return;
    try {
      await SupabaseDatabase.instance.runWithFreshSession(
        () => client.from('profiles').update({
          'main_app_tour_completed_version': currentVersion,
          'main_app_tour_completed_at': completedAt,
        }).eq('id', userId),
      );
    } catch (_) {
      // The local completion remains authoritative until a later sync.
    }
  }

  static String completedVersionKey(String userId) =>
      'dawa_mom_main_app_tour_completed_version_$userId';

  static String completedAtKey(String userId) =>
      'dawa_mom_main_app_tour_completed_at_$userId';
}

class DawaMainAppTourController extends ChangeNotifier {
  DawaMainAppTourController({
    required MainAppTourService service,
    this.onStepChanged,
  }) : _service = service;

  final MainAppTourService _service;
  final ValueChanged<DawaMainAppTourStep>? onStepChanged;

  bool _active = false;
  int _index = 0;

  bool get active => _active;
  int get index => _index;
  DawaMainAppTourStep get step => dawaMainAppTourSteps[_index];

  void start({bool replay = false}) {
    _index = 0;
    _active = true;
    onStepChanged?.call(step);
    notifyListeners();
  }

  Future<void> next() async {
    if (!_active) return;
    if (_index == dawaMainAppTourSteps.length - 1) {
      await finish();
      return;
    }
    _index += 1;
    onStepChanged?.call(step);
    notifyListeners();
  }

  void back() {
    if (!_active || _index == 0) return;
    _index -= 1;
    onStepChanged?.call(step);
    notifyListeners();
  }

  /// Re-resolves the current spotlight after an asynchronous page finishes.
  void refreshTarget() {
    if (_active) notifyListeners();
  }

  Future<void> skip() => finish();

  Future<void> finish() async {
    if (!_active) return;
    _active = false;
    notifyListeners();
    await _service.complete();
  }
}

class DawaMainAppTourScope extends InheritedWidget {
  const DawaMainAppTourScope({
    super.key,
    required this.onReplay,
    required super.child,
  });

  final VoidCallback onReplay;

  static bool replay(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DawaMainAppTourScope>();
    if (scope == null) return false;
    scope.onReplay();
    return true;
  }

  @override
  bool updateShouldNotify(DawaMainAppTourScope oldWidget) =>
      onReplay != oldWidget.onReplay;
}

class DawaMainAppTourOverlay extends StatefulWidget {
  const DawaMainAppTourOverlay({
    super.key,
    required this.controller,
    required this.targetKeys,
  });

  final DawaMainAppTourController controller;
  final Map<DawaMainAppTourTarget, GlobalKey> targetKeys;

  @override
  State<DawaMainAppTourOverlay> createState() => _DawaMainAppTourOverlayState();
}

class _DawaMainAppTourOverlayState extends State<DawaMainAppTourOverlay>
    with WidgetsBindingObserver {
  final GlobalKey _overlayKey = GlobalKey();
  Rect? _targetRect;
  Timer? _retryTimer;
  int _resolveAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_tourChanged);
    _scheduleResolve(resetAttempts: true);
  }

  @override
  void didUpdateWidget(DawaMainAppTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_tourChanged);
      widget.controller.addListener(_tourChanged);
    }
    _scheduleResolve(resetAttempts: true);
  }

  @override
  void didChangeMetrics() => _scheduleResolve(resetAttempts: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleResolve(resetAttempts: true);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    widget.controller.removeListener(_tourChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _tourChanged() {
    if (!mounted) return;
    setState(() => _targetRect = null);
    _scheduleResolve(resetAttempts: true);
  }

  void _scheduleResolve({required bool resetAttempts}) {
    if (resetAttempts) _resolveAttempts = 0;
    _retryTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTarget());
  }

  Future<void> _resolveTarget() async {
    if (!mounted || !widget.controller.active) return;
    final targetContext =
        widget.targetKeys[widget.controller.step.target]?.currentContext;
    if (targetContext != null) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ??
          WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
              .disableAnimations;
      try {
        await Scrollable.ensureVisible(
          targetContext,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      } catch (_) {
        // Navigation controls and fixed headers do not have a scrollable owner.
      }
    }
    if (!mounted) return;
    final targetBox = targetContext?.findRenderObject();
    final overlayBox = _overlayKey.currentContext?.findRenderObject();
    if (targetBox is RenderBox &&
        targetBox.hasSize &&
        overlayBox is RenderBox &&
        overlayBox.hasSize) {
      final origin = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
      final rawRect = origin & targetBox.size;
      final viewport = Offset.zero & overlayBox.size;
      final resolved = rawRect.inflate(7).intersect(viewport);
      if (!resolved.isEmpty && mounted) {
        setState(() => _targetRect = resolved);
        return;
      }
    }
    _resolveAttempts += 1;
    if (_resolveAttempts < 5) {
      _retryTimer = Timer(
        const Duration(milliseconds: 90),
        _resolveTarget,
      );
    } else if (mounted) {
      setState(() => _targetRect = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.active) return const SizedBox.shrink();
    final step = widget.controller.step;
    final progress =
        '${widget.controller.index + 1} of ${dawaMainAppTourSteps.length}';
    final media = MediaQuery.of(context);
    final target = _targetRect;
    final placeAtTop =
        target != null && target.center.dy > media.size.height * 0.5;

    return Material(
      key: const ValueKey('dawa-main-app-tour-overlay'),
      type: MaterialType.transparency,
      child: Stack(
        key: _overlayKey,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DawaTourSpotlightPainter(targetRect: target),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Align(
              alignment: target == null
                  ? Alignment.center
                  : placeAtTop
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
              child: BlockSemantics(
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: '$progress. ${step.title}. ${step.message}',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 390,
                      maxHeight: media.size.height * 0.58,
                    ),
                    child: SingleChildScrollView(
                      child: _DawaTourCard(
                        step: step,
                        progress: progress,
                        canGoBack: widget.controller.index > 0,
                        isLast: widget.controller.index ==
                            dawaMainAppTourSteps.length - 1,
                        onBack: widget.controller.back,
                        onNext: widget.controller.next,
                        onSkip: widget.controller.skip,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DawaTourCard extends StatelessWidget {
  const _DawaTourCard({
    required this.step,
    required this.progress,
    required this.canGoBack,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final DawaMainAppTourStep step;
  final String progress;
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onBack;
  final Future<void> Function() onNext;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) => Material(
        key: const ValueKey('dawa-main-app-tour-card'),
        color: DawaColors.surface,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(DawaRadii.feature),
        child: Padding(
          padding: const EdgeInsets.all(DawaSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    progress,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: DawaColors.greenDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('tour-skip'),
                    onPressed: onSkip,
                    child: const Text('Skip tour'),
                  ),
                ],
              ),
              const SizedBox(height: DawaSpacing.xs),
              Text(
                step.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: DawaColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: DawaSpacing.xs),
              Text(
                step.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: DawaColors.textSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: DawaSpacing.md),
              Row(
                children: [
                  if (canGoBack)
                    OutlinedButton(
                      key: const ValueKey('tour-back'),
                      onPressed: onBack,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 1),
                  const Spacer(),
                  FilledButton.icon(
                    key: const ValueKey('tour-next'),
                    onPressed: onNext,
                    icon: Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(isLast ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _DawaTourSpotlightPainter extends CustomPainter {
  const _DawaTourSpotlightPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.52);
    final target = targetRect;
    if (target == null) {
      canvas.drawRect(bounds, dimPaint);
      return;
    }
    final hole = RRect.fromRectAndRadius(target, const Radius.circular(18));
    final overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(bounds),
      Path()..addRRect(hole),
    );
    canvas.drawPath(overlayPath, dimPaint);
    canvas.drawRRect(
      hole,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _DawaTourSpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}
