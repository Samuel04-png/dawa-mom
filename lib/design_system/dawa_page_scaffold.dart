import 'package:flutter/material.dart';

import 'dawa_design_tokens.dart';

class DawaPageScaffold extends StatelessWidget {
  const DawaPageScaffold({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.scrollable = true,
    this.includeBottomWave = true,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final bool scrollable;
  final bool includeBottomWave;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(
          DawaBreakpoints.pagePadding(context),
          4,
          DawaBreakpoints.pagePadding(context),
          DawaBreakpoints.isMobile(context) ? 112 : 32,
        );
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );

    return Material(
      color: DawaColors.canvas,
      child: Stack(
        children: [
          if (includeBottomWave)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 98,
              child:
                  IgnorePointer(child: CustomPaint(painter: DawaWavePainter())),
            ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: scrollable
                  ? SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: content,
                    )
                  : content,
            ),
          ),
        ],
      ),
    );
  }
}

class DawaWavePainter extends CustomPainter {
  const DawaWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = DawaColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final greenPath = Path()
      ..moveTo(0, 20)
      ..cubicTo(
        size.width * 0.28,
        48,
        size.width * 0.62,
        -8,
        size.width,
        22,
      );
    canvas.drawPath(greenPath, green);

    final blue = Paint()
      ..color = DawaColors.primary
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(0, 28)
      ..cubicTo(
        size.width * 0.28,
        56,
        size.width * 0.62,
        0,
        size.width,
        30,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bluePath, blue);
  }

  @override
  bool shouldRepaint(covariant DawaWavePainter oldDelegate) => false;
}

class DawaBottomSheetFrame extends StatelessWidget {
  const DawaBottomSheetFrame({
    super.key,
    required this.child,
    this.maxWidth = 620,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: DawaColors.canvas,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DawaBreakpoints.pagePadding(context),
                  10,
                  DawaBreakpoints.pagePadding(context),
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DawaColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
