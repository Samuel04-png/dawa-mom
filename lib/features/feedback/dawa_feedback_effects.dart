import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '/features/preferences/dawa_user_preferences_repository.dart';

/// Optional, non-blocking cues for an action whose result is already known.
///
/// Visual state remains in the owning screen. This helper only adds a gentle
/// haptic acknowledgement after a confirmed write, and never blocks it if a
/// platform does not support haptics.
abstract final class DawaFeedbackEffects {
  static DateTime? _lastHapticAt;
  static const _hapticCooldown = Duration(milliseconds: 450);

  static Future<void> confirmed() async {
    final preferences = await DawaUserPreferencesRepository().load();
    if (!preferences.hapticFeedbackEnabled) return;

    final now = DateTime.now();
    if (_lastHapticAt != null &&
        now.difference(_lastHapticAt!) < _hapticCooldown) {
      return;
    }
    _lastHapticAt = now;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Browsers and some devices do not expose haptics. The screen's visual
      // confirmation is still the source of truth.
    }
  }
}

/// A one-shot Lottie used only alongside an existing, confirmed visual state.
/// It is intentionally absent for reduced motion and never loads repeatedly
/// because its preference request is created once per mounted widget.
class DawaOptionalFeedbackAnimation extends StatefulWidget {
  const DawaOptionalFeedbackAnimation({
    super.key,
    required this.asset,
    required this.semanticLabel,
    this.height = 96,
  });

  final String asset;
  final String semanticLabel;
  final double height;

  @override
  State<DawaOptionalFeedbackAnimation> createState() =>
      _DawaOptionalFeedbackAnimationState();
}

class _DawaOptionalFeedbackAnimationState
    extends State<DawaOptionalFeedbackAnimation> {
  late final Future<DawaUserPreferences> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = DawaUserPreferencesRepository().load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DawaUserPreferences>(
        future: _preferences,
        builder: (context, snapshot) {
          final hideAnimation = snapshot.data?.reducedAnimations == true ||
              MediaQuery.disableAnimationsOf(context);
          if (hideAnimation) return const SizedBox.shrink();
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return Semantics(
            image: true,
            label: widget.semanticLabel,
            child: SizedBox(
              height: widget.height,
              child: Lottie.asset(widget.asset, repeat: false),
            ),
          );
        },
      );
}
