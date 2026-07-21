import '/backend/backend.dart';
import '/components/shimmer/shimmer_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EncounterDetailsWidget extends StatelessWidget {
  const EncounterDetailsWidget({
    super.key,
    required this.encounterDets,
  });

  final DocumentReference? encounterDets;

  static const String routeName = 'EncounterDetails';
  static const String routePath = '/encounterDetails';

  static const _brand = Color(0xFF2449D8);
  static const _page = Color(0xFFF5F7FB);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E8F0);
  static const _text = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    if (encounterDets == null) {
      return _messageScaffold(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Encounter unavailable',
        message:
            'We could not identify this encounter. Please go back and try again.',
      );
    }

    return StreamBuilder<EncounterRecord>(
      stream: EncounterRecord.getDocument(encounterDets!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _messageScaffold(
            context,
            icon: Icons.cloud_off_rounded,
            title: 'Could not load results',
            message:
                'Check your connection, then return to this page to try again.',
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: _page,
            body: SafeArea(child: ShimmerWidget()),
          );
        }
        return _resultsScaffold(context, snapshot.data!);
      },
    );
  }

  Widget _resultsScaffold(BuildContext context, EncounterRecord encounter) {
    final dateLabel = encounter.date == null
        ? 'Clinical encounter'
        : 'Encounter on ${dateTimeFormat('d MMMM y', encounter.date)}';

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _text),
        ),
        title: Text(
          dateLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 36),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _introCard(encounter),
                      const SizedBox(height: 24),
                      _sectionTitle(
                        Icons.favorite_outline_rounded,
                        'Mother’s health',
                        'Measurements recorded during this encounter',
                      ),
                      const SizedBox(height: 12),
                      _responsiveCards(
                        constraints.maxWidth,
                        [
                          _ResultMetric(
                            label: 'Heart rate',
                            value: encounter.hasPulse()
                                ? '${encounter.pulse} bpm'
                                : 'Not recorded',
                            icon: Icons.monitor_heart_outlined,
                            color: const Color(0xFFE65D75),
                          ),
                          _ResultMetric(
                            label: 'Blood pressure',
                            value: encounter.bp.trim().isEmpty
                                ? 'Not recorded'
                                : encounter.bp,
                            icon: Icons.favorite_border_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                          _ResultMetric(
                            label: 'Haemoglobin',
                            value: encounter.hasHemocheck()
                                ? '${encounter.hemocheck} g/dL'
                                : 'Not recorded',
                            icon: Icons.water_drop_outlined,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _sectionTitle(
                        Icons.child_care_rounded,
                        'Pregnancy and baby',
                        'Baby observations shared from the clinical record',
                      ),
                      const SizedBox(height: 12),
                      _responsiveCards(
                        constraints.maxWidth,
                        [
                          _ResultMetric(
                            label: 'Baby heartbeat',
                            value: encounter.hasHeartBeat()
                                ? '${encounter.heartBeat} bpm'
                                : 'Not recorded',
                            icon: Icons.favorite_rounded,
                            color: const Color(0xFFEC4899),
                          ),
                          _ResultMetric(
                            label: 'Heartbeat quality',
                            value: _orNotRecorded(encounter.heartBeatQuality),
                            icon: Icons.monitor_heart_outlined,
                            color: const Color(0xFF0891B2),
                          ),
                          _ResultMetric(
                            label: 'Womb position',
                            value: _orNotRecorded(encounter.wombPosition),
                            icon: Icons.pregnant_woman_rounded,
                            color: const Color(0xFF0F9F75),
                          ),
                          _ResultMetric(
                            label: 'Estimated baby size',
                            value: encounter.hasEstimatedBabySize()
                                ? '${encounter.estimatedBabySize} cm'
                                : 'Not recorded',
                            icon: Icons.straighten_rounded,
                            color: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                      if (encounter.comment.trim().isNotEmpty ||
                          encounter.nextVisit != null) ...[
                        const SizedBox(height: 28),
                        _followUpCard(encounter),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _introCard(EncounterRecord encounter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brand, Color(0xFF3B64E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242449D8),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.health_and_safety_outlined,
                color: Colors.white, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your encounter results',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These are the measurements recorded by your care team. Contact your clinic if you have questions about a result.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: .88),
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _brand, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _responsiveCards(double availableWidth, List<_ResultMetric> metrics) {
    final columns = availableWidth >= 900
        ? 3
        : availableWidth >= 620
            ? 2
            : 1;
    const gap = 12.0;
    final contentWidth = availableWidth.clamp(0, 1060).toDouble();
    final cardWidth = (contentWidth - (columns - 1) * gap) / columns;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: metrics
          .map((metric) => SizedBox(
                width: cardWidth,
                child: _metricCard(metric),
              ))
          .toList(),
    );
  }

  Widget _metricCard(_ResultMetric metric) {
    final missing = metric.value == 'Not recorded';
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: GoogleFonts.dmSans(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  metric.value,
                  style: GoogleFonts.dmSans(
                    color: missing ? _muted : _text,
                    fontSize: missing ? 15 : 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _followUpCard(EncounterRecord encounter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes and follow-up',
            style: GoogleFonts.dmSans(
              color: _text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (encounter.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _detailRow(Icons.notes_rounded, 'Care notes', encounter.comment),
          ],
          if (encounter.nextVisit != null) ...[
            const SizedBox(height: 14),
            _detailRow(
              Icons.event_available_outlined,
              'Next visit',
              dateTimeFormat('d MMMM y', encounter.nextVisit),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _brand, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value,
                  style: GoogleFonts.dmSans(
                      color: _text, fontSize: 14, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messageScaffold(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _text),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: _brand),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      color: _text, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      color: _muted, fontSize: 14, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }

  static String _orNotRecorded(String value) =>
      value.trim().isEmpty ? 'Not recorded' : value;
}

class _ResultMetric {
  const _ResultMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
