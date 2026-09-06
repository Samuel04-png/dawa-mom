# DawaMom Supabase Migration

This folder contains the local Supabase migration draft and Edge Function code for the Firebase to Supabase move.

Do not apply the migration until a Supabase project exists and the team has reviewed the schema, RLS policies, and seed/import strategy.

## Current Files

- `migrations/202605040001_initial_schema.sql` creates the first PostgreSQL schema, indexes, triggers, auth profile hook, and Row Level Security policies.
- `functions/rudo-chat/index.ts` is an authenticated Edge Function for storing Rudo chat in Supabase while still calling the existing production backend/Redis flow.
- `functions/gemini-proxy/index.ts` is an authenticated Edge Function scaffold for Gemini calls so API keys stay out of Flutter.
- `functions/rudo-chat/README.md` documents the function secrets and request shape.

## Assumptions Captured

- Every patient has their own Supabase Auth login.
- Patients, doctors, and admins all log into the same app.
- Both patients and doctors can create accounts. New auth users start with `profiles.role = patient`; a doctor signup can set `requested_role = doctor`, but an admin must manually approve/promote the profile and link it to a `doctors` row.
- Admins are manually created at first by updating `profiles.role = admin` through the Supabase dashboard/SQL editor or another service-role-only path. Invite-based admin creation can come later.
- Patients can edit their own profile/mother demographic data and period tracker data, and can schedule/cancel appointment fields. Patients cannot create or edit clinical encounter, first encounter, or parity data.
- Assigned doctors/medical specialists manage clinical data. Doctors can only see and update data for appointments/patients assigned to their own `doctors` row.
- Admins can see all app data. The app-level RLS does not grant admins patient clinical writes; service-role tooling should be used for import/repair operations.
- Doctors and admins are represented through `profiles.role`.
- Existing Firebase document paths can be stored in `firebase_ref` columns and in `legacy_firebase_refs` during phased migration.
- Rudo chat can be stored durably in Supabase while the production backend/Redis keeps live session state during the cutover.
- Rudo chat history is visible to the patient, assigned doctors for that patient, and admins.
- Rudo chat data must stay JSON-shaped. `chat_messages.payload` and `chat_sessions.session_state` are intended to absorb the current Upstash Redis JSON history/state into Supabase.
- Gemini and other private backend secrets should live in Supabase Edge Function secrets or the existing production backend, not in the Flutter client.
- Rudo's production assistant call stays behind the existing backend for now.
- Any direct Gemini calls from Flutter have been removed; Gemini calls should go through Supabase Edge Function secrets if that helper path is used.
- Rudo chat messages should include a stable `client_message_id` from Flutter to prevent retry/double-tap duplicate sends.
- A single cutover is acceptable; no long-term Firebase/Supabase dual-write mode is assumed.

## Status Notes

- Flutter now points at project `himbfndvsuwiudtzjojh`.
- The `rudo-chat` and `gemini-proxy` Edge Functions are deployed to project `himbfndvsuwiudtzjojh`.
- The initial SQL migration has been pushed to `himbfndvsuwiudtzjojh`.
- `DAWAMOM_BACKEND_URL` could not be set on `himbfndvsuwiudtzjojh`; the current CLI account could deploy functions but was blocked from writing project secrets. The `rudo-chat` function falls back to the current production backend URL when that secret is absent.
- The Flutter client now initializes Supabase directly and no longer imports Firebase packages in active app code.
- `pubspec.yaml` no longer declares Firebase or direct Gemini client dependencies.
- The Rudo UI now uses Supabase `chat_sessions`/`chat_messages`, sends through the `rudo-chat` Edge Function, supports enter-to-send, suggestion chips, duplicate protection, and a voice-mode UI.
- The period tracker now uses Supabase `period_tracker_settings` and `period_tracker_entries`.
- Firebase Auth and Firestore have been imported from project `dawa-ca263` using legacy-password bridge mode. Imported remote counts include 79 Auth users/profiles, 19 doctors, 22 mothers, 1 clinic, 3 first encounters, 5 encounters, 40 pregnancy weeks, and 6 chat sessions.
- The `firebase-auth-migrate-login` Edge Function is deployed with JWT verification disabled because it must be callable before Supabase login. It verifies Firebase SCRYPT hashes server-side and updates the Supabase password on first successful legacy-password login.
- Firebase documents that could not satisfy Supabase foreign keys are preserved in `legacy_orphan_records`; this includes most parity rows because their first-encounter/mother parent chain was incomplete in the export.
- Current Flutter code uses appointment statuses like `scheduled`, `completed`, and `canceled`.
- The team reported Firebase production status/data labels including `Had first encounter` and `missing data`.
- Before import, normalize those labels into final appointment/clinical status values so slot booking, first encounter completion, and missing-data follow-up are not mixed together.

## Before Applying

1. Create the Supabase project.
2. Confirm the manual admin bootstrap SQL/process.
3. Confirm the doctor signup approval flow and how admins will link approved doctor profiles to `doctors` rows.
4. Normalize appointment/clinical status values from Firebase before import.
5. Export Firebase data and map document references to Supabase UUIDs.
6. Export Upstash Redis Rudo JSON session/message state for import into `chat_sessions.session_state` and `chat_messages.payload`.
7. Deploy `rudo-chat`; set `DAWAMOM_BACKEND_URL` and optional `DAWAMOM_BACKEND_API_KEY` when the Supabase account has project secret permissions.
8. Deploy `gemini-proxy` only if Gemini helper calls are needed, and set `GEMINI_API_KEY`.
