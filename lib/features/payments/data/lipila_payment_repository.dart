import 'package:supabase_flutter/supabase_flutter.dart';

class LipilaPaymentRepository {
  LipilaPaymentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<LipilaPaymentStart> createPayment({
    required String appointmentId,
    required String phoneNumber,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'lipila-create-payment',
        body: {
          'appointment_id': appointmentId,
          'phone_number': normalizeZambianPaymentPhone(phoneNumber),
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final error = data['error']?.toString();
      if (error != null && error.isNotEmpty) throw StateError(error);
      return LipilaPaymentStart.fromJson(data);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map) {
        final message = details['error']?.toString();
        final providerCode = details['provider_code']?.toString();
        final providerMessage = details['provider_message']?.toString();
        if (message != null && message.isNotEmpty) {
          final suffix = providerCode == null || providerCode.isEmpty
              ? ''
              : ' (provider code: $providerCode${providerMessage == null || providerMessage.isEmpty ? '' : ': $providerMessage'})';
          throw StateError('$message$suffix');
        }
      }
      throw StateError(
        error.reasonPhrase?.isNotEmpty == true
            ? error.reasonPhrase!
            : 'Payment request could not be sent. Please try again.',
      );
    }
  }

  static String normalizeZambianPaymentPhone(String value) {
    var normalized = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.startsWith('00')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('0')) {
      normalized = '260${normalized.substring(1)}';
    }
    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }
    if (!RegExp(r'^260[0-9]{9}$').hasMatch(normalized)) {
      throw const FormatException(
        'Enter a valid Zambian Mobile Money number, for example 0970 000 000.',
      );
    }
    return normalized;
  }

  Future<LipilaPaymentStatus> getStatus(String paymentId) async {
    final response = await _client.functions.invoke(
      'lipila-payment-status',
      body: {'payment_id': paymentId},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) throw StateError(error);
    return LipilaPaymentStatus.fromJson(
      Map<String, dynamic>.from(data['payment'] as Map),
    );
  }

  Future<LipilaPaymentRecord?> getAppointmentPayment(String appointmentId) async {
    final rows = await _client
        .from('payments')
        .select(
          'id,status,amount,currency,reference_id,payment_method,provider,created_at,paid_at,failed_at',
        )
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return LipilaPaymentRecord.fromJson(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }
}

class LipilaPaymentStart {
  const LipilaPaymentStart({
    required this.paymentId,
    required this.referenceId,
    required this.status,
    required this.amount,
    required this.currency,
  });

  final String paymentId;
  final String referenceId;
  final String status;
  final double amount;
  final String currency;

  factory LipilaPaymentStart.fromJson(Map<String, dynamic> json) =>
      LipilaPaymentStart(
        paymentId: json['payment_id'].toString(),
        referenceId: json['reference_id'].toString(),
        status: json['status']?.toString() ?? 'pending',
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        currency: json['currency']?.toString() ?? 'ZMW',
      );
}

class LipilaPaymentStatus {
  const LipilaPaymentStatus({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
  });

  final String id;
  final String status;
  final double amount;
  final String currency;

  factory LipilaPaymentStatus.fromJson(Map<String, dynamic> json) =>
      LipilaPaymentStatus(
        id: json['id'].toString(),
        status: json['status']?.toString() ?? 'pending',
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        currency: json['currency']?.toString() ?? 'ZMW',
      );
}

class LipilaPaymentRecord {
  const LipilaPaymentRecord({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    required this.referenceId,
    required this.paymentMethod,
    required this.provider,
    required this.createdAt,
    this.paidAt,
    this.failedAt,
  });

  final String id;
  final String status;
  final double amount;
  final String currency;
  final String referenceId;
  final String paymentMethod;
  final String provider;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? failedAt;

  factory LipilaPaymentRecord.fromJson(Map<String, dynamic> json) {
    return LipilaPaymentRecord(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? 'created',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'ZMW',
      referenceId: json['reference_id']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'mobile_money',
      provider: json['provider']?.toString() ?? 'lipila',
      createdAt: DateTime.parse(json['created_at'].toString()),
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
      failedAt: DateTime.tryParse(json['failed_at']?.toString() ?? ''),
    );
  }
}
