# Technology Stack

| Area | Technology | Evidence | Notes |
|---|---|---|---|
| Mobile/Web app framework | Flutter | `pubspec.yaml`, `lib/main.dart`, `android/`, `ios/`, `web/` | The app is Flutter with generated FlutterFlow-style structure. |
| Language | Dart | `lib/**/*.dart` | Main app code, generated models, services, widgets. |
| Backend platform | Supabase | `supabase/`, `supabase_flutter`, `lib/backend/supabase/` | Active app backend for auth, database, RLS, and Edge Functions. |
| Database | Supabase Postgres | `supabase/migrations/*.sql` | Schema includes profiles, mothers, encounters, period tracking, chat, and migration tables. |
| Auth | Supabase Auth | `lib/auth/supabase_auth/` | Email auth, session stream, password reset, OAuth/phone scaffolding. |
| Legacy auth migration | Firebase password bridge | `supabase/functions/firebase-auth-migrate-login/` | First-login password migration after invalid Supabase login. |
| Edge Functions | Supabase Edge Functions / Deno TypeScript | `supabase/functions/*/index.ts` | Rudo chat, Gemini proxy, ElevenLabs TTS, Firebase auth migration. |
| Rudo backend | Python Flask | `lib/backend/main.py`, `lib/backend/api/`, `lib/backend/requirements.txt` | Includes WhatsApp/Rudo backend logic and training data. |
| AI helper | Gemini through Edge Function/backend | `supabase/functions/gemini-proxy/`, `supabase/functions/rudo-chat/` | API keys stay outside Flutter client. |
| Voice/TTS | speech_to_text, audioplayers, flutter_tts, ElevenLabs | `lib/services/voice_service.dart`, `pubspec.yaml` | Rudo voice input/output. |
| Local persistence | SharedPreferences | `lib/app_state.dart`, `flutter_flow_theme.dart` | Theme mode and mother reference persistence. |
| Local DB package | sqflite | `pubspec.yaml` | Dependency exists, but active offline sync was not confirmed. |
| Routing | go_router | `pubspec.yaml`, `lib/flutter_flow/nav/nav.dart` | App routes and auth navigation wrappers. |
| State management | provider | `pubspec.yaml`, `lib/main.dart` | `FFAppState` is provided at app startup. |
| UI framework | Flutter Material + FlutterFlow widgets | `lib/flutter_flow/`, `lib/components/` | Custom FlutterFlow theme and components. |
| Fonts | Poppins | `assets/fonts/`, `pubspec.yaml` | App font family. |
| Calendar UI | table_calendar / FlutterFlow calendar | `pubspec.yaml`, `lib/navbar/period_tracker/` | Period tracker and booking calendar support. |
| Testing | flutter_test | `test/` | Two focused tests are currently present. |
| Web preview | Node static server | `tools/serve_flutter_web.mjs` | Serves `build/web` at `127.0.0.1:8080` by default. |
| Deployment config | Vercel Python backend config | `lib/backend/vercel.json`, `lib/backend/Procfile.txt` | Backend deployment artifacts exist for Python/Rudo backend. |

## Important Packages From `pubspec.yaml`

| Package | Purpose |
|---|---|
| `supabase_flutter` | Supabase client, auth, functions. |
| `go_router` | App routing. |
| `provider` | App state injection. |
| `shared_preferences` | Persisted theme and app state values. |
| `sqflite` / `sqflite_common` | Local database dependency, active offline sync not confirmed. |
| `table_calendar` | Calendar UI support. |
| `flutter_animate` | UI animations. |
| `google_fonts` | Font handling. |
| `speech_to_text` | Rudo voice input. |
| `audioplayers` | Playing TTS audio bytes. |
| `flutter_tts` | Device fallback text-to-speech. |
| `http` | HTTP calls for fallback voice provider. |
| `cached_network_image` and `flutter_cache_manager` | Image caching support. |
| `video_player` and `chewie` | Video/splash media support. |
