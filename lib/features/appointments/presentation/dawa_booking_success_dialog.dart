import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/design_system/dawa_interactions.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/feedback/dawa_feedback_effects.dart';
import 'dawa_appointment_reminder_sheet.dart';

Future<void> showDawaBookingSuccessDialog(
  BuildContext context,
  Appointment appointment, {
  AppointmentBookingResult? result,
}) async {
  final confirmed = appointment.status == 'confirmed';
  final paid = result?.paymentSucceeded == true;
  final paymentPending = const {'pending', 'created'}
      .contains(result?.paymentStatus.toLowerCase());
  final payAtClinic =
      result?.paymentMethod == 'cash' || appointment.paymentMethod == 'cash';
  final paymentNotRequired = result?.paymentStatus == 'not_required';
  final heading = paid
      ? 'Payment confirmed'
      : paymentPending
          ? 'Payment still pending'
          : payAtClinic
              ? 'Appointment requested'
              : confirmed
                  ? 'Appointment confirmed!'
                  : 'Appointment request sent';
  final supportingCopy = paid
      ? 'Your payment was confirmed. The clinic is reviewing your appointment request.'
      : paymentPending
          ? 'Approve the Mobile Money request on your phone. We will send the appointment request to the clinic after payment is confirmed.'
          : payAtClinic
              ? 'You can pay in cash when you arrive. The clinic is reviewing your appointment request.'
              : confirmed
                  ? 'Your clinic visit has been confirmed.'
                  : 'The clinic is reviewing your request. DawaMom will update this page after it is accepted.';
  final feedbackTone = paid
      ? DawaFeedbackTone.success
      : paymentPending
          ? DawaFeedbackTone.pending
          : DawaFeedbackTone.information;
  final feedbackTitle = paid
      ? 'Payment confirmed'
      : paymentPending
          ? 'Payment request sent'
          : confirmed
              ? 'Appointment confirmed'
              : 'Appointment request sent';
  final feedbackMessage = paid
      ? 'Your payment has been confirmed. Your clinic will now review the appointment request.'
      : paymentPending
          ? 'We are waiting for your Mobile Money approval. You can check the status in appointment details.'
          : supportingCopy;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close booking confirmation',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              DawaActionFeedback(
                title: feedbackTitle,
                message: feedbackMessage,
                tone: feedbackTone,
              ),
              if (confirmed) ...[
                const SizedBox(height: 8),
                const Center(
                  child: DawaOptionalFeedbackAnimation(
                    asset: 'assets/lotties/Book.json',
                    semanticLabel: 'Appointment confirmed',
                    height: 88,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DawaCard(
                padding: EdgeInsets.zero,
                color: paid || confirmed
                    ? DawaColors.softGreen
                    : DawaColors.softBlue,
                borderColor: paid || confirmed
                    ? DawaColors.green.withValues(alpha: .28)
                    : DawaColors.primary.withValues(alpha: .2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paid
                                ? 'PAYMENT CONFIRMED'
                                : paymentPending
                                    ? 'PAYMENT PENDING'
                                    : confirmed
                                        ? 'BOOKING CONFIRMED'
                                        : 'REQUEST RECEIVED',
                            style: dialogContext.dawaCaption.copyWith(
                              color: DawaColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            heading,
                            style: dialogContext.dawaTitle,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${appointment.clinicName ?? 'Your selected clinic'}\n'
                            '${DateFormat('EEEE, d MMMM').format(appointment.date)} • '
                            '${DateFormat.jm().format(Appointment.dateAtTime(appointment.date, appointment.startTime))}'
                            '${appointment.clinicianName?.trim().isNotEmpty == true ? '\nWith ${appointment.clinicianName}' : ''}\n'
                            '$supportingCopy',
                            style: dialogContext.dawaBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _BookingStateSummary(
                paymentLabel: paid
                    ? 'Paid${result?.paymentAmount == null ? '' : ' · ${result!.paymentCurrency} ${result.paymentAmount!.toStringAsFixed(2)}'}'
                    : paymentPending
                        ? 'Waiting for Mobile Money approval'
                        : payAtClinic
                            ? 'Pay at clinic'
                            : paymentNotRequired
                                ? 'No payment due'
                                : 'Payment processing',
                appointmentLabel: confirmed
                    ? 'Confirmed'
                    : paymentPending
                        ? 'Will be sent after payment'
                        : 'Awaiting confirmation',
                paymentSuccessful: paid,
                paymentPending: paymentPending,
                paymentReference: result?.paymentReference,
              ),
              const SizedBox(height: 12),
              DawaCard(
                color: DawaColors.softBlue,
                child: Row(
                  children: [
                    const DawaIconBadge(
                      icon: Icons.notifications_active_outlined,
                      color: DawaColors.primary,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stay prepared',
                            style: dialogContext.dawaSectionTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose when and how DawaMom should remind you about this visit.',
                            style: dialogContext.dawaCaption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!paymentPending)
                DawaPrimaryButton(
                  label: 'Set a reminder',
                  icon: Icons.notifications_active_outlined,
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: .46),
                      builder: (_) => DawaAppointmentReminderSheet(
                        appointment: appointment,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              DawaSecondaryButton(
                label: paymentPending
                    ? 'Check payment status'
                    : 'View appointment',
                icon: Icons.event_note_outlined,
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.push(
                    '/appointmentDetails?appointmentId=${appointment.id}',
                  );
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done for now'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BookingStateSummary extends StatelessWidget {
  const _BookingStateSummary({
    required this.paymentLabel,
    required this.appointmentLabel,
    required this.paymentSuccessful,
    required this.paymentPending,
    this.paymentReference,
  });

  final String paymentLabel;
  final String appointmentLabel;
  final bool paymentSuccessful;
  final bool paymentPending;
  final String? paymentReference;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: context.dawaCaption),
            const SizedBox(height: 3),
            DawaStatusTransition(
              label: paymentSuccessful
                  ? 'Payment confirmed'
                  : paymentPending
                      ? 'Payment pending'
                      : paymentLabel,
              icon: paymentSuccessful
                  ? Icons.check_circle_outline_rounded
                  : paymentPending
                      ? Icons.schedule_rounded
                      : Icons.payments_outlined,
              color: paymentSuccessful
                  ? DawaColors.greenDark
                  : paymentPending
                      ? DawaColors.primary
                      : DawaColors.textSecondary,
            ),
            if (paymentReference?.isNotEmpty == true)
              Text('Reference: $paymentReference', style: context.dawaCaption),
            const SizedBox(height: 12),
            Text('Appointment status', style: context.dawaCaption),
            const SizedBox(height: 3),
            DawaStatusTransition(
              label: appointmentLabel,
              icon: appointmentLabel == 'Confirmed'
                  ? Icons.event_available_outlined
                  : Icons.schedule_rounded,
              color: appointmentLabel == 'Confirmed'
                  ? DawaColors.greenDark
                  : DawaColors.primary,
            ),
            if (paymentPending)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'The clinic will receive your appointment request after payment is confirmed.',
                  style: context.dawaCaption,
                ),
              ),
          ],
        ),
      );
}
