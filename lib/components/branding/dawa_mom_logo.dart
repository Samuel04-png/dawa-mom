import 'package:flutter/material.dart';

enum DawaMomLogoVariant {
  full,
  compact,
  iconOnly,
  wordmarkOnly,
  authentication,
}

class DawaMomLogo extends StatelessWidget {
  const DawaMomLogo({
    super.key,
    this.variant = DawaMomLogoVariant.full,
    this.size = 44,
    this.width,
    this.showSubtitle = false,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Dawa Mom',
  });

  static const crossAsset = 'assets/images/dawa_mom_cross.png';
  static const wordmarkAsset = 'assets/images/dawa_mom_wordmark.png';
  static const fullAsset = 'assets/images/dawa_mom_full.png';

  final DawaMomLogoVariant variant;
  final double size;
  final double? width;
  final bool showSubtitle;
  final BoxFit fit;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isCompact = variant == DawaMomLogoVariant.compact ||
        variant == DawaMomLogoVariant.iconOnly;
    final valueKey = switch (variant) {
      DawaMomLogoVariant.full => 'dawa-mom-logo-full',
      DawaMomLogoVariant.compact => 'dawa-mom-logo-compact',
      DawaMomLogoVariant.iconOnly => 'dawa-mom-logo-icon-only',
      DawaMomLogoVariant.wordmarkOnly => 'dawa-mom-logo-wordmark-only',
      DawaMomLogoVariant.authentication => 'dawa-mom-logo-authentication',
    };

    return Semantics(
      key: ValueKey(valueKey),
      container: true,
      image: true,
      label: isCompact ? '$semanticLabel icon' : semanticLabel,
      child: ExcludeSemantics(
        child: _buildLogo(context),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    switch (variant) {
      case DawaMomLogoVariant.compact:
      case DawaMomLogoVariant.iconOnly:
        return Image.asset(
          crossAsset,
          width: width ?? size,
          height: size,
          fit: fit,
        );
      case DawaMomLogoVariant.wordmarkOnly:
        return Image.asset(
          wordmarkAsset,
          width: width ?? size * 2.65,
          height: size,
          fit: fit,
        );
      case DawaMomLogoVariant.authentication:
        return Image.asset(
          fullAsset,
          width: width ?? size,
          height: size,
          fit: fit,
        );
      case DawaMomLogoVariant.full:
        return SizedBox(
          width: width,
          height: size,
          child: Row(
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Image.asset(
                crossAsset,
                width: size,
                height: size,
                fit: fit,
              ),
              SizedBox(width: size * 0.2),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Image.asset(
                        wordmarkAsset,
                        alignment: Alignment.centerLeft,
                        fit: fit,
                      ),
                    ),
                    if (showSubtitle)
                      Text(
                        'Dawa Mom maternal health',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.66),
                          fontFamily: 'Poppins',
                          fontSize: size * 0.18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
