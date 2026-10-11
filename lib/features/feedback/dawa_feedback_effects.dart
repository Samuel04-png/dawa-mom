import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
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
  static DateTime? _lastSoundAt;
  static DateTime? _lastNotificationAt;
  static const _hapticCooldown = Duration(milliseconds: 450);
  static const _soundCooldown = Duration(milliseconds: 600);
  static const _notificationCooldown = Duration(seconds: 5);

  // This path is the registered Flutter asset key. Keeping the cache prefix
  // empty prevents audioplayers from adding a second assets/ segment on web.
  static final AudioPlayer _player = AudioPlayer()
    ..audioCache = AudioCache(prefix: '');

  static const _appointmentConfirmedSound =
      'assets/audios/sounds/notification_05.mp3';
  static const _profileSavedSound = 'assets/audios/sounds/notification_03.mp3';

  static Future<void> confirmed({String? soundAsset}) async {
    final preferences = await DawaUserPreferencesRepository().load();
    if (soundAsset != null && preferences.soundEffectsEnabled) {
      unawaited(_play(soundAsset));
    }
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

  /// Use only after an appointment request has been persisted, or an online
  /// payment has been verified. Pending, failed, and cancelled actions remain
  /// silent so the audible cue never overstates a medical or payment outcome.
  static Future<void> appointmentBooked() =>
      confirmed(soundAsset: _appointmentConfirmedSound);

  /// A clinic-confirmed visit is a distinct, server-provided state change.
  /// The status transition guard in Care ensures this is not replayed on a
  /// widget rebuild.
  static Future<void> appointmentConfirmed() =>
      confirmed(soundAsset: _appointmentConfirmedSound);

  /// A short acknowledgement for an already-persisted profile step. This is
  /// deliberately separate from rewards: profile points need an approved,
  /// server-issued policy before they can be displayed or celebrated.
  static Future<void> profileStepSaved() =>
      confirmed(soundAsset: _profileSavedSound);

  /// Learning and reward feedback is called only after the server-owned
  /// learning ledger returns a higher confirmed balance. It intentionally
  /// shares the existing short notification asset rather than adding a sound
  /// for every lesson interaction.
  static Future<void> learningAwardConfirmed() =>
      confirmed(soundAsset: _profileSavedSound);

  /// A voucher is celebrated only after the claim RPC returns its durable
  /// server record. Claiming and clinic redemption remain separate actions.
  static Future<void> rewardUnlocked() =>
      confirmed(soundAsset: _appointmentConfirmedSound);

  /// Notification delivery can arrive in bursts. Debounce it separately from
  /// user-action cues so a batch never creates overlapping sounds or haptics.
  static Future<void> notificationReceived() async {
    final now = DateTime.now();
    if (_lastNotificationAt != null &&
        now.difference(_lastNotificationAt!) < _notificationCooldown) {
      return;
    }
    _lastNotificationAt = now;
    await confirmed(soundAsset: _appointmentConfirmedSound);
  }

  static Future<void> _play(String assetPath) async {
    final now = DateTime.now();
    if (_lastSoundAt != null &&
        now.difference(_lastSoundAt!) < _soundCooldown) {
      return;
    }
    _lastSoundAt = now;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Audio is an optional enhancement. A browser autoplay restriction or
      // unavailable output must never affect the completed appointment action.
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
