import 'package:flutter/material.dart';
import 'dart:async';

import '/components/branding/dawa_mom_logo.dart';

class DawaSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const DawaSplashScreen({Key? key, required this.onAnimationComplete})
      : super(key: key);

  @override
  State<DawaSplashScreen> createState() => _DawaSplashScreenState();
}

class _DawaSplashScreenState extends State<DawaSplashScreen> {
  static const _splashDuration = Duration(seconds: 2);
  bool _hasCompleted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(_splashDuration, _completeAnimation);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DawaMomLogo(
                variant: DawaMomLogoVariant.authentication,
                size: 240,
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(
                color: Color(0xFF1945CD),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
