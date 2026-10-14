import 'dart:async';

import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_interactions.dart';
import '/design_system/dawa_page_scaffold.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/data/dawa_appointment_reminder_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/care_plan/data/dawa_care_plan_repository.dart';
import '/features/care_plan/domain/dawa_care_item.dart';
import '/features/feedback/dawa_feedback_effects.dart';
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
    this.carePlanRepository,
    this.initialAppointments,
    this.initialClinics,
    this.initialCareItems,
    this.initialSectionIndex = 0,
  });

  final AppointmentRepository? repository;
  final DawaCarePlanRepository? carePlanRepository;
  final List<Appointment>? initialAppointments;
  final List<ClinicOption>? initialClinics;
  final List<DawaCareItem>? initialCareItems;
  final int initialSectionIndex;

  @override
  State<DawaCarePage> createState() => _DawaCarePageState();
}

class _DawaCarePageState extends State<DawaCarePage> {
  AppointmentRepository? _repository;
  DawaCarePlanRepository? _carePlanRepository;
  late Future<List<Appointment>> _appointments;
  late Future<List<ClinicOption>> _clinics;
  late Future<DawaCarePlanSnapshot> _carePlan;
  final _clinicSearch = TextEditingController();
  final _reminderRepository = DawaAppointmentReminderRepository();
  final _reminderFutures = <String, Future<DawaAppointmentReminder>>{};
  late _CareSection _section;
  _ClinicFilter _clinicFilter = _ClinicFilter.all;
  String? _cancellingAppointmentId;
  final _knownAppointmentStatuses = <String, String>{};
  String? _statusFeedbackTitle;
  String? _statusFeedbackMessage;
  DawaFeedbackTone _statusFeedbackTone = DawaFeedbackTone.information;

  AppointmentRepository get _repo =>
      _repository ??= widget.repository ?? AppointmentRepository();
  DawaCarePlanRepository get _carePlanRepo => _carePlanRepository ??=
      widget.carePlanRepository ?? DawaCarePlanRepository();

  @override
  void initState() {
    super.initState();
    _section = _CareSection.values[widget.initialSectionIndex
        .clamp(0, _CareSection.values.length - 1)
        .toInt()];
    AppointmentRepository.changes.addListener(_onAppointmentsChanged);
    DawaCarePlanRepository.changes.addListener(_onCarePlanChanged);
    _appointments = widget.initialAppointments != null
        ? Future.value(widget.initialAppointments)
        : _repo.getAppointments();
    _clinics = widget.initialClinics != null
        ? Future.value(widget.initialClinics)
        : _repo.getClinics();
    _carePlan = widget.initialCareItems != null
        ? Future.value(
            DawaCarePlanSnapshot(
              items: widget.initialCareItems!,
              isCached: false,
            ),
          )
        : widget.initialAppointments != null &&
                widget.carePlanRepository == null
            ? Future.value(
                const DawaCarePlanSnapshot(items: [], isCached: false))
            : _carePlanRepo.load();
    unawaited(_seedAppointmentStatuses());
  }

  @override
  void dispose() {
    AppointmentRepository.changes.removeListener(_onAppointmentsChanged);
    DawaCarePlanRepository.changes.removeListener(_onCarePlanChanged);
    _clinicSearch.dispose();
    super.dispose();
  }

  void _onAppointmentsChanged() {
    if (mounted && widget.initialAppointments == null) {
      _refreshAppointments();
    }
  }

  void _onCarePlanChanged() {
    if (mounted && widget.initialCareItems == null) _refreshCarePlan();
  }

  Future<void> _seedAppointmentStatuses() async {
    try {
      _rememberAppointmentStatuses(await _appointments);
    } catch (_) {
      // The existing error state explains a failed initial appointment load.
    }
  }

  Future<void> _refreshAppointments() async {
    final appointments = _repo.getAppointments();
    setState(() {
      _appointments = appointments;
    });
    try {
      _announceAppointmentTransitions(await appointments);
    } catch (_) {
      // The existing FutureBuilder presents the error state.
    }
  }

  Future<void> _refreshCarePlan() async {
    if (widget.initialCareItems != null) return;
    final carePlan = _carePlanRepo.load();
    setState(() => _carePlan = carePlan);
    try {
      await carePlan;
    } catch (_) {
      // Appointments remain available when the care plan has no live/cache read.
    }
  }

  void _rememberAppointmentStatuses(List<Appointment> appointments) {
    _knownAppointmentStatuses
      ..clear()
      ..addEntries(
        appointments.map((appointment) => MapEntry(
              appointment.id,
              appointment.status,
            )),
      );
  }

  void _announceAppointmentTransitions(List<Appointment> appointments) {
    final previous = Map<String, String>.from(_knownAppointmentStatuses);
    _rememberAppointmentStatuses(appointments);
    if (!mounted || previous.isEmpty) return;
    for (final appointment in appointments) {
      final oldStatus = previous[appointment.id];
      if (oldStatus == null || oldStatus == appointment.status) continue;
      _showAppointmentStatusFeedback(appointment);
      return;
    }
  }

  void _showAppointmentStatusFeedback(Appointment appointment) {
    final status = appointment.status;
    final details = switch (status) {
      'confirmed' => (
          title: 'Appointment confirmed',
          message: 'Your clinic has confirmed your visit.',
          tone: DawaFeedbackTone.success,
        ),
      'rescheduled' => (
          title: 'Appointment updated',
          message:
              'Your clinic proposed a new appointment time. Check the details.',
          tone: DawaFeedbackTone.information,
        ),
      'completed' => (
          title: 'Appointment completed',
          message: 'Your visit is now available in your care history.',
          tone: DawaFeedbackTone.success,
        ),
      'declined' => (
          title: 'Appointment could not be confirmed',
          message: 'Choose another time when you are ready.',
          tone: DawaFeedbackTone.error,
        ),
      'cancelled' => (
          title: 'Appointment cancelled',
          message: 'This visit is now in your care history.',
          tone: DawaFeedbackTone.information,
        ),
      _ => null,
    };
    if (details == null || !mounted) return;
    setState(() {
      _statusFeedbackTitle = details.title;
      _statusFeedbackMessage = details.message;
      _statusFeedbackTone = details.tone;
    });
    if (status == 'confirmed') {
      unawaited(DawaFeedbackEffects.appointmentConfirmed());
    }
  }

  Future<void> _refresh() async {
    final appointments = widget.initialAppointments == null
        ? _repo.getAppointments()
        : _appointments;
    final clinics =
        widget.initialClinics == null ? _repo.getClinics() : _clinics;
    final carePlan =
        widget.initialCareItems == null ? _carePlanRepo.load() : _carePlan;
    setState(() {
      _appointments = appointments;
      _clinics = clinics;
      _carePlan = carePlan;
    });
    await Future.wait([appointments, clinics, carePlan]);
  }

  Future<void> _openBooking({String? clinicId}) async {
    final result = await showModalBottomSheet<AppointmentBookingResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingBottomSheetWidget(initialClinicId: clinicId),
    );
    if (result == null || !mounted) return;
    final appointment = result.appointment;
    if (widget.initialAppointments == null) {
      await _refreshAppointments();
    } else {
      final current = await _appointments;
      if (!mounted) return;
      setState(() => _appointments = Future.value([...current, appointment]));
    }
    if (!mounted) return;
    // Do not celebrate an online booking until the provider has verified the
    // payment. Clinic confirmation remains a separate later transition.
    if (!appointment.requiresOnlinePayment || result.paymentSucceeded) {
      unawaited(DawaFeedbackEffects.appointmentBooked());
    }
    await showDawaBookingSuccessDialog(context, appointment, result: result);
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
      _rememberAppointmentStatuses([updated]);
      _showAppointmentStatusFeedback(updated);
      // Cancellation is never celebrated, but a quiet haptic makes the
      // confirmed state change clear without presenting another popup.
      unawaited(DawaFeedbackEffects.confirmed());
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
              'Visits, trusted clinics, and care history.',
              textAlign: TextAlign.center,
              style: context.dawaCaption,
            ),
            if (_statusFeedbackTitle != null &&
                _statusFeedbackMessage != null) ...[
              const SizedBox(height: DawaSpacing.sm),
              DawaActionFeedback(
                title: _statusFeedbackTitle!,
                message: _statusFeedbackMessage!,
                tone: _statusFeedbackTone,
                actionLabel: 'View appointments',
                onAction: () =>
                    setState(() => _section = _CareSection.upcoming),
                dismissLabel: 'Dismiss',
                onDismiss: () => setState(() {
                  _statusFeedbackTitle = null;
                  _statusFeedbackMessage = null;
                }),
              ),
            ],
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
          final usingSavedAppointments = widget.initialAppointments == null &&
              _repo.lastAppointmentLoadUsedCache;
          return FutureBuilder<DawaCarePlanSnapshot>(
            future: _carePlan,
            builder: (context, careSnapshot) {
              final nextCare = careSnapshot.data?.nextActionable;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (usingSavedAppointments) ...[
                    DawaOfflineBanner(
                      message: 'Showing saved appointment information'
                          '${_repo.lastAppointmentCacheAt == null ? '' : ' from ${DateFormat('d MMM, h:mm a').format(_repo.lastAppointmentCacheAt!.toLocal())}'}. Connect to update, book, or cancel a visit.',
                      onRetry: _refreshAppointments,
                    ),
                    const SizedBox(height: DawaSpacing.md),
                  ],
                  if (careSnapshot.connectionState ==
                      ConnectionState.waiting) ...[
                    const DawaLoadingSkeleton(
                      label: 'Loading recommended care',
                      lines: 1,
                    ),
                    const SizedBox(height: DawaSpacing.lg),
                  ] else if (careSnapshot.hasError) ...[
                    _CarePlanUnavailableNotice(onRetry: _refreshCarePlan),
                    const SizedBox(height: DawaSpacing.sm),
                  ] else if (nextCare != null) ...[
                    _CarePlanNextStepCard(
                      item: nextCare,
                      isCached: careSnapshot.data!.isCached,
                      onOpenAppointment: nextCare.appointmentId == null
                          ? null
                          : () => context.push(
                                '/appointmentDetails?appointmentId=${nextCare.appointmentId}',
                              ),
                    ),
                    const SizedBox(height: DawaSpacing.lg),
                  ],
                  if (upcoming.isEmpty)
                    _NoUpcomingAppointment(
                      offline: usingSavedAppointments,
                      onBook: () => _openBooking(),
                      onBrowseClinics: () =>
                          setState(() => _section = _CareSection.clinics),
                    )
                  else ...[
                    const _SectionIntroduction(
                      eyebrow: 'UPCOMING',
                      title: 'Your next visit',
                      description: 'Your appointment details in one place.',
                    ),
                    const SizedBox(height: DawaSpacing.sm),
                    _UpcomingAppointmentCard(
                      appointment: upcoming.first,
                      reminder: _reminderFor(upcoming.first.id),
                      cancelling: _cancellingAppointmentId == upcoming.first.id,
                      onOpen: usingSavedAppointments
                          ? null
                          : () => context.push(
                                '/appointmentDetails?appointmentId=${upcoming.first.id}',
                              ),
                      onReminder: () => _openReminder(upcoming.first),
                      onCancel: !usingSavedAppointments &&
                              upcoming.first.canPatientCancel
                          ? () => _cancelAppointment(upcoming.first)
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
                                onOpen: usingSavedAppointments
                                    ? null
                                    : () => context.push(
                                          '/appointmentDetails?appointmentId=${appointment.id}',
                                        ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ],
              );
            },
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
          final usingSavedClinics =
              widget.initialClinics == null && _repo.lastClinicLoadUsedCache;
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
                description: 'Choose a clinic to see details or book a visit.',
              ),
              if (usingSavedClinics) ...[
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
                          onView: () => _showClinicDetails(
                            clinic,
                            allowBooking: !usingSavedClinics,
                          ),
                          onBook: usingSavedClinics
                              ? null
                              : () => _openBooking(clinicId: clinic.id),
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
          final usingSavedAppointments = widget.initialAppointments == null &&
              _repo.lastAppointmentLoadUsedCache;
          return FutureBuilder<DawaCarePlanSnapshot>(
            future: _carePlan,
            builder: (context, careSnapshot) {
              final careHistory = (careSnapshot.data?.items ?? const [])
                  .where(
                    (item) => item.isTerminal && item.appointmentId == null,
                  )
                  .toList()
                ..sort(
                  (a, b) => (b.completedAt ?? b.updatedAt)
                      .compareTo(a.completedAt ?? a.updatedAt),
                );
              if (history.isEmpty && careHistory.isEmpty) {
                return _EmptyHistory(
                  offline: usingSavedAppointments,
                  onBook: () => _openBooking(),
                );
              }
              final groups = _historyGroups(history);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (usingSavedAppointments) ...[
                    DawaOfflineBanner(
                      message: 'Showing saved appointment information'
                          '${_repo.lastAppointmentCacheAt == null ? '' : ' from ${DateFormat('d MMM, h:mm a').format(_repo.lastAppointmentCacheAt!.toLocal())}'}. Connect to view details or book a follow-up.',
                      onRetry: _refreshAppointments,
                    ),
                    const SizedBox(height: DawaSpacing.md),
                  ],
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
                          onOpen: usingSavedAppointments
                              ? null
                              : () => context.push(
                                    '/appointmentDetails?appointmentId=${appointment.id}',
                                  ),
                          onBookFollowUp: !usingSavedAppointments &&
                                  appointment.status == 'completed'
                              ? () =>
                                  _openBooking(clinicId: appointment.clinicId)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: DawaSpacing.xs),
                  ],
                  if (careHistory.isNotEmpty) ...[
                    if (history.isNotEmpty)
                      const SizedBox(height: DawaSpacing.md),
                    const DawaSectionHeader(
                      title: 'Other completed care',
                      subtitle:
                          'Care-plan items appear here when they are completed, cancelled, or dismissed.',
                    ),
                    const SizedBox(height: DawaSpacing.sm),
                    ...careHistory.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: DawaSpacing.sm),
                        child: _CarePlanHistoryCard(item: item),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      );

  Future<void> _showClinicDetails(
    ClinicOption clinic, {
    required bool allowBooking,
  }) async {
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
        allowBooking: allowBooking,
      ),
    );
    if (book == true && allowBooking && mounted) {
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
  Widget build(BuildContext context) => DawaSegmentedControl(
        keyPrefix: 'care-tab',
        selectedIndex: _CareSection.values.indexOf(selected),
        onSelected: (index) => onSelected(_CareSection.values[index]),
        items: const [
          DawaSegmentedItem(label: 'Upcoming', id: 'upcoming'),
          DawaSegmentedItem(label: 'Clinics', id: 'clinics'),
          DawaSegmentedItem(label: 'History', id: 'history'),
        ],
      );
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

class _CarePlanNextStepCard extends StatelessWidget {
  const _CarePlanNextStepCard({
    required this.item,
    required this.isCached,
    required this.onOpenAppointment,
  });

  final DawaCareItem item;
  final bool isCached;
  final VoidCallback? onOpenAppointment;

  @override
  Widget build(BuildContext context) {
    final when = item.relevantAt;
    final status = item.status.name;
    final statusColor = switch (item.status) {
      DawaCareItemStatus.overdue => DawaColors.danger,
      DawaCareItemStatus.due => DawaColors.warning,
      DawaCareItemStatus.scheduled => DawaColors.primary,
      _ => DawaColors.green,
    };
    return DawaCard(
      featured: true,
      color: item.priority == DawaCareItemPriority.urgent ||
              item.priority == DawaCareItemPriority.high
          ? DawaColors.warningSurface
          : DawaColors.softGreen,
      borderColor: statusColor.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED NEXT STEP',
            style: context.dawaCaption.copyWith(
              color: DawaColors.greenDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: DawaSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DawaIconBadge(
                icon: _careItemIcon(item.type),
                color: statusColor,
              ),
              const SizedBox(width: DawaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.dawaSectionTitle),
                    const SizedBox(height: DawaSpacing.xxs),
                    DawaStatusPill(
                      label: _careItemStatusLabel(status),
                      icon: _statusIcon(status),
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: DawaSpacing.sm),
            Text(item.description!.trim(), style: context.dawaBody),
          ],
          if (when != null) ...[
            const SizedBox(height: DawaSpacing.sm),
            _VisitFact(
              icon: Icons.event_outlined,
              label: DateFormat('EEE, d MMM • h:mm a').format(when),
            ),
          ],
          if (isCached) ...[
            const SizedBox(height: DawaSpacing.xxs),
            Text(
              'Showing saved care information. Connect to refresh it.',
              style: context.dawaCaption,
            ),
          ],
          if (onOpenAppointment != null)
            Align(
              alignment: Alignment.centerLeft,
              child: DawaTextButton(
                label: 'View appointment',
                icon: Icons.chevron_right_rounded,
                compact: true,
                onPressed: onOpenAppointment,
              ),
            ),
        ],
      ),
    );
  }
}

class _CarePlanUnavailableNotice extends StatelessWidget {
  const _CarePlanUnavailableNotice({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: DawaColors.warning,
              size: 18,
            ),
            const SizedBox(width: DawaSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Care recommendations couldn't refresh",
                    style: context.dawaBody.copyWith(
                      color: DawaColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Your appointments are still available.',
                    style: context.dawaCaption,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DawaTextButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      compact: true,
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _NoUpcomingAppointment extends StatelessWidget {
  const _NoUpcomingAppointment({
    required this.onBook,
    required this.onBrowseClinics,
    this.offline = false,
  });

  final VoidCallback onBook;
  final VoidCallback onBrowseClinics;
  final bool offline;

  @override
  Widget build(BuildContext context) => DawaCard(
        padding: const EdgeInsets.all(DawaSpacing.md),
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: 0.16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackContent = constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2;
            final image = SizedBox(
              width: stackContent ? 96 : 88,
              child: AspectRatio(
                aspectRatio: 1,
                child: DawaContextualImage(
                  assetId: 'clinic_visit_02',
                  variant: DawaImageVariant.moduleThumbnail,
                  borderRadius: BorderRadius.circular(DawaRadii.medium),
                ),
              ),
            );
            final copy = Column(
              crossAxisAlignment: stackContent
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'No visits yet',
                  textAlign: stackContent ? TextAlign.center : TextAlign.start,
                  style: context.dawaSectionTitle,
                ),
                const SizedBox(height: DawaSpacing.xxs),
                Text(
                  offline
                      ? 'Connect to book a clinic visit.'
                      : 'Book a clinic visit when you are ready.',
                  textAlign: stackContent ? TextAlign.center : TextAlign.start,
                  style: context.dawaCaption,
                ),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stackContent) ...[
                  Center(child: image),
                  const SizedBox(height: DawaSpacing.sm),
                  copy,
                ] else
                  Row(
                    children: [
                      image,
                      const SizedBox(width: DawaSpacing.sm),
                      Expanded(child: copy),
                    ],
                  ),
                const SizedBox(height: DawaSpacing.sm),
                if (!offline)
                  DawaPrimaryButton(
                    label: 'Book a visit',
                    icon: Icons.add_circle_outline_rounded,
                    onPressed: onBook,
                  ),
                Align(
                  alignment: Alignment.center,
                  child: DawaTextButton(
                    label: 'Find clinics',
                    icon: Icons.local_hospital_outlined,
                    onPressed: onBrowseClinics,
                  ),
                ),
              ],
            );
          },
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
  final VoidCallback? onOpen;
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
              _AppointmentDateBadge(date: start),
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
                    const SizedBox(height: DawaSpacing.xxs),
                    Text(
                      DateFormat('h:mm a').format(start),
                      style: context.dawaBody.copyWith(
                        color: DawaColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
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
          const SizedBox(height: DawaSpacing.sm),
          if (onOpen != null)
            DawaPrimaryButton(
              label: 'View visit',
              icon: Icons.arrow_forward_rounded,
              onPressed: onOpen,
            )
          else
            const _OfflineAppointmentActionNotice(),
          const SizedBox(height: DawaSpacing.sm),
          _VisitFact(
            icon: Icons.calendar_month_outlined,
            label: DateFormat('EEEE, d MMMM y').format(start),
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
          const SizedBox(height: DawaSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DawaSpacing.sm,
              vertical: DawaSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(DawaRadii.small),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: DawaColors.greenDark,
                  size: 20,
                ),
                const SizedBox(width: DawaSpacing.xs),
                Expanded(
                  child: Text(
                    'Visit preparation: $preparationCompleted of 5',
                    style: context.dawaCaption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onOpen != null)
                  DawaTextButton(
                    label: 'Prepare',
                    compact: true,
                    onPressed: onOpen,
                  ),
              ],
            ),
          ),
          const SizedBox(height: DawaSpacing.sm),
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

class _AppointmentDateBadge extends StatelessWidget {
  const _AppointmentDateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Semantics(
        label: DateFormat('EEEE, d MMMM y').format(date),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(DawaRadii.medium),
            border: Border.all(
              color: DawaColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('MMM').format(date).toUpperCase(),
                style: context.dawaCaption.copyWith(
                  color: DawaColors.greenDark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                DateFormat('d').format(date),
                style: context.dawaTitle.copyWith(
                  color: DawaColors.primaryDark,
                  height: 1,
                ),
              ),
            ],
          ),
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
  final VoidCallback? onBook;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final displayName = _clinicDisplayName(clinic);
    final metadata = <Widget>[
      if (clinic.distanceKm != null)
        _ClinicMeta(
          icon: Icons.near_me_outlined,
          label: '${clinic.distanceKm!.toStringAsFixed(1)} km',
        ),
      if (clinic.isOpen != null)
        _ClinicMeta(
          icon: clinic.isOpen!
              ? Icons.check_circle_outline_rounded
              : Icons.schedule_rounded,
          label: clinic.isOpen! ? 'Open now' : 'Closed',
        ),
      if (clinic.isPreferred == true)
        const _ClinicMeta(icon: Icons.star_rounded, label: 'Preferred'),
    ];
    final hasSupportingInformation = metadata.isNotEmpty ||
        clinic.address?.trim().isNotEmpty == true ||
        clinic.services.isNotEmpty ||
        clinic.nextAvailableAt != null ||
        clinic.openingHours?.trim().isNotEmpty == true ||
        onCall != null ||
        onDirections != null;
    const image = SizedBox(
      width: 76,
      child: AspectRatio(
        aspectRatio: 1,
        child: DawaContextualImage(
          assetId: 'clinic_visit_02',
          variant: DawaImageVariant.moduleThumbnail,
        ),
      ),
    );
    const compactImage = SizedBox(
      width: 64,
      child: AspectRatio(
        aspectRatio: 1,
        child: DawaContextualImage(
          assetId: 'clinic_visit_02',
          variant: DawaImageVariant.moduleThumbnail,
        ),
      ),
    );
    Widget actions() => LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Flexible(
                child: DawaTextButton(
                  label: 'View clinic',
                  compact: true,
                  onPressed: onView,
                ),
              ),
              if (onBook != null) ...[
                if (constraints.maxWidth >= 300)
                  const Spacer()
                else
                  const SizedBox(width: DawaSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 88),
                  child: DawaCompactButton(
                    label: 'Book',
                    filled: true,
                    onPressed: onBook,
                  ),
                ),
              ],
            ],
          ),
        );
    return DawaCard(
      key: ValueKey('clinic-card-${clinic.id}'),
      padding: const EdgeInsets.all(DawaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasSupportingInformation)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    compactImage,
                    const SizedBox(width: DawaSpacing.sm),
                    Expanded(
                      child: Text(
                        displayName,
                        style: context.dawaSectionTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DawaSpacing.xxs),
                actions(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: DawaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: context.dawaSectionTitle),
                      if (clinic.address?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: DawaSpacing.xxs),
                        Text(
                          clinic.address!.trim(),
                          style: context.dawaCaption,
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: DawaSpacing.xs),
                        Wrap(
                          spacing: DawaSpacing.xs,
                          runSpacing: DawaSpacing.xxs,
                          children: metadata,
                        ),
                      ],
                      if (clinic.services.isNotEmpty) ...[
                        const SizedBox(height: DawaSpacing.xs),
                        Text(
                          clinic.services.take(3).join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
          if (clinic.nextAvailableAt != null ||
              clinic.openingHours?.trim().isNotEmpty == true) ...[
            const SizedBox(height: DawaSpacing.xs),
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
          if (hasSupportingInformation) ...[
            const SizedBox(height: DawaSpacing.xs),
            actions(),
          ],
          if (onCall != null || onDirections != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: DawaSpacing.xs,
                children: [
                  if (onCall != null)
                    DawaIconButton(
                      icon: Icons.call_outlined,
                      tooltip: 'Call $displayName',
                      onPressed: onCall,
                    ),
                  if (onDirections != null)
                    DawaIconButton(
                      icon: Icons.directions_outlined,
                      tooltip: 'Directions to $displayName',
                      onPressed: onDirections,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
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
    required this.allowBooking,
  });

  final ClinicOption clinic;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final bool allowBooking;

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
                          Text(_clinicDisplayName(clinic),
                              style: context.dawaTitle),
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
                if (allowBooking)
                  DawaPrimaryButton(
                    label: 'Book at this clinic',
                    icon: Icons.add_circle_outline_rounded,
                    onPressed: () => Navigator.pop(context, true),
                  )
                else
                  const _OfflineAppointmentActionNotice(),
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
  final VoidCallback? onOpen;
  final VoidCallback? onBookFollowUp;

  @override
  Widget build(BuildContext context) {
    final start =
        Appointment.dateAtTime(appointment.date, appointment.startTime);
    return DawaCard(
      key: ValueKey('care-history-${appointment.id}'),
      padding: const EdgeInsets.all(DawaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DawaIconBadge(
                icon: Icons.medical_services_outlined,
                color: DawaColors.primary,
                size: 38,
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
            ],
          ),
          if (appointment.status == 'completed') ...[
            const SizedBox(height: DawaSpacing.xs),
            Text(
              'Your patient-safe visit summary and any follow-up guidance are available in appointment details.',
              style: context.dawaCaption,
            ),
          ],
          const SizedBox(height: DawaSpacing.xxs),
          LayoutBuilder(
            builder: (context, constraints) {
              // Both controls retain their 48dp touch targets. The compact
              // history action keeps the core visit state and its next action
              // on one scan line without compressing the labels.
              final actionRowFits = constraints.maxWidth >= 252 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.2;
              final status = DawaStatusPill(
                label: _statusLabel(appointment.status),
                icon: _statusIcon(appointment.status),
                color: _statusColor(appointment.status),
              );
              final primaryAction = _HistoryPrimaryAction(
                label: actionLabel,
                onPressed: onOpen,
              );
              final followUpAction = onBookFollowUp == null
                  ? null
                  : DawaTextButton(
                      label: 'Book follow-up',
                      icon: Icons.add_circle_outline_rounded,
                      compact: true,
                      onPressed: onBookFollowUp,
                    );

              if (actionRowFits && followUpAction == null) {
                return Row(
                  children: [
                    status,
                    const Spacer(),
                    SizedBox(width: 124, child: primaryAction),
                  ],
                );
              }
              return Wrap(
                spacing: DawaSpacing.xs,
                runSpacing: DawaSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  status,
                  primaryAction,
                  if (followUpAction != null) followUpAction,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryPrimaryAction extends StatelessWidget {
  const _HistoryPrimaryAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onPressed != null,
        label: label,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: DawaSpacing.xs),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.chevron_right_rounded, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
}

class _OfflineAppointmentActionNotice extends StatelessWidget {
  const _OfflineAppointmentActionNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DawaSpacing.sm,
          vertical: DawaSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: DawaColors.warningSurface,
          borderRadius: BorderRadius.circular(DawaRadii.small),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: DawaColors.warning,
            ),
            const SizedBox(width: DawaSpacing.xs),
            Expanded(
              child: Text(
                'Connect to view the latest visit details.',
                style: context.dawaCaption,
              ),
            ),
          ],
        ),
      );
}

class _CarePlanHistoryCard extends StatelessWidget {
  const _CarePlanHistoryCard({required this.item});

  final DawaCareItem item;

  @override
  Widget build(BuildContext context) {
    final completedAt = item.completedAt ?? item.updatedAt;
    final status = item.status.name;
    return DawaCard(
      padding: const EdgeInsets.all(DawaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DawaIconBadge(
            icon: _careItemIcon(item.type),
            color: _statusColor(status),
            size: 38,
          ),
          const SizedBox(width: DawaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.dawaSectionTitle),
                const SizedBox(height: DawaSpacing.xxs),
                Text(
                  DateFormat('d MMM y').format(completedAt),
                  style: context.dawaCaption,
                ),
                const SizedBox(height: DawaSpacing.xs),
                DawaStatusPill(
                  label: _careItemStatusLabel(status),
                  icon: _statusIcon(status),
                  color: _statusColor(status),
                ),
              ],
            ),
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
  const _EmptyHistory({required this.onBook, this.offline = false});

  final VoidCallback onBook;
  final bool offline;

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
            if (!offline)
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

String _clinicDisplayName(ClinicOption clinic) {
  final name = clinic.name.trim();
  // A tenant or product label is not evidence of a physical clinic identity.
  // Keep the booking option available while using a neutral, truthful label.
  if (const {'dawamom', 'dawa mom', 'dawa health'}.contains(
    name.toLowerCase(),
  )) {
    return 'Clinic available for booking';
  }
  return name.isEmpty ? 'Clinic available for booking' : name;
}

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

String _careItemStatusLabel(String value) => switch (value) {
      'recommended' => 'Recommended',
      'due' => 'Due now',
      'scheduled' => 'Scheduled',
      'completed' => 'Completed',
      'overdue' => 'Overdue',
      'cancelled' => 'Cancelled',
      'dismissed' => 'Dismissed',
      _ => _statusLabel(value),
    };

IconData _careItemIcon(String type) => switch (type) {
      'anc_visit' || 'postpartum_visit' => Icons.pregnant_woman_outlined,
      'screening' || 'screening_followup' => Icons.health_and_safety_outlined,
      'learning' => Icons.menu_book_outlined,
      'vaccination' => Icons.vaccines_outlined,
      'callback' => Icons.phone_in_talk_outlined,
      _ => Icons.medical_services_outlined,
    };
