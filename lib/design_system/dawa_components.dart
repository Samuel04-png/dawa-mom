import '/localization/dawa_localized_material.dart';

import '/components/branding/dawa_mom_logo.dart';
import '/content/dawa_learning_asset_registry.dart';
import 'dawa_contextual_image.dart';
import 'dawa_design_tokens.dart';

abstract final class DawaArtwork {
  static const motherGreeting =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Greeting.png';
  static const motherLearning =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Learning.png';
  static const motherQuestion =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Asking_Question.png';
  static const motherListening =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Listening.png';
  static const motherReward =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Receiving_Reward.png';
  static const pregnancyPhone =
      'dawa_mom_screens/assets/characters/pregnancy/CHAR-MOTHER-PREG-T2-Phone.png';
  static const pregnancyEarly =
      'dawa_mom_screens/assets/characters/pregnancy/CHAR-MOTHER-PREG-T1-Early.png';
  static const pregnancyBirth =
      'dawa_mom_screens/assets/characters/pregnancy/CHAR-MOTHER-PREG-T3-Birth_Preparation.png';
  static const cycleCalendar =
      'dawa_mom_screens/assets/characters/cycle/CHAR-MOTHER-CYCLE-Ovulation_Estimate-Calendar.png';
  static const cycleCramps =
      'dawa_mom_screens/assets/characters/cycle/CHAR-MOTHER-CYCLE-Menstruation-Cramps.png';
  static const cycleEnergy =
      'dawa_mom_screens/assets/characters/cycle/CHAR-MOTHER-CYCLE-Follicular-Energy.png';
  static const banaCalendar =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Calendar_Guidance.png';
  static const banaWelcome =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Welcoming.png';
  static const banaCelebrate =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Celebrating_Reward.png';
  static const banaExplain =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Explaining.png';
  static const banaReassure =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Reassuring.png';
  static const clinicianDoctor =
      'dawa_mom_screens/assets/characters/clinicians/CHAR-CLINICIAN-Doctor-Explaining.png';
  static const clinicianMidwife =
      'dawa_mom_screens/assets/characters/clinicians/CHAR-CLINICIAN-Midwife-Listening.png';
  static const clinicianNurse =
      'dawa_mom_screens/assets/characters/clinicians/CHAR-CLINICIAN-Nurse-Greeting.png';
  static const cervicalAwareness =
      'dawa_mom_screens/assets/characters/cervical_health/CHAR-MOTHER-CERVIX-Awareness.png';
  static const cervicalClinic =
      'dawa_mom_screens/assets/characters/cervical_health/CHAR-MOTHER-CERVIX-At_Clinic.png';
  static const pregnantMother =
      'dawa_mom_screens/assets/illustrations/pregnant-mother.png';
  static const motherBabyLine =
      'dawa_mom_screens/assets/illustrations/mother-baby-line-transparent.png';
  static const guideAvatar =
      'dawa_mom_screens/assets/illustrations/guide-avatar-crop.png';
  static const clinicConversation =
      'dawa_mom_screens/assets/illustrations/clinic-conversation-crop.png';
  static const cervicalRibbon = 'assets/images/cervical cancer.jpg';
  static const nutritionCounselling = 'assets/images/nutrition2.jpg';
}

class DawaWovenPatternPainter extends CustomPainter {
  const DawaWovenPatternPainter({
    this.color = DawaColors.primary,
    this.opacity = 0.055,
  });

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dot = Paint()
      ..color = DawaColors.green.withValues(alpha: opacity * 1.6)
      ..style = PaintingStyle.fill;
    const step = 18.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final path = Path()
          ..moveTo(x, y + step * 0.5)
          ..lineTo(x + step * 0.5, y)
          ..lineTo(x + step, y + step * 0.5)
          ..lineTo(x + step * 0.5, y + step)
          ..close();
        canvas.drawPath(path, stroke);
        if (((x / step).round() + (y / step).round()).isEven) {
          canvas.drawCircle(
            Offset(x + step * 0.5, y + step * 0.5),
            1.6,
            dot,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DawaWovenPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

class DawaCard extends StatelessWidget {
  const DawaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = DawaColors.surface,
    this.borderColor = DawaColors.line,
    this.radius = DawaRadii.medium,
    this.onTap,
    this.semanticLabel,
    this.showPattern = false,
    this.featured = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool showPattern;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = featured ? DawaRadii.feature : radius;
    final borderRadius = BorderRadius.circular(effectiveRadius);
    final effectiveColor = color;
    final effectiveBorderColor = borderColor;
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: effectiveBorderColor),
    );
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        if (featured && showPattern)
          const Positioned(
            right: -4,
            top: -5,
            child: IgnorePointer(
              child: SizedBox(
                width: 104,
                height: 76,
                child: CustomPaint(
                  painter: DawaWovenPatternPainter(),
                ),
              ),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    );
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: featured ? DawaShadows.floating : DawaShadows.card,
      ),
      child: Material(
        color: effectiveColor,
        shape: shape,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                canRequestFocus: true,
                mouseCursor: SystemMouseCursors.click,
                hoverColor: DawaColors.primary.withValues(alpha: 0.05),
                focusColor: DawaColors.primary.withValues(alpha: 0.12),
                child: content,
              ),
      ),
    );
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: surface,
    );
  }
}

/// A content-driven illustrated card with separate text and artwork regions.
///
/// Important copy and controls never share a paint layer with the illustration,
/// so transparent character assets cannot cover headings or actions. Compact
/// screens retain a roughly 60/40 split; exceptionally narrow cards fall back
/// to a vertical composition.
class DawaIllustratedHeroCard extends StatelessWidget {
  const DawaIllustratedHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustrationPath,
    this.category,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.backgroundColor = DawaColors.softBlue,
    this.borderColor,
    this.illustrationAlignment = Alignment.bottomCenter,
    this.contextualAssetId,
    this.illustrationAspectRatio,
    this.progress,
    this.progressLabel,
    this.semanticLabel,
  });

  final String title;
  final String subtitle;
  final String illustrationPath;
  final String? category;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color backgroundColor;
  final Color? borderColor;
  final AlignmentGeometry illustrationAlignment;
  final String? contextualAssetId;
  final double? illustrationAspectRatio;
  final double? progress;
  final String? progressLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: semanticLabel,
        child: DawaCard(
          color: backgroundColor,
          borderColor:
              borderColor ?? DawaColors.primary.withValues(alpha: 0.16),
          padding: EdgeInsets.zero,
          showPattern: true,
          featured: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 304;
              final tablet = constraints.maxWidth >= DawaBreakpoints.mobile;
              final artworkMaxHeight = tablet
                  ? DawaLayout.tabletIllustrationMaxHeight
                  : DawaLayout.mobileIllustrationMaxHeight;
              final text = Padding(
                padding: EdgeInsets.fromLTRB(
                  tablet ? DawaSpacing.xl : DawaSpacing.md,
                  tablet ? DawaSpacing.xl : DawaSpacing.lg,
                  vertical ? DawaSpacing.md : DawaSpacing.xs,
                  tablet ? DawaSpacing.xl : DawaSpacing.lg,
                ),
                child: _DawaHeroTextRegion(
                  category: category,
                  title: title,
                  subtitle: subtitle,
                  primaryActionLabel: primaryActionLabel,
                  onPrimaryAction: onPrimaryAction,
                  secondaryActionLabel: secondaryActionLabel,
                  onSecondaryAction: onSecondaryAction,
                  progress: progress,
                  progressLabel: progressLabel,
                ),
              );
              if (contextualAssetId != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DawaContextualImage(
                      assetId: contextualAssetId!,
                      variant: DawaImageVariant.articleHeader,
                      borderRadius: BorderRadius.zero,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tablet ? DawaSpacing.xl : DawaSpacing.md,
                        tablet ? DawaSpacing.lg : DawaSpacing.md,
                        tablet ? DawaSpacing.xl : DawaSpacing.md,
                        tablet ? DawaSpacing.xl : DawaSpacing.lg,
                      ),
                      child: _DawaHeroTextRegion(
                        category: category,
                        title: title,
                        subtitle: subtitle,
                        primaryActionLabel: primaryActionLabel,
                        onPrimaryAction: onPrimaryAction,
                        secondaryActionLabel: secondaryActionLabel,
                        onSecondaryAction: onSecondaryAction,
                        progress: progress,
                        progressLabel: progressLabel,
                      ),
                    ),
                  ],
                );
              }
              final artwork = Padding(
                padding: EdgeInsets.only(
                  top: vertical ? 0 : DawaSpacing.xs,
                  right: vertical ? 0 : DawaSpacing.xs,
                ),
                child: Align(
                  alignment: illustrationAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: vertical ? 164 : artworkMaxHeight,
                      maxWidth: tablet ? 260 : 190,
                    ),
                    child: AspectRatio(
                      aspectRatio:
                          illustrationAspectRatio ?? (vertical ? 1.15 : 0.78),
                      child: Image.asset(
                        illustrationPath,
                        fit: BoxFit.contain,
                        alignment: illustrationAlignment,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              );

              if (vertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    artwork,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(flex: 62, child: text),
                  Flexible(flex: 38, child: artwork),
                ],
              );
            },
          ),
        ),
      );
}

class _DawaHeroTextRegion extends StatelessWidget {
  const _DawaHeroTextRegion({
    required this.title,
    required this.subtitle,
    this.category,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.progress,
    this.progressLabel,
  });

  final String title;
  final String subtitle;
  final String? category;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final double? progress;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final primaryVisible =
        primaryActionLabel != null && onPrimaryAction != null;
    final secondaryVisible =
        secondaryActionLabel != null && onSecondaryAction != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category != null) ...[
          Text(
            category!,
            style: context.dawaCaption.copyWith(
              color: DawaColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DawaSpacing.xxs),
        ],
        Text(
          title,
          style: context.dawaDisplay.copyWith(
            fontSize: DawaBreakpoints.isMobile(context) ? 26 : 32,
          ),
        ),
        const SizedBox(height: DawaSpacing.xs),
        Text(subtitle, style: context.dawaBody),
        if (progress != null) ...[
          const SizedBox(height: DawaSpacing.sm),
          DawaProgressBar(
            value: progress!,
            semanticLabel: progressLabel ?? 'Journey progress',
            color: DawaColors.green,
          ),
          if (progressLabel != null) ...[
            const SizedBox(height: DawaSpacing.xxs),
            Text(progressLabel!, style: context.dawaCaption),
          ],
        ],
        if (primaryVisible || secondaryVisible) ...[
          const SizedBox(height: DawaSpacing.md),
          Wrap(
            spacing: DawaSpacing.xs,
            runSpacing: DawaSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (primaryVisible)
                FilledButton.icon(
                  onPressed: onPrimaryAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DawaSpacing.md,
                      vertical: DawaSpacing.sm,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(primaryActionLabel!),
                ),
              if (secondaryVisible)
                TextButton(
                  onPressed: onSecondaryAction,
                  style: TextButton.styleFrom(
                    foregroundColor: DawaColors.primary,
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

enum DawaLessonVisual {
  pregnancy,
  cervicalHealth,
  screening,
  nutrition,
  period,
  appointment,
  postpartum,
  mythFact,
  general,
}

/// A clean, offline-first lesson thumbnail.
///
/// The image is deliberately the only visual inside a successful thumbnail.
/// Metadata, badges and actions belong in the card's text section below it.
class DawaLessonThumbnail extends StatelessWidget {
  const DawaLessonThumbnail({
    super.key,
    required this.topic,
    this.assetPath,
    this.aspectRatio = 16 / 9,
    this.imageFit = BoxFit.cover,
    this.imageAlignment = Alignment.center,
  });

  final DawaLessonVisual topic;
  final String? assetPath;
  final double aspectRatio;
  final BoxFit imageFit;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final spec = _DawaLessonThumbnailSpec.forTopic(topic);
    return AspectRatio(
      key: const ValueKey('lesson-thumbnail-aspect-ratio'),
      aspectRatio: aspectRatio,
      child: ColoredBox(
        color: spec.background,
        child: assetPath == null
            ? _DawaLessonThumbnailFallback(spec: spec)
            : Image.asset(
                assetPath!,
                key: const ValueKey('lesson-thumbnail-image'),
                fit: imageFit,
                alignment: imageAlignment,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, synchronousLoad) =>
                    synchronousLoad || frame != null
                        ? child
                        : _DawaLessonThumbnailPlaceholder(spec: spec),
                errorBuilder: (_, __, ___) =>
                    _DawaLessonThumbnailFallback(spec: spec),
              ),
      ),
    );
  }
}

class _DawaLessonThumbnailPlaceholder extends StatelessWidget {
  const _DawaLessonThumbnailPlaceholder({required this.spec});

  final _DawaLessonThumbnailSpec spec;

  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const ValueKey('lesson-thumbnail-placeholder'),
        color: spec.background,
        child: const SizedBox.expand(),
      );
}

class _DawaLessonThumbnailFallback extends StatelessWidget {
  const _DawaLessonThumbnailFallback({required this.spec});

  final _DawaLessonThumbnailSpec spec;

  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const ValueKey('lesson-thumbnail-fallback'),
        color: spec.background,
        child: Center(
          child: Icon(
            spec.fallbackIcon,
            color: spec.accent.withValues(alpha: 0.66),
            size: 46,
          ),
        ),
      );
}

class _DawaLessonThumbnailSpec {
  const _DawaLessonThumbnailSpec({
    required this.background,
    required this.accent,
    required this.fallbackIcon,
  });

  final Color background;
  final Color accent;
  final IconData fallbackIcon;

  static _DawaLessonThumbnailSpec forTopic(DawaLessonVisual topic) =>
      switch (topic) {
        DawaLessonVisual.pregnancy => const _DawaLessonThumbnailSpec(
            background: Color(0xFFF7F3FC),
            accent: DawaColors.purple,
            fallbackIcon: Icons.pregnant_woman_rounded,
          ),
        DawaLessonVisual.cervicalHealth => const _DawaLessonThumbnailSpec(
            background: Color(0xFFF2F7FF),
            accent: DawaColors.primary,
            fallbackIcon: Icons.health_and_safety_outlined,
          ),
        DawaLessonVisual.screening => const _DawaLessonThumbnailSpec(
            background: Color(0xFFF2F9F3),
            accent: DawaColors.greenDark,
            fallbackIcon: Icons.fact_check_outlined,
          ),
        DawaLessonVisual.nutrition => const _DawaLessonThumbnailSpec(
            background: Color(0xFFFFF8EE),
            accent: DawaColors.greenDark,
            fallbackIcon: Icons.restaurant_rounded,
          ),
        DawaLessonVisual.period => const _DawaLessonThumbnailSpec(
            background: Color(0xFFFFF4F7),
            accent: DawaColors.pink,
            fallbackIcon: Icons.water_drop_outlined,
          ),
        DawaLessonVisual.appointment => const _DawaLessonThumbnailSpec(
            background: Color(0xFFF2F9F3),
            accent: DawaColors.greenDark,
            fallbackIcon: Icons.calendar_month_rounded,
          ),
        DawaLessonVisual.postpartum => const _DawaLessonThumbnailSpec(
            background: Color(0xFFF4F7FF),
            accent: DawaColors.primary,
            fallbackIcon: Icons.child_friendly_rounded,
          ),
        DawaLessonVisual.mythFact => const _DawaLessonThumbnailSpec(
            background: Color(0xFFFFF8EE),
            accent: DawaColors.orange,
            fallbackIcon: Icons.fact_check_rounded,
          ),
        DawaLessonVisual.general => const _DawaLessonThumbnailSpec(
            background: Color(0xFFF4F7FF),
            accent: DawaColors.primary,
            fallbackIcon: Icons.menu_book_outlined,
          ),
      };
}

/// A clean lesson card with a real thumbnail region and useful metadata.
class DawaContentThumbnailCard extends StatelessWidget {
  const DawaContentThumbnailCard({
    super.key,
    required this.thumbnail,
    required this.category,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.onOpen,
    this.actionLabel = 'Read now',
    this.onSave,
    this.saved = false,
    this.audioAvailable = false,
    this.completed = false,
    this.featured = false,
  });

  final Widget thumbnail;
  final String category;
  final String title;
  final String description;
  final int durationMinutes;
  final VoidCallback onOpen;
  final String actionLabel;
  final VoidCallback? onSave;
  final bool saved;
  final bool audioAvailable;
  final bool completed;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return DawaCard(
      padding: EdgeInsets.zero,
      onTap: onOpen,
      semanticLabel: '$category. $title. $durationMinutes minutes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DawaRadii.medium),
            ),
            child: thumbnail,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              featured ? 18 : 13,
              featured ? 16 : 12,
              featured ? 12 : 8,
              featured ? 14 : 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        maxLines: 2,
                        softWrap: true,
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.greenDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (completed)
                      const DawaStatusPill(
                        label: 'Done',
                        icon: Icons.check_circle_outline,
                        color: DawaColors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: featured ? 3 : 4,
                  softWrap: true,
                  style: context.dawaSectionTitle.copyWith(
                    fontSize: featured ? 22 : 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: featured ? 4 : 3,
                  softWrap: true,
                  style: context.dawaCaption,
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 230;
                    final stackAction = narrow ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.25 ||
                        actionLabel.length > 14;
                    final details = Row(
                      children: [
                        Icon(
                          audioAvailable
                              ? Icons.headphones_rounded
                              : Icons.schedule_rounded,
                          size: 16,
                          color: DawaColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '$durationMinutes min ${audioAvailable ? 'listen' : 'read'}',
                            maxLines: 2,
                            softWrap: true,
                            style: context.dawaCaption,
                          ),
                        ),
                        if (onSave != null)
                          IconButton(
                            tooltip: saved
                                ? 'Remove from library'
                                : 'Save to library',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: onSave,
                            icon: Icon(
                              saved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: DawaColors.primary,
                            ),
                          ),
                      ],
                    );
                    final action = DawaTextButton(
                      label: actionLabel,
                      onPressed: onOpen,
                    );
                    if (stackAction) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details,
                          Align(
                            alignment: Alignment.centerRight,
                            child: action,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 4),
                        action,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact white quest row. Status is carried by its icon and label.
class DawaModuleRow extends StatelessWidget {
  const DawaModuleRow({
    super.key,
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.onTap,
  });

  final int stepNumber;
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final complete = status == 'Completed' || status == 'Done';
    return DawaCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      semanticLabel: 'Step $stepNumber. $title. $status.',
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: complete
                  ? DawaColors.green.withValues(alpha: 0.1)
                  : DawaColors.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              complete ? Icons.check_rounded : icon,
              color: complete ? DawaColors.greenDark : DawaColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: DawaColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.dawaSectionTitle),
                const SizedBox(height: 2),
                Text(description, style: context.dawaCaption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: context.dawaCaption.copyWith(
                  color: complete ? DawaColors.greenDark : DawaColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DawaColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DawaSectionHeader extends StatelessWidget {
  const DawaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _DawaSectionMark(),
          const SizedBox(width: DawaSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.dawaSectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.dawaCaption),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: DawaColors.primary,
                minimumSize: const Size(44, 44),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      );
}

class _DawaSectionMark extends StatelessWidget {
  const _DawaSectionMark();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 10,
        height: 30,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: DawaColors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: DawaColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      );
}

class DawaAppHeader extends StatelessWidget {
  const DawaAppHeader({
    super.key,
    this.title,
    this.eyebrow,
    this.onBack,
    this.onNotifications,
    this.onProfile,
    this.notificationUnread = false,
    this.notificationKey,
  });

  final String? title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool notificationUnread;
  final GlobalKey? notificationKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: DawaColors.primary,
              )
            else
              const DawaMomLogo(
                variant: DawaMomLogoVariant.full,
                size: 34,
                width: 104,
                semanticLabel: 'DawaMom',
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: title == null
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (eyebrow != null)
                    Text(
                      eyebrow!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.dawaCaption,
                    ),
                  if (title != null)
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.dawaTitle.copyWith(fontSize: 17),
                    ),
                ],
              ),
            ),
            if (onNotifications != null)
              KeyedSubtree(
                key: notificationKey,
                child: Stack(
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: onNotifications,
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: DawaColors.primary,
                    ),
                    if (notificationUnread)
                      Positioned(
                        right: 10,
                        top: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: DawaColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (onProfile != null)
              Semantics(
                button: true,
                label: 'Open profile',
                child: InkResponse(
                  onTap: onProfile,
                  radius: 25,
                  child: Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: DawaColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: DawaColors.line, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        DawaArtwork.motherGreeting,
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DawaResponsiveGrid extends StatelessWidget {
  const DawaResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= DawaBreakpoints.desktop
              ? desktopColumns
              : constraints.maxWidth >= DawaBreakpoints.mobile
                  ? tabletColumns
                  : mobileColumns;
          final safeCount = count.clamp(1, children.length);
          final width =
              (constraints.maxWidth - spacing * (safeCount - 1)) / safeCount;
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}

class DawaIconBadge extends StatelessWidget {
  const DawaIconBadge({
    super.key,
    required this.icon,
    this.color = DawaColors.primary,
    this.background,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.38),
            topRight: Radius.circular(size * 0.2),
            bottomRight: Radius.circular(size * 0.38),
            bottomLeft: Radius.circular(size * 0.2),
          ),
        ),
        child: Icon(icon, color: color, size: size * 0.52),
      );
}

class DawaStatusPill extends StatelessWidget {
  const DawaStatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.color = DawaColors.green,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DawaRadii.pill),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class DawaProgressBar extends StatelessWidget {
  const DawaProgressBar({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.color = DawaColors.primary,
    this.height = 7,
  });

  final double value;
  final String semanticLabel;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        value: '${(value.clamp(0, 1) * 100).round()} percent',
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) => ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              minHeight: height,
              value: animatedValue,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      );
}

class DawaPrimaryButton extends StatelessWidget {
  const DawaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _DawaButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        busy: busy,
        fullWidth: fullWidth,
        variant: _DawaButtonVariant.primary,
      );
}

class DawaSecondaryButton extends StatelessWidget {
  const DawaSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _DawaButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        busy: busy,
        fullWidth: fullWidth,
        variant: _DawaButtonVariant.outlined,
      );
}

class DawaOutlinedButton extends StatelessWidget {
  const DawaOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _DawaButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        busy: busy,
        fullWidth: fullWidth,
        variant: _DawaButtonVariant.outlined,
      );
}

class DawaTextButton extends StatelessWidget {
  const DawaTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _DawaButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        busy: busy,
        fullWidth: fullWidth,
        variant: _DawaButtonVariant.text,
      );
}

class DawaDestructiveButton extends StatelessWidget {
  const DawaDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline_rounded,
    this.busy = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _DawaButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        busy: busy,
        fullWidth: fullWidth,
        variant: _DawaButtonVariant.destructive,
      );
}

class DawaCompactButton extends StatelessWidget {
  const DawaCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool filled;

  @override
  Widget build(BuildContext context) => _DawaButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        busy: busy,
        fullWidth: false,
        compact: true,
        variant:
            filled ? _DawaButtonVariant.primary : _DawaButtonVariant.outlined,
      );
}

class DawaIconButton extends StatelessWidget {
  const DawaIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = DawaColors.primary,
    this.filled = false,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip,
        liveRegion: busy,
        value: busy ? 'In progress' : null,
        child: IconButton(
          tooltip: tooltip,
          onPressed: busy ? null : onPressed,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: IconButton.styleFrom(
            backgroundColor: filled ? color : color.withValues(alpha: 0.08),
            foregroundColor: filled ? Colors.white : color,
            disabledBackgroundColor: DawaColors.disabledSurface,
            disabledForegroundColor: DawaColors.disabledText,
          ),
          icon: busy
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: filled ? Colors.white : color,
                  ),
                )
              : Icon(icon),
        ),
      );
}

enum _DawaButtonVariant { primary, outlined, text, destructive }

class _DawaButton extends StatelessWidget {
  const _DawaButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.busy,
    required this.fullWidth,
    required this.variant,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;
  final bool compact;
  final _DawaButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final foreground =
        variant == _DawaButtonVariant.destructive ? DawaColors.danger : null;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(48, compact ? 48 : 54),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: compact ? 14 : 22,
          vertical: compact ? 10 : 12,
        ),
      ),
      foregroundColor:
          foreground == null ? null : WidgetStatePropertyAll(foreground),
      side: variant == _DawaButtonVariant.destructive
          ? const WidgetStatePropertyAll(
              BorderSide(color: DawaColors.danger),
            )
          : null,
    );
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(
            dimension: compact ? 18 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: variant == _DawaButtonVariant.primary
                  ? Colors.white
                  : foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: compact ? 18 : 20),
        if (busy || icon != null) const SizedBox(width: 9),
        Flexible(
          child: Text(
            busy ? 'Please wait' : label,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
    final VoidCallback? action = busy ? null : onPressed;
    final button = switch (variant) {
      _DawaButtonVariant.primary => FilledButton(
          onPressed: action,
          style: style,
          child: content,
        ),
      _DawaButtonVariant.outlined ||
      _DawaButtonVariant.destructive =>
        OutlinedButton(
          onPressed: action,
          style: style,
          child: content,
        ),
      _DawaButtonVariant.text => TextButton(
          onPressed: action,
          style: style,
          child: content,
        ),
    };
    return Semantics(
      button: true,
      label: label,
      liveRegion: busy,
      value: busy ? 'In progress' : null,
      excludeSemantics: true,
      child:
          fullWidth ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class DawaFormField extends StatelessWidget {
  const DawaFormField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixIcon: suffix,
        ),
      );
}

class DawaEmptyState extends StatelessWidget {
  const DawaEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _DawaStateCard(
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class DawaErrorState extends StatelessWidget {
  const DawaErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _DawaStateCard(
        icon: Icons.cloud_off_rounded,
        iconColor: DawaColors.danger,
        title: title,
        message: message,
        actionLabel: 'Try again',
        onAction: onRetry,
      );
}

enum DawaSkeletonLayout {
  content,
  thumbnail,
  stat,
  appointment,
  reward,
  questRow,
}

class DawaLoadingSkeleton extends StatelessWidget {
  const DawaLoadingSkeleton({
    super.key,
    this.lines = 3,
    this.label = 'Loading content',
    this.layout = DawaSkeletonLayout.content,
  });

  final int lines;
  final String label;
  final DawaSkeletonLayout layout;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        liveRegion: true,
        child: ExcludeSemantics(
          child: DawaCard(
            padding: layout == DawaSkeletonLayout.thumbnail
                ? EdgeInsets.zero
                : const EdgeInsets.all(16),
            child: _DawaSkeletonBody(layout: layout, lines: lines),
          ),
        ),
      );
}

class _DawaSkeletonBody extends StatelessWidget {
  const _DawaSkeletonBody({
    required this.layout,
    required this.lines,
  });

  final DawaSkeletonLayout layout;
  final int lines;

  @override
  Widget build(BuildContext context) => switch (layout) {
        DawaSkeletonLayout.thumbnail => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DawaShimmerBox(height: 138, radius: 0),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaShimmerBox(height: 10, widthFactor: 0.34),
                    SizedBox(height: 9),
                    DawaShimmerBox(height: 18, widthFactor: 0.76),
                    SizedBox(height: 8),
                    DawaShimmerBox(height: 11),
                    SizedBox(height: 7),
                    DawaShimmerBox(height: 11, widthFactor: 0.65),
                  ],
                ),
              ),
            ],
          ),
        DawaSkeletonLayout.stat => const Row(
            children: [
              DawaShimmerBox(width: 42, height: 42, radius: 13),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaShimmerBox(height: 10, widthFactor: 0.6),
                    SizedBox(height: 8),
                    DawaShimmerBox(height: 17, widthFactor: 0.82),
                  ],
                ),
              ),
            ],
          ),
        DawaSkeletonLayout.appointment => const Row(
            children: [
              DawaShimmerBox(width: 44, height: 44, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaShimmerBox(height: 10, widthFactor: 0.42),
                    SizedBox(height: 8),
                    DawaShimmerBox(height: 16, widthFactor: 0.7),
                    SizedBox(height: 8),
                    DawaShimmerBox(height: 11, widthFactor: 0.9),
                  ],
                ),
              ),
              SizedBox(width: 10),
              DawaShimmerBox(width: 82, height: 40, radius: 14),
            ],
          ),
        DawaSkeletonLayout.reward => const Row(
            children: [
              DawaShimmerBox(width: 48, height: 48, radius: 16),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaShimmerBox(height: 11, widthFactor: 0.42),
                    SizedBox(height: 8),
                    DawaShimmerBox(height: 18, widthFactor: 0.52),
                    SizedBox(height: 10),
                    DawaShimmerBox(height: 8, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        DawaSkeletonLayout.questRow => const Row(
            children: [
              DawaShimmerBox(width: 42, height: 42, radius: 12),
              SizedBox(width: 11),
              DawaShimmerBox(width: 25, height: 25, radius: 13),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaShimmerBox(height: 14, widthFactor: 0.68),
                    SizedBox(height: 8),
                    DawaShimmerBox(height: 10, widthFactor: 0.86),
                  ],
                ),
              ),
            ],
          ),
        DawaSkeletonLayout.content => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  DawaShimmerBox(width: 46, height: 46, radius: 16),
                  SizedBox(width: DawaSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DawaShimmerBox(height: 14, widthFactor: 0.7),
                        SizedBox(height: DawaSpacing.xs),
                        DawaShimmerBox(height: 10, widthFactor: 0.45),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DawaSpacing.md),
              for (var index = 0; index < lines; index++) ...[
                DawaShimmerBox(
                  height: 12,
                  widthFactor: index == lines - 1 ? 0.62 : 1,
                ),
                if (index != lines - 1) const SizedBox(height: DawaSpacing.xs),
              ],
            ],
          ),
      };
}

class DawaPageSkeleton extends StatelessWidget {
  const DawaPageSkeleton({
    super.key,
    this.label = 'Loading page',
    this.showHero = true,
    this.cardCount = 3,
  });

  final String label;
  final bool showHero;
  final int cardCount;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        liveRegion: true,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  DawaShimmerBox(width: 106, height: 38, radius: 12),
                  Spacer(),
                  DawaShimmerBox(width: 38, height: 38, radius: 19),
                ],
              ),
              const SizedBox(height: DawaSpacing.md),
              if (showHero) ...[
                DawaCard(
                  color: DawaColors.softBlue,
                  featured: true,
                  showPattern: true,
                  child: SizedBox(
                    height: DawaBreakpoints.isMobile(context) ? 190 : 220,
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DawaShimmerBox(height: 11, widthFactor: 0.45),
                              SizedBox(height: 12),
                              DawaShimmerBox(height: 25, widthFactor: 0.9),
                              SizedBox(height: 9),
                              DawaShimmerBox(height: 12),
                              SizedBox(height: 7),
                              DawaShimmerBox(height: 12, widthFactor: 0.75),
                              SizedBox(height: 18),
                              DawaShimmerBox(
                                  width: 130, height: 42, radius: 16),
                            ],
                          ),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          flex: 2,
                          child: DawaShimmerBox(height: 150, radius: 28),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DawaSpacing.lg),
              ],
              const DawaShimmerBox(height: 18, widthFactor: 0.46),
              const SizedBox(height: DawaSpacing.sm),
              for (var index = 0; index < cardCount; index++) ...[
                const DawaLoadingSkeleton(lines: 2),
                if (index != cardCount - 1)
                  const SizedBox(height: DawaSpacing.sm),
              ],
            ],
          ),
        ),
      );
}

class DawaShimmerBox extends StatefulWidget {
  const DawaShimmerBox({
    super.key,
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = 8,
  }) : assert(width == null || widthFactor == null);

  final double? width;
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  State<DawaShimmerBox> createState() => _DawaShimmerBoxState();
}

class _DawaShimmerBoxState extends State<DawaShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
    Widget box = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = reduceMotion ? 0.45 : _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-2.2 + value * 3.6, 0),
            end: Alignment(-0.8 + value * 3.6, 0),
            colors: const [
              DawaColors.disabledSurface,
              Color(0xFFF8F9FD),
              DawaColors.disabledSurface,
            ],
          ).createShader(bounds),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: DawaColors.disabledSurface,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
        );
      },
    );
    final widthFactor = widget.widthFactor;
    if (widthFactor != null) {
      box = FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: box,
      );
    }
    return box;
  }
}

class DawaOfflineBanner extends StatelessWidget {
  const DawaOfflineBanner({
    super.key,
    this.message =
        'You are offline. Changes saved on this device will sync later.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: message,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: DawaSpacing.md,
            vertical: DawaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: DawaColors.warningSurface,
            border: Border.all(color: DawaColors.warning),
            borderRadius: BorderRadius.circular(DawaRadii.medium),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: DawaColors.warning),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.dawaBody.copyWith(
                    color: DawaColors.textPrimary,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class DawaPointsBadge extends StatelessWidget {
  const DawaPointsBadge({
    super.key,
    required this.points,
    this.label = 'points',
  });

  final int points;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$points $label',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DawaColors.warningSurface,
            borderRadius: BorderRadius.circular(DawaRadii.pill),
            border: Border.all(color: DawaColors.warning),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: DawaColors.warning,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                '$points',
                style: context.dawaCaption.copyWith(
                  color: DawaColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class DawaAudioButton extends StatelessWidget {
  const DawaAudioButton({
    super.key,
    required this.onPressed,
    this.playing = false,
    this.busy = false,
    this.label = 'Listen',
  });

  final VoidCallback? onPressed;
  final bool playing;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: busy
            ? 'Loading audio'
            : playing
                ? 'Pause audio'
                : label,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.volume_up_outlined,
                ),
          label: Text(playing ? 'Pause' : label),
        ),
      );
}

class _DawaStateCard extends StatelessWidget {
  const _DawaStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = DawaColors.primary,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                DawaIconBadge(icon: icon, color: iconColor, size: 58),
                const SizedBox(height: DawaSpacing.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.dawaSectionTitle,
                ),
                const SizedBox(height: DawaSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.dawaBody,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: DawaSpacing.md),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
