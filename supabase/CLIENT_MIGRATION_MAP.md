# Flutter Client Migration Map

This map tracks the app-side Firebase to Supabase migration work. It is intentionally separate from the SQL migration so the database can be reviewed before Flutter code is switched over.

## Current Client Status

As of May 6, 2026, the Flutter client has been switched to Supabase at the app layer:

- `lib/main.dart` initializes Supabase with the project URL and publishable anon key.
- `lib/auth/supabase_auth/*` replaces the Firebase auth manager and auth streams.
- `lib/backend/supabase/*` provides the Supabase client config and the compatibility data adapter used by existing FlutterFlow record classes.
- `lib/backend/backend.dart` now creates and updates Supabase-backed `profiles` rows.
- `lib/app_state.dart` no longer has the shared hardcoded mother reference.
- `lib/navbar/period_tracker/period_tracker_widget.dart` and `lib/backend/period_tracker_service.dart` read/write Supabase `period_tracker_settings` and `period_tracker_entries`.
- `lib/navbar/home/home_widget.dart` routes Rudo through the `rudo-chat` Supabase Edge Function and reads/writes Supabase chat tables.
- Firebase Dart package imports and direct Firebase dependencies were removed from active app code and `pubspec.yaml`.
- Flutter now points at the new Supabase project `himbfndvsuwiudtzjojh`.
- The `rudo-chat` and `gemini-proxy` Edge Functions are deployed to `himbfndvsuwiudtzjojh`.
- `202605040001_initial_schema.sql` has been pushed to `himbfndvsuwiudtzjojh`.
- `DAWAMOM_BACKEND_URL` could not be set on `himbfndvsuwiudtzjojh`; the current CLI account could deploy functions but did not have permission to write project secrets. The `rudo-chat` function now falls back to the current production backend URL when that secret is absent.
- Firebase Auth was exported from project `dawa-ca263`: 79 accounts.
- Firestore was exported from project `dawa-ca263`: `user` 77, `mother` 22, `doctor` 19, `clinic` 1, `encounter` 39, `first_encounter` 10, `parity` 4339, `weeks_of_pregenancy` 40, `whatsapp_chats` 6.
- The export includes password hashes but not Firebase's Auth hash configuration, so Supabase Auth migration currently requires reset-password mode unless the Firebase hash configuration is provided.
- The Supabase schema now includes `legacy_payload` columns for mapped migrated rows, `legacy_orphan_records` for Firebase documents that cannot satisfy Supabase foreign keys, and a locked Firebase Auth migration bridge for first-login password migration.
- The Firebase Auth migration bridge is deployed as `firebase-auth-migrate-login`. The Flutter login flow retries through this function only after a Supabase invalid-login response.
- The legacy-bridge import has been executed. Remote counts: Auth users/profiles 79, Firebase hash credentials 79, doctors 19, mothers 22, clinic 1, first encounters 3, encounters 5, pregnancy weeks 40, chat sessions 6, legacy orphan records 4382.
- Profile roles after import: 19 doctors and 60 patients.
- 4382 Firebase documents were preserved as `legacy_orphan_records` because they could not satisfy Supabase foreign keys from the exported parent data. Most are parity rows pointing to a first-encounter target that was not importable from the exported mother links.

## Original Firebase Anchors

- `lib/main.dart`
  - Previously imported Firebase auth utilities, called `initFirebase()`, and started `dawaMomFirebaseUserStream()`.
- `lib/backend/firebase/firebase_config.dart` and `lib/auth/firebase_auth/*`
  - Removed from the Flutter client.
- `lib/backend/backend.dart`
  - Retains FlutterFlow-compatible helper names, but active reads/writes are backed by Supabase.
- `lib/backend/schema/*_record.dart`
  - Generated Firestore collection models.
- `lib/app_state.dart`
  - Contains the hardcoded shared mother document reference:
    `/mother/sr3XgdmYl33UybEDYPJv`.
- `lib/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart`
  - Reads clinics/doctors/encounters.
  - Writes new appointment/encounter records.
  - Uses `FFAppState().motherRef`, which must be replaced with the logged-in patient's Supabase mother row.
- `lib/navbar/home/home_widget.dart`
  - Reads current mother, encounters, first encounters, and Rudo chat Supabase rows.
  - Uses `FFAppState().motherRef` for patient-specific data.
- `lib/navbar/appointments/encounters/encounters_widget.dart`
  - Reads patient encounters using `FFAppState().motherRef`.
- `lib/navbar/appointments/appointment_details/appointment_details_widget.dart`
  - Updates encounter records.
- `lib/navbar/period_tracker/period_tracker_widget.dart` and `lib/backend/period_tracker_service.dart`
  - Now use Supabase period tracker tables.

## Supabase App-Side Target

Already added:

- `supabase_flutter` dependency.
- Supabase initialization in `main.dart`.
- Supabase app config in `lib/backend/supabase/supabase_config.dart`.
- Auth replacement for:
  - email sign up
  - email sign in
  - sign out
  - password reset
  - current user/session stream
- Signup should support patient and doctor account creation. Doctor signups should only set `requested_role = doctor`; actual `role = doctor` must wait for manual admin approval and doctor-row linking.
- Data services replacing Firestore document references with UUID row ids.

Do not put the service role key, Gemini key, or backend secret in Flutter.

## Access Decisions From Team Review

- Patients cannot edit clinical data.
- Patients may edit their own demographic/profile fields, period tracker data, and appointment booking/cancellation fields.
- Doctors/medical specialists edit clinical fields, first encounters, and parity history only for patients assigned to their own appointments.
- Admins are manually created at first and can see everything.
- Doctors should see only appointments/patients assigned to their own `doctors` row.
- Rudo chat history should be visible to the patient, assigned doctors, and admins.
- Rudo chat/session history must stay JSON-shaped so the current Upstash Redis state can move into Supabase.
- Single cutover is acceptable; the client migration does not need a long-term dual-write mode.

## Recommended Client Migration Order

1. Add Supabase initialization behind config placeholders.
2. Implement Supabase Auth while Firebase remains present for rollback.
3. Add signup account-type capture:
   - patient signup creates/fetches the patient's `mothers` row for the authenticated `profiles.id`
   - doctor signup sets `requested_role = doctor` and waits for manual admin approval
4. Replace `FFAppState().motherRef` with a nullable Supabase `motherId` UUID.
5. Migrate read-only content first:
   - `pregnancy_weeks`
   - `clinics`
   - public doctor lookup data
6. Migrate patient-owned reads:
   - `mothers`
   - `first_encounters`
   - `parities`
   - `encounters`
7. Migrate patient-owned writes:
   - profile/mother edits
   - appointment booking/cancel/update fields only
   - period tracker settings and daily entries
8. Migrate doctor clinical writes:
   - first encounter creation/update
   - parity history creation/update
   - encounter clinical fields
9. Route Rudo chat through the `rudo-chat` Edge Function and store/read JSON history from Supabase.
10. Remove Firebase imports only after Supabase Auth, RLS, data reads, writes, and chat are verified.

## Clinical Data Guardrails

The Flutter app must not expose clinical-field write calls to patient sessions.

The SQL migration also enforces this at RLS/trigger level:

- patient writes to `encounters` are limited to appointment scheduling/cancellation fields
- patient writes to `first_encounters` and `parities` are not allowed
- assigned doctors can write clinical records for their assigned patients
- admins can read clinical records, but app-level RLS does not grant admin clinical edits

Use service-role migration scripts, not the Flutter app, for data import/repair.

## Double Message Fix Path

Flutter should generate one stable `client_message_id` per outbound Rudo user message and send it to the Edge Function.

The migration schema has a unique index on `(session_id, client_message_id)`, so retries or duplicate button taps cannot create duplicate chat rows or duplicate backend calls.

Rudo requests and stored history should remain JSON. The Edge Function stores display text in `chat_messages.content`, but the migrated Redis-shaped data belongs in `chat_messages.payload` and session-level JSON state belongs in `chat_sessions.session_state`.

## Patient Isolation Fix Path

The current hardcoded Firebase mother reference must not be migrated as-is.

Supabase should always resolve patient data from:

```sql
select id
from public.mothers
where profile_id = auth.uid();
```

The Flutter app should store only the resolved Supabase `mothers.id` for the current session, and RLS should remain the final enforcement layer.
