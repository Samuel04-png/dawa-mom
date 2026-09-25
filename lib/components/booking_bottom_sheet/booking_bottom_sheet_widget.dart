import '/localization/dawa_localized_material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '/features/appointments/data/appointment_repository.dart';
import '/features/appointments/data/clinician_directory_repository.dart';
import '/features/appointments/domain/appointment.dart';
import '/features/services/data/service_catalog_repository.dart';
import '/features/services/domain/service_catalog_item.dart';
import '/features/payments/data/lipila_payment_repository.dart';
import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';
import '/flutter_flow/flutter_flow_theme.dart';

export 'booking_bottom_sheet_model.dart';

enum _BookingState { ready, loading, success, error }

enum _PaymentChoice { online, cash }

class BookingBottomSheetWidget extends StatefulWidget {
  const BookingBottomSheetWidget({
    super.key,
    this.initialClinicId,
  });

  final String? initialClinicId;

  @override
  State<BookingBottomSheetWidget> createState() =>
      _BookingBottomSheetWidgetState();
}

class _BookingBottomSheetWidgetState extends State<BookingBottomSheetWidget> {
  late final SupabaseClinicianDirectoryRepository _clinicianDirectory;
  late final AppointmentRepository _appointments;
  late final ServiceCatalogRepository _services;
  late final LipilaPaymentRepository _payments;
  final _reasonController = TextEditingController();
  String _idempotencyKey = Uuid().v4();
  List<ServiceCatalogItem> _serviceOptions = const [];
  ServiceCatalogItem? _selectedService;
  _PaymentChoice _paymentChoice = _PaymentChoice.online;

  List<ClinicOption> _clinics = const [];
  List<ClinicianProfile> _clinicians = const [];
  List<AppointmentSlot> _slots = const [];
  ClinicOption? _selectedClinic;
  ClinicianProfile? _selectedClinician;
  AppointmentSlot? _selectedSlot;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  bool _loadingDirectory = true;
  bool _loadingClinicians = false;
  bool _loadingSlots = false;
  _BookingState _bookingState = _BookingState.ready;
  String? _formError;
  String? _clinicError;
  String? _clinicianError;
  String? _dateError;
  String? _timeError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _clinicianDirectory = SupabaseClinicianDirectoryRepository();
    _appointments = AppointmentRepository(
      clinicianDirectory: _clinicianDirectory,
    );
    _services = ServiceCatalogRepository();
    _payments = LipilaPaymentRepository();
    _loadClinics();
    _loadServices();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    try {
      try {
        await _clinicianDirectory.refreshClinicianDirectory();
      } catch (_) {
        // Keep the previously imported booking-safe cache available as a
        // degraded fallback; clinic selection shows a retry state if no
        // mapped clinicians can be loaded.
      }
      final directoryClinicians = await _clinicianDirectory.getClinicians();
      final activeClinicIds = directoryClinicians
          .where((clinician) => clinician.isActive && clinician.isBookable)
          .map((clinician) => clinician.clinicId)
          .toSet();
      final clinics = (await _appointments.getClinics())
          .where((clinic) => activeClinicIds.contains(clinic.id))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _clinics = clinics;
        _loadingDirectory = false;
        if (clinics.isEmpty) {
          _formError = 'No clinics are available for booking right now.';
        } else if (_clinicianDirectory.isUsingCachedDirectory) {
          _formError =
              'Showing the last saved health worker list. Connect to the internet to see live times.';
        }
      });
      if (widget.initialClinicId != null &&
          clinics.any((clinic) => clinic.id == widget.initialClinicId)) {
        await _selectClinic(widget.initialClinicId);
      }
    } on AppointmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingDirectory = false;
        _formError = error.message;
        _bookingState = _BookingState.error;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingState = _BookingState.error;
        _formError = error.message;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingState = _BookingState.error;
        _formError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDirectory = false;
        _formError = 'Clinics could not be loaded. Please try again.';
        _bookingState = _BookingState.error;
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      final services = await _services.getActiveServices();
      if (!mounted) return;
      setState(() {
        _serviceOptions = services;
        _selectedService = services.isNotEmpty ? services.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _formError = 'Services could not be loaded. Please try again.');
    }
  }

  Future<void> _selectClinic(String? id) async {
    final clinic = _clinics.where((item) => item.id == id).firstOrNull;
    setState(() {
      _selectedClinic = clinic;
      _selectedClinician = null;
      _selectedSlot = null;
      _clinicians = const [];
      _slots = const [];
      _clinicError = null;
      _clinicianError = null;
      _timeError = null;
      _formError = null;
      _bookingState = _BookingState.ready;
      _loadingClinicians = clinic != null;
    });
    if (clinic == null) return;

    try {
      final clinicians =
          await _clinicianDirectory.getCliniciansByClinic(clinic.id);
      if (!mounted || _selectedClinic?.id != clinic.id) return;
      setState(() {
        _clinicians = clinicians;
        _loadingClinicians = false;
        if (clinicians.isEmpty) {
          _clinicianError =
              'No health workers can be booked at this clinic right now.';
        } else if (_clinicianDirectory.isUsingCachedDirectory) {
          _formError =
              'Showing the last saved health worker list. Connect to the internet to see live times.';
        }
      });
    } catch (_) {
      if (!mounted || _selectedClinic?.id != clinic.id) return;
      setState(() {
        _loadingClinicians = false;
        _clinicianError =
            'Health workers did not load. Choose the clinic again.';
      });
    }
  }

  Future<void> _selectClinician(String? id) async {
    final clinician = _clinicians.where((item) => item.id == id).firstOrNull;
    setState(() {
      _selectedClinician = clinician;
      _selectedSlot = null;
      _slots = const [];
      _clinicianError = null;
      _timeError = null;
      _formError = null;
      _bookingState = _BookingState.ready;
    });
    await _loadSlots();
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedSlot = null;
      _slots = const [];
      _dateError = null;
      _timeError = null;
      _formError = null;
      _bookingState = _BookingState.ready;
    });
    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    final clinician = _selectedClinician;
    if (clinician == null) return;
    setState(() => _loadingSlots = true);
    try {
      final slots = await _clinicianDirectory.getClinicianAvailability(
        clinician.id,
        _selectedDate,
      );
      if (!mounted || _selectedClinician?.id != clinician.id) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
        if (!slots.any((slot) => slot.isAvailable)) {
          _timeError = 'No appointment times are available on this date.';
        }
      });
    } on AppointmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSlots = false;
        _timeError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSlots = false;
        _timeError = 'Appointment times could not be loaded. Please retry.';
      });
    }
  }

  bool _validate() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    setState(() {
      _clinicError = _selectedClinic == null ? 'Please select a clinic.' : null;
      _clinicianError =
          _selectedClinician == null ? 'Please choose a health worker.' : null;
      _dateError = _selectedDate.isBefore(normalizedToday)
          ? 'Please choose a date in the future.'
          : null;
      _timeError =
          _selectedSlot == null ? 'Please choose an appointment time.' : null;
      _formError = null;
    });
    return _clinicError == null &&
        _clinicianError == null &&
        _dateError == null &&
        _timeError == null;
  }

  Future<void> _book() async {
    if (_bookingState == _BookingState.loading || !_validate()) return;
    final clinic = _selectedClinic!;
    final clinician = _selectedClinician!;
    final slot = _selectedSlot!;
    setState(() {
      _bookingState = _BookingState.loading;
      _formError = null;
      _successMessage = null;
    });

    try {
      final appointment = await _appointments.bookAppointment(
        clinicId: clinic.id,
        clinicianId: clinician.id,
        date: _selectedDate,
        slot: slot,
        reason: _reasonController.text,
        idempotencyKey: _idempotencyKey,
        service: _selectedService,
        paymentMethod:
            _paymentChoice == _PaymentChoice.cash ? 'cash' : 'online',
      );
      if (!mounted) return;
      var paymentStatus = 'not_required';
      String? paymentReference;
      double? paymentAmount;
      String? paymentCurrency;
      if (appointment.isPaidSnapshot) {
        if (_paymentChoice == _PaymentChoice.cash) {
          _successMessage =
              'Your appointment request has been sent. Payment is due at the clinic.';
        } else {
          var paymentCreated = false;
          try {
            final phoneNumber = await _requestPaymentPhone();
            if (phoneNumber == null || !mounted) {
              await _cancelUnpaidAppointment(appointment.id);
              return;
            }
            final payment = await _payments.createPayment(
              appointmentId: appointment.id,
              phoneNumber: phoneNumber,
            );
            paymentCreated = true;
            paymentReference = payment.referenceId;
            paymentAmount = payment.amount;
            paymentCurrency = payment.currency;
            paymentStatus = await _showPaymentProgress(payment);
            if (paymentStatus != 'successful') {
              // The Mobile Money request was declined or cancelled on the
              // phone; the appointment must not remain booked without payment.
              if (const {'failed', 'cancelled', 'expired'}
                  .contains(paymentStatus)) {
                await _cancelUnpaidAppointment(appointment.id);
              }
              throw StateError(
                _paymentStatusMessage(paymentStatus),
              );
            }
            _successMessage =
                'Payment received: ${payment.currency} ${payment.amount.toStringAsFixed(2)}. Your appointment request has been sent to the clinic.';
          } catch (_) {
            if (!paymentCreated) {
              await _cancelUnpaidAppointment(appointment.id);
            }
            rethrow;
          }
        }
      } else {
        _successMessage =
            'Your appointment request has been sent to the clinic.';
      }
      setState(() => _bookingState = _BookingState.success);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      if (mounted) {
        Navigator.of(context).pop(
          AppointmentBookingResult(
            appointment: appointment,
            paymentStatus: paymentStatus,
            paymentMethod:
                _paymentChoice == _PaymentChoice.cash ? 'cash' : 'online',
            paymentAmount: paymentAmount,
            paymentCurrency: paymentCurrency,
            paymentReference: paymentReference,
          ),
        );
      }
    } on AppointmentException catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingState = _BookingState.error;
        _formError = error.message;
        _idempotencyKey = Uuid().v4();
      });
      if (error.retryable) {
        await _loadSlots();
      }
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingState = _BookingState.error;
        _formError = error.message;
        _idempotencyKey = Uuid().v4();
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingState = _BookingState.error;
        _formError = error.message;
        _idempotencyKey = Uuid().v4();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookingState = _BookingState.error;
        _formError = 'We could not book your appointment. Please try again.';
        _idempotencyKey = Uuid().v4();
      });
    }
  }

  Future<void> _cancelUnpaidAppointment(String appointmentId) async {
    try {
      await _appointments.cancelAppointment(appointmentId);
    } catch (_) {
      // Preserve the payment error shown to the user; cleanup is retryable.
    }
  }

  Future<String> _showPaymentProgress(LipilaPaymentStart payment) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var status = 'pending';
        var checking = false;
        var started = false;
        var attempts = 0;
        var dialogOpen = true;
        late StateSetter setDialogState;
        late Future<void> Function() poll;

        poll = () async {
          if (checking) return;
          checking = true;
          try {
            final result = await _payments.getStatus(payment.paymentId);
            status = result.status;
            attempts++;
            if (dialogOpen &&
                dialogContext.mounted &&
                !{'pending', 'created'}.contains(status)) {
              dialogOpen = false;
              Navigator.pop(dialogContext, status);
              return;
            }
            if (dialogOpen && dialogContext.mounted) {
              setDialogState(() {});
            }
          } catch (_) {
            status = 'check_error';
            if (dialogOpen && dialogContext.mounted) {
              setDialogState(() {});
            }
          } finally {
            checking = false;
          }
        };

        if (!started) {
          started = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            for (var attempt = 0; attempt < 15; attempt++) {
              if (!dialogOpen || !dialogContext.mounted) return;
              await poll();
              if (!dialogOpen ||
                  !dialogContext.mounted ||
                  !{'pending', 'created', 'check_error'}.contains(status)) {
                return;
              }
              await Future<void>.delayed(const Duration(seconds: 2));
            }
            if (dialogOpen && dialogContext.mounted) {
              status = 'pending_timeout';
              setDialogState(() {});
            }
          });
        }

        final waiting = status == 'pending' || status == 'created';
        final terminal =
            !waiting && status != 'check_error' && status != 'pending_timeout';
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            setDialogState = dialogSetState;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    terminal
                        ? (status == 'successful'
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded)
                        : Icons.phone_iphone_rounded,
                    color: terminal
                        ? (status == 'successful'
                            ? DawaColors.green
                            : DawaColors.danger)
                        : DawaColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      terminal
                          ? (status == 'successful'
                              ? 'Payment received'
                              : 'Payment not completed')
                          : 'Check your phone',
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (waiting || status == 'check_error') ...[
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    terminal
                        ? _paymentStatusMessage(status)
                        : status == 'check_error'
                            ? 'We could not check the payment status. It is safe to check again.'
                            : status == 'pending_timeout'
                                ? 'Still waiting. Approve the Mobile Money prompt if it is still on your phone.'
                                : "We've sent a payment request to your phone. Approve it to continue. Dawa is checking automatically.",
                    textAlign: TextAlign.center,
                  ),
                  if (attempts > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reference: ${payment.referenceId}',
                      style: TextStyle(
                        color: DawaColors.textMuted,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                if (!terminal)
                  TextButton(
                    onPressed: checking ? null : poll,
                    child: Text(checking ? 'Checking…' : 'Check again'),
                  ),
                if (!waiting ||
                    status == 'pending_timeout' ||
                    status == 'check_error')
                  TextButton(
                    onPressed: () {
                      dialogOpen = false;
                      Navigator.pop(dialogContext, status);
                    },
                    child: const Text('Done'),
                  ),
              ],
            );
          },
        );
      },
    );
    return result ?? 'pending';
  }

  static String _paymentStatusMessage(String status) {
    switch (status) {
      case 'successful':
        return 'Your appointment request has been sent to the clinic for confirmation.';
      case 'failed':
        return "The payment wasn't approved, so the appointment wasn't booked. You can try again.";
      case 'cancelled':
        return "The payment request was cancelled, so the appointment wasn't booked. You can try again.";
      case 'expired':
        return "The payment request expired, so the appointment wasn't booked. You can try again.";
      case 'pending_timeout':
        return 'The payment request is still pending. Check your phone, then try again if needed.';
      default:
        return "The payment wasn't completed, so the appointment wasn't booked. You can try again.";
    }
  }

  Future<String?> _requestPaymentPhone() async {
    var phoneNumber = '';
    final price = _selectedService?.displayPrice ?? '';
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (price.isNotEmpty) ...[
              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: DawaColors.primary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              "We'll send a payment request to your phone.",
              style: TextStyle(color: DawaColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.phone,
              autofocus: true,
              onChanged: (value) => phoneNumber = value,
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '0970 000 000',
                helperText: "You'll approve the payment on your phone.",
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: DawaColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dawa will never ask for your Mobile Money PIN.',
                    style: TextStyle(
                      color: DawaColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, phoneNumber),
            child: const Text('Send payment request'),
          ),
        ],
      ),
    );
    return value?.trim().isEmpty == true ? null : value?.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final media = MediaQuery.of(context);
    final compact = media.size.width < 700;
    final bottomPadding = media.viewInsets.bottom;

    return Align(
      alignment: compact ? Alignment.bottomCenter : Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: compact ? double.infinity : 720,
          constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
          margin: compact ? EdgeInsets.zero : const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(22),
              bottom: compact ? Radius.zero : const Radius.circular(22),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                offset: Offset(0, 12),
                color: Color(0x33000000),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                isSubmitting: _bookingState == _BookingState.loading,
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Flexible(
                child: _loadingDirectory
                    ? const SingleChildScrollView(
                        padding: EdgeInsets.all(DawaSpacing.md),
                        child: Column(
                          children: [
                            DawaLoadingSkeleton(
                              label: 'Loading clinics',
                              lines: 3,
                            ),
                            SizedBox(height: DawaSpacing.sm),
                            DawaLoadingSkeleton(lines: 2),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 28,
                          22,
                          compact ? 16 : 28,
                          20 + bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose a date, clinic, health worker and time.',
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedService?.id,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                context,
                                label: 'Service',
                              ),
                              hint: const Text('Select a service'),
                              items: _serviceOptions
                                  .map(
                                    (service) => DropdownMenuItem(
                                      value: service.id,
                                      child: Text(
                                        '${service.name} · ${service.displayPrice}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _bookingState == _BookingState.loading
                                  ? null
                                  : (id) => setState(() {
                                        _selectedService = _serviceOptions
                                            .where(
                                                (service) => service.id == id)
                                            .firstOrNull;
                                      }),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedService?.isPaid == true) ...[
                              Text(
                                'Payment method',
                                style: theme.titleSmall.copyWith(
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<_PaymentChoice>(
                                initialValue: _paymentChoice,
                                decoration: _inputDecoration(
                                  context,
                                  label: 'How would you like to pay?',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: _PaymentChoice.online,
                                    child: Text('Pay now · Mobile Money'),
                                  ),
                                  DropdownMenuItem(
                                    value: _PaymentChoice.cash,
                                    child: Text('Pay at clinic · Cash'),
                                  ),
                                ],
                                onChanged: _bookingState ==
                                        _BookingState.loading
                                    ? null
                                    : (value) => setState(() {
                                          _paymentChoice =
                                              value ?? _PaymentChoice.online;
                                        }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _paymentChoice == _PaymentChoice.cash
                                    ? 'Pay in cash when you arrive for your appointment.'
                                    : 'Use Mobile Money to pay before the clinic confirms your visit.',
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            _DateSection(
                              selectedDate: _selectedDate,
                              errorText: _dateError,
                              onSelected: _selectDate,
                            ),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<String>(
                              key: ValueKey('clinic-${_selectedClinic?.id}'),
                              initialValue: _selectedClinic?.id,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                context,
                                label: 'Clinic',
                                errorText: _clinicError,
                              ),
                              hint: const Text('Select a clinic'),
                              items: _clinics
                                  .map(
                                    (clinic) => DropdownMenuItem(
                                      value: clinic.id,
                                      child: Text(
                                        clinic.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _bookingState == _BookingState.loading
                                  ? null
                                  : _selectClinic,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                'clinician-${_selectedClinic?.id}-${_selectedClinician?.id}',
                              ),
                              initialValue: _selectedClinician?.id,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                context,
                                label: 'Health worker',
                                errorText: _clinicianError,
                                suffix: _loadingClinicians
                                    ? const Padding(
                                        padding: EdgeInsets.all(13),
                                        child: SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              hint: Text(
                                _selectedClinic == null
                                    ? 'Select a clinic first'
                                    : 'Choose a health worker',
                              ),
                              items: _clinicians
                                  .map(
                                    (clinician) => DropdownMenuItem(
                                      value: clinician.id,
                                      child: Text(
                                        clinician.subtitle.isEmpty
                                            ? clinician.displayName
                                            : '${clinician.displayName} - ${clinician.subtitle}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _selectedClinic == null ||
                                      _loadingClinicians ||
                                      _bookingState == _BookingState.loading
                                  ? null
                                  : _selectClinician,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Available times',
                              style: theme.titleSmall.copyWith(
                                color: theme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_loadingSlots)
                              const LinearProgressIndicator(minHeight: 3)
                            else if (_selectedClinician == null)
                              Text(
                                'Choose a health worker to see appointment times.',
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _slots
                                    .where((slot) => slot.isAvailable)
                                    .map(
                                      (slot) => ChoiceChip(
                                        label:
                                            Text(_displayTime(slot.startTime)),
                                        selected: _selectedSlot?.startTime ==
                                            slot.startTime,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedSlot =
                                                selected ? slot : null;
                                            _timeError = null;
                                            _formError = null;
                                            _bookingState = _BookingState.ready;
                                          });
                                        },
                                        selectedColor: theme.primary
                                            .withValues(alpha: 0.15),
                                        checkmarkColor: theme.primary,
                                        labelStyle: TextStyle(
                                          color: _selectedSlot?.startTime ==
                                                  slot.startTime
                                              ? theme.primary
                                              : theme.primaryText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        side: BorderSide(
                                          color: _selectedSlot?.startTime ==
                                                  slot.startTime
                                              ? theme.primary
                                              : theme.alternate,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            if (_timeError != null) ...[
                              const SizedBox(height: 8),
                              _FieldError(_timeError!),
                            ],
                            const SizedBox(height: 18),
                            TextField(
                              controller: _reasonController,
                              enabled: _bookingState != _BookingState.loading,
                              maxLength: 500,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                context,
                                label: 'Reason for appointment (optional)',
                              ).copyWith(
                                hintText:
                                    'Share a short reason to help the care team prepare.',
                              ),
                            ),
                            if (_formError != null) ...[
                              const SizedBox(height: 8),
                              _StatusBanner(
                                message: _formError!,
                                isSuccess: false,
                              ),
                            ],
                            if (_bookingState == _BookingState.success) ...[
                              const SizedBox(height: 8),
                              _StatusBanner(
                                message: _successMessage ??
                                    'Appointment booked successfully',
                                isSuccess: true,
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _book : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: theme.alternate,
                                  disabledForegroundColor: theme.secondaryText,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _buildButtonContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _bookingState != _BookingState.loading &&
      _bookingState != _BookingState.success &&
      !_loadingDirectory &&
      _clinics.isNotEmpty;

  Widget _buildButtonContent() {
    switch (_bookingState) {
      case _BookingState.loading:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Text('Booking appointment…'),
          ],
        );
      case _BookingState.success:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline),
            SizedBox(width: 8),
            Text('Appointment booked'),
          ],
        );
      case _BookingState.error:
        return const Text('Retry booking');
      case _BookingState.ready:
        return const Text('Book Appointment');
    }
  }

  static InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? errorText,
    Widget? suffix,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.secondaryBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.alternate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
    );
  }

  static String _displayTime(String value) {
    final date = Appointment.dateAtTime(DateTime(2000), value);
    return DateFormat.jm().format(date);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isSubmitting, required this.onClose});

  final bool isSubmitting;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Container(
      color: primary,
      padding: const EdgeInsets.fromLTRB(20, 15, 10, 15),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Book an appointment',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close booking form',
            onPressed: isSubmitting ? null : onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.selectedDate,
    required this.onSelected,
    this.errorText,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select date',
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText == null ? theme.alternate : theme.error,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: firstDate,
            lastDate: firstDate.add(const Duration(days: 180)),
            onDateChanged: onSelected,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          _FieldError(errorText!),
        ],
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: TextStyle(
          color: FlutterFlowTheme.of(context).error,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = isSuccess ? theme.success : theme.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
