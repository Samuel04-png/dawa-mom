import '/localization/dawa_localized_material.dart';

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
    this.semanticLabel = 'DawaMom',
  });

  static const crossAsset =
      'assets/images/transparent assets/dawa_mom_cross.png';
  static const wordmarkAsset = 'assets/images/dawa_mom_wordmark.png';
  static const fullAsset = 'assets/images/transparent assets/dawa_mom_full.png';

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
        return SizedBox(
          width: width ?? size * 2.9,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: _DawaMomWordmark(fontSize: size),
          ),
        );
      case DawaMomLogoVariant.authentication:
        return SizedBox(
          width: width ?? size * 1.35,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  crossAsset,
                  width: size * 0.6,
                  height: size * 0.6,
                  fit: fit,
                ),
                SizedBox(height: size * 0.06),
                _DawaMomWordmark(fontSize: size * 0.3),
              ],
            ),
          ),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DawaMomWordmark(fontSize: size * 0.48),
                      if (showSubtitle)
                        Text(
                          'Care that stays with you',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.66),
                            fontFamily: 'Poppins',
                            fontSize: size * 0.16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _DawaMomWordmark extends StatelessWidget {
  const _DawaMomWordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Dawa'),
            TextSpan(
              text: 'Mom',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        maxLines: 1,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontFamily: 'Poppins',
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
        ),
      );
}
