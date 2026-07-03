# Setup And Installation

This page documents the local setup flow confirmed from the repo. It does not require Firebase for the active Flutter app runtime.

## Prerequisites

- Flutter stable with Dart SDK compatible with `>=3.0.0 <4.0.0`.
- Android Studio or Xcode if building mobile targets.
- Node.js if serving the built web app through `tools/serve_flutter_web.mjs`.
- Supabase CLI if applying migrations or deploying Edge Functions.
- Access to the correct Supabase project if testing live data/auth/functions.

## Install Flutter Dependencies

```powershell
flutter pub get
```

## Run Static Analysis

```powershell
flutter analyze --no-pub
```

## Run Tests

```powershell
flutter test --no-pub
```

Current test coverage is small, so passing tests should not be treated as a full release signoff.

## Run The App Locally

Use Flutter as normal:

```powershell
flutter run
```

For a staging/local Supabase project, override the Supabase config with Dart defines:

```powershell
flutter run `
  --dart-define=SUPABASE_URL="your_supabase_url" `
  --dart-define=SUPABASE_ANON_KEY="your_supabase_anon_key"
```

Do not put service-role keys in Flutter.

## Build Web

```powershell
flutter build web
```

## Serve Web Build

```powershell
node tools/serve_flutter_web.mjs build/web
```

The helper server defaults to:

```text
http://127.0.0.1:8080
```

To change the port:

```powershell
$env:PORT="8090"
node tools/serve_flutter_web.mjs build/web
```

## Supabase Setup For A New Developer

1. Install and log into the Supabase CLI.
2. Link the local `supabase/` folder to the correct project.
3. Review every migration before applying it.
4. Apply migrations in filename order.
5. Run `supabase/POST_MIGRATION_VERIFY.sql`.
6. Deploy only the Edge Functions needed for the environment.
7. Set secrets through Supabase secrets, not client code.

## Edge Function Deployment

Examples with placeholders:

```powershell
supabase functions deploy rudo-chat --project-ref your_project_ref
supabase functions deploy gemini-proxy --project-ref your_project_ref
supabase functions deploy elevenlabs-tts --project-ref your_project_ref
supabase functions deploy firebase-auth-migrate-login --project-ref your_project_ref
```

## Important Local Security Note

The ignored local file `lib/backend/.env.txt` exists in this workspace and contains real credentials. It is ignored by `.gitignore`, but it should still be treated as sensitive local material:

- Do not commit it.
- Do not copy its values into docs.
- Rotate exposed credentials if they have ever been shared.
- Use environment-specific secret managers instead.

## Setup Gaps

- There is no committed `.env.example` for backend/Python variables.
- There is no one-command Supabase local bootstrap script.
- There are no docs proving storage buckets are required.
- There are no committed screenshots for setup verification.
