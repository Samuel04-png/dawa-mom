import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/components/branding/dawa_mom_logo.dart';
import '/design_system/dawa_components.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'app_walkthrough_service.dart';

Future<void> showDawaMomWalkthrough(
  BuildContext context, {
  AppWalkthroughService? service,
}) async {
  final preferenceService = service ?? AppWalkthroughService();
  final compact = MediaQuery.sizeOf(context).width < 600;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      insetPadding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 30, vertical: 34),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 0 : 22),
      ),
      child: SizedBox(
        width: compact ? double.infinity : 820,
        height: compact ? double.infinity : 620,
        child: DawaMomWalkthrough(
          onComplete: () async {
            await preferenceService.complete();
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    ),
  );
}

class DawaMomWalkthrough extends StatefulWidget {
  const DawaMomWalkthrough({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<DawaMomWalkthrough> createState() => _DawaMomWalkthroughState();
}

class _DawaMomWalkthroughState extends State<DawaMomWalkthrough> {
  static const _steps = [
    _WalkthroughStep(
      title: 'Welcome to Dawa Mom',
      description:
          'Maternal-health support, appointments and cycle tracking in one place.',
      image: DawaArtwork.motherGreeting,
    ),
    _WalkthroughStep(
      title: 'Book appointments',
      description:
          'Choose a clinic, clinician, date and available appointment time.',
      image: DawaArtwork.clinicianDoctor,
    ),
    _WalkthroughStep(
      title: 'Track your cycle',
      description:
          'Record periods and view estimated cycle information when it is useful to you.',
      image: DawaArtwork.cycleCalendar,
    ),
    _WalkthroughStep(
      title: 'Play, learn and earn',
      description:
          'Complete short health games, collect one-time Dawa points and follow your rewards progress.',
      image: DawaArtwork.banaCelebrate,
    ),
    _WalkthroughStep(
      title: 'Complete your health profile',
      description:
          'Add relevant health information for more personalised guidance.',
      image: DawaArtwork.motherLearning,
    ),
    _WalkthroughStep(
      title: 'Ask Rudo',
      description:
          'Open the Rudo assistant whenever you need health support and guidance.',
      image: DawaArtwork.banaExplain,
    ),
  ];

  final _controller = PageController();
  int _index = 0;
  bool _closing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_closing) return;
    setState(() => _closing = true);
    await widget.onComplete();
    if (mounted) setState(() => _closing = false);
  }

  void _next() {
    if (_index == _steps.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _closing) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _next();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _back();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _finish();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: SafeArea(
        child: Column(
          children: [
            if (_closing) const LinearProgressIndicator(minHeight: 3),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 28,
                compact ? 16 : 22,
                compact ? 10 : 18,
                8,
              ),
              child: Row(
                children: [
                  const DawaMomLogo(
                    variant: DawaMomLogoVariant.full,
                    size: 40,
                  ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('skip-app-tour'),
                    onPressed: _closing ? null : _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 24 : 54,
                      vertical: compact ? 8 : 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 5,
                          child: Semantics(
                            image: true,
                            label: step.title,
                            child: Image.asset(
                              step.image,
                              fit: BoxFit.contain,
                              width: compact ? 280 : 390,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: theme.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            step.description,
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium.copyWith(
                              color: theme.secondaryText,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 20 : 30,
                10,
                compact ? 20 : 30,
                compact ? 20 : 26,
              ),
              child: Column(
                children: [
                  Semantics(
                    label: 'Step ${_index + 1} of ${_steps.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == _index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _index
                                ? theme.primary
                                : theme.alternate,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _index == 0 || _closing ? null : _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const ValueKey('next-app-tour'),
                        onPressed: _closing ? null : _next,
                        icon: Icon(
                          _index == _steps.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          _index == _steps.length - 1 ? 'Get started' : 'Next',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
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

class _WalkthroughStep {
  const _WalkthroughStep({
    required this.title,
    required this.description,
    required this.image,
  });

  final String title;
  final String description;
  final String image;
}
