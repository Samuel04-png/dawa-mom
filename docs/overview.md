# Overview

Dawa Mom focuses on maternal health workflows for mothers and expectant mothers. The app combines profile onboarding, appointment access, pregnancy information, cycle tracking, clinical result viewing, and Rudo support into one Flutter application.

## Problem The App Solves

The project is designed to give mothers a structured place to access pregnancy-related guidance, book and review appointments, keep track of period/cycle information, and interact with Rudo for maternal-health questions. On the backend side, the project also moves the old Firebase-shaped data model into a Supabase-backed model with stronger PostgreSQL structure, RLS policies, and Edge Function boundaries for sensitive services.

## Main Workflows

- A mother registers with email and password.
- The app creates or updates a Supabase-backed profile row and mother row.
- The mother completes demographic profile fields such as name, date of birth, phone number, occupation, and address.
- The home screen reads the mother's records and appointment data.
- The mother can schedule appointments by choosing date, clinic, clinician, and time slot.
- Appointment records can be listed, opened, cancelled when scheduled, and reviewed when completed.
- Pregnancy-week guidance is calculated from first encounter LNMP and loaded from `pregnancy_weeks`.
- Period tracking stores cycle settings and daily entries in Supabase.
- Rudo chat stores session/message history in Supabase and sends the live assistant request through an Edge Function.

## What Has Already Been Built

I confirmed these areas directly from the repo:

- Flutter app startup initializes Supabase in `lib/main.dart`.
- Supabase config is defined in `lib/backend/supabase/supabase_config.dart`.
- Supabase auth manager and user streams live in `lib/auth/supabase_auth/`.
- Supabase compatibility reads/writes live in `lib/backend/supabase/supabase_database.dart`.
- Supabase migrations and verification SQL live under `supabase/`.
- Edge Functions live under `supabase/functions/`.
- Maternal profile, appointment, pregnancy week, period tracker, and Rudo chat UI code lives under `lib/navbar/`, `lib/auth/`, `lib/components/`, and `lib/services/`.

## What Is Still In Progress

Some areas are not fully confirmed as complete:

- A dedicated mother-facing blood pressure monitor page with systolic/diastolic entry, age input, chronic disease input, saved results, and recommendations was not found.
- Doctor/admin role data exists in the schema, but the app UI I found is mainly mother/patient-facing.
- Offline support is limited to persisted app state/theme and Supabase session persistence. I did not find a complete offline data sync queue.
- The repo has no committed screenshots.
- Some migration docs contain both completed migration notes and "before applying" checklist language, so the final live environment should be verified before a release handoff.

## Dawa Ecosystem Fit

Dawa Mom is part of the Dawa health ecosystem. It focuses on maternal and mother-facing workflows, while the repo also contains Rudo backend and training assets for maternal health and cervical cancer education. It shares healthcare concepts with the wider Dawa product family: profiles, appointments, clinicians/doctors, encounters, clinical results, and patient guidance.

## Relationship To Dawa Clinician

No direct Dawa Clinician code relationship was confirmed in this repo. I found workflow overlap in the data model: doctors, clinics, encounters, first encounters, and clinical result fields. I did not find a shared package, imported Dawa Clinician module, or direct reference to a Dawa Clinician repository.

## Rudo Relationship

Rudo is confirmed as an in-app assistant workflow and backend/Edge Function integration. The repo includes:

- `lib/navbar/home/home_widget.dart` for the Rudo chat modal.
- `lib/services/voice_service.dart` for speech and TTS support.
- `supabase/functions/rudo-chat/` for the Supabase-side chat proxy.
- `lib/backend/training/` and Python backend files for Rudo-related knowledge and WhatsApp/backend flows.

I did not confirm a separate Rudo design system dependency in this repo.
