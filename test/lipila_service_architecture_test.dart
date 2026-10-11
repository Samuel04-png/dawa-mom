import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202609150001_add_service_catalog_and_payments.sql',
  ).readAsStringSync();
  final paymentFunction = File(
    'supabase/functions/lipila-create-payment/index.ts',
  ).readAsStringSync();
  final webhookFunction = File(
    'supabase/functions/lipila-webhook/index.ts',
  ).readAsStringSync();
  final paidLifecycleMigration = File(
    'supabase/migrations/202610100001_secure_paid_appointment_lifecycle.sql',
  ).readAsStringSync();
  final syncFunction = File(
    'supabase/functions/receive-service-catalog-sync/index.ts',
  ).readAsStringSync();
  final rudoFunction =
      File('supabase/functions/rudo-chat/index.ts').readAsStringSync();

  test('catalog and payment migration is additive and server authoritative',
      () {
    expect(migration,
        contains('create table if not exists public.service_catalog'));
    expect(migration, contains('create table if not exists public.payments'));
    expect(migration,
        contains('create table if not exists public.payment_events'));
    expect(migration, contains('source_updated_at'));
    expect(migration, contains('on conflict (external_service_id) do update'));
    expect(migration, contains('price_snapshot'));
    expect(migration, contains('is_paid_snapshot'));
    expect(migration, contains('service_catalog_read_active'));
    expect(migration, contains('payments_select_owner'));
    expect(migration, contains('revoke all on table public.payment_events'));
    expect(
      migration,
      contains('(is_paid and price > 0) or (not is_paid and price = 0)'),
    );
  });

  test('payment creation never accepts a client amount', () {
    expect(paymentFunction, contains('p_appointment_id'));
    expect(paymentFunction, contains('p_phone_number'));
    expect(paymentFunction, isNot(contains('body.amount')));
    expect(paymentFunction, contains('payment.amount'));
    expect(paymentFunction, contains('payment.currency'));
    expect(paymentFunction, contains('LIPILA_API_KEY'));
    expect(paymentFunction, contains('LIPILA_BASE_URL'));
  });

  test('webhook protects raw-body signatures and atomically applies delivery',
      () {
    expect(webhookFunction, contains('webhook-id'));
    expect(webhookFunction, contains('webhook-timestamp'));
    expect(webhookFunction, contains('webhook-signature'));
    expect(webhookFunction, contains('await req.text()'));
    expect(webhookFunction, contains('HMAC'));
    expect(webhookFunction, contains('maxAgeSeconds'));
    expect(webhookFunction, contains('apply_lipila_payment_status'));
    expect(paidLifecycleMigration, contains('payment_events'));
    expect(paidLifecycleMigration,
        contains('on conflict (provider, webhook_id) do nothing'));
    expect(
        paidLifecycleMigration, contains('release_paid_appointment_workflow'));
  });

  test('free and paid appointment notifications remain separate', () {
    expect(
        migration, contains('if tg_op = \'INSERT\' and new.is_paid_snapshot'));
    expect(migration, contains('if new.is_paid_snapshot'));
    expect(migration, contains('appointment.created'));
    expect(migration, contains('release_paid_appointment_workflow'));
  });

  test('future service sync is authenticated and stale-safe', () {
    expect(syncFunction, contains('DAWA_MOM_SYNC_SECRET'));
    expect(syncFunction, contains('x-dawa-sync-secret'));
    expect(syncFunction, contains('source_updated_at'));
    expect(syncFunction, contains('apply_service_catalog_sync'));
    expect(migration,
        contains('p_source_updated_at <= existing.source_updated_at'));
    expect(migration, contains('is_active'));
    expect(migration, contains('on conflict (external_service_id) do update'));
    expect(migration,
        contains('p_source_updated_at <= existing.source_updated_at'));
  });

  test('booking snapshots and payment release remain server controlled', () {
    expect(migration, contains('selected_service.price'));
    expect(migration, contains('selected_service.is_paid'));
    expect(migration, contains('appointment_row.price_snapshot'));
    expect(migration, contains('amount, currency, phone_number'));
    expect(migration, contains('if not appointment_row.is_paid_snapshot'));
    expect(migration, contains('release_paid_appointment_workflow'));
  });

  test('Rudo receives backend service pricing context', () {
    expect(rudoFunction, contains('service_catalog'));
    expect(rudoFunction, contains('from("service_catalog")'));
    expect(rudoFunction, contains('Never invent or infer a service price'));
  });

  test(
      'cancelled, failed, and expired payments release only private reservations',
      () {
    expect(paidLifecycleMigration, contains('payment_state'));
    expect(paidLifecycleMigration, contains("'not_started'"));
    expect(paidLifecycleMigration, contains("'processing'"));
    expect(paidLifecycleMigration, contains("'successful'"));
    expect(paidLifecycleMigration, contains("'cancelled'"));
    expect(paidLifecycleMigration, contains("'expired'"));
    expect(
        paidLifecycleMigration,
        contains(
            "status = case when status = 'pending' then 'cancelled' else status end"));
    expect(paidLifecycleMigration, contains('reconciliation_required'));
    expect(paidLifecycleMigration, contains("dawa.payment_transition"));
    expect(paidLifecycleMigration,
        contains('Patients may only cancel eligible appointments'));
    expect(paymentFunction, contains('collection.create.unknown'));
    expect(
        paymentFunction, contains('Check payment status before trying again'));
  });

  test('legacy booking calls receive the secure initial payment state', () {
    expect(
      paidLifecycleMigration,
      contains('Older installed clients still send the pre-payment-method'),
    );
    expect(
      paidLifecycleMigration,
      contains("'online'\n  );\n\$\$;"),
    );
    expect(
      paidLifecycleMigration,
      contains('text, text, text, uuid, uuid\n) to authenticated;'),
    );
  });
}
