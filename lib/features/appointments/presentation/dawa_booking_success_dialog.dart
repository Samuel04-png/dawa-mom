import '/localization/dawa_localized_material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/content/dawa_learning_asset_registry.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_contextual_image.dart';
import '/design_system/dawa_design_tokens.dart';
import '/features/appointments/domain/appointment.dart';
import 'dawa_appointment_reminder_sheet.dart';

Future<void> showDawaBookingSuccessDialog(
  BuildContext context,
  Appointment appointment,
) async {
  final confirmed = appointment.status == 'confirmed';
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
                color: DawaColors.softGreen,
                borderColor: DawaColors.green.withValues(alpha: .28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DawaContextualImage(
                      assetId: 'clinic_visit_02',
                      variant: DawaImageVariant.featuredBanner,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(DawaRadii.medium),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            confirmed
                                ? 'BOOKING CONFIRMED'
                                : 'REQUEST RECEIVED',
                            style: dialogContext.dawaCaption.copyWith(
                              color: DawaColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            confirmed
                                ? 'Appointment confirmed!'
                                : 'Appointment request sent',
                            style: dialogContext.dawaTitle,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${appointment.clinicName ?? 'Your selected clinic'}\n'
                            '${DateFormat('EEEE, d MMMM').format(appointment.date)} • '
                            '${DateFormat.jm().format(Appointment.dateAtTime(appointment.date, appointment.startTime))}'
                            '${appointment.clinicianName?.trim().isNotEmpty == true ? '\nWith ${appointment.clinicianName}' : ''}'
                            '${confirmed ? '' : '\nThe clinic is reviewing your request. DawaMom will show “Confirmed” after it is accepted.'}',
                            style: dialogContext.dawaBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
