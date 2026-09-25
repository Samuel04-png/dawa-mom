import 'package:flutter/foundation.dart';

@immutable
class ServiceCatalogItem {
  const ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.isPaid,
    required this.price,
    required this.currency,
    required this.isActive,
    this.externalServiceId,
    this.externalClinicId,
    this.description,
    this.category,
  });

  final String id;
  final String? externalServiceId;
  final String? externalClinicId;
  final String name;
  final String? description;
  final String? category;
  final bool isPaid;
  final double price;
  final String currency;
  final bool isActive;

  String get displayPrice => isPaid ? '$currency ${price.toStringAsFixed(2)}' : 'Free';

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      id: json['id'].toString(),
      externalServiceId: json['external_service_id']?.toString(),
      externalClinicId: json['external_clinic_id']?.toString(),
      name: json['name']?.toString() ?? 'Service',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      isPaid: json['is_paid'] as bool? ?? false,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'ZMW',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
