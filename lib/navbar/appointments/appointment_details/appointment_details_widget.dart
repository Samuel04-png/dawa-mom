import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/backend/backend.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class AppointmentDetailsWidget extends StatefulWidget {
  const AppointmentDetailsWidget({
    super.key,
    this.encounterDets,
    this.appointmentId,
  });

  final DocumentReference? encounterDets;
  final String? appointmentId;

  static const String routeName = 'AppointmentDetails';
  static const String routePath = '/appointmentDetails';

  @override
  State<AppointmentDetailsWidget> createState() =>
      _AppointmentDetailsWidgetState();
}

class _AppointmentDetailsWidgetState extends State<AppointmentDetailsWidget> {
  final _repository = AppointmentRepository();
  late Future<Appointment?> _appointment;
  bool _cancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppointmentRepository.changes.addListener(_onAppointmentChanged);
    _appointment = _load();
  }

  @override
  void dispose() {
    AppointmentRepository.changes.removeListener(_onAppointmentChanged);
    super.dispose();
  }

  void _onAppointmentChanged() {
    if (mounted) _refresh();
  }

  Future<Appointment?> _load() {
    final id = widget.appointmentId ?? widget.encounterDets?.id;
    return id == null ? Future.value() : _repository.getAppointment(id);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _appointment = future;
      _error = null;
    });
    await future;
  }

  Future<void> _cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'This will release the selected time. You can book a new appointment afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep appointment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      final updated = await _repository.cancelAppointment(appointment.id);
      if (!mounted) return;
      setState(() {
        _appointment = Future.value(updated);
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled')),
      );
    } on AppointmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = 'The appointment could not be cancelled. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        title: const Text('Appointment details'),
      ),
      body: FutureBuilder<Appointment?>(
        future: _appointment,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailsError(onRetry: _refresh);
          }
          final appointment = snapshot.data;
          if (appointment == null) {
            return const _MissingAppointment();
          }
          return _DetailsBody(
            appointment: appointment,
            error: _error,
            cancelling: _cancelling,
            onCancel: () => _cancel(appointment),
          );
        },
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.appointment,
    required this.cancelling,
    required this.onCancel,
    this.error,
  });

  final Appointment appointment;
  final bool cancelling;
  final VoidCallback onCancel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final start = Appointment.dateAtTime(
      appointment.date,
      appointment.startTime,
    );
    final end = Appointment.dateAtTime(
      appointment.date,
      appointment.endTime,
    );
    final statusMessage = appointment.patientSafeStatusMessage?.trim().isNotEmpty ==
            true
        ? appointment.patientSafeStatusMessage!.trim()
        : appointment.integrationStatus == 'failed'
            ? 'Your appointment is saved, but the clinic connection needs attention. It will be retried safely.'
            : appointment.status == 'pending'
                ? 'Your request is pending confirmation. Dawa Mom will show status updates here when the clinic responds.'
                : 'Appointment status: ${_statusLabel(appointment.status)}.';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              _statusLabel(appointment.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('EEEE, d MMMM y').format(start),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailCard(
                children: [
                  _DetailRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Clinician',
                    value: appointment.clinicianName ?? 'Clinician',
                  ),
                  if (appointment.clinicianTitle?.isNotEmpty == true ||
                      appointment.clinicianSpeciality?.isNotEmpty == true)
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'Title or speciality',
                      value: [
                        appointment.clinicianTitle,
                        appointment.clinicianSpeciality,
                      ]
                          .whereType<String>()
                          .where((value) => value.trim().isNotEmpty)
                          .join(' - '),
                    ),
                  _DetailRow(
                    icon: Icons.local_hospital_outlined,
                    label: 'Clinic',
                    value: appointment.clinicName ?? 'Clinic',
                  ),
                  if (appointment.clinicAddress?.isNotEmpty == true)
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Clinic location',
                      value: appointment.clinicAddress!,
                    ),
                  _DetailRow(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Appointment type',
                    value: _typeLabel(appointment.appointmentType),
                  ),
                  if (appointment.reason?.isNotEmpty == true)
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Reason',
                      value: appointment.reason!,
                    ),
                  if (appointment.notes?.isNotEmpty == true)
                    _DetailRow(
                      icon: Icons.description_outlined,
                      label: 'Booking notes',
                      value: appointment.notes!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailCard(
                children: [
                  _DetailRow(
                    icon: Icons.source_outlined,
                    label: 'Booking source',
                    value: _typeLabel(appointment.source),
                  ),
                  _DetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'Booked on',
                    value: DateFormat('d MMM y, h:mm a')
                        .format(appointment.createdAt.toLocal()),
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: const Text('Technical information'),
                    subtitle: const Text('Reference for support requests'),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          'Appointment ID: ${appointment.id}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: theme.bodyMedium.copyWith(
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Text(
                  error!,
                  style: TextStyle(color: theme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              if (appointment.canPatientCancel) ...[
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: cancelling ? null : onCancel,
                  icon: cancelling
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_busy_outlined),
                  label: Text(
                    cancelling ? 'Cancelling…' : 'Cancel appointment',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.error,
                    side: BorderSide(color: theme.error),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status) => status.isEmpty
      ? 'Pending'
      : '${status[0].toUpperCase()}${status.substring(1)}';

  static String _typeLabel(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingAppointment extends StatelessWidget {
  const _MissingAppointment();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This appointment is no longer available.'),
        ),
      );
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Appointment details could not be loaded.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
