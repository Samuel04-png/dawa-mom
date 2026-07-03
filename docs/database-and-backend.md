# Database And Backend

The app has two backend areas:

- Supabase, which is the active app backend.
- Python/Rudo backend code under `lib/backend/`, which supports Rudo/WhatsApp-style assistant flows and legacy backend functionality.

## Supabase Database Tables

| Table | What It Appears To Store | Important Relationships |
|---|---|---|
| `profiles` | Auth profile mirror with role and requested role. | `id` references `auth.users(id)`. |
| `mothers` | Mother demographics and profile data. | `profile_id` references `profiles(id)` and is unique. |
| `doctors` | Doctor metadata and scheduling fields. | Optional `profile_id` and `clinic_id`. |
| `clinics` | Clinic lookup data. | Referenced by doctors and encounters. |
| `first_encounters` | First clinical intake/maternal history. | `mother_id` references `mothers(id)`. |
| `parities` | Parity/pregnancy history. | `first_encounter_id` references `first_encounters(id)`. |
| `encounters` | Appointments and clinical result fields. | References mothers, doctors, and clinics. |
| `pregnancy_weeks` | Week guidance content. | Read by week number. |
| `period_tracker_settings` | User cycle settings. | `profile_id` references `profiles(id)`. |
| `period_tracker_entries` | Daily tracker entries. | `profile_id` references `profiles(id)`, unique per date. |
| `chat_sessions` | Rudo session state. | `profile_id` references `profiles(id)`. |
| `chat_messages` | Rudo message rows. | `session_id` references `chat_sessions(id)`. |
| `legacy_firebase_refs` | Firebase path to Supabase row mapping. | Used during/after migration. |
| `legacy_orphan_records` | Preserved Firebase records with missing parents/FKs. | Admin-managed. |
| `firebase_auth_migration_credentials` | Firebase password migration rows. | Links to profiles. |
| `firebase_auth_migration_config` | Firebase SCRYPT config. | Singleton config table. |

## Supabase Data Access In Flutter

The app uses two styles:

1. Compatibility record access through `SupabaseDatabase`, which lets generated FlutterFlow code keep using `DocumentReference`, `Query`, and record classes.
2. Direct Supabase table calls for newer service areas like period tracking and Rudo chat.

Examples:

- `MotherRecord.collection.doc(...)` resolves through Supabase compatibility code.
- `PeriodTrackerService` directly calls `period_tracker_settings` and `period_tracker_entries`.
- Rudo chat directly calls `chat_sessions`, `chat_messages`, and the `rudo-chat` Edge Function.

## Backend Services

| Service/File | Purpose |
|---|---|
| `lib/backend/supabase/supabase_database.dart` | Main Supabase compatibility database adapter. |
| `lib/backend/period_tracker_service.dart` | Period tracker Supabase service. |
| `lib/backend/gemini/gemini.dart` | Gemini helper through Supabase function invocation. |
| `lib/services/voice_service.dart` | Speech-to-text, TTS, ElevenLabs function invocation, OmniVoice fallback, device TTS fallback. |
| `supabase/functions/rudo-chat/index.ts` | Stores chat history and proxies assistant requests. |
| `supabase/functions/gemini-proxy/index.ts` | Authenticated Gemini proxy. |
| `supabase/functions/elevenlabs-tts/index.ts` | Authenticated ElevenLabs proxy. |
| `supabase/functions/firebase-auth-migrate-login/index.ts` | Firebase password migration bridge. |
| `lib/backend/main.py` and `lib/backend/api/index.py` | Python Flask Rudo/WhatsApp backend logic. |

## Python Backend

The Python backend uses:

- Flask
- google-generativeai
- SQLAlchemy
- Redis / Upstash Redis
- WhatsApp Graph API
- Training data under `lib/backend/training/`

The backend has Vercel config in `lib/backend/vercel.json` and a Procfile in `lib/backend/Procfile.txt`.

## Known Backend Risks

- The ignored local `lib/backend/.env.txt` contains real credentials in this workspace.
- Python backend and Supabase Edge Function Rudo paths overlap; ownership of the final production assistant path should be confirmed.
- Rudo chat Edge Function has a default backend URL fallback; production should use configured secrets.
- No local seed/demo database script was found.
- RLS policies exist but need role-based testing against real sessions.

## Missing Schema Or Migrations

I did not find:

- Supabase storage bucket migrations.
- A dedicated blood pressure readings table.
- A standalone reminders table.
- A notifications table.
- A documented deployment-specific seed/import script.

These may be planned, but they are not confirmed in the current codebase.
