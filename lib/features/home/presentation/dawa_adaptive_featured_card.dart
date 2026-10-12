import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/care_plan/domain/dawa_care_item.dart';
import '/features/home/domain/dawa_home_presentation.dart';
import '/features/period_tracker/domain/period_cycle_summary.dart';
import '/features/pregnancy/domain/dawa_pregnancy_journey.dart';

/// The single primary Home surface. Its information is selected by the pure
/// Home presentation mapper; this widget only gives each supported journey a
/// recognisable, compact visual treatment.
class DawaAdaptiveFeaturedCard extends StatelessWidget {
  const DawaAdaptiveFeaturedCard({
    super.key,
    required this.presentation,
    required this.onAction,
  });

  final DawaHomePresentation presentation;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final style = _FeaturedStyle.from(presentation.kind);
    return Semantics(
      container: true,
      label: '${presentation.title}. ${presentation.message}',
      child: DawaCard(
        key: ValueKey('home-featured-${presentation.kind.name}'),
        featured: true,
        padding: EdgeInsets.zero,
        color: style.background,
        borderColor: style.color.withValues(alpha: .16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (presentation.showsCyclePreview) {
              return _CycleFeaturedContent(
                presentation: presentation,
                style: style,
                onAction: onAction,
                availableWidth: constraints.maxWidth,
              );
            }
            final stacked = constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final visualSize = constraints.maxWidth < 390 ? 118.0 : 130.0;
            final copy = _FeaturedCopy(
              presentation: presentation,
              style: style,
              onAction: onAction,
            );
            final visual = _FeaturedVisual(
              presentation: presentation,
              style: style,
              size: visualSize,
            );
            if (stacked) {
              return Padding(
                padding: const EdgeInsets.all(DawaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(alignment: Alignment.centerRight, child: visual),
                    const SizedBox(height: DawaSpacing.xs),
                    copy,
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(DawaSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: DawaSpacing.sm),
                  SizedBox(width: visualSize, child: visual),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A Home-sized cycle summary. It intentionally offers time context and a
/// read-only preview only; logging controls continue to live in Track.
class _CycleFeaturedContent extends StatelessWidget {
  const _CycleFeaturedContent({
    required this.presentation,
    required this.style,
    required this.onAction,
    required this.availableWidth,
  });

  final DawaHomePresentation presentation;
  final _FeaturedStyle style;
  final VoidCallback onAction;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final narrow = availableWidth < 300;
    final stackedForText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final ringSize = stackedForText
        ? 148.0
        : narrow
            ? 128.0
            : 170.0;
    final ring = _CyclePreviewRing(
      summary: presentation.cycle!,
      size: ringSize,
    );
    final copy = _FeaturedCopy(
      presentation: presentation,
      style: style,
      onAction: onAction,
      eyebrow: presentation.kind == DawaHomeFeaturedKind.activePeriod
          ? 'PERIOD'
          : 'YOUR CYCLE',
      messageMaxLines: narrow ? 3 : 2,
      actionLabel:
          narrow && presentation.kind == DawaHomeFeaturedKind.activePeriod
              ? 'Track'
              : null,
    );

    return Padding(
      padding: const EdgeInsets.all(DawaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CycleDateStrip(
            summary: presentation.cycle!,
            accent: style.color,
          ),
          const SizedBox(height: DawaSpacing.sm),
          if (stackedForText) ...[
            Align(alignment: Alignment.center, child: ring),
            const SizedBox(height: DawaSpacing.sm),
            copy,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: DawaSpacing.sm),
                SizedBox(width: ringSize, child: ring),
              ],
            ),
        ],
      ),
    );
  }
}

class _CycleDateStrip extends StatelessWidget {
  const _CycleDateStrip({required this.summary, required this.accent});

  final PeriodCycleSummary summary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List<DateTime>.generate(
      5,
      (index) => today.add(Duration(days: index - 2)),
    );
    return Semantics(
      key: const ValueKey('home-cycle-date-strip'),
      container: true,
      label:
          'Five day cycle context. Today is ${DateFormat('d MMMM').format(today)}.',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (final date in dates)
              Expanded(
                child: _CycleDateCell(
                  date: date,
                  isToday: _sameDate(date, today),
                  isPeriodDay: _isPeriodDay(date, summary),
                  accent: accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CycleDateCell extends StatelessWidget {
  const _CycleDateCell({
    required this.date,
    required this.isToday,
    required this.isPeriodDay,
    required this.accent,
  });

  final DateTime date;
  final bool isToday;
  final bool isPeriodDay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat.E().format(date).substring(0, 1).toUpperCase();
    final background =
        isToday ? accent.withValues(alpha: .15) : Colors.transparent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isToday ? 'TODAY' : dayLabel,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: context.dawaCaption.copyWith(
            color: isToday ? accent : DawaColors.textMuted,
            fontSize: 9,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: isToday
                ? Border.all(color: accent.withValues(alpha: .55), width: 1.5)
                : null,
          ),
          child: Text(
            '${date.day}',
            style: context.dawaBody.copyWith(
              color: isToday ? DawaColors.ink : DawaColors.textMuted,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 8,
          child: isPeriodDay
              ? Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: DawaColors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isPeriodDay(DateTime date, PeriodCycleSummary summary) {
  final start = summary.lastPeriodStart;
  if (start == null) return false;
  final dateOnly = DateTime(date.year, date.month, date.day);
  final startOnly = DateTime(start.year, start.month, start.day);
  final difference = dateOnly.difference(startOnly).inDays;
  final periodLength = summary.averagePeriodLength ?? 5;
  return difference >= 0 && difference < periodLength;
}

class _FeaturedCopy extends StatelessWidget {
  const _FeaturedCopy({
    required this.presentation,
    required this.style,
    required this.onAction,
    this.eyebrow,
    this.messageMaxLines = 2,
    this.actionLabel,
  });

  final DawaHomePresentation presentation;
  final _FeaturedStyle style;
  final VoidCallback onAction;
  final String? eyebrow;
  final int messageMaxLines;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow ?? style.eyebrow,
            style: context.dawaCaption.copyWith(
              color: style.color,
              fontWeight: FontWeight.w700,
              letterSpacing: .65,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            presentation.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.dawaTitle.copyWith(fontSize: 20, height: 1.08),
          ),
          const SizedBox(height: 5),
          Text(
            presentation.message,
            maxLines: messageMaxLines,
            overflow: TextOverflow.ellipsis,
            style: context.dawaBody,
          ),
          const SizedBox(height: DawaSpacing.sm),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: Icon(style.actionIcon),
              label: Text(actionLabel ?? presentation.actionLabel),
              style: FilledButton.styleFrom(backgroundColor: style.color),
            ),
          ),
        ],
      );
}

class _FeaturedVisual extends StatelessWidget {
  const _FeaturedVisual({
    required this.presentation,
    required this.style,
    required this.size,
  });

  final DawaHomePresentation presentation;
  final _FeaturedStyle style;
  final double size;

  @override
  Widget build(BuildContext context) => switch (presentation.kind) {
        DawaHomeFeaturedKind.activePeriod ||
        DawaHomeFeaturedKind.cycle =>
          _CyclePreviewRing(summary: presentation.cycle!, size: size),
        DawaHomeFeaturedKind.pregnancy => _PregnancyVisual(
            week: presentation.pregnancyWeek!,
            day: presentation.pregnancyDay ?? 1,
            progress: presentation.pregnancyProgress ?? 0,
            daysUntilDue: presentation.daysUntilDue,
            color: style.color,
            size: size,
          ),
        DawaHomeFeaturedKind.appointment => _AppointmentVisual(
            appointment: presentation.appointment!, size: size),
        DawaHomeFeaturedKind.care => _CareVisual(
            label: presentation.careItem!.status == DawaCareItemStatus.overdue
                ? 'Due'
                : 'Care',
            color: style.color,
            size: size,
          ),
        DawaHomeFeaturedKind.profileSetup => _ArtworkVisual(
            asset: DawaArtwork.motherGreeting,
            label: 'Complete your health profile',
            size: size,
          ),
        DawaHomeFeaturedKind.general => _ArtworkVisual(
            asset: DawaArtwork.homeHeroMama,
            label: 'Your health today',
            size: size,
          ),
      };
}

class _CyclePreviewRing extends StatelessWidget {
  const _CyclePreviewRing({required this.summary, required this.size});

  final PeriodCycleSummary summary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cycleLength = summary.averageCycleLength ?? 28;
    final periodLength = summary.averagePeriodLength ?? 5;
    final cycleDay = summary.cycleDay ?? 1;
    final active = summary.isPeriodActive;
    return SizedBox(
      key: const ValueKey('home-cycle-preview-ring'),
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (active ? DawaColors.softPink : DawaColors.softBlue)
                  .withValues(alpha: .7),
              boxShadow: [
                BoxShadow(
                  color: (active ? DawaColors.pink : DawaColors.primary)
                      .withValues(alpha: .12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: size - 14,
            height: size - 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DawaColors.surface.withValues(alpha: .78),
            ),
          ),
          CustomPaint(
            size: Size.square(size - 22),
            painter: _HomeCycleRingPainter(
              cycleLength: cycleLength,
              periodLength: periodLength,
              cycleDay: cycleDay,
              active: active,
              showFertileWindow: summary.isRegular == true,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active ? 'PERIOD' : 'CYCLE',
                style: context.dawaCaption.copyWith(
                  color: active ? DawaColors.pink : DawaColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
              Text('Day $cycleDay', style: context.dawaSectionTitle),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeCycleRingPainter extends CustomPainter {
  const _HomeCycleRingPainter({
    required this.cycleLength,
    required this.periodLength,
    required this.cycleDay,
    required this.active,
    required this.showFertileWindow,
  });

  final int cycleLength;
  final int periodLength;
  final int cycleDay;
  final bool active;
  final bool showFertileWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 11;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final safeLength = cycleLength.clamp(21, 45);
    final perDay = 2 * math.pi / safeLength;
    void arc(int start, int length, Color color) {
      if (length <= 0) return;
      canvas.drawArc(
        rect,
        startAngle + (start - 1) * perDay,
        math.min(length * perDay - .03, 2 * math.pi - .03),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = DawaColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    arc(1, periodLength.clamp(0, safeLength), DawaColors.pink);
    if (showFertileWindow) arc(safeLength - 19, 7, DawaColors.green);
    final markerAngle =
        startAngle + (cycleDay.clamp(1, safeLength) - 1) * perDay;
    final marker = Offset(
      center.dx + math.cos(markerAngle) * radius,
      center.dy + math.sin(markerAngle) * radius,
    );
    canvas.drawCircle(
      marker,
      8,
      Paint()
        ..color = DawaColors.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      marker,
      5,
      Paint()
        ..color = active ? DawaColors.pink : DawaColors.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeCycleRingPainter oldDelegate) =>
      cycleLength != oldDelegate.cycleLength ||
      periodLength != oldDelegate.periodLength ||
      cycleDay != oldDelegate.cycleDay ||
      active != oldDelegate.active ||
      showFertileWindow != oldDelegate.showFertileWindow;
}

class _PregnancyVisual extends StatelessWidget {
  const _PregnancyVisual({
    required this.week,
    required this.day,
    required this.progress,
    required this.daysUntilDue,
    required this.color,
    required this.size,
  });

  final int week;
  final int day;
  final double progress;
  final int? daysUntilDue;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stage = DawaPregnancyDevelopment.forWeek(week);
    return SizedBox(
        height: size,
        width: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 7,
              color: color,
              backgroundColor: DawaColors.surface,
            ),
            ClipOval(
              child: stage.assetPath == null
                  ? Container(
                      width: size - 24,
                      height: size - 24,
                      color: DawaColors.surface,
                      child: const Icon(Icons.favorite_outline_rounded,
                          color: DawaColors.purple, size: 30),
                    )
                  : Image.asset(
                      stage.assetPath!,
                      width: size - 24,
                      height: size - 24,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      semanticLabel: 'Illustrative pregnancy development stage',
                    ),
            ),
            Positioned(
              bottom: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: DawaColors.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  daysUntilDue == null
                      ? 'Week $week · Day $day'
                      : '$daysUntilDue days',
                  style: context.dawaCaption.copyWith(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}

class _AppointmentVisual extends StatelessWidget {
  const _AppointmentVisual({required this.appointment, required this.size});

  final Appointment appointment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final date = appointment.date;
    final statusLabel = switch (appointment.status) {
      'pending' => 'REQUESTED',
      'confirmed' => 'CONFIRMED',
      'rescheduled' => 'RESCHEDULED',
      _ => 'UPCOMING',
    };
    return Container(
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DawaColors.surface,
        borderRadius: BorderRadius.circular(DawaRadii.large),
        border: Border.all(color: DawaColors.green.withValues(alpha: .25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(DateFormat('MMM').format(date).toUpperCase(),
              style: context.dawaCaption.copyWith(
                color: DawaColors.greenDark,
                fontWeight: FontWeight.w700,
              )),
          Text('${date.day}',
              style: context.dawaDisplay.copyWith(fontSize: 34)),
          Text(
            statusLabel,
            style: context.dawaCaption.copyWith(
              color: appointment.status == 'pending'
                  ? DawaColors.primary
                  : DawaColors.greenDark,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareVisual extends StatelessWidget {
  const _CareVisual({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DawaIconBadge(
              icon: Icons.medical_services_outlined,
              color: color,
              background: DawaColors.surface,
              size: 58,
            ),
            const SizedBox(height: 6),
            Text(label, style: context.dawaCaption),
          ],
        ),
      );
}

class _ArtworkVisual extends StatelessWidget {
  const _ArtworkVisual({
    required this.asset,
    required this.label,
    required this.size,
  });

  final String asset;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: label,
        child: SizedBox(
          height: size,
          child: Image.asset(asset,
              fit: BoxFit.contain, excludeFromSemantics: true),
        ),
      );
}

class _FeaturedStyle {
  const _FeaturedStyle({
    required this.eyebrow,
    required this.color,
    required this.background,
    required this.actionIcon,
  });

  final String eyebrow;
  final Color color;
  final Color background;
  final IconData actionIcon;

  factory _FeaturedStyle.from(DawaHomeFeaturedKind kind) => switch (kind) {
        DawaHomeFeaturedKind.activePeriod => const _FeaturedStyle(
            eyebrow: 'YOUR CYCLE TODAY',
            color: DawaColors.pink,
            background: DawaColors.softPink,
            actionIcon: Icons.water_drop_outlined,
          ),
        DawaHomeFeaturedKind.cycle => const _FeaturedStyle(
            eyebrow: 'YOUR CYCLE TODAY',
            color: DawaColors.primary,
            background: DawaColors.softBlue,
            actionIcon: Icons.auto_graph_rounded,
          ),
        DawaHomeFeaturedKind.pregnancy => const _FeaturedStyle(
            eyebrow: 'YOUR PREGNANCY',
            color: DawaColors.purple,
            background: DawaColors.softPurple,
            actionIcon: Icons.pregnant_woman_rounded,
          ),
        DawaHomeFeaturedKind.appointment => const _FeaturedStyle(
            eyebrow: 'YOUR NEXT VISIT',
            color: DawaColors.greenDark,
            background: DawaColors.softGreen,
            actionIcon: Icons.calendar_month_rounded,
          ),
        DawaHomeFeaturedKind.care => const _FeaturedStyle(
            eyebrow: 'CARE NEXT STEP',
            color: DawaColors.warning,
            background: DawaColors.warningSurface,
            actionIcon: Icons.medical_services_outlined,
          ),
        DawaHomeFeaturedKind.profileSetup => const _FeaturedStyle(
            eyebrow: 'YOUR HEALTH PROFILE',
            color: DawaColors.primary,
            background: DawaColors.softBlue,
            actionIcon: Icons.assignment_ind_outlined,
          ),
        DawaHomeFeaturedKind.general => const _FeaturedStyle(
            eyebrow: 'WELCOME TO DAWAMOM',
            color: DawaColors.greenDark,
            background: DawaColors.softGreen,
            actionIcon: Icons.calendar_month_rounded,
          ),
      };
}
