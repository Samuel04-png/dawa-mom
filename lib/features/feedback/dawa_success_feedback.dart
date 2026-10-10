import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '/design_system/dawa_design_tokens.dart';
import '/features/preferences/dawa_user_preferences_repository.dart';

enum DawaSuccessFeedback { periodStarted, periodEnded, checkInSaved }

/// Lightweight, local-only confirmation feedback. It is called only after a
/// confirmed write and always falls back to an ordinary dialog if motion/audio
/// is unavailable (including browser autoplay restrictions).
class DawaSuccessFeedbackController {
  DawaSuccessFeedbackController._();

  // Flutter asset keys begin with `assets/audios/sounds/`. An empty cache
  // prefix lets audioplayers request that registered key without a duplicate
  // path segment on Flutter Web.
  static final AudioPlayer _player = AudioPlayer()
    ..audioCache = AudioCache(prefix: '');
  static bool _showing = false;

  static Future<void> show(
    BuildContext context,
    DawaSuccessFeedback feedback,
  ) async {
    if (_showing || !context.mounted) return;
    _showing = true;
    try {
      final preferences = await DawaUserPreferencesRepository().load();
      if (!context.mounted) return;
      final reducedMotion = preferences.reducedAnimations ||
          MediaQuery.maybeOf(context)?.disableAnimations == true;
      if (preferences.soundEffectsEnabled) {
        unawaited(_play(feedback));
      }
      if (preferences.hapticFeedbackEnabled) {
        unawaited(_vibrate());
      }
      final ended = feedback == DawaSuccessFeedback.periodEnded;
      final checkIn = feedback == DawaSuccessFeedback.checkInSaved;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: ended ? 'Period ended' : 'Period started',
        barrierColor: Colors.black45,
        transitionDuration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
        pageBuilder: (context, _, __) => Center(
          child: Semantics(
            liveRegion: true,
            label: ended
                ? 'Period ended'
                : checkIn
                    ? 'Check-in saved'
                    : 'Period started',
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 236,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DawaColors.surface,
                  borderRadius: BorderRadius.circular(DawaRadii.large),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!reducedMotion)
                    SizedBox(
                      height: 116,
                      child: Lottie.asset(
                        ended
                            ? 'assets/lotties/Confetti.json'
                            : 'assets/lotties/Success.json',
                        repeat: false,
                      ),
                    )
                  else
                    Icon(
                      ended
                          ? Icons.celebration_rounded
                          : Icons.check_circle_rounded,
                      color: ended ? DawaColors.green : DawaColors.primary,
                      size: 56,
                    ),
                  const SizedBox(height: 8),
                  Text(
                      ended
                          ? 'Period ended'
                          : checkIn
                              ? 'Check-in saved'
                              : 'Period started',
                      style: Theme.of(context).textTheme.titleLarge),
                ]),
              ),
            ),
          ),
        ),
      ).timeout(const Duration(seconds: 2), onTimeout: () {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    } finally {
      _showing = false;
    }
  }

  static Future<void> _play(DawaSuccessFeedback feedback) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(feedback == DawaSuccessFeedback.periodEnded
          ? 'assets/audios/sounds/period_ended.mp3'
          : 'assets/audios/sounds/period_started.mp3'));
    } catch (_) {}
  }

  static Future<void> _vibrate() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics are optional and unavailable in most browser environments.
    }
  }
}
