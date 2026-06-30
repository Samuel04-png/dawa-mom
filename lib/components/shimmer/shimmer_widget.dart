import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'shimmer_model.dart';
export 'shimmer_model.dart';

class ShimmerWidget extends StatefulWidget {
  const ShimmerWidget({super.key});

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with TickerProviderStateMixin {
  late ShimmerModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ShimmerModel());

    animationsMap.addAll({
      'imageOnPageLoadAnimation': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 830.0.ms,
            begin: Offset(0.0, 200.0),
            end: Offset(0.0, -200.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150.0,
      constraints: BoxConstraints(
        maxWidth: 250.0,
      ),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 6.0,
            sigmaY: 6.0,
          ),
          child: Transform.rotate(
            angle: 108.0 * (math.pi / 180),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/images/background.jpg',
                width: 300.0,
                height: 300.0,
                fit: BoxFit.cover,
              ),
            ).animateOnPageLoad(animationsMap['imageOnPageLoadAnimation']!),
          ),
        ),
      ),
    );
  }
}
