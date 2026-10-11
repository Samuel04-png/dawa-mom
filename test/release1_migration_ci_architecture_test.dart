import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final workflow = File(
    '$root/.github/workflows/release1-migration-validation.yml',
  ).readAsStringSync();
  final runner = File(
    '$root/tool/ci/release1_migration_validation.sh',
  ).readAsStringSync();
  final lifecycle = File(
    '$root/ci/release1/payment_lifecycle.sql',
  ).readAsStringSync();
  final preMigrationFixture = File(
    '$root/ci/release1/pre_lifecycle_migration_fixture.sql',
  ).readAsStringSync();

  test('Release 1 CI uses an isolated local Supabase stack', () {
    expect(workflow, contains('supabase/setup-cli@v1'));
    expect(workflow, contains('release1_migration_validation.sh'));
    expect(runner, contains('mktemp -d'));
    expect(runner, contains('supabase start'));
    expect(runner, contains('supabase db reset --local'));
    expect(runner, contains('pre_lifecycle_migration_fixture.sql'));
    expect(runner, contains('supabase db push --local'));
    expect(runner, isNot(contains('--linked')));
    expect(runner, isNot(contains('project-ref')));
  });

  test('Release 1 workspace excludes Care Plan and Release 2 migrations', () {
    expect(runner, contains('202610090001'));
    expect(runner, contains('202610100002'));
    expect(runner, contains('202610100003'));
    expect(runner, contains('202610090002'));
    expect(runner, contains('202610100001'));
    expect(
        lifecycle, contains("to_regclass('public.care_plan_items') is null"));
  });

  test(
      'payment lifecycle fixture covers private, terminal, replay, and recovery states',
      () {
    expect(lifecycle, contains("'not_started'"));
    expect(lifecycle, contains("'pending'"));
    expect(lifecycle, contains("'processing'"));
    expect(lifecycle, contains("'successful'"));
    expect(lifecycle, contains("'failed'"));
    expect(lifecycle, contains("'expired'"));
    expect(lifecycle, contains("'cancelled'"));
    expect(lifecycle, contains("'reconciliation_required'"));
    expect(lifecycle, contains('duplicate successful webhook'));
    expect(lifecycle, contains('payment RLS exposed'));
    expect(lifecycle, contains('legacy booking RPC bypassed'));
    expect(preMigrationFixture, contains('Release 1 Legacy Patient'));
    expect(lifecycle,
        contains('legacy paid appointment without a provider record'));
  });
}
