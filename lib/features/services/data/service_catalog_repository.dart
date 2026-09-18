import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_database.dart';
import '../domain/service_catalog_item.dart';

class ServiceCatalogRepository {
  ServiceCatalogRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ServiceCatalogItem>> getActiveServices({String? clinicExternalId}) async {
    final rows = await SupabaseDatabase.instance.runWithFreshSession(
      () => _client
          .from('service_catalog')
          .select()
          .eq('is_active', true)
          .order('name'),
    );
    final filteredRows = clinicExternalId == null || clinicExternalId.trim().isEmpty
        ? rows as List
        : (rows as List).where((row) {
            final externalClinicId = (row as Map)['external_clinic_id']?.toString();
            return externalClinicId == null || externalClinicId == clinicExternalId.trim();
          }).toList(growable: false);
    return filteredRows
        .map((row) => ServiceCatalogItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}
