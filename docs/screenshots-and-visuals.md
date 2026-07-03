# Screenshots And Visuals

## Current Screenshot Status

No committed app screenshots were found in the repo.

I found app assets and illustrations under `assets/images/`, but I did not find actual captured screenshots of screens such as Login, Home, Appointment Details, Period Tracker, or Rudo chat. I am not adding fake screenshots.

## Existing Visual Assets

Confirmed assets include:

- Dawa logo and icon assets.
- Login/register illustrations.
- Pregnancy illustrations.
- Period/menstrual calendar illustration.
- No-data illustration.
- Doctor images.
- Splash/background media.

These are product assets, not screenshots.

## Screenshot Capture Checklist

Capture these before connecting the docs to a client-facing GitBook:

- [ ] Register screen.
- [ ] Login screen.
- [ ] Forgot password screen.
- [ ] Profile completion screen.
- [ ] Home/dashboard.
- [ ] Upcoming appointment card.
- [ ] No upcoming appointments state.
- [ ] Schedule appointment bottom sheet.
- [ ] Appointments list.
- [ ] Appointment details.
- [ ] Completed encounter results.
- [ ] Blood pressure result display.
- [ ] Pregnancy week detail.
- [ ] Period tracker overview.
- [ ] Period tracker settings.
- [ ] Period tracker daily symptoms/notes.
- [ ] Mother profile.
- [ ] Edit profile.
- [ ] Rudo chat modal.
- [ ] Rudo voice mode.
- [ ] Offline/error state if implemented later.

## Architecture Diagram

```mermaid
flowchart TD
  A[Dawa Mom Flutter App] --> B[Supabase Auth]
  A --> C[Supabase Compatibility Data Layer]
  C --> D[Supabase Postgres]
  A --> E[Mother Health Workflows]
  E --> F[Appointments]
  E --> G[Pregnancy Weeks]
  E --> H[Period Tracker]
  A --> I[Rudo Chat]
  I --> J[rudo-chat Edge Function]
  J --> K[chat_sessions And chat_messages]
```

## Firebase To Supabase Migration Flow

```mermaid
flowchart LR
  A[Legacy Firebase Auth And Firestore Data] --> B[Export And Mapping]
  B --> C[Supabase Tables]
  B --> D[legacy_firebase_refs]
  B --> E[legacy_payload]
  B --> F[legacy_orphan_records]
  A --> G[Firebase Password Hashes]
  G --> H[firebase_auth_migration_credentials]
  H --> I[firebase-auth-migrate-login]
  I --> J[Supabase Auth Password Updated]
```

## Blood Pressure Interpretation Flow

```mermaid
flowchart TD
  A[Encounter bp Field] --> B[Parse systolic/diastolic]
  B --> C{Valid Format?}
  C -->|No| D[Invalid Input]
  C -->|Yes| E[Apply Basic Thresholds]
  E --> F[Result Label]
  F --> G[Encounter Details UI]
  G --> H[Needs Clinical Review]
```

## Offline Mode Flow

```mermaid
flowchart TD
  A[App Opens] --> B[Read Local SharedPreferences]
  B --> C[Initialize Supabase]
  C --> D{Session Exists?}
  D -->|Yes| E[Refresh Session]
  E -->|Success| F[Use Supabase Data]
  E -->|Fail| G[Local Sign Out]
  D -->|No| H[Logged Out Flow]
```

## User Journey Flow

```mermaid
journey
  title Dawa Mom Mother Journey
  section Account
    Register: 4: Mother
    Complete profile: 4: Mother
  section Care
    View home dashboard: 4: Mother
    Schedule appointment: 4: Mother
    Review appointment details: 3: Mother
    View completed encounter results: 3: Mother
  section Guidance
    Read pregnancy week content: 4: Mother
    Track period symptoms: 4: Mother
    Ask Rudo: 4: Mother
```

## Where Future Images Should Go

Place future captured screenshots here:

```text
docs/assets/screenshots/
```

Place exported static diagrams here only if Mermaid is not enough:

```text
docs/assets/diagrams/
```

Use relative image links from Markdown after the real files exist in `docs/assets/screenshots/`.
