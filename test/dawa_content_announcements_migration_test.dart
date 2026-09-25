import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content announcements migration enforces published read-only RLS', () {
    final sql = File(
      'supabase/migrations/202607280001_add_content_announcements.sql',
    ).readAsStringSync();

    expect(sql,
        contains('create table if not exists public.content_announcements'));
    expect(
      sql,
      contains(
          'alter table public.content_announcements enable row level security'),
    );
    expect(
      sql,
      contains(
          'alter table public.content_announcements force row level security'),
    );
    expect(sql, contains('for select\n  to authenticated'));
    expect(sql, contains('starts_at <= now()'));
    expect(sql, contains('(ends_at is null or ends_at > now())'));
    expect(
      sql,
      contains(
        'revoke all on table public.content_announcements from anon, authenticated',
      ),
    );
    expect(
      sql,
      contains(
          'grant select on table public.content_announcements to authenticated'),
    );
    expect(sql, isNot(contains('grant insert')));
    expect(sql, isNot(contains('grant update')));
    expect(sql, contains("asset_id ~ '^[a-z0-9_]+_[0-9]{2}\$'"));
    expect(sql, contains("left(deep_link, 2) <> '//'"));
  });
}
