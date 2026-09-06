import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:flutter/services.dart';

class DawaSplashScreen extends StatefulWidget {
  const DawaSplashScreen({
    super.key,
    required this.onAnimationComplete,
  });

  static const assetPath = 'assets/dawa_intro.gif';
  static const splashBackgroundColor = Color(0xFF102490);
  // Full GIF playback duration (233 frames, ~8.3s total). Kept with a
  // small buffer since frame timing can render slightly differently
  // across devices/decoders. Update this if the GIF asset ever changes.
  static const splashDuration = Duration(milliseconds: 8400);
  // Safety net in case the image never finishes loading (e.g. asset
  // error). Must stay longer than splashDuration, or it will cut the
  // animation short before it finishes playing.
  static const maxWait = Duration(milliseconds: 10000);

  final VoidCallback onAnimationComplete;

  @override
  State<DawaSplashScreen> createState() => _DawaSplashScreenState();
}

class _DawaSplashScreenState extends State<DawaSplashScreen> {
  Timer? _minDurationTimer;
  Timer? _safetyTimer;
  bool _hasCompleted = false;
  bool _didPrecache = false;
  bool _imageReady = false;
  bool _minDurationElapsed = false;

  late ImageStream _imageStream;
  late final ImageStreamListener _imageStreamListener;

  @override
  void initState() {
    super.initState();
    debugPrint('[Splash] Showing ${DawaSplashScreen.assetPath}.');

    _imageStreamListener = ImageStreamListener(
      _onImageLoaded,
      onError: _onImageError,
    );

    // The GIF gets `splashDuration` to actually play once it starts
    // rendering, instead of racing a wall-clock timer started at initState.
    _minDurationTimer = Timer(DawaSplashScreen.splashDuration, () {
      _minDurationElapsed = true;
      _maybeComplete();
    });

    // Absolute fallback so we never get stuck on splash if the image
    // fails to load or decode for some reason.
    _safetyTimer = Timer(DawaSplashScreen.maxWait, _completeAnimation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;

    final config = createLocalImageConfiguration(context);
    _imageStream =
        const AssetImage(DawaSplashScreen.assetPath).resolve(config);
    _imageStream.addListener(_imageStreamListener);
  }

  void _onImageLoaded(ImageInfo info, bool synchronousCall) {
    if (_imageReady) return;
    _imageReady = true;
    debugPrint('[Splash] Intro GIF first frame ready.');

    // Reset so the freshly-restarted timer actually gets to run its full
    // course, even if the original timer already fired while we were
    // still decoding (which happens on slower devices under load).
    _minDurationElapsed = false;
    _minDurationTimer?.cancel();
    _minDurationTimer = Timer(DawaSplashScreen.splashDuration, () {
      _minDurationElapsed = true;
      _maybeComplete();
    });
  }

  void _onImageError(Object error, StackTrace? stackTrace) {
    debugPrint('[Splash] Failed to load the intro GIF: $error');
    // Don't block the app on a broken asset.
    _imageReady = true;
    _minDurationElapsed = true;
    _maybeComplete();
  }

  void _maybeComplete() {
    if (_imageReady && _minDurationElapsed) {
      _completeAnimation();
    }
  }

  void _completeAnimation() {
    if (_hasCompleted) return;
    _hasCompleted = true;
    _minDurationTimer?.cancel();
    _safetyTimer?.cancel();
    debugPrint('[Splash] Intro GIF display completed.');
    if (mounted) widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _imageStream.removeListener(_imageStreamListener);
    _minDurationTimer?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: DawaSplashScreen.splashBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: DawaSplashScreen.splashBackgroundColor,
        body: Semantics(
          label: 'Dawa introduction animation',
          image: true,
          child: Center(
            // Constrains the GIF to a box that is 50% of the screen's
            // width and 50% of its height, i.e. ~25% of the screen area,
            // instead of covering the entire screen.
            child: FractionallySizedBox(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: Image.asset(
                DawaSplashScreen.assetPath,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('[Splash] Image.asset FAILED to load: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}