import 'package:flutter/material.dart';

import '/content/dawa_learning_asset_registry.dart';
import '/localization/dawa_localizations.dart';
import 'dawa_design_tokens.dart';

@immutable
class DawaImageVariantSpec {
  const DawaImageVariantSpec({
    required this.aspectRatio,
    required this.fit,
    required this.borderRadius,
    required this.maximumHeight,
    required this.overlayAllowed,
    required this.fullBleed,
  });

  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double maximumHeight;
  final bool overlayAllowed;
  final bool fullBleed;
}

extension DawaImageVariantLayout on DawaImageVariant {
  DawaImageVariantSpec get layout => switch (this) {
        DawaImageVariant.journeyHero => const DawaImageVariantSpec(
            aspectRatio: 4 / 3,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.feature),
            ),
            maximumHeight: 420,
            overlayAllowed: true,
            fullBleed: true,
          ),
        DawaImageVariant.featuredBanner => const DawaImageVariantSpec(
            aspectRatio: 16 / 9,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.feature),
            ),
            maximumHeight: 380,
            overlayAllowed: true,
            fullBleed: true,
          ),
        DawaImageVariant.moduleThumbnail => const DawaImageVariantSpec(
            aspectRatio: 4 / 3,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.medium),
            ),
            maximumHeight: 320,
            overlayAllowed: false,
            fullBleed: true,
          ),
        DawaImageVariant.compactThumbnail => const DawaImageVariantSpec(
            aspectRatio: 1,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.small),
            ),
            maximumHeight: 128,
            overlayAllowed: false,
            fullBleed: false,
          ),
        DawaImageVariant.cardSideImage => const DawaImageVariantSpec(
            aspectRatio: 1,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.medium),
            ),
            maximumHeight: 168,
            overlayAllowed: false,
            fullBleed: false,
          ),
        DawaImageVariant.articleHeader => const DawaImageVariantSpec(
            aspectRatio: 16 / 9,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.large),
            ),
            maximumHeight: 420,
            overlayAllowed: true,
            fullBleed: true,
          ),
        DawaImageVariant.announcementBanner => const DawaImageVariantSpec(
            aspectRatio: 16 / 9,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.medium),
            ),
            maximumHeight: 280,
            overlayAllowed: true,
            fullBleed: true,
          ),
        DawaImageVariant.emptyState => const DawaImageVariantSpec(
            aspectRatio: 4 / 3,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.all(
              Radius.circular(DawaRadii.large),
            ),
            maximumHeight: 320,
            overlayAllowed: false,
            fullBleed: false,
          ),
        DawaImageVariant.avatarIllustration => const DawaImageVariantSpec(
            aspectRatio: 1,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.all(Radius.circular(999)),
            maximumHeight: 160,
            overlayAllowed: false,
            fullBleed: false,
          ),
      };
}

/// Registry-backed, accessible learning artwork with stable geometry.
///
/// This is the only widget that should render an image from
/// `assets/dawa_learning_assets`. It centralizes focal cropping, localized
/// semantics, loading, failure handling, rounded clipping, and optional Hero
/// transitions.
class DawaContextualImage extends StatelessWidget {
  const DawaContextualImage({
    super.key,
    required this.assetId,
    this.variant = DawaImageVariant.moduleThumbnail,
    this.aspectRatio,
    this.fit,
    this.borderRadius,
    this.heroTag,
    this.decorative = false,
    this.semanticLabel,
    this.backgroundColor = DawaColors.softBlue,
    this.overlay,
    this.onTap,
  });

  final String assetId;
  final DawaImageVariant variant;

  /// A narrowly scoped compatibility override. Product screens should prefer
  /// [variant] so crops remain consistent.
  final double? aspectRatio;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final bool decorative;
  final String? semanticLabel;
  final Color backgroundColor;
  final Widget? overlay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final asset = DawaLearningAssetRegistry.byId(assetId);
    final specification = variant.layout;
    assert(
      overlay == null || specification.overlayAllowed,
      '${variant.name} does not support image overlays',
    );
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = borderRadius ?? specification.borderRadius;
    final effectiveFit = fit ?? specification.fit;
    final fadeDuration =
        animationsDisabled ? Duration.zero : const Duration(milliseconds: 180);
    final image = ClipRRect(
      key: ValueKey('dawa-contextual-frame-$assetId-${variant.name}'),
      borderRadius: radius,
      child: ColoredBox(
        color: backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset.assetPath,
              key: ValueKey('dawa-contextual-image-$assetId'),
              fit: effectiveFit,
              alignment: asset.alignmentFor(variant),
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (frame == null)
                      _DawaImageShimmer(animated: !animationsDisabled),
                    AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: fadeDuration,
                      curve: Curves.easeOut,
                      child: child,
                    ),
                  ],
                );
              },
              errorBuilder: (context, error, stackTrace) => _ImageFallback(
                key: ValueKey('dawa-contextual-image-fallback-$assetId'),
              ),
            ),
            if (overlay != null && specification.overlayAllowed) overlay!,
          ],
        ),
      ),
    );
    final ratio = aspectRatio ?? specification.aspectRatio;
    Widget result = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: specification.maximumHeight),
      child: AspectRatio(aspectRatio: ratio, child: image),
    );
    if (heroTag != null && !animationsDisabled) {
      result = Hero(tag: heroTag!, child: result);
    }
    final label = semanticLabel ??
        DawaTranslations.translate(
          asset.localizedSemanticLabel,
          Localizations.maybeLocaleOf(context) ??
              DawaLocaleController.instance.locale,
        );
    if (decorative) {
      result = ExcludeSemantics(child: result);
    } else {
      result = Semantics(
        image: true,
        label: label,
        child: result,
      );
    }
    if (onTap != null) {
      result = Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: result,
          ),
        ),
      );
    }
    return result;
  }
}

class _DawaImageShimmer extends StatefulWidget {
  const _DawaImageShimmer({required this.animated});

  final bool animated;

  @override
  State<_DawaImageShimmer> createState() => _DawaImageShimmerState();
}

class _DawaImageShimmerState extends State<_DawaImageShimmer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1250),
      )..forward();
    }
  }

  @override
  void didUpdateWidget(covariant _DawaImageShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animated == widget.animated) return;
    _controller?.dispose();
    _controller = widget.animated
        ? (AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1250),
          )..forward())
        : null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const low = Color(0xFFE8ECF8);
    const high = Color(0xFFF8F9FD);
    final controller = _controller;
    if (controller == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [low, high, low]),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1.8 + controller.value * 3.6, 0),
            end: Alignment(-.8 + controller.value * 3.6, 0),
            colors: const [low, high, low],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: DawaColors.softBlue,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: DawaColors.muted,
            size: 30,
          ),
        ),
      );
}
