# Developer Notes

## How To Understand The App

Start with the app as a Supabase-backed FlutterFlow project. A lot of class and helper names still look like Firestore, but the active reads/writes route through Supabase.

The most important mental model:

```text
Flutter UI -> Generated Record Classes -> Supabase Compatibility Layer -> Supabase Tables
```

For newer features like period tracking and Rudo chat, the app often calls Supabase tables/functions directly.

## Best Starting Files

| File | Why It Matters |
|---|---|
| `lib/main.dart` | App startup, Supabase init, routing, tabs. |
| `lib/backend/supabase/supabase_config.dart` | Supabase client config and startup session refresh. |
| `lib/auth/supabase_auth/supabase_auth_manager.dart` | Main auth logic and Firebase migration fallback. |
| `lib/backend/supabase/supabase_database.dart` | Compatibility layer and collection/table mapping. |
| `supabase/migrations/202605040001_initial_schema.sql` | Main database schema and RLS. |
| `lib/navbar/home/home_widget.dart` | Home, appointment summary, pregnancy content entry, Rudo chat. |
| `lib/backend/period_tracker_service.dart` | Clear example of direct Supabase service logic. |
| `lib/flutter_flow/custom_functions.dart` | Health/pregnancy helper functions. |

## Common Pitfalls

- Do not assume `FirestoreRecord` means Firebase is active.
- Do not put service-role keys or API keys in Flutter.
- Do not rely on `FFAppState().motherRef` without verifying it belongs to the current authenticated user.
- Do not change generated record field names casually; the compatibility layer maps legacy names.
- Do not rewrite the Supabase compatibility layer without checking every generated screen that depends on it.
- Do not treat health interpretation helpers as clinically validated.
- Do not commit local `.env` files.

## Adding New Supabase Tables

1. Add a migration under `supabase/migrations/`.
2. Enable RLS.
3. Add policies.
4. Add indexes for common queries.
5. Add updated-at trigger if the table has `updated_at`.
6. Add Flutter service or compatibility mapping as needed.
7. Add tests or manual verification steps.
8. Update these docs.

## Adding New Mother-Facing Features

- Confirm the feature is patient-owned.
- Use `auth.uid()`/profile ownership as the source of truth.
- Avoid storing stale cross-user references.
- Keep clinical writes separate from patient writes.
- Add empty/loading/error states.
- Add manual QA steps.

## Safely Working With Auth

- Keep `SupabaseAuthManager` as the main auth boundary.
- Keep Firebase migration fallback only for invalid login cases.
- Keep role promotion out of normal client signup.
- Test auth on app start, logout, expired session, and password reset.

## Safely Working With Health Logic

- Keep rules simple and testable.
- Add clinical review notes before expanding recommendations.
- Add unit tests for edge cases.
- Do not make diagnostic claims without reviewed requirements.

## Updating Documentation

When code changes:

1. Update the relevant feature page.
2. Update `completed-tasks.md` if the work is complete.
3. Update `known-issues.md` if a limitation remains.
4. Update `future-improvements.md` if a roadmap item changes.
5. Add screenshots if UI changes are visible.
6. Keep `SUMMARY.md` links valid.

## GitBook Sync Notes

- GitBook root is `./docs/`.
- `docs/README.md` is the GitBook home page.
- `docs/SUMMARY.md` controls navigation.
- Use relative image links for docs assets.
- Do not include secrets in Markdown.
