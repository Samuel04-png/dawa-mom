import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/features/appointments/domain/appointment.dart';
import 'dawa_appointment_reminder_sheet.dart';

Future<void> showDawaBookingSuccessDialog(
  BuildContext context,
  Appointment appointment, {
  AppointmentBookingResult? result,
}) async {
  final confirmed = appointment.status == 'confirmed';
  final paid = result?.paymentSucceeded == true;
  final payAtClinic =
      result?.paymentMethod == 'cash' || appointment.paymentMethod == 'cash';
  final paymentNotRequired = result?.paymentStatus == 'not_required';
  final heading = paid
      ? 'Payment successful'
      : payAtClinic
          ? 'Appointment requested'
          : confirmed
              ? 'Appointment confirmed!'
              : 'Appointment request sent';
  final supportingCopy = paid
      ? 'Your payment was received. The clinic is reviewing your appointment request.'
      : payAtClinic
          ? 'You can pay in cash when you arrive. The clinic is reviewing your appointment request.'
          : confirmed
              ? 'Your clinic visit has been confirmed.'
              : 'The clinic is reviewing your request. DawaMom will update this page after it is accepted.';
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
                                ? 'PAYMENT RECEIVED'
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
                    : payAtClinic
                        ? 'Pay at clinic'
                        : paymentNotRequired
                            ? 'No payment due'
                            : 'Payment processing',
                appointmentLabel:
                    confirmed ? 'Confirmed' : 'Awaiting confirmation',
                paymentSuccessful: paid,
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
                label: 'View appointment',
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
    this.paymentReference,
  });

  final String paymentLabel;
  final String appointmentLabel;
  final bool paymentSuccessful;
  final String? paymentReference;

  @override
  Widget build(BuildContext context) => DawaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: context.dawaCaption),
            const SizedBox(height: 3),
            Text(paymentSuccessful ? 'Payment successful' : paymentLabel,
                style: context.dawaSectionTitle),
            if (paymentSuccessful && paymentReference?.isNotEmpty == true)
              Text('Reference: $paymentReference', style: context.dawaCaption),
            const SizedBox(height: 12),
            Text('Appointment status', style: context.dawaCaption),
            const SizedBox(height: 3),
            Text(appointmentLabel, style: context.dawaSectionTitle),
            if (!paymentSuccessful && paymentLabel == 'Payment processing')
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'We are still waiting for the payment provider to confirm the transaction.',
                  style: context.dawaCaption,
                ),
              ),
          ],
        ),
      );
}
