import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/features/appointments/domain/appointment.dart';
import 'dawa_appointment_reminder_sheet.dart';

Future<void> showDawaBookingSuccessDialog(
  BuildContext context,
  Appointment appointment,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: DawaColors.green.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: DawaColors.green,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Appointment booked!',
                textAlign: TextAlign.center,
                style: dialogContext.dawaTitle,
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormat('EEEE, d MMMM').format(appointment.date)} at '
                '${DateFormat.jm().format(Appointment.dateAtTime(appointment.date, appointment.startTime))}',
                textAlign: TextAlign.center,
                style: dialogContext.dawaBody,
              ),
              const SizedBox(height: 4),
              Text(
                appointment.clinicName ?? 'Your selected clinic',
                textAlign: TextAlign.center,
                style: dialogContext.dawaCaption,
              ),
              const SizedBox(height: 20),
              DawaPrimaryButton(
                label: 'Set a reminder',
                icon: Icons.notifications_active_outlined,
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DawaAppointmentReminderSheet(
                      appointment: appointment,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
