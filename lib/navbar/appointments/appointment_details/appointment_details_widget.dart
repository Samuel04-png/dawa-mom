import '/localization/dawa_localized_material.dart';
import 'package:intl/intl.dart';

import '/backend/backend.dart';
import '/content/dawa_learning_asset_registry.dart';
import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/appointments/domain/appointment_result_summary.dart';
import '/features/appointments/presentation/dawa_appointment_reminder_sheet.dart';
import '/features/appointments/presentation/appointment_result_summary_view.dart';
import '/features/payments/data/lipila_payment_repository.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_interactions.dart';
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
  late Future<AppointmentResultSummary?> _resultSummary;
  late Future<LipilaPaymentRecord?> _payment;
  bool _cancelling = false;
  bool _cancelledLocally = false;
  bool _retryingPayment = false;
  String? _error;
  String? _paymentNotice;
  DawaFeedbackTone _paymentNoticeTone = DawaFeedbackTone.information;

  @override
  void initState() {
    super.initState();
    AppointmentRepository.changes.addListener(_onAppointmentChanged);
    _appointment = _load();
    _resultSummary = _loadResultSummary();
    _payment = _loadPayment();
  }

  @override
  void dispose() {
    AppointmentRepository.changes.removeListener(_onAppointmentChanged);
    super.dispose();
  }

  void _onAppointmentChanged() {
    if (mounted && !_cancelledLocally) {
      _refresh();
    }
  }

  Future<Appointment?> _load() {
    final id = widget.appointmentId ?? widget.encounterDets?.id;
    return id == null ? Future.value() : _repository.getAppointment(id);
  }

  Future<AppointmentResultSummary?> _loadResultSummary() {
    final id = widget.appointmentId ?? widget.encounterDets?.id;
    return id == null
        ? Future.value()
        : _repository.getAppointmentResultSummary(id);
  }

  Future<void> _refresh() async {
    final future = _load();
    final resultFuture = _loadResultSummary();
    final paymentFuture = _loadPayment();
    setState(() {
      _appointment = future;
      _resultSummary = resultFuture;
      _payment = paymentFuture;
      _error = null;
    });
    await Future.wait([future, resultFuture, paymentFuture]);
  }

  Future<LipilaPaymentRecord?> _loadPayment() {
    final id = widget.appointmentId ?? widget.encounterDets?.id;
    return id == null
        ? Future.value()
        : LipilaPaymentRepository().getAppointmentPayment(id);
  }

  Future<void> _refreshPayment() async {
    try {
      // A provider callback can change both the payment ledger and the
      // appointment's server-owned payment state. Reload both so a successful
      // payment becomes visible without restarting the app.
      await _refresh();
      if (mounted) setState(() => _paymentNotice = null);
    } catch (_) {
      if (mounted) {
        setState(() {
          _paymentNotice =
              'We could not check your payment status. Your appointment details are still here.';
          _paymentNoticeTone = DawaFeedbackTone.error;
        });
      }
    }
  }

  Future<String?> _requestPaymentPhone(Appointment appointment) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${appointment.currencySnapshot} ${appointment.priceSnapshot.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DawaColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "We'll send a payment request to your phone. Dawa will never ask for your Mobile Money PIN.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '0970 000 000',
                helperText: "You'll approve the payment on your phone.",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Send payment request'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _retryPayment(Appointment appointment) async {
    if (_retryingPayment) return;
    final phoneNumber = await _requestPaymentPhone(appointment);
    if (phoneNumber == null || !mounted) return;
    setState(() {
      _retryingPayment = true;
      _paymentNotice = null;
    });
    try {
      await LipilaPaymentRepository().createPayment(
        appointmentId: appointment.id,
        phoneNumber: phoneNumber,
      );
      if (!mounted) return;
      final paymentFuture = _loadPayment();
      setState(() {
        _payment = paymentFuture;
        _paymentNotice =
            'Payment request sent. Approve it on your phone, then check the payment status.';
        _paymentNoticeTone = DawaFeedbackTone.pending;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _paymentNotice = error.message;
        _paymentNoticeTone = DawaFeedbackTone.error;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _paymentNotice = error.message;
        _paymentNoticeTone = DawaFeedbackTone.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentNotice =
            'We could not send a payment request. Please check your connection and try again.';
        _paymentNoticeTone = DawaFeedbackTone.error;
      });
    } finally {
      if (mounted) setState(() => _retryingPayment = false);
    }
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
      _cancelledLocally = true;
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
        _cancelledLocally = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _cancelledLocally = false;
        _error = 'The appointment could not be cancelled. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DawaColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DawaBreakpoints.pagePadding(context),
                  ),
                  child: DawaAppHeader(
                    title: 'Appointment details',
                    onBack: () => Navigator.maybePop(context),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<Appointment?>(
                future: _appointment,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(DawaSpacing.md),
                      child: DawaPageSkeleton(
                        label: 'Loading appointment details',
                        showHero: true,
                        cardCount: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _DetailsError(onRetry: _refresh);
                  }
                  final appointment = snapshot.data;
                  if (appointment == null) {
                    return const _MissingAppointment();
                  }
                  return FutureBuilder<AppointmentResultSummary?>(
                    future: _resultSummary,
                    builder: (context, resultSnapshot) =>
                        FutureBuilder<LipilaPaymentRecord?>(
                      future: _payment,
                      builder: (context, paymentSnapshot) =>
                          AppointmentDetailsContent(
                        appointment: appointment,
                        payment: paymentSnapshot.data,
                        resultSummary: resultSnapshot.data,
                        resultLoading: resultSnapshot.connectionState ==
                            ConnectionState.waiting,
                        resultError: resultSnapshot.hasError,
                        error: _error,
                        cancelling: _cancelling,
                        retryingPayment: _retryingPayment,
                        paymentNotice: _paymentNotice,
                        onCancel: () => _cancel(appointment),
                        onRefresh: _refresh,
                        onRefreshPayment: _refreshPayment,
                        onRetryPayment: () => _retryPayment(appointment),
                        paymentNoticeTone: _paymentNoticeTone,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class AppointmentDetailsContent extends StatelessWidget {
  const AppointmentDetailsContent({
    super.key,
    required this.appointment,
    required this.cancelling,
    required this.onCancel,
    required this.onRefresh,
    required this.resultLoading,
    required this.resultError,
    this.retryingPayment = false,
    this.resultSummary,
    this.error,
    this.payment,
    this.paymentNotice,
    this.paymentNoticeTone = DawaFeedbackTone.information,
    this.onRefreshPayment,
    this.onRetryPayment,
  });

  final Appointment appointment;
  final bool cancelling;
  final VoidCallback onCancel;
  final Future<void> Function() onRefresh;
  final AppointmentResultSummary? resultSummary;
  final bool resultLoading;
  final bool resultError;
  final bool retryingPayment;
  final String? error;
  final LipilaPaymentRecord? payment;
  final String? paymentNotice;
  final DawaFeedbackTone paymentNoticeTone;
  final VoidCallback? onRefreshPayment;
  final VoidCallback? onRetryPayment;

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
    final isCompleted = appointment.status == 'completed';
    final isCancelled = appointment.status == 'cancelled';
    final paymentSucceeded = payment?.status == 'successful';
    final statusMessage = appointment.patientSafeStatusMessage
                    ?.trim()
                    .isNotEmpty ==
                true &&
            !paymentSucceeded
        ? appointment.patientSafeStatusMessage!.trim()
        : appointment.integrationStatus == 'failed'
            ? 'Your appointment is saved, but the clinic connection needs attention. It will be retried safely.'
            : appointment.status == 'pending'
                ? 'Your request is waiting for confirmation. DawaMom will update this page when the clinic responds.'
                : 'This appointment is ${_statusLabel(appointment.status).toLowerCase()}.';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        20,
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        40,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppointmentHero(
                appointment: appointment,
                start: start,
                end: end,
              ),
              const SizedBox(height: 22),
              if (isCompleted) ...[
                const _SectionHeading(
                  eyebrow: 'YOUR RESULTS',
                  title: 'Consultation results',
                  subtitle: 'A simple summary shared by your health worker.',
                ),
                const SizedBox(height: 12),
                if (resultSummary != null)
                  AppointmentResultSummaryView(summary: resultSummary!)
                else
                  _ResultPendingCard(
                    loading: resultLoading,
                    failed: resultError,
                    onRefresh: onRefresh,
                  ),
                const SizedBox(height: 26),
              ] else if (isCancelled &&
                  appointment.integrationStatus != 'synced') ...[
                _CancellationSyncNotice(appointment: appointment),
                const SizedBox(height: 26),
              ] else if (!isCancelled) ...[
                _StatusNotice(
                  appointment: appointment,
                  message: statusMessage,
                ),
                const SizedBox(height: 26),
              ],
              const _SectionHeading(
                eyebrow: 'APPOINTMENT',
                title: 'Visit details',
                subtitle: 'Your care team, clinic, and booking information.',
              ),
              const SizedBox(height: 12),
              _VisitInformation(appointment: appointment),
              if (paymentNotice != null) ...[
                const SizedBox(height: 16),
                DawaActionFeedback(
                  title: paymentNoticeTone == DawaFeedbackTone.error
                      ? 'Payment status could not be updated'
                      : paymentNoticeTone == DawaFeedbackTone.pending
                          ? 'Payment request sent'
                          : 'Payment update',
                  message: paymentNotice!,
                  tone: paymentNoticeTone,
                  actionLabel: paymentNoticeTone == DawaFeedbackTone.pending
                      ? 'Check again'
                      : null,
                  onAction: paymentNoticeTone == DawaFeedbackTone.pending
                      ? onRefreshPayment
                      : null,
                ),
              ],
              if (payment != null) ...[
                const SizedBox(height: 16),
                _PaymentHistoryCard(
                  payment: payment!,
                  appointment: appointment,
                  retrying: retryingPayment,
                  onRefresh: onRefreshPayment,
                  onRetry: onRetryPayment,
                ),
              ] else if (appointment.paymentMethod == 'cash') ...[
                const SizedBox(height: 16),
                const _PayAtClinicCard(),
              ] else if (appointment.isPaidSnapshot &&
                  appointment.paymentMethod == 'online' &&
                  !_appointmentIsTerminal(appointment.status)) ...[
                const SizedBox(height: 16),
                _PaymentNeededCard(
                  onStartPayment: onRetryPayment,
                  busy: retryingPayment,
                ),
              ],
              if (appointment.isUpcoming) ...[
                const SizedBox(height: 16),
                const _AppointmentPreparationCard(),
                const SizedBox(height: 16),
                DawaCard(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DawaAppointmentReminderSheet(
                      appointment: appointment,
                    ),
                  ),
                  semanticLabel: 'Set an appointment reminder',
                  child: Row(
                    children: [
                      const DawaIconBadge(
                        icon: Icons.notifications_active_outlined,
                        color: DawaColors.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set a reminder',
                              style: context.dawaSectionTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose when and how you would like to be reminded.',
                              style: context.dawaCaption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: DawaColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 16),
                _InlineError(message: error!),
              ],
              if (appointment.canPatientCancel) ...[
                const SizedBox(height: 18),
                _CancelPanel(
                  cancelling: cancelling,
                  onCancel: onCancel,
                ),
              ],
              if (isCompleted && resultSummary == null && !resultLoading) ...[
                const SizedBox(height: 16),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
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
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({
    required this.payment,
    required this.appointment,
    required this.retrying,
    this.onRefresh,
    this.onRetry,
  });

  final LipilaPaymentRecord payment;
  final Appointment appointment;
  final bool retrying;
  final VoidCallback? onRefresh;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final presentation = _paymentPresentation(payment.status);
    final date =
        DateFormat('d MMM yyyy, HH:mm').format(payment.createdAt.toLocal());
    final canRetry = presentation.isTerminal &&
        !_appointmentIsTerminal(appointment.status) &&
        onRetry != null;
    return DawaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment', style: context.dawaSectionTitle),
          const SizedBox(height: 10),
          Text(
            '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
            style: context.dawaSectionTitle,
          ),
          const SizedBox(height: 8),
          DawaStatusTransition(
            label: presentation.label,
            icon: presentation.icon,
            color: presentation.color,
          ),
          const SizedBox(height: 10),
          DawaActionFeedback(
            title: presentation.title,
            message: presentation.message,
            tone: presentation.tone,
            actionLabel: presentation.isPending && onRefresh != null
                ? 'Check again'
                : canRetry
                    ? 'Try payment again'
                    : null,
            onAction: presentation.isPending && onRefresh != null
                ? onRefresh
                : canRetry
                    ? onRetry
                    : null,
          ),
          const SizedBox(height: 10),
          Text(date, style: context.dawaCaption),
          const SizedBox(height: 4),
          Text(
            '${payment.paymentMethod.replaceAll('_', ' ')} via ${payment.provider}',
            style: context.dawaCaption,
          ),
          if (payment.referenceId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Reference: ${payment.referenceId}',
                style: context.dawaCaption),
          ],
          if (retrying) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ],
        ],
      ),
    );
  }
}

class _PaymentNeededCard extends StatelessWidget {
  const _PaymentNeededCard({
    required this.onStartPayment,
    required this.busy,
  });

  final VoidCallback? onStartPayment;
  final bool busy;

  @override
  Widget build(BuildContext context) => DawaCard(
        color: DawaColors.softBlue,
        borderColor: DawaColors.primary.withValues(alpha: .2),
        child: DawaActionFeedback(
          title: 'Payment needed',
          message:
              'Payment has not started yet. Start a Mobile Money payment before the clinic can review this appointment request.',
          tone: DawaFeedbackTone.pending,
          actionLabel: onStartPayment == null
              ? null
              : busy
                  ? 'Sending request…'
                  : 'Start payment',
          onAction: busy ? null : onStartPayment,
        ),
      );
}

class _PaymentPresentation {
  const _PaymentPresentation({
    required this.label,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.tone,
    this.isPending = false,
    this.isTerminal = false,
  });

  final String label;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DawaFeedbackTone tone;
  final bool isPending;
  final bool isTerminal;
}

_PaymentPresentation _paymentPresentation(String status) => switch (status) {
      'successful' => const _PaymentPresentation(
          label: 'Payment confirmed',
          title: 'Payment confirmed',
          message:
              'Your payment has been confirmed. Check your appointment status for clinic updates.',
          icon: Icons.check_circle_outline_rounded,
          color: DawaColors.greenDark,
          tone: DawaFeedbackTone.success,
        ),
      'pending' || 'created' => const _PaymentPresentation(
          label: 'Payment pending',
          title: 'Waiting for payment',
          message:
              'Approve the Mobile Money request on your phone. We will update this page when payment is confirmed.',
          icon: Icons.schedule_rounded,
          color: DawaColors.primary,
          tone: DawaFeedbackTone.pending,
          isPending: true,
        ),
      'failed' => const _PaymentPresentation(
          label: 'Payment failed',
          title: "Payment wasn't completed",
          message:
              'No money was confirmed as received. You can try again if this appointment is still available.',
          icon: Icons.error_outline_rounded,
          color: DawaColors.danger,
          tone: DawaFeedbackTone.error,
          isTerminal: true,
        ),
      'cancelled' => const _PaymentPresentation(
          label: 'Payment cancelled',
          title: 'Payment was cancelled',
          message:
              'No money was confirmed as received. You can try again if this appointment is still available.',
          icon: Icons.cancel_outlined,
          color: DawaColors.danger,
          tone: DawaFeedbackTone.error,
          isTerminal: true,
        ),
      'expired' => const _PaymentPresentation(
          label: 'Payment expired',
          title: 'Payment request expired',
          message:
              'No money was confirmed as received. You can try again if this appointment is still available.',
          icon: Icons.timer_off_outlined,
          color: DawaColors.danger,
          tone: DawaFeedbackTone.error,
          isTerminal: true,
        ),
      _ => _PaymentPresentation(
          label: status.isEmpty ? 'Payment status unavailable' : status,
          title: 'Payment status unavailable',
          message:
              'We could not read the payment status. Check again when you have a connection.',
          icon: Icons.sync_problem_rounded,
          color: DawaColors.warning,
          tone: DawaFeedbackTone.error,
        ),
    };

bool _appointmentIsTerminal(String status) =>
    const {'cancelled', 'declined', 'completed', 'missed'}.contains(status);

class _PayAtClinicCard extends StatelessWidget {
  const _PayAtClinicCard();

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: context.dawaSectionTitle),
            const SizedBox(height: 8),
            Text('Pay at clinic', style: context.dawaSectionTitle),
            const SizedBox(height: 4),
            Text(
              'Payment is due in cash when you arrive for your appointment.',
              style: context.dawaCaption,
            ),
          ],
        ),
      );
}

class _AppointmentPreparationCard extends StatelessWidget {
  const _AppointmentPreparationCard();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return DawaCard(
      semanticLabel: 'How to prepare for this appointment',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 104,
            child: DawaContextualImage(
              assetId: 'clinic_visit_03',
              variant: DawaImageVariant.cardSideImage,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prepare for your visit',
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bring any medicines or records you have, and write down questions you want to ask.',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
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

class _AppointmentHero extends StatelessWidget {
  const _AppointmentHero({
    required this.appointment,
    required this.start,
    required this.end,
  });

  final Appointment appointment;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = _appointmentStatus(appointment.status, theme);
    final completed = appointment.status == 'completed';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary,
            Color.lerp(theme.primary, const Color(0xFF173EA5), 0.48)!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 590;
          final icon = Container(
            width: compact ? 50 : 58,
            height: compact ? 50 : 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              completed ? Icons.task_alt_rounded : Icons.calendar_month_rounded,
              color: Colors.white,
              size: compact ? 27 : 31,
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroStatusBadge(status: status),
              const SizedBox(height: 10),
              Text(
                completed ? 'Appointment completed' : 'Your appointment',
                style: theme.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM y').format(start),
                style: theme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}',
                style: theme.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroMeta(
                    icon: Icons.health_and_safety_outlined,
                    text: _typeLabel(appointment.appointmentType),
                  ),
                  _HeroMeta(
                    icon: Icons.local_hospital_outlined,
                    text: appointment.clinicName ?? 'Clinic',
                  ),
                ],
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 16), details],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.status});

  final _AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.labelSmall.copyWith(
            color: theme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.titleLarge.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _VisitInformation extends StatelessWidget {
  const _VisitInformation({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final careTeam = _InformationCard(
      icon: Icons.medical_services_outlined,
      title: 'Care team and clinic',
      children: [
        _InformationRow(
          icon: Icons.person_outline_rounded,
          label: 'Health worker',
          value: appointment.clinicianName ?? 'Health worker',
        ),
        if (appointment.clinicianTitle?.isNotEmpty == true ||
            appointment.clinicianSpeciality?.isNotEmpty == true)
          _InformationRow(
            icon: Icons.badge_outlined,
            label: 'Role or speciality',
            value: [
              appointment.clinicianTitle,
              appointment.clinicianSpeciality,
            ]
                .whereType<String>()
                .where((value) => value.trim().isNotEmpty)
                .join(' • '),
          ),
        _InformationRow(
          icon: Icons.local_hospital_outlined,
          label: 'Clinic',
          value: appointment.clinicName ?? 'Clinic',
        ),
        if (appointment.clinicAddress?.isNotEmpty == true)
          _InformationRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: appointment.clinicAddress!,
          ),
      ],
    );
    final booking = _InformationCard(
      icon: Icons.event_note_outlined,
      title: 'Booking information',
      children: [
        _InformationRow(
          icon: Icons.health_and_safety_outlined,
          label: 'Appointment type',
          value: _typeLabel(appointment.appointmentType),
        ),
        if (appointment.reason?.isNotEmpty == true)
          _InformationRow(
            icon: Icons.notes_rounded,
            label: 'Reason for visit',
            value: appointment.reason!,
          ),
        if (appointment.notes?.isNotEmpty == true)
          _InformationRow(
            icon: Icons.description_outlined,
            label: 'Booking notes',
            value: appointment.notes!,
          ),
        _InformationRow(
          icon: Icons.mobile_friendly_outlined,
          label: 'Booked through',
          value: _typeLabel(appointment.source),
        ),
        _InformationRow(
          icon: Icons.schedule_outlined,
          label: 'Booked on',
          value: DateFormat('d MMM y, h:mm a')
              .format(appointment.createdAt.toLocal()),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [careTeam, const SizedBox(height: 14), booking],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: careTeam),
            const SizedBox(width: 14),
            Expanded(child: booking),
          ],
        );
      },
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.appointment, required this.message});

  final Appointment appointment;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = _appointmentStatus(appointment.status, theme);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.foreground.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: status.foreground, size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DawaStatusTransition(
                  label: status.label,
                  icon: status.icon,
                  color: status.foreground,
                ),
                const SizedBox(height: 3),
                Text(
                  message,
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

class _CancellationSyncNotice extends StatelessWidget {
  const _CancellationSyncNotice({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final failed = appointment.integrationStatus == 'failed';
    return DawaActionFeedback(
      title: failed
          ? 'Cancellation has not reached the clinic'
          : 'Cancellation pending sync',
      message: failed
          ? 'Contact the clinic if you need immediate confirmation.'
          : "We'll update the clinic when you're connected.",
      tone: failed ? DawaFeedbackTone.error : DawaFeedbackTone.pending,
    );
  }
}

class _ResultPendingCard extends StatelessWidget {
  const _ResultPendingCard({
    required this.loading,
    required this.failed,
    required this.onRefresh,
  });

  final bool loading;
  final bool failed;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final icon = Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    failed ? Icons.sync_problem_rounded : Icons.sync_rounded,
                    color: theme.primary,
                  ),
          );
          final message = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                failed
                    ? 'Care summary is still on its way'
                    : 'Preparing your care summary',
                style: theme.titleMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                failed
                    ? 'Your appointment is complete. The secure clinic connection will retry the summary safely.'
                    : 'Your appointment is complete. High-level results will appear here when the secure clinic update arrives.',
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                  height: 1.45,
                ),
              ),
              if (!loading) ...[
                const SizedBox(height: 11),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check again'),
                ),
              ],
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 14), message],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: message),
            ],
          );
        },
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.bodyMedium.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelPanel extends StatelessWidget {
  const _CancelPanel({required this.cancelling, required this.onCancel});

  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.alternate),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final action = OutlinedButton.icon(
            onPressed: cancelling ? null : onCancel,
            icon: cancelling
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_busy_outlined),
            label: Text(cancelling ? 'Cancelling…' : 'Cancel appointment'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.error,
              side: BorderSide(color: theme.error.withValues(alpha: 0.55)),
              minimumSize: const Size(190, 46),
            ),
          );
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need to change your plans?',
                style: theme.titleSmall.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Cancel this appointment to release the time for another patient.',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 12), action],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _MissingAppointment extends StatelessWidget {
  const _MissingAppointment();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 42,
              color: theme.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'This appointment is no longer available.',
              textAlign: TextAlign.center,
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.onRetry});

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
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: theme.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'Appointment details could not be loaded.',
              textAlign: TextAlign.center,
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentStatus {
  const _AppointmentStatus({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
}

_AppointmentStatus _appointmentStatus(
  String value,
  FlutterFlowTheme theme,
) {
  return switch (value) {
    'completed' => const _AppointmentStatus(
        label: 'Completed',
        icon: Icons.check_circle_outline_rounded,
        foreground: Color(0xFF15803D),
        background: Color(0xFFECFDF3),
      ),
    'confirmed' => _AppointmentStatus(
        label: 'Confirmed',
        icon: Icons.event_available_outlined,
        foreground: theme.primary,
        background: theme.primary.withValues(alpha: 0.08),
      ),
    'rescheduled' => const _AppointmentStatus(
        label: 'Rescheduled',
        icon: Icons.event_repeat_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFFBEB),
      ),
    'cancelled' => _AppointmentStatus(
        label: 'Cancelled',
        icon: Icons.event_busy_outlined,
        foreground: theme.error,
        background: const Color(0xFFFFF1F2),
      ),
    'declined' => _AppointmentStatus(
        label: 'Declined',
        icon: Icons.block_outlined,
        foreground: theme.error,
        background: const Color(0xFFFFF1F2),
      ),
    _ => const _AppointmentStatus(
        label: 'Pending confirmation',
        icon: Icons.schedule_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFFBEB),
      ),
  };
}

String _typeLabel(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
