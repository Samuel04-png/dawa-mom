import 'package:flutter/material.dart';

import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

class EncountersWidget extends StatefulWidget {
  const EncountersWidget({super.key});

  static const String routeName = 'Encounters';
  static const String routePath = '/encounters';

  @override
  State<EncountersWidget> createState() => _EncountersWidgetState();
}

class _EncountersWidgetState extends State<EncountersWidget> {
  final _repository = AppointmentRepository();
  late Future<List<Appointment>> _appointments;

  @override
  void initState() {
    super.initState();
    AppointmentRepository.changes.addListener(_onAppointmentsChanged);
    _appointments = _repository.getAppointments();
  }

  @override
  void dispose() {
    AppointmentRepository.changes.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  void _onAppointmentsChanged() {
    if (mounted) _refresh();
  }

  Future<void> _refresh() async {
    final future = _repository.getAppointments();
    setState(() => _appointments = future);
    await future;
  }

  Future<void> _openBooking() async {
    final appointment = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingBottomSheetWidget(),
    );
    if (appointment != null && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        title: Text(
          'My Appointments',
          style: theme.headlineSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: FilledButton.icon(
                onPressed: _openBooking,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Book appointment'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: _openBooking,
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book'),
            ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AppointmentsError(onRetry: _refresh);
          }
          final appointments = snapshot.data ?? const [];
          if (appointments.isEmpty) {
            return _AppointmentsEmptyState(onBook: _openBooking);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                12,
                wide ? 24 : 16,
                wide ? 24 : 100,
              ),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _AppointmentCard(
                  appointment: appointment,
                  onTap: () {
                    final reference = SupabaseDatabase.instance
                        .collection('appointments')
                        .doc(appointment.id);
                    context.pushNamed(
                      AppointmentDetailsWidget.routeName,
                      queryParameters: {
                        'encounterDets': serializeParam(
                          reference,
                          ParamType.DocumentReference,
                        ),
                      }.withoutNulls,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusColor = _statusColor(theme, appointment.status);
    final dateTime = Appointment.dateAtTime(
      appointment.date,
      appointment.startTime,
    );
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        focusColor: theme.primary.withValues(alpha: 0.08),
        hoverColor: theme.primary.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: theme.alternate),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(dateTime).toUpperCase(),
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(dateTime),
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 22,
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(appointment.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      appointment.clinicName ?? 'Clinic',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 17,
                          color: theme.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('EEEE, d MMMM').format(dateTime)} • '
                          '${DateFormat.jm().format(dateTime)}',
                          style: theme.bodySmall.copyWith(
                            color: theme.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(FlutterFlowTheme theme, String status) {
    switch (status) {
      case 'confirmed':
      case 'completed':
        return theme.success;
      case 'declined':
      case 'cancelled':
      case 'missed':
        return theme.error;
      case 'rescheduled':
        return theme.primary;
      default:
        return const Color(0xFFB26A00);
    }
  }

  static String _statusLabel(String status) => status.isEmpty
      ? 'Pending'
      : '${status[0].toUpperCase()}${status.substring(1)}';
}

class _AppointmentsEmptyState extends StatelessWidget {
  const _AppointmentsEmptyState({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              Image.asset(
                'assets/images/transparent assets/No_data-pana.png',
                height: 170,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              Text(
                'No upcoming appointments',
                textAlign: TextAlign.center,
                style: theme.titleLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Book an appointment with a clinic or healthcare professional.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Book Appointment'),
                style: FilledButton.styleFrom(backgroundColor: theme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentsError extends StatelessWidget {
  const _AppointmentsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: theme.secondaryText),
            const SizedBox(height: 14),
            Text(
              'Appointments could not be loaded',
              style: theme.titleMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              style: theme.bodyMedium.copyWith(color: theme.secondaryText),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
