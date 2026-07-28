import '/localization/dawa_localized_material.dart';

import '/design_system/dawa_design_tokens.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class ResponsivePageContainer extends StatelessWidget {
  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1240,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: width >= 1100 ? 32 : 22,
                vertical: width >= 700 ? 24 : 16,
              ),
          child: child,
        ),
      ),
    );
  }
}

class ResponsiveContentGrid extends StatelessWidget {
  const ResponsiveContentGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minItemWidth).floor().clamp(
              1,
              children.length,
            );
        final itemWidth =
            (constraints.maxWidth - (spacing * (count - 1))) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.titleLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class DawaMomEmptyState extends StatelessWidget {
  const DawaMomEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 46 : 58,
            height: compact ? 46 : 58,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.16),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(compact ? 18 : 22),
                topRight: Radius.circular(compact ? 10 : 12),
                bottomRight: Radius.circular(compact ? 18 : 22),
                bottomLeft: Radius.circular(compact ? 10 : 12),
              ),
            ),
            child: Icon(icon, color: theme.primary, size: compact ? 24 : 29),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.titleSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: theme.primary),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class DawaMomCard extends StatelessWidget {
  const DawaMomCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DawaRadii.large),
          topRight: Radius.circular(DawaRadii.medium),
          bottomRight: Radius.circular(DawaRadii.large),
          bottomLeft: Radius.circular(DawaRadii.medium),
        ),
        border: Border.all(color: theme.alternate),
        boxShadow: DawaShadows.card,
      ),
      child: child,
    );
  }
}
