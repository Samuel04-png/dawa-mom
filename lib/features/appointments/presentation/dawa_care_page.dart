import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/data/dawa_appointment_reminder_repository.dart';
import '/features/appointments/domain/appointment.dart';
import 'dawa_appointment_reminder_sheet.dart';
import 'dawa_booking_success_dialog.dart';

enum _CareSection { upcoming, clinics, history }

enum _ClinicFilter {
  all,
  nearest,
  earliest,
  cervical,
  antenatal,
  general,
  preferred,
}

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
  final _clinicSearch = TextEditingController();
  final _reminderRepository = DawaAppointmentReminderRepository();
  final _reminderFutures = <String, Future<DawaAppointmentReminder>>{};
  _CareSection _section = _CareSection.upcoming;
  _ClinicFilter _clinicFilter = _ClinicFilter.all;
  String? _cancellingAppointmentId;

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
    _clinicSearch.dispose();
    super.dispose();
  }

  void _onAppointmentsChanged() {
    if (mounted && widget.initialAppointments == null) {
      _refreshAppointments();
    }
  }

  Future<void> _refreshAppointments() async {
    final appointments = _repo.getAppointments();
    setState(() => _appointments = appointments);
    await appointments;
  }

  Future<void> _refresh() async {
    final appointments = widget.initialAppointments == null
        ? _repo.getAppointments()
        : _appointments;
    final clinics =
        widget.initialClinics == null ? _repo.getClinics() : _clinics;
    setState(() {
      _appointments = appointments;
      _clinics = clinics;
    });
    await Future.wait([appointments, clinics]);
  }

  Future<void> _openBooking({String? clinicId}) async {
    final appointment = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingBottomSheetWidget(initialClinicId: clinicId),
    );
    if (appointment == null || !mounted) return;
    if (widget.initialAppointments == null) {
      await _refreshAppointments();
    } else {
      final current = await _appointments;
      if (!mounted) return;
      setState(() => _appointments = Future.value([...current, appointment]));
    }
    if (!mounted) return;
    await showDawaBookingSuccessDialog(context, appointment);
  }

  Future<DawaAppointmentReminder> _reminderFor(String appointmentId) =>
      _reminderFutures.putIfAbsent(
        appointmentId,
        () => _reminderRepository.load(appointmentId),
      );

  Future<void> _openReminder(Appointment appointment) async {
    final reminder = await showModalBottomSheet<DawaAppointmentReminder>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DawaAppointmentReminderSheet(
        appointment: appointment,
        repository: _reminderRepository,
      ),
    );
    if (reminder != null && mounted) {
      setState(
        () => _reminderFutures[appointment.id] = Future.value(reminder),
      );
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    if (_cancellingAppointmentId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'The clinic will be notified and this time will be released. '
          'The visit will remain in your care history.',
        ),
        actions: [
          DawaTextButton(
            label: 'Keep appointment',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          DawaDestructiveButton(
            label: 'Cancel appointment',
            icon: Icons.event_busy_outlined,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancellingAppointmentId = appointment.id);
    try {
      final updated = await _repo.cancelAppointment(appointment.id);
      if (!mounted) return;
      if (widget.initialAppointments == null) {
        await _refreshAppointments();
      } else {
        final current = await _appointments;
        if (!mounted) return;
        setState(
          () => _appointments = Future.value(
            current
                .map((item) => item.id == updated.id ? updated : item)
                .toList(growable: false),
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled.')),
      );
    } on AppointmentException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The appointment could not be cancelled. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancellingAppointmentId = null);
    }
  }

  Future<void> _launchClinicCall(ClinicOption clinic) async {
    final phone = clinic.phone?.trim();
    if (phone == null || phone.isEmpty) return;
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling is unavailable on this device.')),
      );
    }
  }

  Future<void> _launchDirections(ClinicOption clinic) async {
    if (clinic.latitude == null || clinic.longitude == null) return;
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '${clinic.latitude},${clinic.longitude}',
      },
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Directions could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => DawaPageScaffold(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DawaAppHeader(
              title: 'Care',
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/settings'),
            ),
            const SizedBox(height: DawaSpacing.xs),
            Text(
              'Appointments, trusted clinics, and visit history.',
              textAlign: TextAlign.center,
              style: context.dawaCaption,
            ),
            const SizedBox(height: DawaSpacing.md),
            _CareSectionNavigation(
              selected: _section,
              onSelected: (section) => setState(() => _section = section),
            ),
            const SizedBox(height: DawaSpacing.lg),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_section),
                child: switch (_section) {
                  _CareSection.upcoming => _buildUpcoming(),
                  _CareSection.clinics => _buildClinics(),
                  _CareSection.history => _buildHistory(),
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildUpcoming() => FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CareLoadingState(label: 'Loading upcoming care');
          }
          if (snapshot.hasError) {
            return _CareErrorState(
              title: 'Upcoming care could not be loaded',
              onRetry: _refreshAppointments,
            );
          }
          final upcoming = (snapshot.data ?? const <Appointment>[])
              .where((appointment) => appointment.isUpcoming)
              .toList()
            ..sort(
              (a, b) => Appointment.dateAtTime(a.date, a.startTime).compareTo(
                Appointment.dateAtTime(b.date, b.startTime),
              ),
            );
          if (upcoming.isEmpty) {
            return _NoUpcomingAppointment(
              onBook: () => _openBooking(),
              onBrowseClinics: () =>
                  setState(() => _section = _CareSection.clinics),
            );
          }
          final next = upcoming.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionIntroduction(
                eyebrow: 'UPCOMING',
                title: 'Your next visit',
                description:
                    'Everything you need for a calm, prepared clinic visit.',
              ),
              const SizedBox(height: DawaSpacing.sm),
              _UpcomingAppointmentCard(
                appointment: next,
                reminder: _reminderFor(next.id),
                cancelling: _cancellingAppointmentId == next.id,
                onOpen: () => context.push(
                  '/appointmentDetails?appointmentId=${next.id}',
                ),
                onReminder: () => _openReminder(next),
                onCancel: next.canPatientCancel
                    ? () => _cancelAppointment(next)
                    : null,
              ),
              if (upcoming.length > 1) ...[
                const SizedBox(height: DawaSpacing.xl),
                DawaSectionHeader(
                  title: 'Later appointments',
                  subtitle:
                      '${upcoming.length - 1} more scheduled ${upcoming.length == 2 ? 'visit' : 'visits'}.',
                ),
                const SizedBox(height: DawaSpacing.sm),
                ...upcoming.skip(1).map(
                      (appointment) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: DawaSpacing.sm,
                        ),
                        child: _CareHistoryCard(
                          appointment: appointment,
                          actionLabel: 'View appointment',
                          onOpen: () => context.push(
                            '/appointmentDetails?appointmentId=${appointment.id}',
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      );

  Widget _buildClinics() => FutureBuilder<List<ClinicOption>>(
        future: _clinics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CareLoadingState(label: 'Loading clinics');
          }
          if (snapshot.hasError) {
            return _CareErrorState(
              title: 'Clinic information is unavailable',
              onRetry: _refresh,
            );
          }
          final clinics = snapshot.data ?? const <ClinicOption>[];
          if (clinics.isEmpty) {
            return _EmptyClinics(onRetry: _refresh);
          }
          final availableFilters = _availableClinicFilters(clinics);
          final selectedFilter = availableFilters.contains(_clinicFilter)
              ? _clinicFilter
              : _ClinicFilter.all;
          final filtered = _filterClinics(
            clinics,
            selectedFilter,
            _clinicSearch.text,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionIntroduction(
                eyebrow: 'CLINICS',
                title: 'Find care near you',
                description:
                    'Only verified clinic information is shown. Choose a clinic to review details and book.',
              ),
              if (widget.initialClinics == null &&
                  _repo.lastClinicLoadUsedCache) ...[
                const SizedBox(height: DawaSpacing.sm),
                DawaCard(
                  color: DawaColors.warningSurface,
                  borderColor: DawaColors.gold.withValues(alpha: 0.35),
                  padding: const EdgeInsets.all(DawaSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: DawaColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: DawaSpacing.xs),
                      Expanded(
                        child: Text(
                          'Showing saved clinic information'
                          '${_repo.lastClinicCacheAt == null ? '' : ' from ${DateFormat('d MMM, h:mm a').format(_repo.lastClinicCacheAt!.toLocal())}'}. Connect to check live availability.',
                          style: context.dawaCaption.copyWith(
                            color: DawaColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (clinics.length >= 5 || _clinicSearch.text.isNotEmpty) ...[
                const SizedBox(height: DawaSpacing.md),
                DawaFormField(
                  label: 'Search clinics',
                  controller: _clinicSearch,
                  hint: 'Clinic name or location',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (availableFilters.length > 1) ...[
                const SizedBox(height: DawaSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableFilters
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(
                              right: DawaSpacing.xs,
                            ),
                            child: ChoiceChip(
                              label: Text(_clinicFilterLabel(filter)),
                              selected: selectedFilter == filter,
                              onSelected: (_) =>
                                  setState(() => _clinicFilter = filter),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              const SizedBox(height: DawaSpacing.md),
              if (filtered.isEmpty)
                DawaCard(
                  child: Column(
                    children: [
                      const DawaIconBadge(
                        icon: Icons.search_off_rounded,
                        color: DawaColors.primary,
                      ),
                      const SizedBox(height: DawaSpacing.sm),
                      Text(
                        'No clinics match these filters.',
                        textAlign: TextAlign.center,
                        style: context.dawaSectionTitle,
                      ),
                      DawaTextButton(
                        label: 'Clear filters',
                        onPressed: () {
                          _clinicSearch.clear();
                          setState(
                            () => _clinicFilter = _ClinicFilter.all,
                          );
                        },
                      ),
                    ],
                  ),
                )
              else
                DawaResponsiveGrid(
                  mobileColumns:
                      MediaQuery.sizeOf(context).width >= 700 ? 2 : 1,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: DawaSpacing.sm,
                  children: filtered
                      .map(
                        (clinic) => _ClinicCard(
                          clinic: clinic,
                          onView: () => _showClinicDetails(clinic),
                          onBook: () => _openBooking(clinicId: clinic.id),
                          onCall: clinic.phone?.trim().isNotEmpty == true
                              ? () => _launchClinicCall(clinic)
                              : null,
                          onDirections: clinic.latitude != null &&
                                  clinic.longitude != null
                              ? () => _launchDirections(clinic)
                              : null,
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          );
        },
      );

  Widget _buildHistory() => FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CareLoadingState(label: 'Loading care history');
          }
          if (snapshot.hasError) {
            return _CareErrorState(
              title: 'Care history could not be loaded',
              onRetry: _refreshAppointments,
            );
          }
          final history = (snapshot.data ?? const <Appointment>[])
              .where((appointment) => !appointment.isUpcoming)
              .toList()
            ..sort(
              (a, b) => Appointment.dateAtTime(b.date, b.startTime).compareTo(
                Appointment.dateAtTime(a.date, a.startTime),
              ),
            );
          if (history.isEmpty) {
            return _EmptyHistory(onBook: () => _openBooking());
          }
          final groups = _historyGroups(history);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionIntroduction(
                eyebrow: 'HISTORY',
                title: 'Your previous care',
                description:
                    'Patient-safe visit summaries remain here for easy follow-up.',
              ),
              const SizedBox(height: DawaSpacing.md),
              for (final group in groups.entries) ...[
                Semantics(
                  header: true,
                  child: Text(
                    group.key,
                    style: context.dawaCaption.copyWith(
                      color: DawaColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: DawaSpacing.xs),
                ...group.value.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: DawaSpacing.sm),
                    child: _CareHistoryCard(
                      appointment: appointment,
                      actionLabel: appointment.status == 'completed'
                          ? 'View summary'
                          : 'View details',
                      onOpen: () => context.push(
                        '/appointmentDetails?appointmentId=${appointment.id}',
                      ),
                      onBookFollowUp: appointment.status == 'completed'
                          ? () => _openBooking(clinicId: appointment.clinicId)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: DawaSpacing.xs),
              ],
            ],
          );
        },
      );

  Future<void> _showClinicDetails(ClinicOption clinic) async {
    final book = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ClinicDetailsSheet(
        clinic: clinic,
        onCall: clinic.phone?.trim().isNotEmpty == true
            ? () => _launchClinicCall(clinic)
            : null,
        onDirections: clinic.latitude != null && clinic.longitude != null
            ? () => _launchDirections(clinic)
            : null,
      ),
    );
    if (book == true && mounted) {
      await _openBooking(clinicId: clinic.id);
    }
  }
}

class _CareSectionNavigation extends StatelessWidget {
  const _CareSectionNavigation({
    required this.selected,
    required this.onSelected,
  });

  final _CareSection selected;
  final ValueChanged<_CareSection> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: DawaColors.surfaceStrong,
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          border: Border.all(color: DawaColors.line),
        ),
        child: Row(
          children: _CareSection.values
              .map(
                (section) => Expanded(
                  child: Semantics(
                    selected: selected == section,
                    button: true,
                    child: Material(
                      color: selected == section
                          ? DawaColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(DawaRadii.small),
                      child: InkWell(
                        key: ValueKey('care-tab-${section.name}'),
                        onTap: () => onSelected(section),
                        borderRadius: BorderRadius.circular(DawaRadii.small),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              child: Text(
                                _sectionLabel(section),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: context.dawaCaption.copyWith(
                                  color: selected == section
                                      ? Colors.white
                                      : DawaColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      );

  static String _sectionLabel(_CareSection section) => switch (section) {
        _CareSection.upcoming => 'Upcoming',
        _CareSection.clinics => 'Clinics',
        _CareSection.history => 'History',
      };
}

class _SectionIntroduction extends StatelessWidget {
  const _SectionIntroduction({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: context.dawaCaption.copyWith(
              color: DawaColors.greenDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: DawaSpacing.xxs),
          Semantics(
            header: true,
            child: Text(title, style: context.dawaTitle),
          ),
          const SizedBox(height: DawaSpacing.xxs),
          Text(description, style: context.dawaCaption),
        ],
      );
}

class _NoUpcomingAppointment extends StatelessWidget {
  const _NoUpcomingAppointment({
    required this.onBook,
    required this.onBrowseClinics,
  });

  final VoidCallback onBook;
  final VoidCallback onBrowseClinics;

  @override
  Widget build(BuildContext context) => DawaCard(
        featured: true,
        padding: const EdgeInsets.all(DawaSpacing.lg),
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: 0.2),
        child: Column(
          children: [
            SizedBox(
              width: 220,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: DawaContextualImage(
                  assetId: 'clinic_visit_02',
                  variant: DawaImageVariant.moduleThumbnail,
                  borderRadius: BorderRadius.circular(DawaRadii.medium),
                ),
              ),
            ),
            const SizedBox(height: DawaSpacing.md),
            Text(
              'No upcoming appointments',
              textAlign: TextAlign.center,
              style: context.dawaTitle,
            ),
            const SizedBox(height: DawaSpacing.xs),
            Text(
              'When you are ready, choose a clinic, health worker, date, and time that suit you.',
              textAlign: TextAlign.center,
              style: context.dawaBody,
            ),
            const SizedBox(height: DawaSpacing.md),
            DawaPrimaryButton(
              label: 'Book appointment',
              icon: Icons.add_circle_outline_rounded,
              onPressed: onBook,
            ),
            DawaTextButton(
              label: 'Browse clinics',
              icon: Icons.local_hospital_outlined,
              onPressed: onBrowseClinics,
            ),
          ],
        ),
      );
}

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({
    required this.appointment,
    required this.reminder,
    required this.cancelling,
    required this.onOpen,
    required this.onReminder,
    required this.onCancel,
  });

  final Appointment appointment;
  final Future<DawaAppointmentReminder> reminder;
  final bool cancelling;
  final VoidCallback onOpen;
  final VoidCallback onReminder;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final start =
        Appointment.dateAtTime(appointment.date, appointment.startTime);
    final clinician = appointment.clinicianName?.trim();
    final preparationCompleted = _preparationCompleted(appointment);
    return DawaCard(
      featured: true,
      color: DawaColors.softBlue,
      borderColor: DawaColors.primary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 96,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DawaContextualImage(
                    assetId: 'clinic_visit_01',
                    variant: DawaImageVariant.moduleThumbnail,
                  ),
                ),
              ),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DawaStatusPill(
                      label: _statusLabel(appointment.status),
                      icon: _statusIcon(appointment.status),
                      color: _statusColor(appointment.status),
                    ),
                    const SizedBox(height: DawaSpacing.xs),
                    Text(
                      _appointmentType(appointment.appointmentType),
                      style: context.dawaSectionTitle,
                    ),
                    if (appointment.clinicName?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: DawaSpacing.xxs),
                      Text(
                        appointment.clinicName!.trim(),
                        style: context.dawaCaption.copyWith(
                          color: DawaColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DawaSpacing.md),
          DawaPrimaryButton(
            label: 'View appointment',
            icon: Icons.arrow_forward_rounded,
            onPressed: onOpen,
          ),
          const SizedBox(height: DawaSpacing.md),
          _VisitFact(
            icon: Icons.calendar_month_outlined,
            label: DateFormat('EEEE, d MMMM y').format(start),
          ),
          _VisitFact(
            icon: Icons.schedule_rounded,
            label: DateFormat('h:mm a').format(start),
          ),
          if (clinician != null && clinician.isNotEmpty)
            _VisitFact(
              icon: Icons.medical_services_outlined,
              label: clinician,
            ),
          if (appointment.clinicAddress?.trim().isNotEmpty == true)
            _VisitFact(
              icon: Icons.location_on_outlined,
              label: appointment.clinicAddress!.trim(),
            ),
          FutureBuilder<DawaAppointmentReminder>(
            future: reminder,
            builder: (context, snapshot) {
              final value = snapshot.data;
              if (value == null) return const SizedBox.shrink();
              final channels = <String>[
                if (value.appNotification) 'app',
                if (value.smsNotification) 'SMS',
                if (value.emailNotification) 'email',
              ];
              return _VisitFact(
                icon: Icons.notifications_active_outlined,
                label: value.enabled
                    ? 'Reminder: ${value.daysBefore == 0 ? 'on the day' : '${value.daysBefore} ${value.daysBefore == 1 ? 'day' : 'days'} before'}'
                        '${channels.isEmpty ? '' : ' • ${channels.join(', ')}'}'
                    : 'Reminder is off',
              );
            },
          ),
          const SizedBox(height: DawaSpacing.md),
          Container(
            padding: const EdgeInsets.all(DawaSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(DawaRadii.small),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Visit preparation',
                        style: context.dawaSectionTitle,
                      ),
                    ),
                    Text(
                      '$preparationCompleted of 5',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
                const SizedBox(height: DawaSpacing.xs),
                DawaProgressBar(
                  value: preparationCompleted / 5,
                  semanticLabel:
                      'Visit preparation, $preparationCompleted of 5 steps complete',
                  color: DawaColors.green,
                ),
                const SizedBox(height: DawaSpacing.xs),
                Text(
                  'Review your questions, medicines, important dates, and requested records.',
                  style: context.dawaCaption,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DawaTextButton(
                    label: 'Continue preparation',
                    icon: Icons.fact_check_outlined,
                    onPressed: onOpen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.md),
          Wrap(
            spacing: DawaSpacing.xs,
            runSpacing: DawaSpacing.xs,
            alignment: WrapAlignment.center,
            children: [
              DawaCompactButton(
                label: 'Set reminder',
                icon: Icons.notifications_active_outlined,
                onPressed: onReminder,
              ),
              if (onCancel != null)
                DawaDestructiveButton(
                  label: 'Cancel',
                  icon: Icons.event_busy_outlined,
                  busy: cancelling,
                  onPressed: onCancel,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitFact extends StatelessWidget {
  const _VisitFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: DawaSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: DawaColors.primary),
            const SizedBox(width: DawaSpacing.xs),
            Expanded(child: Text(label, style: context.dawaBody)),
          ],
        ),
      );
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({
    required this.clinic,
    required this.onView,
    required this.onBook,
    required this.onCall,
    required this.onDirections,
  });

  final ClinicOption clinic;
  final VoidCallback onView;
  final VoidCallback onBook;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 96,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DawaContextualImage(
                      assetId: 'clinic_visit_02',
                      variant: DawaImageVariant.moduleThumbnail,
                    ),
                  ),
                ),
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clinic.name, style: context.dawaSectionTitle),
                      if (clinic.address?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: DawaSpacing.xxs),
                        Text(
                          clinic.address!.trim(),
                          style: context.dawaCaption,
                        ),
                      ],
                      const SizedBox(height: DawaSpacing.xs),
                      Wrap(
                        spacing: DawaSpacing.xs,
                        runSpacing: DawaSpacing.xxs,
                        children: [
                          if (clinic.distanceKm != null)
                            _ClinicMeta(
                              icon: Icons.near_me_outlined,
                              label:
                                  '${clinic.distanceKm!.toStringAsFixed(1)} km',
                            ),
                          if (clinic.isOpen != null)
                            _ClinicMeta(
                              icon: clinic.isOpen!
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.schedule_rounded,
                              label: clinic.isOpen! ? 'Open now' : 'Closed',
                            ),
                          if (clinic.isPreferred == true)
                            const _ClinicMeta(
                              icon: Icons.star_rounded,
                              label: 'Preferred',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (clinic.services.isNotEmpty) ...[
              const SizedBox(height: DawaSpacing.sm),
              Wrap(
                spacing: DawaSpacing.xs,
                runSpacing: DawaSpacing.xs,
                children: clinic.services
                    .take(3)
                    .map((service) => Chip(label: Text(service)))
                    .toList(growable: false),
              ),
            ],
            if (clinic.nextAvailableAt != null ||
                clinic.openingHours?.trim().isNotEmpty == true) ...[
              const SizedBox(height: DawaSpacing.sm),
              if (clinic.nextAvailableAt != null)
                Text(
                  'Next available ${DateFormat('EEE, d MMM • h:mm a').format(clinic.nextAvailableAt!)}',
                  style: context.dawaCaption.copyWith(
                    color: DawaColors.greenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (clinic.openingHours?.trim().isNotEmpty == true)
                Text(
                  clinic.openingHours!.trim(),
                  style: context.dawaCaption,
                ),
            ],
            const SizedBox(height: DawaSpacing.md),
            Wrap(
              spacing: DawaSpacing.xs,
              runSpacing: DawaSpacing.xs,
              children: [
                DawaCompactButton(
                  label: 'View clinic',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onView,
                ),
                DawaCompactButton(
                  label: 'Book',
                  icon: Icons.add_circle_outline_rounded,
                  filled: true,
                  onPressed: onBook,
                ),
                if (onCall != null)
                  DawaIconButton(
                    icon: Icons.call_outlined,
                    tooltip: 'Call ${clinic.name}',
                    onPressed: onCall,
                  ),
                if (onDirections != null)
                  DawaIconButton(
                    icon: Icons.directions_outlined,
                    tooltip: 'Directions to ${clinic.name}',
                    onPressed: onDirections,
                  ),
              ],
            ),
          ],
        ),
      );
}

class _ClinicMeta extends StatelessWidget {
  const _ClinicMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: DawaColors.greenDark),
          const SizedBox(width: 4),
          Text(label, style: context.dawaCaption),
        ],
      );
}

class _ClinicDetailsSheet extends StatelessWidget {
  const _ClinicDetailsSheet({
    required this.clinic,
    required this.onCall,
    required this.onDirections,
  });

  final ClinicOption clinic;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: DawaColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DawaRadii.large),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DawaSpacing.lg,
              DawaSpacing.sm,
              DawaSpacing.lg,
              DawaSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DawaColors.borderStrong,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: DawaSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DawaIconBadge(
                      icon: Icons.local_hospital_outlined,
                      color: DawaColors.green,
                    ),
                    const SizedBox(width: DawaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clinic.name, style: context.dawaTitle),
                          if (clinic.address?.trim().isNotEmpty == true)
                            Text(
                              clinic.address!.trim(),
                              style: context.dawaBody,
                            ),
                        ],
                      ),
                    ),
                    DawaIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close clinic details',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (clinic.services.isNotEmpty) ...[
                  const SizedBox(height: DawaSpacing.lg),
                  Text('Services', style: context.dawaSectionTitle),
                  const SizedBox(height: DawaSpacing.xs),
                  Wrap(
                    spacing: DawaSpacing.xs,
                    runSpacing: DawaSpacing.xs,
                    children: clinic.services
                        .map((service) => Chip(label: Text(service)))
                        .toList(growable: false),
                  ),
                ],
                if (clinic.openingHours?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: DawaSpacing.md),
                  _VisitFact(
                    icon: Icons.schedule_outlined,
                    label: clinic.openingHours!.trim(),
                  ),
                ],
                if (clinic.languages.isNotEmpty)
                  _VisitFact(
                    icon: Icons.translate_rounded,
                    label: clinic.languages.join(', '),
                  ),
                if (clinic.accessibility.isNotEmpty)
                  _VisitFact(
                    icon: Icons.accessible_rounded,
                    label: clinic.accessibility.join(', '),
                  ),
                const SizedBox(height: DawaSpacing.md),
                DawaPrimaryButton(
                  label: 'Book at this clinic',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () => Navigator.pop(context, true),
                ),
                if (onCall != null || onDirections != null) ...[
                  const SizedBox(height: DawaSpacing.xs),
                  Wrap(
                    spacing: DawaSpacing.xs,
                    runSpacing: DawaSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onCall != null)
                        DawaCompactButton(
                          label: 'Call clinic',
                          icon: Icons.call_outlined,
                          onPressed: onCall,
                        ),
                      if (onDirections != null)
                        DawaCompactButton(
                          label: 'Directions',
                          icon: Icons.directions_outlined,
                          onPressed: onDirections,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _CareHistoryCard extends StatelessWidget {
  const _CareHistoryCard({
    required this.appointment,
    required this.actionLabel,
    required this.onOpen,
    this.onBookFollowUp,
  });

  final Appointment appointment;
  final String actionLabel;
  final VoidCallback onOpen;
  final VoidCallback? onBookFollowUp;

  @override
  Widget build(BuildContext context) {
    final start =
        Appointment.dateAtTime(appointment.date, appointment.startTime);
    return DawaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DawaIconBadge(
                icon: _statusIcon(appointment.status),
                color: _statusColor(appointment.status),
              ),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.clinicName?.trim().isNotEmpty == true
                          ? appointment.clinicName!.trim()
                          : _appointmentType(appointment.appointmentType),
                      style: context.dawaSectionTitle,
                    ),
                    const SizedBox(height: DawaSpacing.xxs),
                    Text(
                      '${DateFormat('d MMM y • h:mm a').format(start)}'
                      '${appointment.clinicianName?.trim().isNotEmpty == true ? '\n${appointment.clinicianName!.trim()}' : ''}',
                      style: context.dawaCaption,
                    ),
                  ],
                ),
              ),
              DawaStatusPill(
                label: _statusLabel(appointment.status),
                icon: _statusIcon(appointment.status),
                color: _statusColor(appointment.status),
              ),
            ],
          ),
          if (appointment.status == 'completed') ...[
            const SizedBox(height: DawaSpacing.sm),
            Text(
              'Your patient-safe visit summary and any follow-up guidance are available in appointment details.',
              style: context.dawaCaption,
            ),
          ],
          const SizedBox(height: DawaSpacing.sm),
          Wrap(
            spacing: DawaSpacing.xs,
            runSpacing: DawaSpacing.xs,
            children: [
              DawaCompactButton(
                label: actionLabel,
                icon: Icons.arrow_forward_rounded,
                filled: true,
                onPressed: onOpen,
              ),
              if (onBookFollowUp != null)
                DawaCompactButton(
                  label: 'Book follow-up',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: onBookFollowUp,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyClinics extends StatelessWidget {
  const _EmptyClinics({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          children: [
            const DawaIconBadge(
              icon: Icons.local_hospital_outlined,
              color: DawaColors.green,
              size: 58,
            ),
            const SizedBox(height: DawaSpacing.sm),
            Text(
              'No booking clinics are available',
              textAlign: TextAlign.center,
              style: context.dawaSectionTitle,
            ),
            const SizedBox(height: DawaSpacing.xs),
            Text(
              'Clinic availability may be temporarily offline. Refresh to check again.',
              textAlign: TextAlign.center,
              style: context.dawaCaption,
            ),
            DawaTextButton(
              label: 'Refresh clinics',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => DawaCard(
        featured: true,
        color: DawaColors.softGreen,
        borderColor: DawaColors.green.withValues(alpha: 0.2),
        child: Column(
          children: [
            SizedBox(
              width: 200,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: DawaContextualImage(
                  assetId: 'clinic_visit_05',
                  variant: DawaImageVariant.moduleThumbnail,
                  borderRadius: BorderRadius.circular(DawaRadii.medium),
                ),
              ),
            ),
            const SizedBox(height: DawaSpacing.md),
            Text(
              'No previous visits yet',
              textAlign: TextAlign.center,
              style: context.dawaTitle,
            ),
            const SizedBox(height: DawaSpacing.xs),
            Text(
              'Completed and cancelled appointments will remain here without exposing internal clinical notes.',
              textAlign: TextAlign.center,
              style: context.dawaBody,
            ),
            const SizedBox(height: DawaSpacing.md),
            DawaPrimaryButton(
              label: 'Book appointment',
              icon: Icons.add_circle_outline_rounded,
              onPressed: onBook,
            ),
          ],
        ),
      );
}

class _CareLoadingState extends StatelessWidget {
  const _CareLoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DawaLoadingSkeleton(label: label, lines: 3),
          const SizedBox(height: DawaSpacing.sm),
          const DawaLoadingSkeleton(lines: 2),
        ],
      );
}

class _CareErrorState extends StatelessWidget {
  const _CareErrorState({
    required this.title,
    required this.onRetry,
  });

  final String title;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: DawaColors.dangerSurface,
        borderColor: DawaColors.danger.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DawaIconBadge(
              icon: Icons.cloud_off_outlined,
              color: DawaColors.danger,
            ),
            const SizedBox(height: DawaSpacing.sm),
            Text(title, style: context.dawaSectionTitle),
            const SizedBox(height: DawaSpacing.xs),
            Text(
              'Check your connection. If you were recently online, your confirmed appointment may still be available in notifications.',
              style: context.dawaCaption,
            ),
            const SizedBox(height: DawaSpacing.sm),
            DawaOutlinedButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      );
}

List<_ClinicFilter> _availableClinicFilters(List<ClinicOption> clinics) {
  final filters = <_ClinicFilter>[_ClinicFilter.all];
  if (clinics.where((clinic) => clinic.distanceKm != null).length > 1) {
    filters.add(_ClinicFilter.nearest);
  }
  if (clinics.where((clinic) => clinic.nextAvailableAt != null).length > 1) {
    filters.add(_ClinicFilter.earliest);
  }
  bool offers(String term) => clinics.any(
        (clinic) => clinic.services.any(
          (service) => service.toLowerCase().contains(term),
        ),
      );
  if (offers('cervical')) filters.add(_ClinicFilter.cervical);
  if (offers('antenatal')) filters.add(_ClinicFilter.antenatal);
  if (offers('general')) filters.add(_ClinicFilter.general);
  if (clinics.any((clinic) => clinic.isPreferred == true)) {
    filters.add(_ClinicFilter.preferred);
  }
  return filters;
}

List<ClinicOption> _filterClinics(
  List<ClinicOption> clinics,
  _ClinicFilter filter,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  final result = clinics.where((clinic) {
    final matchesQuery = normalized.isEmpty ||
        clinic.name.toLowerCase().contains(normalized) ||
        (clinic.address?.toLowerCase().contains(normalized) ?? false);
    if (!matchesQuery) return false;
    return switch (filter) {
      _ClinicFilter.cervical => clinic.services.any(
          (service) => service.toLowerCase().contains('cervical'),
        ),
      _ClinicFilter.antenatal => clinic.services.any(
          (service) => service.toLowerCase().contains('antenatal'),
        ),
      _ClinicFilter.general => clinic.services.any(
          (service) => service.toLowerCase().contains('general'),
        ),
      _ClinicFilter.preferred => clinic.isPreferred == true,
      _ => true,
    };
  }).toList(growable: true);
  if (filter == _ClinicFilter.nearest) {
    result.sort(
      (a, b) => (a.distanceKm ?? double.infinity)
          .compareTo(b.distanceKm ?? double.infinity),
    );
  } else if (filter == _ClinicFilter.earliest) {
    result.sort(
      (a, b) => (a.nextAvailableAt ??
              DateTime.fromMillisecondsSinceEpoch(8640000000000000))
          .compareTo(
        b.nextAvailableAt ??
            DateTime.fromMillisecondsSinceEpoch(8640000000000000),
      ),
    );
  } else {
    result.sort((a, b) => a.name.compareTo(b.name));
  }
  return result;
}

Map<String, List<Appointment>> _historyGroups(
  List<Appointment> appointments,
) {
  final now = DateTime.now();
  final result = <String, List<Appointment>>{};
  for (final appointment in appointments) {
    final start =
        Appointment.dateAtTime(appointment.date, appointment.startTime);
    final label = start.year == now.year && start.month == now.month
        ? 'This month'
        : start.year == now.year
            ? 'Earlier'
            : start.year.toString();
    result.putIfAbsent(label, () => <Appointment>[]).add(appointment);
  }
  return result;
}

int _preparationCompleted(Appointment appointment) {
  var completed = 0;
  if (const {'confirmed', 'rescheduled'}.contains(appointment.status)) {
    completed++;
  }
  if (appointment.clinicName?.trim().isNotEmpty == true) completed++;
  if (appointment.clinicianName?.trim().isNotEmpty == true) completed++;
  if (appointment.reason?.trim().isNotEmpty == true) completed++;
  return completed.clamp(0, 5);
}

String _clinicFilterLabel(_ClinicFilter filter) => switch (filter) {
      _ClinicFilter.all => 'All clinics',
      _ClinicFilter.nearest => 'Nearest',
      _ClinicFilter.earliest => 'Earliest',
      _ClinicFilter.cervical => 'Cervical',
      _ClinicFilter.antenatal => 'Antenatal',
      _ClinicFilter.general => 'General',
      _ClinicFilter.preferred => 'Preferred',
    };

String _appointmentType(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _statusLabel(String value) {
  if (value.trim().isEmpty) return 'Pending';
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

IconData _statusIcon(String value) => switch (value) {
      'completed' => Icons.check_circle_outline_rounded,
      'cancelled' || 'declined' => Icons.cancel_outlined,
      'confirmed' => Icons.verified_outlined,
      'missed' => Icons.event_busy_outlined,
      _ => Icons.schedule_rounded,
    };

Color _statusColor(String value) => switch (value) {
      'completed' || 'confirmed' => DawaColors.green,
      'cancelled' || 'declined' || 'missed' => DawaColors.danger,
      'rescheduled' => DawaColors.purple,
      _ => DawaColors.primary,
    };
