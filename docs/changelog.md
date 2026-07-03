# Changelog

The Git history currently shows one visible commit:

```text
631ea2e Initial Dawa Mom commit
```

Because there is not a long local commit history to reconstruct exact dates from, I am grouping the current documented changes by feature area. Where the repo has dated migration filenames, I include those dates from the filenames.

## Initial Dawa Mom Commit

The initial repo commit contains the Flutter app, Supabase migration artifacts, backend/Rudo files, tests, assets, and local project documentation.

## Supabase Migration Work

### 2026-05-04 Migration File

`supabase/migrations/202605040001_initial_schema.sql` introduced:

- `profiles`
- `clinics`
- `doctors`
- `mothers`
- `first_encounters`
- `parities`
- `encounters`
- `pregnancy_weeks`
- `period_tracker_settings`
- `period_tracker_entries`
- `chat_sessions`
- `chat_messages`
- `legacy_firebase_refs`
- RLS helper functions and policies
- Auth profile creation trigger
- Updated-at triggers
- Duplicate appointment slot constraints
- Duplicate Rudo message protection

### 2026-05-06 Migration Files

`202605060002_add_legacy_payload_columns.sql` added `legacy_payload` JSONB columns to imported/migrated tables.

`202605060003_add_legacy_orphan_records.sql` added `legacy_orphan_records` for Firebase documents that could not satisfy Supabase foreign keys.

`202605060004_add_firebase_auth_migration_bridge.sql` added:

- `firebase_auth_migration_credentials`
- `firebase_auth_migration_config`
- RLS enabled for those tables

## Flutter Client Migration

Repo migration notes and code confirm:

- The app initializes Supabase from `lib/main.dart`.
- Active auth code moved to `lib/auth/supabase_auth/`.
- Active data access moved through `lib/backend/supabase/`.
- FlutterFlow-generated record models remain but use Supabase-backed compatibility helpers.
- Period tracker reads/writes moved to Supabase.
- Rudo chat reads/writes moved to Supabase chat tables and the `rudo-chat` Edge Function.
- Firebase Dart dependencies are not declared in `pubspec.yaml`.

## App Feature Work

Confirmed app feature areas in the current repo:

- Register/login/forgot-password auth screens.
- Mother profile creation and completion.
- Profile view/edit screen.
- Home/dashboard.
- Appointment booking, list, details, cancellation, and completed-result view.
- Pregnancy week detail page.
- Period tracker tab.
- Rudo chat modal with text suggestions and voice mode.
- Encounter result interpretation for blood pressure and other health indicators.

## Backend And Rudo Work

The repo includes:

- Python Flask backend under `lib/backend/`.
- Rudo training data for pregnancy and cervical cancer topics.
- WhatsApp webhook logic in Python backend files.
- Supabase Edge Functions for Rudo chat, Gemini helper calls, ElevenLabs TTS, and Firebase password migration.

## Testing Work

Current tests include:

- Auth user info model storage.
- Period tracker date formatting and Supabase-row-to-legacy-map conversion.

## Documentation Work

This documentation system adds:

- GitBook Sync config.
- GitBook summary/navigation.
- Full `/docs` page set for project overview, architecture, migration, backend, authentication, workflows, known issues, future work, and developer reference.

## Needs Confirmation Before Release Notes

- Live Supabase deployment status should be verified against the current project.
- Remote imported counts from `supabase/README.md` and `supabase/CLIENT_MIGRATION_MAP.md` should be checked against Supabase.
- The Firebase auth migration bridge status should be tested with a real legacy user.
- Screenshots should be captured from a running app build.
