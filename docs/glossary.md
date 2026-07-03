# Glossary

## Dawa Mom

The Flutter maternal health companion app documented here. It focuses on mother-facing workflows such as profile onboarding, appointments, pregnancy guidance, period tracking, encounter result viewing, and Rudo chat.

## Dawa Clinician

A related Dawa ecosystem concept/product for clinician workflows. No direct Dawa Clinician code dependency was confirmed in this repo, but the schema includes clinician-oriented concepts such as doctors, clinics, encounters, first encounters, and clinical result fields.

## Rudo

The assistant/chat workflow used in Dawa Mom. Rudo chat is shown from the Home screen, persisted in Supabase, and routed through the `rudo-chat` Edge Function. Python backend and training files also contain Rudo-related maternal health and cervical cancer content.

## Supabase

The active backend platform for the Flutter app. It provides auth, Postgres database, RLS, and Edge Functions.

## Firebase

The legacy backend being migrated away from. Active Flutter Firebase packages were not confirmed, but Firebase naming remains in migration files and compatibility helpers.

## Row Level Security

Postgres/Supabase policies that control which rows a logged-in user can read or write. In this project, RLS is used for patients, doctors, and admins.

## Edge Function

A Supabase-hosted server-side function. This repo includes Edge Functions for Rudo chat, Gemini proxy, ElevenLabs TTS, and Firebase password migration.

## Profile

The Supabase `profiles` row linked to `auth.users`. It stores user identity fields and role/requested role.

## Mother

The Supabase `mothers` row that stores maternal demographic profile data and links to a profile.

## Encounter

A Supabase `encounters` row. It represents both appointment data and completed clinical encounter results.

## First Encounter

The initial maternal clinical intake/history record, including LNMP, EDD, chronic disease fields, symptoms, and risk/history data.

## Parity

Pregnancy/birth history linked to a first encounter.

## Blood Pressure

A vital sign usually written as systolic over diastolic, such as `120/80`. In this repo, BP is stored as text in encounter rows and interpreted by a helper function.

## Systolic

The top blood pressure number. It represents pressure when the heart contracts.

## Diastolic

The bottom blood pressure number. It represents pressure when the heart rests between beats.

## Chronic Disease Input

Health history fields such as diabetes, hypertension, cardiac disease, asthma, TB, epilepsy, and sickle cell. These are present in first encounter records but not yet confirmed as inputs to BP interpretation.

## Health Interpretation

The app's basic rule-based labels for values such as blood pressure, hydration, pH, pulse, urine indicators, and pregnancy timing. These need clinical review before they are treated as medical guidance.

## Offline Mode

An app mode that allows use without network connectivity. Full offline mode is not confirmed in this repo. Current local persistence is limited.

## RLS

Short for Row Level Security.

## GitBook

The documentation platform this `/docs` structure is prepared for. GitBook Sync reads `docs/README.md` and `docs/SUMMARY.md` through `.gitbook.yaml`.
