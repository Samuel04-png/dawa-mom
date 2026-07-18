# Deployment Notes

## Current Dawa platform status

The cross-project Supabase backend rollout was completed and reconciled on 18 July 2026. It does not by itself publish Flutter web/mobile clients. Follow the verified order in [Dawa Platform Integration](dawa-platform-integration.md) for another environment; never link this repository to the Clinician project.

The Dawa Mom integration assets are migrations `202607170001` and `202607180001`, functions `clinician-directory`, `process-dawa-platform-outbox` and `receive-dawa-clinician-appointment-status`, plus the Vault-backed one-minute worker schedule.

## General application deployment status

Deployment is partially documented in the repo. Flutter build commands, web preview, Supabase function deploy commands, and Python/Vercel backend config are present. A complete production release runbook is not confirmed.

## Flutter Build

Run local checks first:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

Build web:

```powershell
flutter build web
```

Serve the web build locally:

```powershell
node tools/serve_flutter_web.mjs build/web
```

## Android Build

The Android project is configured under `android/`.

Build command:

```powershell
flutter build apk
```

For release signing, `android/key.properties` is ignored and should be supplied locally/securely.

## iOS Build

The iOS project is configured under `ios/`.

Build command:

```powershell
flutter build ios
```

Needs confirmation:

- Apple signing team.
- Bundle ID and release provisioning.
- App Store/TestFlight process.

## Supabase Deployment

1. Link the Supabase project.
2. Apply migrations.
3. Run `supabase/POST_MIGRATION_VERIFY.sql`.
4. Deploy required Edge Functions.
5. Set required secrets.
6. Test auth, RLS, period tracker, appointments, Rudo, and voice.

Example with placeholders:

```powershell
supabase functions deploy rudo-chat --project-ref your_project_ref
supabase functions deploy gemini-proxy --project-ref your_project_ref
supabase functions deploy elevenlabs-tts --project-ref your_project_ref
supabase functions deploy firebase-auth-migrate-login --project-ref your_project_ref
```

## Python/Rudo Backend Deployment

Confirmed files:

- `lib/backend/vercel.json`
- `lib/backend/Procfile.txt`
- `lib/backend/requirements.txt`

The Vercel config points Python routing to `main.py`. The Procfile points gunicorn at `backend.main:app`.

Needs confirmation:

- Final production hosting target.
- Required environment variables.
- Redis/Upstash setup.
- WhatsApp webhook verification.
- Whether the Python backend is still the production Rudo backend or only legacy/support code.

## Environment Variables

Use placeholders and secret managers. Do not put real secrets in GitBook or Flutter client code.

See [Environment Variables](environment-variables.md).

## Known Build/Deployment Issues

- No complete production runbook was found.
- No CI workflow file was found.
- No GitHub Actions deployment config was found.
- No screenshots from a deployed build are committed.
- Supabase function secrets must be manually confirmed.
- Local ignored `.env` file contains credentials and must not be used as deployment documentation.

## Deployment Verification

- [ ] Flutter app builds.
- [ ] Web preview works.
- [ ] Supabase migrations applied.
- [ ] RLS verification SQL passes.
- [ ] Edge Functions deploy.
- [ ] Secrets are present.
- [ ] Auth works.
- [ ] Appointment booking works.
- [ ] Period tracker persists.
- [ ] Rudo chat persists.
- [ ] Voice mode works or is gracefully disabled.
- [ ] No secrets are exposed in client bundle or docs.
