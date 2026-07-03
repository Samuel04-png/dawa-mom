# Dawa Mom Documentation

Dawa Mom is a Flutter maternal health companion app in the wider Dawa health ecosystem. I built this app around mother and pregnancy workflows: onboarding, profile completion, appointment views, pregnancy-week guidance, period tracking, clinical encounter results, and Rudo chat.

The current repo is Supabase-backed. The Flutter app initializes Supabase directly, uses Supabase Auth, reads and writes through a Supabase compatibility layer, and includes Supabase SQL migrations and Edge Functions for Rudo chat, Gemini helper calls, ElevenLabs voice output, and Firebase password migration.

## Who This Is For

These docs are written for developers, project managers, client reviewers, and future team members who need to understand what the Dawa Mom repo currently contains.

## Main Features Confirmed In The Repo

- Supabase Auth with email signup, email login, password reset, OAuth/phone manager scaffolding, and session refresh handling.
- Firebase password migration fallback through the `firebase-auth-migrate-login` Supabase Edge Function.
- Supabase PostgreSQL schema for profiles, clinics, doctors, mothers, first encounters, parities, appointments/encounters, pregnancy weeks, period tracking, chat sessions, and chat messages.
- FlutterFlow-compatible data adapter that maps legacy collection names like `mother` and `encounter` to Supabase tables like `mothers` and `encounters`.
- Mother profile onboarding and edit profile flows.
- Appointment booking, appointment cancellation, appointment listing, and completed encounter-result viewing.
- Pregnancy-week content based on the mother's first encounter LNMP.
- Period tracker with Supabase-backed settings, daily symptoms, notes, and sexual activity entries.
- Rudo chat modal that stores messages in Supabase and sends requests through the `rudo-chat` Edge Function.
- Voice mode for Rudo using speech-to-text and TTS through ElevenLabs or OmniVoice-compatible fallback configuration.
- Basic health interpretation helpers for blood pressure, hydration, pH, pulse, and urine/encounter indicators.

## Current Development Status

The app is actively migrated to Supabase at the Flutter client level. The repo includes migration notes stating that the initial SQL migration and key Edge Functions have been deployed to the configured Supabase project. I have not independently verified the live Supabase project from this documentation pass, so deployment and imported remote counts are documented as repo-confirmed notes.

Some areas still need review:

- The local ignored file `lib/backend/.env.txt` contains real credentials in this workspace and must never be synced to GitHub or GitBook.
- The patient-specific `motherRef` is persisted in local app state and still needs careful review against the intended Supabase patient isolation model.
- There is no confirmed standalone patient-facing blood pressure monitor page. Blood pressure exists as an encounter result field and interpretation helper.
- No real app screenshots are committed in the repo.

## Quick Links

- [Overview](overview.md)
- [Architecture](architecture.md)
- [Completed Tasks](completed-tasks.md)
- [Firebase to Supabase](firebase-to-supabase.md)
- [Database and Backend](database-and-backend.md)
- [Authentication](authentication.md)
- [Mother Health Workflows](mother-health-workflows.md)
- [Blood Pressure Monitor](blood-pressure-monitor.md)
- [Known Issues](known-issues.md)

## Project Owner Note

I want this documentation to stay honest and useful. If a feature is confirmed from code, migrations, README files, or repo notes, I document it as implemented. If something is only implied, partially wired, or mentioned without code evidence, I mark it as needing confirmation instead of presenting it as finished.
