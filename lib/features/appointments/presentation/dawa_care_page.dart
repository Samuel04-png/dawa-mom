import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/components/responsive/dawa_mom_responsive_shell.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import 'dawa_appointment_reminder_sheet.dart';
import 'dawa_booking_success_dialog.dart';

class DawaCarePage extends StatefulWidget {
  const DawaCarePage({
    super.key,
    this.repository,
    this.initialAppointments,
    this.initialClinics,
  });

  final AppointmentRepository? repository;
  final List<Appointment>? initialAppointments;
  final List<ClinicOption>? initialClinics;

  @override
  State<DawaCarePage> createState() => _DawaCarePageState();
}

class _DawaCarePageState extends State<DawaCarePage> {
  AppointmentRepository? _repository;
  late Future<List<Appointment>> _appointments;
  late Future<List<ClinicOption>> _clinics;

  AppointmentRepository get _repo =>
      _repository ??= widget.repository ?? AppointmentRepository();

  @override
  void initState() {
    super.initState();
    AppointmentRepository.changes.addListener(_onAppointmentsChanged);
    _appointments = widget.initialAppointments != null
        ? Future.value(widget.initialAppointments)
        : _repo.getAppointments();
    _clinics = widget.initialClinics != null
        ? Future.value(widget.initialClinics)
        : _repo.getClinics();
  }

  @override
  void dispose() {
    AppointmentRepository.changes.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  void _onAppointmentsChanged() {
    if (mounted && widget.initialAppointments == null) _refresh();
  }

  Future<void> _refresh() async {
    final appointments = _repo.getAppointments();
    final clinics = _repo.getClinics();
    setState(() {
      _appointments = appointments;
      _clinics = clinics;
    });
    await Future.wait([appointments, clinics]);
  }

  Future<void> _openBooking() async {
    final appointment = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingBottomSheetWidget(),
    );
    if (appointment == null || !mounted) return;
    if (widget.initialAppointments == null) await _refresh();
    if (!mounted) return;
    await showDawaBookingSuccessDialog(context, appointment);
  }

  Future<void> _openReminder(Appointment? appointment) async {
    if (appointment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book an appointment before setting a reminder.'),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DawaAppointmentReminderSheet(
        appointment: appointment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, appointmentSnapshot) {
          final appointments = appointmentSnapshot.data ?? const [];
          final upcoming = appointments
              .where((item) => item.isUpcoming)
              .toList()
            ..sort(
              (a, b) => Appointment.dateAtTime(a.date, a.startTime).compareTo(
                Appointment.dateAtTime(b.date, b.startTime),
              ),
            );
          final next = upcoming.firstOrNull;
          return DawaPageScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DawaAppHeader(
                  title: 'Care',
                  onNotifications: () => context.push('/notifications'),
                  onProfile: () => context.go('/settings'),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    'Your care',
                    textAlign: TextAlign.center,
                    style: context.dawaTitle.copyWith(fontSize: 25),
                  ),
                ),
                const SizedBox(height: 3),
                Center(
                  child: Text(
                    'We’re here for you, every step of the way.',
                    textAlign: TextAlign.center,
                    style: context.dawaBody,
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: DawaColors.green,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (appointmentSnapshot.connectionState ==
                    ConnectionState.waiting)
                  const _CareLoadingCard()
                else if (appointmentSnapshot.hasError)
                  _CareErrorCard(onRetry: _refresh)
                else
                  _NextAppointmentCard(
                    appointment: next,
                    onBook: _openBooking,
                    onOpen: next == null
                        ? null
                        : () => context.push(
                              '/appointmentDetails?appointmentId=${next.id}',
                            ),
                  ),
                if (next != null) ...[
                  const SizedBox(height: 10),
                  _CareClinicianCard(appointment: next),
                ],
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    'Quick actions',
                    style: context.dawaCaption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DawaResponsiveGrid(
                  mobileColumns: 4,
                  tabletColumns: 4,
                  desktopColumns: 4,
                  spacing: 7,
                  children: [
                    _CareAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Book\nappointment',
                      color: DawaColors.primary,
                      onTap: _openBooking,
                    ),
                    _CareAction(
                      icon: Icons.local_hospital_outlined,
                      label: 'Find a\nclinic',
                      color: DawaColors.green,
                      onTap: () => _scrollToClinics(context),
                    ),
                    _CareAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Ask\nRudo',
                      color: DawaColors.purple,
                      onTap: () => DawaMomResponsiveShell.openRudo(context),
                    ),
                    _CareAction(
                      icon: Icons.notifications_active_outlined,
                      label: 'My\nreminders',
                      color: DawaColors.gold,
                      onTap: () => _openReminder(next),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: const ValueKey('care-clinics'),
                  child: DawaSectionHeader(
                    title: 'Nearby clinics',
                    subtitle: 'Clinics currently available for booking.',
                    actionLabel: 'View all',
                    onAction: () => _scrollToClinics(context),
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<ClinicOption>>(
                  future: _clinics,
                  builder: (context, clinicSnapshot) {
                    if (clinicSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LinearProgressIndicator(minHeight: 3);
                    }
                    if (clinicSnapshot.hasError) {
                      return DawaCard(
                        child: Text(
                          'Clinic information is unavailable right now. Pull to refresh and try again.',
                          style: context.dawaBody,
                        ),
                      );
                    }
                    final clinics = clinicSnapshot.data ?? const [];
                    if (clinics.isEmpty) {
                      return DawaCard(
                        child: Text(
                          'No booking clinics are available right now.',
                          style: context.dawaBody,
                        ),
                      );
                    }
                    return DawaResponsiveGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 2,
                      children: clinics
                          .take(4)
                          .map((clinic) => _ClinicCard(clinic: clinic))
                          .toList(),
                    );
                  },
                ),
                if (next != null) ...[
                  const SizedBox(height: 14),
                  _CareReminderCard(
                    appointment: next,
                    onTap: () => _openReminder(next),
                  ),
                ],
                const SizedBox(height: 20),
                DawaSectionHeader(
                  title: 'My appointments',
                  subtitle: appointments.isEmpty
                      ? 'No appointments booked yet.'
                      : '${appointments.length} saved in your care history.',
                ),
                const SizedBox(height: 10),
                if (appointments.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: DawaCard(
                      child: Row(
                        children: [
                          const DawaIconBadge(
                            icon: Icons.calendar_month_outlined,
                            color: DawaColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'When you book, your appointment details and status will appear here.',
                              style: context.dawaBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...appointments.take(3).map(
                        (appointment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CompactAppointmentCard(
                            appointment: appointment,
                            onTap: () => context.push(
                              '/appointmentDetails?appointmentId=${appointment.id}',
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      );

  void _scrollToClinics(BuildContext context) {
    final target = _findClinicsContext(context);
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  BuildContext? _findClinicsContext(BuildContext root) {
    BuildContext? result;
    void visitor(Element element) {
      if (result != null) return;
      if (element.widget.key == const ValueKey('care-clinics')) {
        result = element;
        return;
      }
      element.visitChildElements(visitor);
    }

    (root as Element).visitChildElements(visitor);
    return result;
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.appointment,
    required this.onBook,
    required this.onOpen,
  });

  final Appointment? appointment;
  final VoidCallback onBook;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final appointment = this.appointment;
    final start = appointment == null
        ? null
        : Appointment.dateAtTime(appointment.date, appointment.startTime);
    return SizedBox(
      width: double.infinity,
      child: DawaCard(
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: 0.12),
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
        onTap: onOpen ?? onBook,
        semanticLabel: appointment == null
            ? 'Book your first appointment'
            : 'Open upcoming appointment details',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DawaStatusPill(
                  label: 'Next appointment',
                  icon: Icons.calendar_month_rounded,
                  color: DawaColors.primary,
                ),
                const SizedBox(height: 9),
                Text(
                  appointment?.clinicianName ?? 'Plan your next care visit',
                  style: context.dawaSectionTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  start == null
                      ? 'Choose a clinic, clinician, date and live available time.'
                      : DateFormat('EEEE, d MMMM • h:mm a').format(start),
                  style: context.dawaBody,
                ),
                if (appointment?.clinicName != null) ...[
                  const SizedBox(height: 3),
                  Text(appointment!.clinicName!, style: context.dawaCaption),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: appointment == null ? onBook : onOpen,
                  icon: Icon(
                    appointment == null
                        ? Icons.add_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    appointment == null ? 'Book appointment' : 'View details',
                  ),
                ),
              ],
            );
            final artwork = SizedBox(
              width: constraints.maxWidth < 470 ? 100 : 152,
              height: 132,
              child: Image.asset(
                DawaArtwork.cycleCalendar,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            );
            if (constraints.maxWidth < 300) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [artwork, details],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                artwork,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CareAction extends StatelessWidget {
  const _CareAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DawaCard(
        onTap: onTap,
        semanticLabel: label.replaceAll('\n', ' '),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DawaIconBadge(icon: icon, color: color, size: 37),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.dawaCaption.copyWith(
                color: DawaColors.ink,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _CareClinicianCard extends StatelessWidget {
  const _CareClinicianCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final role = [
      appointment.clinicianTitle,
      appointment.clinicianSpeciality,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • ');
    return SizedBox(
      width: double.infinity,
      child: DawaCard(
        padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
        child: Row(
          children: [
            Container(
              width: 67,
              height: 67,
              decoration: BoxDecoration(
                color: DawaColors.softBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: DawaShadows.card,
              ),
              child: ClipOval(
                child: Image.asset(
                  DawaArtwork.clinicianDoctor,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.clinicianName ?? 'Your clinician',
                    style: context.dawaSectionTitle,
                  ),
                  if (role.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(role, style: context.dawaCaption),
                  ],
                  const SizedBox(height: 5),
                  const DawaStatusPill(
                    label: 'Your care team',
                    icon: Icons.verified_user_outlined,
                    color: DawaColors.green,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ask Rudo about your appointment',
              onPressed: () => DawaMomResponsiveShell.openRudo(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              color: DawaColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CareReminderCard extends StatelessWidget {
  const _CareReminderCard({
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start =
        Appointment.dateAtTime(appointment.date, appointment.startTime);
    final appointmentName = appointment.appointmentType
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return SizedBox(
      width: double.infinity,
      child: DawaCard(
        color: DawaColors.softGreen,
        borderColor: DawaColors.green.withValues(alpha: .22),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            const DawaIconBadge(
              icon: Icons.notifications_active_outlined,
              color: DawaColors.green,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appointment reminder', style: context.dawaCaption),
                  Text(
                    appointmentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.dawaSectionTitle,
                  ),
                  Text(
                    DateFormat('EEE, d MMM • h:mm a').format(start),
                    style: context.dawaCaption,
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 40),
                foregroundColor: DawaColors.green,
                side: const BorderSide(color: DawaColors.green),
              ),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAppointmentCard extends StatelessWidget {
  const _CompactAppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = Appointment.dateAtTime(
      appointment.date,
      appointment.startTime,
    );
    return DawaCard(
      onTap: onTap,
      semanticLabel: 'Appointment at ${appointment.clinicName ?? 'clinic'}',
      child: Row(
        children: [
          DawaIconBadge(
            icon: appointment.status == 'completed'
                ? Icons.check_circle_outline_rounded
                : Icons.calendar_today_outlined,
            color: appointment.status == 'completed'
                ? DawaColors.green
                : DawaColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.clinicName ?? 'Clinic appointment',
                  style: context.dawaSectionTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM y • h:mm a').format(start),
                  style: context.dawaCaption,
                ),
              ],
            ),
          ),
          DawaStatusPill(
            label: _label(appointment.status),
            icon: appointment.status == 'completed'
                ? Icons.check_rounded
                : appointment.status == 'cancelled'
                    ? Icons.close_rounded
                    : Icons.schedule_rounded,
            color: appointment.status == 'completed'
                ? DawaColors.green
                : appointment.status == 'cancelled'
                    ? DawaColors.pink
                    : DawaColors.primary,
          ),
        ],
      ),
    );
  }

  String _label(String value) => value.isEmpty
      ? 'Pending'
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic});

  final ClinicOption clinic;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Row(
          children: [
            const DawaIconBadge(
              icon: Icons.local_hospital_outlined,
              color: DawaColors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clinic.name, style: context.dawaSectionTitle),
                  if (clinic.address?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(clinic.address!.trim(), style: context.dawaCaption),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _CareLoadingCard extends StatelessWidget {
  const _CareLoadingCard();

  @override
  Widget build(BuildContext context) => const DawaCard(
        child: SizedBox(
          height: 130,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _CareErrorCard extends StatelessWidget {
  const _CareErrorCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: DawaColors.pink.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Care information could not be loaded.',
                style: context.dawaSectionTitle),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: context.dawaBody,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
}
