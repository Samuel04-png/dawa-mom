import 'package:flutter/material.dart';

import 'dawa_design_tokens.dart';
import '/features/preferences/dawa_user_preferences_repository.dart';

/// Motion timings shared by state-changing DawaMom interactions.
///
/// These are intentionally short: motion explains what changed, then gets out
/// of the way. Every component in this file resolves to zero duration when a
/// person has asked the platform to reduce motion.
abstract final class DawaMotion {
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const celebration = Duration(milliseconds: 420);

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ||
              DawaUserPreferencesRepository.feedbackAnimationsReduced.value
          ? Duration.zero
          : duration;
}

enum DawaFeedbackTone { success, pending, error, information }

/// A compact, readable acknowledgement for a confirmed action or a known
/// pending/error state. Use this inline near the action that produced it; save
/// sheets for consequential milestones such as a confirmed payment.
class DawaActionFeedback extends StatelessWidget {
  const DawaActionFeedback({
    super.key,
    required this.title,
    required this.message,
    this.tone = DawaFeedbackTone.success,
    this.actionLabel,
    this.onAction,
    this.dismissLabel,
    this.onDismiss,
  });

  final String title;
  final String message;
  final DawaFeedbackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable:
            DawaUserPreferencesRepository.feedbackAnimationsReduced,
        builder: (context, _, __) => _buildFeedback(context),
      );

  Widget _buildFeedback(BuildContext context) {
    final presentation = _feedbackPresentation(tone);
    final canAct = actionLabel != null && onAction != null;
    final canDismiss = dismissLabel != null && onDismiss != null;
    final body = Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: AnimatedContainer(
        duration: DawaMotion.resolve(context, DawaMotion.standard),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(DawaSpacing.sm),
        decoration: BoxDecoration(
          color: presentation.background,
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          border: Border.all(color: presentation.color.withValues(alpha: .28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeedbackIcon(
              icon: presentation.icon,
              color: presentation.color,
              animate: tone == DawaFeedbackTone.success,
            ),
            const SizedBox(width: DawaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.dawaSectionTitle.copyWith(
                      color: presentation.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.textSecondary,
                    ),
                  ),
                  if (canAct || canDismiss) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: DawaSpacing.xs,
                      children: [
                        if (canAct)
                          TextButton(
                            onPressed: onAction,
                            style: TextButton.styleFrom(
                              foregroundColor: presentation.foreground,
                              minimumSize: const Size(44, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: DawaSpacing.xs,
                              ),
                            ),
                            child: Text(actionLabel!),
                          ),
                        if (canDismiss)
                          TextButton(
                            onPressed: onDismiss,
                            style: TextButton.styleFrom(
                              foregroundColor: DawaColors.textSecondary,
                              minimumSize: const Size(44, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: DawaSpacing.xs,
                              ),
                            ),
                            child: Text(dismissLabel!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: DawaMotion.resolve(context, DawaMotion.standard),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .97, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('$tone-$title-$message'),
        child: body,
      ),
    );
  }
}

class _FeedbackIcon extends StatelessWidget {
  const _FeedbackIcon({
    required this.icon,
    required this.color,
    required this.animate,
  });

  final IconData icon;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? .82 : 1, end: 1),
        duration: DawaMotion.resolve(
          context,
          animate ? DawaMotion.celebration : DawaMotion.fast,
        ),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 23),
        ),
      );
}

class _FeedbackPresentation {
  const _FeedbackPresentation({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final Color background;
}

_FeedbackPresentation _feedbackPresentation(DawaFeedbackTone tone) =>
    switch (tone) {
      DawaFeedbackTone.success => const _FeedbackPresentation(
          icon: Icons.check_rounded,
          color: DawaColors.greenDark,
          foreground: DawaColors.greenDark,
          background: DawaColors.successSurface,
        ),
      DawaFeedbackTone.pending => const _FeedbackPresentation(
          icon: Icons.schedule_rounded,
          color: DawaColors.primary,
          foreground: DawaColors.primaryDark,
          background: DawaColors.softBlue,
        ),
      DawaFeedbackTone.error => const _FeedbackPresentation(
          icon: Icons.info_outline_rounded,
          color: DawaColors.danger,
          foreground: DawaColors.danger,
          background: DawaColors.dangerSurface,
        ),
      DawaFeedbackTone.information => const _FeedbackPresentation(
          icon: Icons.info_outline_rounded,
          color: DawaColors.teal,
          foreground: DawaColors.teal,
          background: DawaColors.softTeal,
        ),
    };

/// A count-up treatment for a real change in the rewards balance.
///
/// Callers must provide the old and new persisted values; a zero/negative
/// delta intentionally does not look like a reward.
class DawaPointsFeedback extends StatelessWidget {
  const DawaPointsFeedback({
    super.key,
    required this.previousPoints,
    required this.currentPoints,
    this.label = 'Dawa Points',
    this.compact = false,
  });

  final int previousPoints;
  final int currentPoints;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final delta = currentPoints - previousPoints;
    final earned = delta > 0;
    return Semantics(
      liveRegion: true,
      label: earned
          ? '$label updated. You earned $delta points. Total $currentPoints.'
          : '$label total $currentPoints.',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? DawaSpacing.xs : DawaSpacing.sm,
          vertical: compact ? 5 : DawaSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: earned ? DawaColors.softGreen : DawaColors.softBlue,
          borderRadius: BorderRadius.circular(DawaRadii.small),
          border: Border.all(
            color: (earned ? DawaColors.green : DawaColors.primary)
                .withValues(alpha: .25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              earned
                  ? Icons.add_circle_outline_rounded
                  : Icons.workspace_premium_outlined,
              color: earned ? DawaColors.greenDark : DawaColors.primary,
              size: compact ? 17 : 19,
            ),
            const SizedBox(width: 5),
            if (earned) ...[
              Text(
                '+$delta',
                style: context.dawaCaption.copyWith(
                  color: DawaColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
            ],
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: MediaQuery.disableAnimationsOf(context)
                    ? currentPoints.toDouble()
                    : previousPoints.toDouble(),
                end: currentPoints.toDouble(),
              ),
              duration: DawaMotion.resolve(context, DawaMotion.celebration),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                '${value.round()} $label',
                style: context.dawaCaption.copyWith(
                  color: DawaColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gives a known status a small, state-change transition without relying on
/// colour alone. It is useful for real-time appointment/payment updates.
class DawaStatusTransition extends StatelessWidget {
  const DawaStatusTransition({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: DawaMotion.resolve(context, DawaMotion.standard),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Semantics(
          key: ValueKey(label),
          liveRegion: true,
          label: label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(DawaRadii.pill),
              border: Border.all(color: color.withValues(alpha: .28)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final labelText = Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.dawaCaption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );
                return Row(
                  mainAxisSize: constraints.hasBoundedWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 5),
                    if (constraints.hasBoundedWidth)
                      Flexible(child: labelText)
                    else
                      labelText,
                  ],
                );
              },
            ),
          ),
        ),
      );
}

/// Subtle press feedback for selected large cards and controls. It is not a
/// replacement for normal Material ink feedback and deliberately never bounces.
class DawaPressable extends StatefulWidget {
  const DawaPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.scale = .98,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<DawaPressable> createState() => _DawaPressableState();
}

class _DawaPressableState extends State<DawaPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _pressed && !MediaQuery.disableAnimationsOf(context)
              ? widget.scale
              : 1,
          duration: DawaMotion.resolve(context, DawaMotion.fast),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
