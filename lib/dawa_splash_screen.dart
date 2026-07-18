import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_theme.dart';

class DawaSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const DawaSplashScreen({super.key, required this.onAnimationComplete});

  static const assetPath = 'assets/dawa_intro.gif';
  static const splashDuration = Duration(seconds: 2);

  @override
  State<DawaSplashScreen> createState() => _DawaSplashScreenState();
}

class _DawaSplashScreenState extends State<DawaSplashScreen> {
  bool _hasCompleted = false;
  bool _didPrecache = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(DawaSplashScreen.splashDuration, _completeAnimation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    precacheImage(
      const AssetImage(DawaSplashScreen.assetPath),
      context,
    );
  }

  void _completeAnimation() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    _timer?.cancel();
    if (mounted) widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splashBlue = FlutterFlowTheme.of(context).primary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: splashBlue,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: splashBlue,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widthFactor = constraints.maxWidth < 600
                  ? 0.68
                  : constraints.maxWidth < 1024
                      ? 0.50
                      : 0.38;
              final animationWidth = (constraints.maxWidth * widthFactor)
                  .clamp(180.0, 560.0)
                  .toDouble();

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: animationWidth,
                    maxHeight: constraints.maxHeight * 0.60,
                  ),
                  child: Image.asset(
                    DawaSplashScreen.assetPath,
                    width: animationWidth,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
