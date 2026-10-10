# Testing DawaMom

This repository includes the public client configuration required for a normal
development build. Private backend credentials are stored on the deployed
services and are not required on a tester's computer.

## Quick start

```bash
git clone https://github.com/Samuel04-png/dawa-mom.git
cd dawa-mom
git checkout feature/dawa-mom-screens
flutter pub get
flutter analyze
flutter test
flutter run
```

Choose a connected Android device, iOS simulator, or Chrome when Flutter asks
for a target.

## Test account

Use the registration screen to create a separate test account. Do not share an
administrator or production staff account with a tester.

## Runtime configuration

The checked-in Flutter configuration contains the public Supabase project URL
and anonymous client key. Authentication, database access, chat, voice,
appointment booking, clinician synchronization, and notification processing
use the deployed Supabase project and its server-side functions.

Appointment requests can be created without provider credentials on the
tester’s computer. Outbound appointment email delivery additionally requires
an email provider key and verified sender configured on the deployed backend.

Private service credentials must stay on those services. They should never be
placed in a Flutter build, copied into this repository, or sent with a test
account.

For a different staging project, override only its public client values:

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-public-anon-key"
```

## Expected verification

Before handing off a build, these commands should complete successfully:

```bash
flutter analyze
flutter test
```

Some features require an internet connection because they communicate with the
deployed backend.
