# Dawa Mom

Dawa Mom is a Flutter maternal health companion app. It supports patient onboarding, appointment views, pregnancy-week guidance, period tracking, and Rudo chat through Supabase-backed data and Edge Functions.

The active app runtime is Supabase-backed. Firebase project files, Firebase Gradle plugins, Firebase iOS pods, and Firebase platform config files are not used by the Flutter app.

## Tech Stack

- Flutter stable / Dart
- Supabase Auth, Postgres, Row Level Security, and Edge Functions
- Python Rudo backend code under `lib/backend`

## Local Checks

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

## Web Preview

Build the web app, then serve the generated files:

```powershell
flutter build web
node tools/serve_flutter_web.mjs build/web
```

The server defaults to `http://127.0.0.1:8080`. Set `PORT` to use another port.

## Runtime Configuration

Supabase is initialized from `lib/backend/supabase/supabase_config.dart`. The production defaults are checked in for the public URL and anon key, and can be overridden for staging/local builds:

```powershell
flutter run --dart-define=SUPABASE_URL="https://project.supabase.co" --dart-define=SUPABASE_ANON_KEY="..."
```

Voice playback uses the Supabase `elevenlabs-tts` Edge Function by default. The ElevenLabs API key belongs in Supabase secrets, not in the Flutter app:

```powershell
supabase secrets set ELEVENLABS_API_KEY="<elevenlabs-api-key>" --project-ref himbfndvsuwiudtzjojh
supabase secrets set ELEVENLABS_VOICE_ID="EXAVITQu4vr4xnSDxMaL" ELEVENLABS_MODEL_ID="eleven_multilingual_v2" --project-ref himbfndvsuwiudtzjojh
supabase functions deploy elevenlabs-tts --project-ref himbfndvsuwiudtzjojh
```

For local Flutter runs, no ElevenLabs key is needed in the app. You can optionally make the provider explicit:

```powershell
flutter run --dart-define=TTS_PROVIDER=elevenlabs --dart-define=ELEVENLABS_VOICE_ID="EXAVITQu4vr4xnSDxMaL"
```

`ELEVENLABS_EDGE_FUNCTION` defaults to `elevenlabs-tts`, and `ELEVENLABS_MODEL_ID` defaults to `eleven_multilingual_v2`.

The fallback OmniVoice-compatible endpoint still uses Dart defines:

```powershell
flutter run --dart-define=OMNIVOICE_API_URL="https://example.com/tts" --dart-define=OMNIVOICE_API_KEY="..."
```

Private Gemini, backend, and service-role keys should stay in Supabase Edge Function secrets or backend environment variables, not in Flutter client code.

## Supabase Notes

Migration docs and SQL live in `supabase/`. Some migration files still use legacy Firebase naming because they map/import old data, but those paths run through Supabase tables and Supabase Edge Functions. After changing Supabase-facing client code, verify:

- Auth sign-in and Firebase password migration fallback
- `period_tracker_settings` and `period_tracker_entries` reads/writes
- `rudo-chat` Edge Function invocation and chat history persistence
- RLS policies for patient, doctor, and admin roles

Patient appointment requests are stored in `public.appointments`; `public.encounters` is retained for legacy and clinician-owned clinical observations. New Dawa Mom bookings use `status = pending`, `source = dawa_mom`, and owner-scoped RLS. Apply all migrations before testing booking:

```powershell
supabase db push --linked
```

The clinician selector uses the booking-safe `get_bookable_clinicians` RPC over Dawa Mom's imported cache rows. The optional authenticated `clinician-directory` Edge Function is the adapter for the future authoritative Dawa Clinician endpoint; see `docs/dawa-clinician-integration-contract.md`.

After applying migrations, run `supabase/POST_MIGRATION_VERIFY.sql` and the transactional owner/non-owner/anonymous checks in `supabase/APPOINTMENTS_RLS_VERIFY.sql`.

`rudo-chat` stores chat history in Supabase, calls the configured Rudo backend, and falls back to Gemini from the Edge Function when the configured/backend fallback returns demo greeting data. Set the secret before deploying:

```powershell
supabase secrets set GEMINI_API_KEY="<gemini-api-key>" --project-ref himbfndvsuwiudtzjojh
supabase functions deploy rudo-chat --project-ref himbfndvsuwiudtzjojh
```
