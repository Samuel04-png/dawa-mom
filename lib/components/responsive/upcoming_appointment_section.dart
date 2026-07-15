import 'package:flutter/material.dart';
import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/navbar/appointments/appointment_details/appointment_details_widget.dart';
import 'responsive_layout.dart';

class UpcomingAppointmentSection extends StatelessWidget {
  UpcomingAppointmentSection({super.key, this.compact = false});

  final bool compact;
  final AppointmentRepository _repository = AppointmentRepository();

  Future<void> _book(BuildContext context) async {
    await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingBottomSheetWidget(),
    );
  }

  void _open(BuildContext context, Appointment appointment) {
    context.pushNamed(
      AppointmentDetailsWidget.routeName,
      queryParameters: {'appointmentId': appointment.id},
    );
  }

  Future<void> _cancel(BuildContext context, Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'The clinic will be notified and this time will be released. This does not delete your appointment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await _repository.cancelAppointment(appointment.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The appointment could not be cancelled. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppointmentRepository.changes,
      builder: (context, _, __) {
        return FutureBuilder<Appointment?>(
          future: _repository.getNextAppointment(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: compact ? 150 : 190,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return DawaMomEmptyState(
                icon: Icons.event_available_outlined,
                title: 'No upcoming appointments',
                description:
                    'Book an appointment with a clinic or healthcare professional.',
                actionLabel: 'Book Appointment',
                onAction: () => _book(context),
                compact: compact,
              );
            }
            final appointment = snapshot.data!;
            return UpcomingAppointmentCard(
              appointment: appointment,
              compact: compact,
              onOpen: () => _open(context, appointment),
              onCancel: appointment.canPatientCancel
                  ? () => _cancel(context, appointment)
                  : null,
            );
          },
        );
      },
    );
  }
}

class UpcomingAppointmentCard extends StatelessWidget {
  const UpcomingAppointmentCard({
    required this.appointment,
    required this.compact,
    required this.onOpen,
    this.onCancel,
  });

  final Appointment appointment;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final start = Appointment.dateAtTime(
      appointment.date,
      appointment.startTime,
    );
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 52 : 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('MMM').format(start).toUpperCase(),
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('d').format(start),
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.clinicianName ?? 'Clinician',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _AppointmentStatusBadge(status: appointment.status),
                  PopupMenuButton<_AppointmentCardAction>(
                    tooltip: 'Appointment actions',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case _AppointmentCardAction.view:
                          onOpen();
                        case _AppointmentCardAction.cancel:
                          onCancel?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _AppointmentCardAction.view,
                        child: Text('View details'),
                      ),
                      if (onCancel != null)
                        const PopupMenuItem(
                          value: _AppointmentCardAction.cancel,
                          child: Text('Cancel appointment'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                appointment.clinicName ?? 'Clinic',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
              const SizedBox(height: 10),
              Text(
                '${DateFormat('EEEE, d MMMM').format(start)} - ${DateFormat.jm().format(start)}',
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        mouseCursor: SystemMouseCursors.click,
        canRequestFocus: true,
        borderRadius: BorderRadius.circular(14),
        hoverColor: theme.primary.withValues(alpha: 0.04),
        focusColor: theme.primary.withValues(alpha: 0.1),
        child: compact
            ? Padding(padding: const EdgeInsets.all(10), child: content)
            : DawaMomCard(child: content),
      ),
    );
  }
}

enum _AppointmentCardAction { view, cancel }

class _AppointmentStatusBadge extends StatelessWidget {
  const _AppointmentStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'confirmed' || 'completed' => const Color(0xFF1C8B4C),
      'declined' || 'cancelled' || 'missed' => const Color(0xFFC63A3A),
      'rescheduled' => const Color(0xFF6F42C1),
      _ => const Color(0xFF9A5B00),
    };
    final label = normalized.isEmpty
        ? 'Pending'
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
