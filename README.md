# DawaMom

DawaMom is a Flutter maternal health companion app. It supports patient onboarding, appointment views, pregnancy-week guidance, period tracking, and Rudo chat through Supabase-backed data and Edge Functions.

The active app runtime is Supabase-backed. Firebase project files, Firebase Gradle plugins, Firebase iOS pods, and Firebase platform config files are not used by the Flutter app.

## Tech Stack

- Flutter stable / Dart
- Supabase Auth, Postgres, Row Level Security, and Edge Functions
- Python Rudo backend code under `lib/backend`

## Languages

The app supports English, Nyanja, Bemba, Tonga, and Lozi. The selected
language is previewed immediately, stored locally, synced to the signed-in
profile when available, and applied to navigation, screen copy, forms,
validation, accessibility labels, date/time controls, and Rudo. The bundled
catalog works offline. Nuanced clinical and long-form educational translations
still require qualified native-language review before public-health release.

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

Voice playback uses the Supabase `sahara-tts` Edge Function by default. The
Sahara/Intron API key belongs in Supabase secrets, not in the Flutter app:

```powershell
supabase secrets set SAHARA_API_KEY="<sahara-api-key>" --project-ref himbfndvsuwiudtzjojh
supabase functions deploy sahara-tts --project-ref himbfndvsuwiudtzjojh
```

For local Flutter runs, no Sahara key is needed in the app. You can optionally
make the provider explicit:

```powershell
flutter run --dart-define=TTS_PROVIDER=sahara
```

`SAHARA_TTS_EDGE_FUNCTION` defaults to `sahara-tts`. The current verified
Sahara mappings use its female Zulu accent for English and its female Shona
accent for Shona; unsupported languages fall back to the device voice. Add a
new accent only after it has been confirmed by Sahara's supported-voice API.

The fallback OmniVoice-compatible endpoint still uses Dart defines:

```powershell
flutter run --dart-define=OMNIVOICE_API_URL="https://example.com/tts" --dart-define=OMNIVOICE_API_KEY="..."
```

Private Gemini, backend, and service-role keys should stay in Supabase Edge Function secrets or backend environment variables, not in Flutter client code.

## Offline behaviour

DawaMom supports local-first learning progress, reminder preferences, and a
cached clinic directory. Care also keeps a platform-secured, user-scoped
snapshot of the last successful appointment list for up to 24 hours. It stores
only the information needed to identify a visit on screen (date/time, general
visit type, status, and clinic/health-worker display names); it never caches
notes, reasons, contacts, payment references, or clinical summaries.

Learning transcripts and the lesson catalogue are bundled for offline reading.
Cloud-generated lesson audio is not downloaded: it may need a connection, with
the transcript remaining available when audio cannot play.

Saved Care data is clearly marked and display-only. A connection is always
required to book, cancel, pay for, confirm, or check availability for a visit.

## Supabase Notes

Migration docs and SQL live in `supabase/`. Some migration files still use legacy Firebase naming because they map/import old data, but those paths run through Supabase tables and Supabase Edge Functions. After changing Supabase-facing client code, verify:

- Auth sign-in and Firebase password migration fallback
- `period_tracker_settings` and `period_tracker_entries` reads/writes
- `rudo-chat` Edge Function invocation and chat history persistence
- RLS policies for patient, doctor, and admin roles

Patient appointment requests are stored in `public.appointments`; `public.encounters` is retained for legacy and clinician-owned clinical observations. New DawaMom bookings use `status = pending`, `source = dawa_mom`, and owner-scoped RLS. Apply all migrations before testing booking:

```powershell
supabase db push --linked
```

The clinician selector uses the booking-safe `get_bookable_clinicians` RPC over DawaMom's imported cache rows. The optional authenticated `clinician-directory` Edge Function is the adapter for the future authoritative Dawa Clinician endpoint; see `docs/dawa-clinician-integration-contract.md`.

After applying migrations, run `supabase/POST_MIGRATION_VERIFY.sql` and the transactional owner/non-owner/anonymous checks in `supabase/APPOINTMENTS_RLS_VERIFY.sql`.

`rudo-chat` stores chat history in Supabase, calls the configured Rudo backend, and falls back to Gemini from the Edge Function when the configured/backend fallback returns demo greeting data. Set the secret before deploying:

```powershell
supabase secrets set GEMINI_API_KEY="<gemini-api-key>" --project-ref himbfndvsuwiudtzjojh
supabase functions deploy rudo-chat --project-ref himbfndvsuwiudtzjojh
```
