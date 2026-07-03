# Project Structure

This is the high-level structure I confirmed from the repository.

```text
dawa_mom/
  android/
  assets/
  docs/
  firebase/
  ios/
  lib/
    auth/
    backend/
    components/
    flutter_flow/
    navbar/
    services/
    app_state.dart
    dawa_splash_screen.dart
    index.dart
    main.dart
  supabase/
    functions/
    migrations/
    CLIENT_MIGRATION_MAP.md
    POST_MIGRATION_VERIFY.sql
    README.md
  test/
  tools/
  web/
  .gitignore
  .gitbook.yaml
  pubspec.yaml
  README.md
```

## Root Files

| Path | Purpose |
|---|---|
| `README.md` | Existing project overview, local checks, web preview, runtime config, and Supabase notes. |
| `pubspec.yaml` | Flutter package definition, dependencies, assets, fonts, app icon config. |
| `.gitignore` | Ignores build output, local config, logs, `.env` files, and local run files. |
| `.gitbook.yaml` | GitBook Sync config pointing GitBook at `./docs/`. |

## Flutter App

| Path | Purpose |
|---|---|
| `lib/main.dart` | App entrypoint, Supabase initialization, theme initialization, app state initialization, splash handling, router setup, bottom navigation. |
| `lib/index.dart` | Exports app pages for routing. |
| `lib/app_state.dart` | Stores app state, including persisted `motherRef` through `SharedPreferences`. |
| `lib/dawa_splash_screen.dart` | App splash/video startup behavior. |

## Authentication

| Path | Purpose |
|---|---|
| `lib/auth/supabase_auth/` | Active Supabase auth manager, auth utilities, Supabase user provider, JWT stream, and Firebase password migration fallback. |
| `lib/auth/login/` | Login UI and Supabase email sign-in action. |
| `lib/auth/register/` | Email registration UI and profile/mother row creation flow. |
| `lib/auth/create_account/` | Mother profile completion after signup. |
| `lib/auth/forgot_password/` | Supabase password reset UI. |
| `lib/auth/welcome/` | Welcome/auth screen assets and UI. |
| `lib/auth/auth_manager.dart` | Abstract/auth manager interface used by the Supabase implementation. |

## Backend And Data Layer

| Path | Purpose |
|---|---|
| `lib/backend/supabase/supabase_config.dart` | Supabase URL/key config and app startup session refresh. |
| `lib/backend/supabase/supabase_database.dart` | Supabase-backed compatibility adapter for FlutterFlow/Firestore-shaped generated code. |
| `lib/backend/backend.dart` | Exports record models and query helpers, and creates/updates profile rows. |
| `lib/backend/schema/` | Generated record classes for users, mothers, doctors, clinics, encounters, first encounters, parities, pregnancy weeks, and structs. |
| `lib/backend/period_tracker_service.dart` | Supabase service for period tracker settings and daily entries. |
| `lib/backend/gemini/gemini.dart` | Gemini helper wrapper through Supabase function invocation. |
| `lib/backend/main.py`, `lib/backend/api/` | Python/Rudo backend code. |
| `lib/backend/training/` | Rudo training and health content files, including pregnancy and cervical cancer data in multiple languages. |

## Screens And UI

| Path | Purpose |
|---|---|
| `lib/navbar/home/` | Home/dashboard, appointment summary, pregnancy guidance entry points, Rudo chat modal, voice mode. |
| `lib/navbar/profile/` | Mother profile display and sign-out entry. |
| `lib/navbar/edit_profile/` | Mother profile edit screen. |
| `lib/navbar/appointments/encounters/` | Appointment list. |
| `lib/navbar/appointments/appointment_details/` | Appointment status/details and cancellation. |
| `lib/navbar/appointments/encounter_details/` | Completed encounter results, including blood pressure and lab-result interpretations. |
| `lib/navbar/week/` | Pregnancy week detail page. |
| `lib/navbar/period_tracker/` | Period tracker UI and predictions. |
| `lib/components/` | Reusable appointment, booking, empty state, shimmer, and bottom-sheet components. |
| `lib/flutter_flow/` | FlutterFlow-generated utilities, theme, widgets, nav, serialization, calendar, animations, and custom functions. |

## Supabase

| Path | Purpose |
|---|---|
| `supabase/migrations/202605040001_initial_schema.sql` | Initial schema, indexes, triggers, RLS, helper functions, and comments. |
| `supabase/migrations/202605060002_add_legacy_payload_columns.sql` | Adds `legacy_payload` JSONB columns to migrated tables. |
| `supabase/migrations/202605060003_add_legacy_orphan_records.sql` | Preserves Firebase records that could not satisfy Supabase foreign keys. |
| `supabase/migrations/202605060004_add_firebase_auth_migration_bridge.sql` | Adds Firebase auth migration credential/config tables. |
| `supabase/functions/rudo-chat/` | Authenticated Rudo chat proxy and persistence Edge Function. |
| `supabase/functions/gemini-proxy/` | Authenticated Gemini helper Edge Function. |
| `supabase/functions/elevenlabs-tts/` | Authenticated ElevenLabs TTS proxy Edge Function. |
| `supabase/functions/firebase-auth-migrate-login/` | Firebase password hash verification and first-login migration function. |
| `supabase/POST_MIGRATION_VERIFY.sql` | SQL checks for RLS, policies, triggers, and required functions. |

## Firebase Remnants

| Path | Status |
|---|---|
| `firebase/functions/` | Empty folder in the workspace during this documentation pass. |
| `lib/backend/schema/util/firestore_util.dart` | Legacy helper names remain, but comments say they are Supabase-backed compatibility helpers. |
| `lib/backend/schema/*_record.dart` | Generated classes still use Firestore-style naming while routing through Supabase. |
| `supabase/*firebase*` | Migration bridge, Firebase reference mapping, and legacy import tables are intentional migration artifacts. |

## Assets

| Path | Purpose |
|---|---|
| `assets/images/` | Logos, onboarding images, pregnancy/period/no-data illustrations, doctor images, app icon assets, background image. |
| `assets/fonts/` | Poppins font files. |
| `assets/videos/` | Video asset folder. |
| `assets/Video_Not_a_GIF.mp4` | Splash or visual media asset. |
| `web/` | Flutter web shell, icons, manifest, and web assets. |

No committed app screenshots were found.
