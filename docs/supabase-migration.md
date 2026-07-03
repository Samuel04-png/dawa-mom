# Supabase Migration

The `supabase/` folder contains migrations, Edge Functions, migration notes, and verification SQL. This is one of the most important parts of the project because the Flutter app now depends on Supabase as the active runtime.

## Folder Structure

```text
supabase/
  functions/
    _shared/
    elevenlabs-tts/
    firebase-auth-migrate-login/
    gemini-proxy/
    rudo-chat/
  migrations/
    202605040001_initial_schema.sql
    202605060002_add_legacy_payload_columns.sql
    202605060003_add_legacy_orphan_records.sql
    202605060004_add_firebase_auth_migration_bridge.sql
  CLIENT_MIGRATION_MAP.md
  POST_MIGRATION_VERIFY.sql
  README.md
```

## Migration Files

| Migration | Purpose | Status |
|---|---|---|
| `202605040001_initial_schema.sql` | Creates main schema, indexes, helper functions, triggers, RLS policies, and comments. | Done in repo. |
| `202605060002_add_legacy_payload_columns.sql` | Adds `legacy_payload` JSONB columns to migrated tables. | Done in repo. |
| `202605060003_add_legacy_orphan_records.sql` | Adds `legacy_orphan_records` for imported Firebase rows that cannot satisfy FKs. | Done in repo. |
| `202605060004_add_firebase_auth_migration_bridge.sql` | Adds Firebase auth migration credential/config tables. | Done in repo. |

## Tables Found

| Table | Stores |
|---|---|
| `profiles` | Supabase Auth profile mirror, role, requested role, contact fields, Firebase UID. |
| `clinics` | Clinic names and addresses. |
| `doctors` | Doctor profile/scheduling metadata linked to profiles and clinics. |
| `mothers` | Mother demographic profile linked one-to-one to profile. |
| `first_encounters` | First maternal clinical encounter data including LNMP, EDD, HIV, diabetes, hypertension, cardiac disease, symptoms, and history. |
| `parities` | Parity history linked to first encounters. |
| `encounters` | Appointments and clinical encounter results. |
| `pregnancy_weeks` | Week-based pregnancy guidance content. |
| `period_tracker_settings` | Per-user cycle settings. |
| `period_tracker_entries` | Daily period tracker entries, symptoms, notes, and sexual activity JSON. |
| `chat_sessions` | Rudo chat sessions and migrated/live session state. |
| `chat_messages` | Rudo message history and payloads. |
| `legacy_firebase_refs` | Mapping from Firebase document paths to Supabase rows. |
| `legacy_orphan_records` | Firebase rows preserved because relationships could not be imported cleanly. |
| `firebase_auth_migration_credentials` | Legacy Firebase password hash material for migration. |
| `firebase_auth_migration_config` | Firebase SCRYPT hash config for migration. |

## Functions And Triggers

Confirmed helper functions include:

- `set_updated_at`
- `handle_new_auth_user`
- `current_app_role`
- `is_admin`
- `is_doctor`
- `owns_mother`
- `doctor_owns_doctor`
- `doctor_assigned_to_mother`
- `doctor_assigned_to_profile`
- `owns_chat_session`
- `can_read_chat_session`
- `can_access_first_encounter`
- `can_write_first_encounter`
- `is_patient_appointment_status`
- `prevent_profile_role_self_change`
- `prevent_patient_clinical_encounter_write`

Confirmed triggers include:

- Auth profile creation on `auth.users`.
- Updated-at triggers across app tables.
- Profile role self-change protection.
- Patient clinical encounter write protection.

## Row Level Security

RLS is enabled for the main app tables. The policy design in the SQL says:

- Patients can access their own profile/mother data.
- Patients can schedule/cancel appointment fields.
- Patients should not write clinical encounter fields.
- Doctors can access assigned patient/encounter data.
- Admins can read broad app data and manage specific admin-only resources.
- Chat history can be read by the patient, assigned doctors, and admins.

## Edge Functions

| Function | Purpose | Auth/Secrets |
|---|---|---|
| `rudo-chat` | Stores user message, calls Rudo backend or Gemini fallback, stores assistant reply. | Requires user JWT. Uses backend/Gemini secrets. |
| `gemini-proxy` | Authenticated helper for Gemini generate/count/image text actions. | Requires user JWT and `GEMINI_API_KEY`. |
| `elevenlabs-tts` | Authenticated TTS proxy for Rudo voice replies. | Requires user JWT and `ELEVENLABS_API_KEY`. |
| `firebase-auth-migrate-login` | Verifies Firebase password hash and updates Supabase password. | Must use `SUPABASE_SERVICE_ROLE_KEY`; callable before login. |

## Storage Buckets

No Supabase storage bucket migrations or storage policies were found. Storage needs are not confirmed in the current codebase.

## Setup Steps For A New Developer

1. Read `supabase/README.md` and `supabase/CLIENT_MIGRATION_MAP.md`.
2. Review all SQL migrations before applying them.
3. Link Supabase CLI to the correct project.
4. Apply migrations in order.
5. Run `supabase/POST_MIGRATION_VERIFY.sql`.
6. Deploy required Edge Functions.
7. Set required secrets.
8. Test auth, RLS, period tracker, appointments, Rudo chat, voice, and Firebase password migration fallback.

## Missing Or Unclear Items

- No storage bucket schema was found.
- No seed script was found for local demo data.
- No `.env.example` was found.
- Imported remote counts are documented in repo notes, but live data should be verified.
- The docs state the migration has been pushed/deployed, while some migration docs still include pre-application checklist language. I am preserving both as repo evidence until live status is confirmed.
