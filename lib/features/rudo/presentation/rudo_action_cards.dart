import 'package:flutter/material.dart';

import '/features/payments/data/lipila_payment_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Structured booking widgets rendered under a Rudo assistant chat bubble
/// when `ChatMessage.action` is present. These reuse the exact same real
/// data (services, clinics, slots, appointments) returned by the
/// `rudo-chat` Edge Function's booking pipeline; nothing here is
/// generated or guessed on the client.
///
/// [onSendAction] sends a reserved `__rudo_action__:{...}` payload back to
/// Rudo (via the caller's `_sendMessage`), while [displayText] is shown in
/// the local user bubble instead of the raw JSON.
class RudoActionCard extends StatelessWidget {
  const RudoActionCard({
    super.key,
    required this.action,
    required this.onSendAction,
  });

  final Map<String, dynamic> action;
  final void Function(String actionJson, String displayText) onSendAction;

  @override
  Widget build(BuildContext context) {
    switch (action['type']) {
      case 'service_options':
        return _ServiceOptions(
          services: List<Map<String, dynamic>>.from(
            (action['services'] as List? ?? const []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          onSendAction: onSendAction,
        );
      case 'clinic_options':
        return _ClinicOptions(
          clinics: List<Map<String, dynamic>>.from(
            (action['clinics'] as List? ?? const []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          onSendAction: onSendAction,
        );
      case 'slot_options':
        return _SlotOptions(
          slots: List<Map<String, dynamic>>.from(
            (action['slots'] as List? ?? const []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          onSendAction: onSendAction,
        );
      case 'booking_summary':
        return _BookingSummaryCard(
          summary: Map<String, dynamic>.from(action['summary'] as Map? ?? const {}),
          onSendAction: onSendAction,
        );
      case 'payment_required':
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 38),
          child: Text(
            'Payment needed',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      case 'booking_success':
        return _BookingSuccessCard(
          appointment: Map<String, dynamic>.from(
            action['appointment'] as Map? ?? const {},
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

String _rudoAction(String type, [Map<String, dynamic>? extra]) {
  final payload = {'type': type, ...?extra};
  final buffer = StringBuffer('__rudo_action__:');
  buffer.write(_encodeJson(payload));
  return buffer.toString();
}

// Minimal, dependency-free JSON encoder for the small reserved payloads used
// here (avoids importing dart:convert twice at call sites).
String _encodeJson(Map<String, dynamic> map) {
  final entries = map.entries.map((e) {
    final value = e.value;
    final encoded = value is String ? '"${value.replaceAll('"', '\\"')}"' : value.toString();
    return '"${e.key}":$encoded';
  }).join(',');
  return '{$entries}';
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 38),
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
    );
  }
}

class _ServiceOptions extends StatelessWidget {
  const _ServiceOptions({required this.services, required this.onSendAction});
  final List<Map<String, dynamic>> services;
  final void Function(String, String) onSendAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 38, top: 8),
          child: Text(
            'Select a service',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        _ChipWrap(
          children: services.map((service) {
            final name = service['name']?.toString() ?? 'Service';
            final isPaid = service['is_paid'] == true;
            final price = (service['price'] as num?)?.toDouble() ?? 0;
            final currency = service['currency']?.toString() ?? 'ZMW';
            final label = isPaid ? '$name · $currency ${price.toStringAsFixed(0)}' : name;
            return ActionChip(
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              backgroundColor: theme.primary.withValues(alpha: 0.08),
              onPressed: () => onSendAction(
                _rudoAction('select_service', {'service_id': service['id']}),
                name,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ClinicOptions extends StatelessWidget {
  const _ClinicOptions({required this.clinics, required this.onSendAction});
  final List<Map<String, dynamic>> clinics;
  final void Function(String, String) onSendAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 38, top: 8),
          child: Text(
            'Select a clinic',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        _ChipWrap(
          children: clinics.map((clinic) {
            final name = clinic['name']?.toString() ?? 'Clinic';
            return ActionChip(
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              backgroundColor: theme.primary.withValues(alpha: 0.08),
              onPressed: () => onSendAction(
                _rudoAction('select_clinic', {'clinic_id': clinic['id']}),
                name,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SlotOptions extends StatelessWidget {
  const _SlotOptions({required this.slots, required this.onSendAction});
  final List<Map<String, dynamic>> slots;
  final void Function(String, String) onSendAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 38, top: 8),
          child: Text(
            'Choose a time',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        _ChipWrap(
          children: slots.map((slot) {
            final date = slot['date']?.toString() ?? '';
            final start = slot['startTime']?.toString() ?? '';
            final clinicianName = slot['clinicianName']?.toString() ?? '';
            final label = '$date $start · $clinicianName';
            return ActionChip(
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              backgroundColor: theme.primary.withValues(alpha: 0.08),
              onPressed: () => onSendAction(
                _rudoAction('select_slot', {'index': slot['index']}),
                label,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({required this.summary, required this.onSendAction});
  final Map<String, dynamic> summary;
  final void Function(String, String) onSendAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isPaid = summary['isPaid'] == true;
    final price = (summary['price'] as num?)?.toDouble() ?? 0;
    final currency = summary['currency']?.toString() ?? 'ZMW';

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 38, right: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary['serviceName']?.toString() ?? 'Appointment',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text('${summary['date'] ?? ''} · ${summary['startTime'] ?? ''}'),
            Text(summary['clinicName']?.toString() ?? ''),
            Text(summary['clinicianName']?.toString() ?? 'Any available clinician'),
            const SizedBox(height: 4),
            Text(
              isPaid ? '$currency ${price.toStringAsFixed(2)}' : 'Free',
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.primary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        onSendAction(_rudoAction('change'), 'Change details'),
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
                    onPressed: () =>
                        onSendAction(_rudoAction('confirm'), 'Confirm appointment'),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSuccessCard extends StatelessWidget {
  const _BookingSuccessCard({required this.appointment});
  final Map<String, dynamic> appointment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 38, right: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['serviceName']?.toString() ?? 'Appointment booked',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                  ),
                  Text('${appointment['date'] ?? ''} · ${appointment['startTime'] ?? ''}'),
                  Text(appointment['clinicName']?.toString() ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Handles the payment_required action by reusing the exact same
/// [LipilaPaymentRepository] the normal booking sheet uses; no new
/// payment logic is implemented here.
class _PaymentCard extends StatefulWidget {
  const _PaymentCard({required this.appointment});
  final Map<String, dynamic> appointment;

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

enum _PaymentCardStatus { idle, pending, success, failed }

class _PaymentCardState extends State<_PaymentCard> {
  final _repository = LipilaPaymentRepository();
  final _phoneController = TextEditingController();
  _PaymentCardStatus _status = _PaymentCardStatus.idle;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final appointmentId = widget.appointment['id']?.toString();
    if (appointmentId == null || appointmentId.isEmpty) return;
    setState(() {
      _status = _PaymentCardStatus.pending;
      _error = null;
    });
    try {
      final start = await _repository.createPayment(
        appointmentId: appointmentId,
        phoneNumber: _phoneController.text,
      );
      var status = start.status;
      for (var i = 0; i < 10 && status == 'pending'; i++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        final polled = await _repository.getStatus(start.paymentId);
        status = polled.status;
      }
      if (!mounted) return;
      setState(() {
        _status = status == 'completed' || status == 'success'
            ? _PaymentCardStatus.success
            : status == 'pending'
                ? _PaymentCardStatus.pending
                : _PaymentCardStatus.failed;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _PaymentCardStatus.failed;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final appointment = widget.appointment;
    final price = (appointment['price'] as num?)?.toDouble() ?? 0;
    final currency = appointment['currency']?.toString() ?? 'ZMW';

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 38, right: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment['serviceName']?.toString() ?? 'Appointment',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
            ),
            Text('$currency ${price.toStringAsFixed(2)} · ${appointment['date'] ?? ''} ${appointment['startTime'] ?? ''}'),
            const SizedBox(height: 8),
            if (_status == _PaymentCardStatus.success)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 6),
                  const Text('Payment received'),
                ],
              )
            else if (_status == _PaymentCardStatus.pending)
              const Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Waiting for payment confirmation...'),
                ],
              )
            else ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Money number',
                  hintText: '0970 000 000',
                  isDense: true,
                ),
                keyboardType: TextInputType.phone,
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
                  onPressed: _pay,
                  child: const Text('Pay now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
