import 'package:flutter/material.dart';

import '/components/branding/dawa_mom_logo.dart';
import 'dawa_design_tokens.dart';

abstract final class DawaArtwork {
  static const motherGreeting =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Greeting.png';
  static const motherLearning =
      'dawa_mom_screens/assets/characters/main_mother/CHAR-MOTHER-Learning.png';
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
  static const banaWelcome =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Welcoming.png';
  static const banaCelebrate =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Celebrating_Reward.png';
  static const banaExplain =
      'dawa_mom_screens/assets/characters/bana_chenjela/CHAR-BANA-Explaining.png';
  static const clinicianDoctor =
      'dawa_mom_screens/assets/characters/clinicians/CHAR-CLINICIAN-Doctor-Explaining.png';
  static const clinicianMidwife =
      'dawa_mom_screens/assets/characters/clinicians/CHAR-CLINICIAN-Midwife-Listening.png';
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    final content = Padding(padding: padding, child: child);
    final surface = Material(
      color: color,
      shape: shape,
      elevation: 1,
      shadowColor: const Color(0x1A0C2878),
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
    );
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: surface,
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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

class DawaAppHeader extends StatelessWidget {
  const DawaAppHeader({
    super.key,
    this.title,
    this.eyebrow,
    this.onBack,
    this.onNotifications,
    this.onProfile,
    this.notificationUnread = false,
  });

  final String? title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool notificationUnread;

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
                semanticLabel: 'Dawa Mom',
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
              Stack(
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
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            minHeight: height,
            value: value.clamp(0, 1),
            backgroundColor: DawaColors.line,
            valueColor: AlwaysStoppedAnimation(color),
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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, size: 19),
                    ],
                  ],
                ),
        ),
      );
}
