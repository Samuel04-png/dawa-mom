import 'package:flutter/material.dart';
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
      title: 'Track your cycle',
      description:
          'Understand your period, fertile days and pregnancy journey with simple daily guidance.',
      asset: DawaArtwork.pregnancyPhone,
      cards: [
        (Icons.water_drop_rounded, 'Period in 3 days'),
        (Icons.calendar_month_rounded, 'Cycle calendar'),
        (Icons.pregnant_woman_rounded, 'Pregnancy journey'),
      ],
    ),
    _OnboardingStep(
      title: 'Book care easily',
      description:
          'Schedule appointments, get reminders and connect with Dawa clinicians without stress.',
      asset: DawaArtwork.pregnantMother,
      cards: [
        (Icons.check_circle_rounded, 'Appointment confirmed'),
        (Icons.medical_services_rounded, 'Trusted clinician'),
        (Icons.notifications_active_rounded, 'Helpful reminder'),
      ],
    ),
    _OnboardingStep(
      title: 'Learn and feel supported',
      description:
          'Get trusted health tips, pregnancy guidance and helpful rewards as you care for yourself and your baby.',
      asset: DawaArtwork.pregnancyPhone,
      cards: [
        (Icons.menu_book_rounded, 'Learn'),
        (Icons.health_and_safety_rounded, 'Women’s health'),
        (Icons.fact_check_rounded, 'Myth vs Fact'),
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DawaColors.canvas,
        body: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 150,
              child: IgnorePointer(
                child: CustomPaint(painter: DawaWavePainter()),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: DawaMomLogo(
                      variant: DawaMomLogoVariant.authentication,
                      size: 85,
                      width: 110,
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
                    padding: EdgeInsets.fromLTRB(
                      DawaBreakpoints.pagePadding(context),
                      0,
                      DawaBreakpoints.pagePadding(context),
                      18,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 510),
                      child: Column(
                        children: [
                          Semantics(
                            label:
                                'Onboarding step ${_index + 1} of ${_steps.length}',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _steps.length; i++) ...[
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i <= _index
                                          ? DawaColors.primary
                                          : DawaColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: i <= _index
                                            ? DawaColors.primary
                                            : DawaColors.line,
                                      ),
                                    ),
                                    child: i < _index
                                        ? const Icon(Icons.check_rounded,
                                            size: 14, color: Colors.white)
                                        : Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              color: i <= _index
                                                  ? Colors.white
                                                  : DawaColors.muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                  ),
                                  if (i < _steps.length - 1)
                                    Container(
                                      width: 45,
                                      height: 2,
                                      color: i < _index
                                          ? DawaColors.primary
                                          : DawaColors.line,
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DawaPrimaryButton(
                            label: _index == _steps.length - 1
                                ? 'Get started'
                                : 'Next',
                            busy: _busy,
                            onPressed: _next,
                          ),
                          const SizedBox(height: 3),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : _index > 0
                                    ? () => _controller.previousPage(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          curve: Curves.easeOut,
                                        )
                                    : _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_index > 0 ? 'Back' : 'Skip'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: DawaBreakpoints.pagePadding(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                SizedBox(
                  height: DawaBreakpoints.isMobile(context) ? 340 : 390,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        top: 10,
                        child: Image.asset(
                          step.asset,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 65,
                        child: _OnboardingMiniCard(
                          icon: step.cards[0].$1,
                          label: step.cards[0].$2,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 105,
                        child: _OnboardingMiniCard(
                          icon: step.cards[1].$1,
                          label: step.cards[1].$2,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 14,
                        child: _OnboardingMiniCard(
                          icon: step.cards[2].$1,
                          label: step.cards[2].$2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: context.dawaDisplay.copyWith(fontSize: 31),
                ),
                const SizedBox(height: 9),
                const Icon(Icons.favorite, color: DawaColors.green, size: 17),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: context.dawaBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _OnboardingMiniCard extends StatelessWidget {
  const _OnboardingMiniCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        width: DawaBreakpoints.isMobile(context) ? 128 : 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: DawaColors.line),
          boxShadow: DawaShadows.card,
        ),
        child: Row(
          children: [
            Icon(icon, color: DawaColors.primary, size: 20),
            const SizedBox(width: 7),
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
    required this.title,
    required this.description,
    required this.asset,
    required this.cards,
  });

  final String title;
  final String description;
  final String asset;
  final List<(IconData, String)> cards;
}
