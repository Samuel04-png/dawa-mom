import 'package:flutter/material.dart';

import 'dawa_design_tokens.dart';

class DawaPageScaffold extends StatelessWidget {
  const DawaPageScaffold({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.scrollable = true,
    this.includeBottomWave = false,
    this.padding,
    this.header,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.reserveMobileNavigationSpace = false,
    this.onRefresh,
  });

  final Widget child;
  final double maxWidth;
  final bool scrollable;
  final bool includeBottomWave;
  final EdgeInsetsGeometry? padding;
  final Widget? header;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool reserveMobileNavigationSpace;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final mobileNavigationSpace =
        DawaBreakpoints.isMobile(context) && reserveMobileNavigationSpace
            ? DawaLayout.mobileNavigationHeight +
                DawaLayout.mobileNavigationWaveClearance
            : 0.0;
    final bottomPadding =
        mobileNavigationSpace + safeBottom + DawaLayout.bottomContentGap;
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(
          DawaBreakpoints.pagePadding(context),
          DawaSpacing.xxs,
          DawaBreakpoints.pagePadding(context),
          bottomPadding,
        );
    final resolvedPadding =
        effectivePadding.resolve(Directionality.of(context));
    final pageContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: DawaSpacing.xs),
        ],
        child,
      ],
    );
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: DawaColors.canvas,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    resolvedPadding.left,
                    resolvedPadding.top,
                    resolvedPadding.right,
                    0,
                  ),
                  child: pageContent,
                ),
              ),
              SizedBox(height: resolvedPadding.bottom),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: DawaColors.canvas,
      resizeToAvoidBottomInset: true,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: DawaColors.canvas),
          if (includeBottomWave)
            const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                height: DawaLayout.bottomWaveHeight,
                child: IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(painter: DawaWavePainter()),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: scrollable
                ? Builder(
                    builder: (context) {
                      final scrollView = SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: content,
                      );
                      final refresh = onRefresh;
                      return refresh == null
                          ? scrollView
                          : RefreshIndicator(
                              onRefresh: refresh,
                              child: scrollView,
                            );
                    },
                  )
                : content,
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

    final thread = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (double x = 10; x < size.width; x += 28) {
      canvas.drawLine(
        Offset(x, size.height - 15),
        Offset(x + 7, size.height - 8),
        thread,
      );
      canvas.drawLine(
        Offset(x + 7, size.height - 8),
        Offset(x + 14, size.height - 15),
        thread,
      );
    }
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
