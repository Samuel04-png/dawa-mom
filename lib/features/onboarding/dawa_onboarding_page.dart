import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/components/branding/dawa_mom_logo.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import 'app_walkthrough_service.dart';

class DawaOnboardingPage extends StatefulWidget {
  const DawaOnboardingPage({super.key, this.service});

  static const routeName = 'DawaOnboarding';
  static const routePath = '/onboarding';

  final AppWalkthroughService? service;

  @override
  State<DawaOnboardingPage> createState() => _DawaOnboardingPageState();
}

class _DawaOnboardingPageState extends State<DawaOnboardingPage> {
  late final AppWalkthroughService _service;
  final _controller = PageController();
  int _index = 0;
  bool _busy = false;

  static const _steps = [
    _OnboardingStep(
      eyebrow: 'CARE THAT FITS YOUR DAY',
      title: 'Book a visit with ease',
      description:
          'Choose a clinic, health worker and time. DawaMom will remind you.',
      asset: DawaArtwork.clinicianNurse,
      color: DawaColors.greenDark,
      cards: [
        (Icons.check_circle_rounded, 'Visit booked'),
        (Icons.medical_services_rounded, 'Health worker'),
        (Icons.notifications_active_rounded, 'Visit reminder'),
      ],
    ),
    _OnboardingStep(
      eyebrow: 'CLEAR, TRUSTED GUIDANCE',
      title: 'Health answers you can trust',
      description:
          'Read or listen to short health lessons in the language you chose.',
      asset: DawaArtwork.motherLearning,
      color: DawaColors.purple,
      cards: [
        (Icons.menu_book_rounded, 'Short lessons'),
        (Icons.headphones_rounded, 'Listen'),
        (Icons.fact_check_rounded, 'Myth or fact'),
      ],
    ),
    _OnboardingStep(
      eyebrow: 'UNDERSTAND YOUR BODY',
      title: 'Know your cycle',
      description:
          'Add periods and symptoms. See simple dates that help you plan.',
      asset: DawaArtwork.cycleCalendar,
      color: DawaColors.pink,
      cards: [
        (Icons.water_drop_rounded, 'Period dates'),
        (Icons.calendar_month_rounded, 'Cycle calendar'),
        (Icons.favorite_rounded, 'How you feel'),
      ],
    ),
    _OnboardingStep(
      eyebrow: 'HEALTHY HABITS, REWARDED',
      title: 'Learn, play and earn',
      description:
          'Play short health games, earn Dawa points and work towards care rewards.',
      asset: DawaArtwork.banaCelebrate,
      color: DawaColors.orange,
      cards: [
        (Icons.sports_esports_rounded, 'Health games'),
        (Icons.monetization_on_rounded, '+10 points'),
        (Icons.card_giftcard_rounded, 'Care rewards'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AppWalkthroughService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await _service.complete();
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(loggedIn ? '/home' : '/register');
  }

  void _next() {
    if (_index == _steps.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = DawaBreakpoints.pagePadding(context);
    return Scaffold(
      backgroundColor: DawaColors.canvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF9),
              DawaColors.canvas,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 84,
              child: IgnorePointer(
                child: CustomPaint(painter: DawaWavePainter()),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(pagePadding, 6, pagePadding, 2),
                    child: SizedBox(
                      width: double.infinity,
                      height: 66,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const DawaMomLogo(
                            variant: DawaMomLogoVariant.authentication,
                            size: 68,
                            width: 122,
                          ),
                          if (_index < _steps.length - 1)
                            Positioned(
                              right: 0,
                              child: TextButton(
                                key: const ValueKey('skip-onboarding'),
                                onPressed: _busy ? null : _finish,
                                style: TextButton.styleFrom(
                                  foregroundColor: DawaColors.primary,
                                  backgroundColor: DawaColors.surface,
                                  minimumSize: const Size(48, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  side: BorderSide(
                                    color: DawaColors.primary
                                        .withValues(alpha: .14),
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Skip'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _steps.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) =>
                          _OnboardingStepView(step: _steps[index]),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(pagePadding, 6, pagePadding, 10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 510),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        decoration: BoxDecoration(
                          color: DawaColors.surface,
                          borderRadius:
                              BorderRadius.circular(DawaRadii.feature),
                          border: Border.all(
                            color: DawaColors.primary.withValues(alpha: 0.12),
                          ),
                          boxShadow: DawaShadows.floating,
                        ),
                        child: Column(
                          children: [
                            Semantics(
                              label:
                                  'Onboarding step ${_index + 1} of ${_steps.length}',
                              child: Row(
                                children: [
                                  Text(
                                    'STEP ${_index + 1} OF ${_steps.length}',
                                    style: context.dawaCaption.copyWith(
                                      color: DawaColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                  const Spacer(),
                                  for (var i = 0; i < _steps.length; i++)
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      width: i == _index ? 24 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: i == _index
                                            ? DawaColors.primary
                                            : i < _index
                                                ? DawaColors.green
                                                : DawaColors.line,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            DawaPrimaryButton(
                              label: _index == _steps.length - 1
                                  ? 'Get started'
                                  : 'Continue',
                              icon: _index == _steps.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              busy: _busy,
                              onPressed: _next,
                            ),
                            SizedBox(
                              height: 38,
                              child: _index > 0
                                  ? TextButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _controller.previousPage(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                curve: Curves.easeOutCubic,
                                              ),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 17,
                                      ),
                                      label: const Text('Back'),
                                    )
                                  : Center(
                                      child: Text(
                                        'Swipe to explore',
                                        style: context.dawaCaption.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
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
    );
  }
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DawaBreakpoints.pagePadding(context),
          4,
          DawaBreakpoints.pagePadding(context),
          12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .96, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(scale: value, child: child),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 350;
                      final height = compact ? 286.0 : 310.0;
                      final chipWidth = (constraints.maxWidth * .46)
                          .clamp(132.0, 176.0)
                          .toDouble();
                      return SizedBox(
                        height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      step.color.withValues(alpha: 0.06),
                                      step.color.withValues(alpha: 0.12),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: step.color.withValues(alpha: 0.22),
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(DawaRadii.feature),
                                  boxShadow: DawaShadows.card,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -20,
                                      top: -18,
                                      child: SizedBox(
                                        width: 176,
                                        height: 150,
                                        child: CustomPaint(
                                          painter: DawaWovenPatternPainter(
                                            color: step.color,
                                            opacity: 0.075,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -28,
                                      bottom: -54,
                                      child: Container(
                                        width: 210,
                                        height: 210,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: .48),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 10,
                                      bottom: 6,
                                      width: constraints.maxWidth * .52,
                                      child: Image.asset(
                                        step.asset,
                                        fit: BoxFit.contain,
                                        alignment: Alignment.bottomCenter,
                                        filterQuality: FilterQuality.medium,
                                        excludeFromSemantics: true,
                                        errorBuilder: (_, __, ___) => Icon(
                                          step.cards.first.$1,
                                          color: step.color,
                                          size: 68,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            for (var i = 0; i < step.cards.length; i++)
                              Positioned(
                                left: 12,
                                top: 22.0 + (i * (compact ? 82.0 : 88.0)),
                                width: chipWidth,
                                child: _OnboardingMiniCard(
                                  icon: step.cards[i].$1,
                                  label: step.cards[i].$2,
                                  color: step.color,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  step.eyebrow,
                  textAlign: TextAlign.center,
                  style: context.dawaCaption.copyWith(
                    color: step.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: context.dawaDisplay.copyWith(
                    fontSize: DawaBreakpoints.isMobile(context) ? 28 : 34,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: context.dawaBody.copyWith(
                      color: DawaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _OnboardingMiniCard extends StatelessWidget {
  const _OnboardingMiniCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(10),
          ),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: DawaShadows.card,
        ),
        child: Row(
          children: [
            DawaIconBadge(icon: icon, color: color, size: 34),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                style: context.dawaCaption.copyWith(
                  color: DawaColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.asset,
    required this.color,
    required this.cards,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String asset;
  final Color color;
  final List<(IconData, String)> cards;
}
