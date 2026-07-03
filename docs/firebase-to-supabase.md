# Firebase To Supabase

This repo contains a real Firebase-to-Supabase migration path. The active Flutter app uses Supabase, while legacy Firebase names remain where they support migration, compatibility, and old data mapping.

## Why I Moved The App Toward Supabase

The repo evidence points to these goals:

- Move active auth to Supabase Auth.
- Move Firestore-shaped app data into Supabase Postgres tables.
- Use RLS for patient, doctor, and admin access boundaries.
- Preserve old Firebase document paths and payloads during migration.
- Keep Gemini, ElevenLabs, service-role, and backend secrets out of Flutter.
- Avoid a long-term Firebase/Supabase dual-write system.

## What Firebase Pieces Existed Or Still Exist

Confirmed legacy/migration pieces:

- `supabase/CLIENT_MIGRATION_MAP.md` references old Firebase auth utilities and Firebase config files that were removed from active Flutter code.
- Generated model names still say Firestore, for example `FirestoreRecord`, `FFFirestorePage`, and `firestore_util.dart`.
- The Supabase schema has `firebase_ref` and `legacy_firebase_refs`.
- Later migrations add `legacy_payload`, `legacy_orphan_records`, and Firebase auth migration bridge tables.
- `firebase-auth-migrate-login` verifies Firebase SCRYPT password hashes server-side.
- A local ignored `lib/backend/.env.txt` contains Firebase service account data in this workspace. It must not be committed or documented with real values.

The active Flutter app does not declare Firebase Dart packages in `pubspec.yaml`, and Android Gradle config does not apply Firebase plugins.

## What Supabase Handles Now

Supabase now handles:

- Auth and session state.
- PostgreSQL app data.
- RLS policies.
- Edge Functions for sensitive backend actions.
- Rudo chat persistence.
- Period tracker persistence.
- Firebase legacy password migration.

## Migration Bridge

The migration bridge has three parts:

1. SQL tables store Firebase auth migration credentials/config.
2. The Flutter login flow retries invalid Supabase login through `firebase-auth-migrate-login`.
3. The Edge Function verifies the Firebase hash and updates the Supabase user's password through service-role auth admin APIs.

## Supabase Initialization Snippet

**File:** `lib/backend/supabase/supabase_config.dart`

**Purpose:** Initializes Supabase and refreshes any persisted session. This snippet is redacted with placeholders.

```dart
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'your_supabase_url',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your_supabase_anon_key',
);

Future<void> initSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError('Supabase URL and anon key must be configured.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  await _refreshPersistedSession();
}
```

## Auth Migration Fallback Snippet

**File:** `lib/auth/supabase_auth/supabase_auth_manager.dart`

**Purpose:** Attempts normal Supabase login first, then tries Firebase password migration only after invalid login.

```dart
Future<AuthResponse> _signInWithFirebaseMigrationFallback(
  String email,
  String password,
) async {
  try {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  } on AuthException catch (e) {
    if (!_isInvalidLogin(e)) {
      rethrow;
    }

    final migrated = await _tryMigrateFirebasePassword(email, password);
    if (!migrated) {
      rethrow;
    }

    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```

## Firebase Password Edge Function Snippet

**File:** `supabase/functions/firebase-auth-migrate-login/index.ts`

**Purpose:** Uses the service role key inside Supabase Edge Function runtime, never in Flutter.

```ts
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  return jsonResponse({ error: "Migration function is not configured" }, 500);
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});
```

## Example Supabase Database Call

**File:** `lib/backend/period_tracker_service.dart`

**Purpose:** Persists cycle settings directly to Supabase.

```dart
await SupabaseDatabase.instance.runWithFreshSession(
  () => _client.from('period_tracker_settings').upsert({
    'profile_id': profileId,
    'average_cycle_length': averageCycleLength,
    'period_length': periodLength,
    'is_regular': isRegular,
    'last_period_start':
        lastPeriodStart != null ? formatDateId(lastPeriodStart) : null,
  }, onConflict: 'profile_id'),
);
```

## Remaining Firebase Naming

The following names are expected migration leftovers:

- `FirestoreRecord`
- `FFFirestorePage`
- `firestore_util.dart`
- `mapToFirestore()`
- `mapFromFirestore()`
- `firebase_ref`
- `legacy_firebase_refs`
- `firebase_auth_migration_credentials`

These names do not mean the active client is using Firebase. They are compatibility and migration terms.

## Risks And Incomplete Areas

- The live Firebase password migration bridge must be tested with real migrated users.
- The local ignored `.env` file contains sensitive credentials and should be rotated/removed from local project handoff material.
- `FFAppState().motherRef` still needs review to make sure the app always resolves the current user's mother row safely after migration.
- Repo notes include imported remote counts, but the live Supabase project should be checked before final client handoff.
- If old Firebase auth hash config is incomplete, reset-password fallback may still be needed for some users.
