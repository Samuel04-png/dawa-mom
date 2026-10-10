import '/localization/dawa_localized_material.dart';
import 'package:intl/intl.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../domain/appointment_result_summary.dart';

class AppointmentResultSummaryView extends StatelessWidget {
  const AppointmentResultSummaryView({
    super.key,
    required this.summary,
  });

  final AppointmentResultSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final overallStatus = _overallStatus(summary.overallStatus, theme);
    final maternal = _ResultSection(
      icon: Icons.favorite_outline_rounded,
      title: 'Mother’s health',
      subtitle: 'High-level findings confirmed during your consultation.',
      measurements: [
        _ResultItem(
          'Heart rate',
          Icons.monitor_heart_outlined,
          summary.maternalSummary['heart_rate'],
        ),
        _ResultItem(
          'Blood pressure',
          Icons.speed_rounded,
          summary.maternalSummary['blood_pressure'],
        ),
        _ResultItem(
          'Blood / haemoglobin',
          Icons.water_drop_outlined,
          summary.maternalSummary['hemoglobin'],
        ),
      ],
    );
    final pregnancy = _ResultSection(
      icon: Icons.child_friendly_rounded,
      title: 'Pregnancy and baby health',
      subtitle: 'Only information recorded by your care team is shown.',
      measurements: [
        _ResultItem(
          'Pregnancy status',
          Icons.pregnant_woman_rounded,
          summary.pregnancySummary['pregnancy_status'],
        ),
        _ResultItem(
          'Heartbeat',
          Icons.favorite_border_rounded,
          summary.pregnancySummary['fetal_heartbeat'],
        ),
        _ResultItem(
          'Heartbeat quality',
          Icons.graphic_eq_rounded,
          summary.pregnancySummary['heartbeat_quality'],
        ),
        _ResultItem(
          'Position',
          Icons.baby_changing_station_outlined,
          summary.pregnancySummary['fetal_position'],
        ),
        _ResultItem(
          'Estimated baby size',
          Icons.straighten_rounded,
          summary.pregnancySummary['estimated_baby_size'],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryHeader(
          summary: summary,
          status: overallStatus,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 860) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  maternal,
                  const SizedBox(height: 16),
                  pregnancy,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: maternal),
                const SizedBox(width: 16),
                Expanded(child: pregnancy),
              ],
            );
          },
        ),
        if (_hasGuidance(summary)) ...[
          const SizedBox(height: 16),
          _GuidanceSection(summary: summary),
        ],
        const SizedBox(height: 16),
        _PatientSafetyNote(summary: summary),
      ],
    );
  }

  static bool _hasGuidance(AppointmentResultSummary summary) =>
      summary.recommendations != null ||
      summary.followUpInstructions != null ||
      summary.referralSummary != null ||
      summary.nextAppointmentAt != null ||
      summary.urgentCareInstruction != null;
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.summary,
    required this.status,
  });

  final AppointmentResultSummary summary;
  final _StatusSpec status;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 540;
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONSULTATION SUMMARY',
                    style: theme.labelSmall.copyWith(
                      color: theme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Your care summary',
                    style: theme.titleLarge.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed ${DateFormat('d MMMM y, h:mm a').format(summary.completedAt.toLocal())}',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              );
              final badge = _StatusBadge(spec: status);
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), badge],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: title), badge],
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status.foreground.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(status.icon, color: status.foreground, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.title,
                        style: theme.titleMedium.copyWith(
                          color: status.foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.keyFindings ?? status.description,
                        style: theme.bodyMedium.copyWith(
                          color: status.foreground,
                          height: 1.4,
                        ),
                      ),
                    ],
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

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.measurements,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<_ResultItem> measurements;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final visible = measurements
        .where((item) => item.measurement?.hasContent == true)
        .toList(growable: false);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: theme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                'No high-level result was recorded in this section.',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620
                    ? 3
                    : constraints.maxWidth >= 360
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - ((columns - 1) * 10)) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in visible)
                      SizedBox(
                        width: width,
                        child: _MeasurementCard(item: item),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.item});

  final _ResultItem item;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final measurement = item.measurement!;
    final status = _measurementStatus(measurement, theme);
    final value = _displayValue(measurement);
    return Container(
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: status.foreground, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.titleMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _StatusBadge(spec: status, compact: true),
        ],
      ),
    );
  }

  static String _displayValue(ResultMeasurement result) {
    if (result.value == null) return _stateLabel(result.state);
    if (result.unit == null) return _humanize(result.value!);
    return '${result.value} ${result.unit}';
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection({required this.summary});

  final AppointmentResultSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final items = <({IconData icon, String title, String value, bool urgent})>[
      if (summary.recommendations != null)
        (
          icon: Icons.tips_and_updates_outlined,
          title: 'Recommendations',
          value: summary.recommendations!,
          urgent: false,
        ),
      if (summary.followUpInstructions != null)
        (
          icon: Icons.event_repeat_rounded,
          title: 'Follow-up',
          value: summary.followUpInstructions!,
          urgent: false,
        ),
      if (summary.referralSummary != null)
        (
          icon: Icons.assistant_direction_outlined,
          title: 'Referral',
          value: summary.referralSummary!,
          urgent: false,
        ),
      if (summary.nextAppointmentAt != null)
        (
          icon: Icons.calendar_month_outlined,
          title: 'Recommended next visit',
          value: DateFormat('EEEE, d MMMM y')
              .format(summary.nextAppointmentAt!.toLocal()),
          urgent: false,
        ),
      if (summary.urgentCareInstruction != null)
        (
          icon: Icons.warning_amber_rounded,
          title: 'Urgent care instruction',
          value: summary.urgentCareInstruction!,
          urgent: true,
        ),
    ];
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: theme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recommendations and next steps',
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 12)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _GuidanceTile(
                        icon: item.icon,
                        title: item.title,
                        value: item.value,
                        urgent: item.urgent,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GuidanceTile extends StatelessWidget {
  const _GuidanceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.urgent,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = urgent ? theme.error : theme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFFF7F7)
            : theme.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: urgent
              ? theme.error.withValues(alpha: 0.18)
              : theme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    height: 1.4,
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

class _PatientSafetyNote extends StatelessWidget {
  const _PatientSafetyNote({required this.summary});

  final AppointmentResultSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: theme.primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This simple summary was checked by ${summary.clinicianDisplayName}. Contact ${summary.clinicName} if you have questions or your symptoms change.',
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.spec, this.compact = false});

  final _StatusSpec spec;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, color: spec.foreground, size: compact ? 14 : 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              spec.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: spec.foreground,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultItem {
  const _ResultItem(this.label, this.icon, this.measurement);

  final String label;
  final IconData icon;
  final ResultMeasurement? measurement;
}

class _StatusSpec {
  const _StatusSpec({
    required this.title,
    required this.description,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color foreground;
  final Color background;
}

_StatusSpec _overallStatus(String value, FlutterFlowTheme theme) {
  return switch (value) {
    'routine' => const _StatusSpec(
        title: 'Routine care',
        description: 'Your health worker added care advice.',
        icon: Icons.check_circle_outline_rounded,
        foreground: Color(0xFF15803D),
        background: Color(0xFFECFDF3),
      ),
    'urgent' => _StatusSpec(
        title: 'Urgent care instruction',
        description: 'Please follow the urgent care steps shown below.',
        icon: Icons.warning_amber_rounded,
        foreground: theme.error,
        background: const Color(0xFFFFF1F2),
      ),
    'needs_attention' => const _StatusSpec(
        title: 'Needs attention',
        description: 'Please review the findings and next steps carefully.',
        icon: Icons.error_outline_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFFBEB),
      ),
    _ => _StatusSpec(
        title: 'Follow-up recommended',
        description:
            'Please read what your health worker wants you to do next.',
        icon: Icons.event_repeat_rounded,
        foreground: theme.primary,
        background: theme.primary.withValues(alpha: 0.075),
      ),
  };
}

_StatusSpec _measurementStatus(
  ResultMeasurement result,
  FlutterFlowTheme theme,
) {
  if (result.source == 'patient' && result.state == 'recorded') {
    return _StatusSpec(
      title: 'Patient-provided',
      description: '',
      icon: Icons.person_outline_rounded,
      foreground: theme.primary,
      background: theme.primary.withValues(alpha: 0.09),
    );
  }
  final interpretation = result.interpretation ?? result.state;
  return switch (interpretation) {
    'normal' => const _StatusSpec(
        title: 'Normal',
        description: '',
        icon: Icons.check_circle_outline_rounded,
        foreground: Color(0xFF15803D),
        background: Color(0xFFECFDF3),
      ),
    'low' => const _StatusSpec(
        title: 'Low',
        description: '',
        icon: Icons.south_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFFBEB),
      ),
    'high' => const _StatusSpec(
        title: 'High',
        description: '',
        icon: Icons.north_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFFBEB),
      ),
    'critical' => _StatusSpec(
        title: 'Critical',
        description: '',
        icon: Icons.warning_amber_rounded,
        foreground: theme.error,
        background: const Color(0xFFFFF1F2),
      ),
    'needs_attention' => const _StatusSpec(
        title: 'Needs attention',
        description: '',
        icon: Icons.error_outline_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFFBEB),
      ),
    'not_measured' => _StatusSpec(
        title: 'Not measured',
        description: '',
        icon: Icons.remove_circle_outline_rounded,
        foreground: theme.secondaryText,
        background: theme.alternate.withValues(alpha: 0.55),
      ),
    'unable_to_obtain' => _StatusSpec(
        title: 'Unable to obtain',
        description: '',
        icon: Icons.info_outline_rounded,
        foreground: theme.secondaryText,
        background: theme.alternate.withValues(alpha: 0.55),
      ),
    'not_applicable' => _StatusSpec(
        title: 'Not applicable',
        description: '',
        icon: Icons.not_interested_outlined,
        foreground: theme.secondaryText,
        background: theme.alternate.withValues(alpha: 0.55),
      ),
    _ => _StatusSpec(
        title: 'Recorded',
        description: '',
        icon: Icons.check_rounded,
        foreground: theme.primary,
        background: theme.primary.withValues(alpha: 0.09),
      ),
  };
}

String _stateLabel(String value) => switch (value) {
      'not_measured' => 'Not measured',
      'unable_to_obtain' => 'Unable to obtain',
      'not_applicable' => 'Not applicable',
      _ => 'Recorded',
    };

String _humanize(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
