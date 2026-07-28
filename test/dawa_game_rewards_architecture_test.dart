import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game reward migration is additive, owner-scoped and idempotent', () {
    final sql = File(
      'supabase/migrations/202607230002_add_dawa_mom_game_rewards.sql',
    ).readAsStringSync();

    expect(sql, contains("when 'game-myth-match' then 10"));
    expect(sql, contains("when 'game-nutrition-sort' then 10"));
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('on conflict (profile_id, content_id) do nothing'));
    expect(sql, contains('security definer'));
    expect(
      sql,
      contains(
        'grant execute on function public.complete_dawa_mom_learning_item(text)',
      ),
    );
    expect(sql.toLowerCase(), isNot(contains('disable row level security')));
    expect(sql.toLowerCase(), isNot(contains('drop table')));
  });

  test('local points, progress and vouchers are scoped to the signed-in owner',
      () {
    final repository = File(
      'lib/features/learning/data/dawa_learning_repository.dart',
    ).readAsStringSync();

    expect(repository, contains('dawa_learning_local_owner'));
    expect(repository, contains(r"'${base}_$userId'"));
    expect(repository, contains('_keyFor(_freeScanVoucherKey)'));
    expect(repository, contains('_keyFor(_completedKey)'));
    expect(repository, contains('_prepareOwnerScopedStorage'));
  });

  test('cycle game progress is owner-scoped and stores no symptom answers', () {
    final sql = File(
      'supabase/migrations/202607280002_add_cycle_learning_games.sql',
    ).readAsStringSync();

    expect(sql, contains('dawa_mom_cycle_game_progress'));
    expect(sql, contains('profile_id = auth.uid()'));
    expect(sql, contains('content_version'));
    expect(sql, contains("when 'cycle-game-phase-match' then 10"));
    expect(sql, contains("when 'cycle-game-products-match' then 10"));
    expect(sql, contains('on conflict (profile_id, content_id) do nothing'));
    expect(sql.toLowerCase(), isNot(contains('symptom_answer')));
    expect(sql.toLowerCase(), isNot(contains('service_role')));
    expect(sql.toLowerCase(), isNot(contains('disable row level security')));
  });
}
