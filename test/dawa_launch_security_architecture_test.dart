import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;

  test('learning points remain server-authoritative', () {
    final repository = File(
      '$root/lib/features/learning/data/dawa_learning_repository.dart',
    ).readAsStringSync();

    expect(repository, contains("'complete_dawa_mom_learning_item'"));
    expect(repository, isNot(contains('coins: state.coins + rewardCoins')));
    expect(repository, contains('balanceVerified: true'));
    expect(repository, isNot(contains('dawa_reward_free_scan_voucher')));
  });

  test('voucher migration requires service-only clinician redemption', () {
    final sql = File(
      '$root/supabase/migrations/202610100002_secure_dawa_reward_vouchers.sql',
    ).readAsStringSync();
    final receiver = File(
      '$root/supabase/functions/receive-dawa-clinician-voucher-redemption/index.ts',
    ).readAsStringSync();

    expect(sql, contains('claim_dawa_mom_reward'));
    expect(sql,
        contains("status in ('claimed', 'redeemed', 'expired', 'cancelled')"));
    expect(sql, contains('dawa_mom_voucher_eligibility'));
    expect(sql, contains('Voucher is not eligible for this clinic service'));
    expect(sql, contains('drop function if exists public.redeem_dawa_mom_reward_voucher'));
    expect(
        sql,
        contains(
            'grant execute on function public.redeem_dawa_mom_reward_voucher'));
    expect(sql, contains('to service_role'));
    expect(receiver, contains("x-dawa-sync-secret"));
    expect(receiver, contains("'voucher.redeemed'"));
    expect(receiver, contains('external_service_id'));
  });

  test('transactional email work remains server-side and idempotent', () {
    final sql = File(
      '$root/supabase/migrations/202610100003_dawa_mom_transactional_email_events.sql',
    ).readAsStringSync();
    final worker = File(
      '$root/supabase/functions/process-dawa-mom-emails/index.ts',
    ).readAsStringSync();
    final appointmentWorker = File(
      '$root/supabase/functions/process-appointment-emails/index.ts',
    ).readAsStringSync();

    expect(sql, contains('dawa_mom_email_outbox'));
    expect(sql, contains('unique (profile_id, event_key)'));
    expect(sql, contains("'appointment_' || new.status"));
    expect(appointmentWorker, contains('appointment_confirmed'));
    expect(appointmentWorker, contains('appointment_cancelled'));
    expect(worker, contains('RESEND_API_KEY'));
    expect(worker, contains('Idempotency-Key'));
    expect(worker, isNot(contains('flutter')));
  });
}
