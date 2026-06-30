import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class DawaSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const DawaSplashScreen({Key? key, required this.onAnimationComplete})
      : super(key: key);

  @override
  State<DawaSplashScreen> createState() => _DawaSplashScreenState();
}

class _DawaSplashScreenState extends State<DawaSplashScreen> {
  static const _maxSplashDuration = Duration(seconds: 4);
  static const _fallbackSplashDuration = Duration(seconds: 2);

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasCompleted = false;
  Timer? _completionTimer;
  Timer? _maxSplashTimer;

  @override
  void initState() {
    super.initState();

    _maxSplashTimer = Timer(_maxSplashDuration, _completeAnimation);

    // Initialize video controller
    _videoController = VideoPlayerController.asset(
      'assets/Video_Not_a_GIF.mp4',
    );

    // Listen for video initialization
    _videoController.initialize().timeout(_fallbackSplashDuration).then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Start playing the video
        _videoController.setVolume(0.0);
        _videoController.setLooping(false);
        _videoController.play();

        // Setup completion
        _setupCompletion();
      }
    }).catchError((error) {
      if (error is! TimeoutException) {
        debugPrint('Error initializing video: $error');
      }
      _completeAnimation();
    });
  }

  void _setupCompletion() {
    // Calculate video duration
    final duration = _videoController.value.duration;

    if (duration.inSeconds > 0) {
      final displayDuration = duration + const Duration(milliseconds: 500);
      final cappedDuration = displayDuration < _maxSplashDuration
          ? displayDuration
          : _maxSplashDuration;
      _completionTimer = Timer(cappedDuration, _completeAnimation);
    } else {
      // Fallback duration
      _completionTimer = Timer(_fallbackSplashDuration, _completeAnimation);
    }
  }

  void _completeAnimation() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    _completionTimer?.cancel();
    _maxSplashTimer?.cancel();
    if (_videoController.value.isInitialized) {
      _videoController.pause();
    }

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _maxSplashTimer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B2091), // Blue background
      body: _isVideoInitialized
          ? _buildFullscreenVideo()
          : _buildLoadingIndicator(),
    );
  }

  Widget _buildFullscreenVideo() {
    if (!_videoController.value.isInitialized) {
      return _buildLoadingIndicator();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final videoAspectRatio = _videoController.value.aspectRatio;

    // Calculate dimensions for 50% of screen
    double containerWidth = screenWidth * 0.5;
    double containerHeight = screenHeight * 0.5;

    // Calculate actual video dimensions within container
    double videoWidth;
    double videoHeight;

    if (containerWidth / containerHeight > videoAspectRatio) {
      // Container is wider than video aspect ratio
      videoHeight = containerHeight;
      videoWidth = videoHeight * videoAspectRatio;
    } else {
      // Container is taller than video aspect ratio
      videoWidth = containerWidth;
      videoHeight = videoWidth / videoAspectRatio;
    }

    return Container(
      color: Color(0xFF0B2091),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: containerWidth,
          height: containerHeight,
          color: Color(0xFF111F8A),
          child: Center(
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(_videoController),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Color(0xFF111F8A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
