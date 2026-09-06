# Dawa Mom refinement report

## Scope

This refinement is limited to Dawa Mom. It extends the existing responsive
shell, Supabase maternal profile model, appointment repository, and Period
Tracker rather than creating parallel systems.

## Branding

- Expanded desktop: the reusable `DawaMomLogo.full` composes the transparent
  maternal `app_logo_2.png` icon with a rendered “Dawa Mom” wordmark.
- Login, registration, and welcome surfaces use the same full variant.
- Collapsed desktop and tablet: `DawaMomLogo.compact` uses only
  `app_logo_2.png`.
- `Logos-06.png`, `dawa_text2.png`, and the cross assets were inspected but
  still display Dawa Health artwork, so they are intentionally not used as the
  Dawa Mom wordmark.
- `assets/images/` is already registered in `pubspec.yaml`.

## User journeys

- Registration saves the personal profile and then opens an optional Period
  Tracker setup step with Back, Continue, and Skip for now.
- Skipping creates no fake period and records only a skip timestamp on the
  authenticated profile.
- Profile Completion independently reports and updates personal, contact,
  pregnancy-relevance, and period sections.
- Period setup is available from registration, Profile Completion, Settings,
  the dashboard summary, and the Period Tracker empty state.
- Period history is stored in the existing `period_tracker_entries` table and
  supports adding, correcting, and removing period markers without deleting
  daily symptoms or notes.
- Appointment cards and overflow menus open the existing appointment-details
  route. Details include status, times, clinician/clinic context, reason,
  notes, source, created time, and a secondary technical ID. Only View and the
  implemented Cancel workflow are shown.
- The old Profile destination and route now resolve to Settings. Appearance is
  controlled only from Settings, and destructive account deletion requires
  typing `DELETE` before calling a server-side self-delete RPC.
- A five-step, keyboard-accessible app walkthrough persists completion on the
  Supabase profile with a per-user local cache and can be replayed from
  Settings.

## Database migration

`202607150002_complete_dawa_mom_user_journeys.sql` adds:

- server-backed walkthrough completion fields;
- a period-setup skip timestamp;
- pregnancy relevance on the existing maternal profile;
- period start/end markers on existing tracker entries;
- a constrained patient health-profile RPC;
- an authenticated self-delete RPC that can delete only `auth.uid()`.

RLS remains enabled. No service-role credential is present in Flutter.

## Manual verification

1. Register a new account, complete personal details, choose Back once, then
   Skip for now. Confirm Home opens and no period estimate is fabricated.
2. Open Period Tracker and confirm the setup empty state. Complete setup and
   verify calendar estimates and cycle history refresh immediately.
3. Edit and delete a period-history marker; confirm daily notes remain.
4. Open Complete Profile and independently update personal, pregnancy, and
   period sections. Return to Home and confirm the summary text updates.
5. Book an appointment, tap its card, and use the overflow View details action.
   Confirm only Cancel appears when the status allows it.
6. At 390, 768, 1024, 1366, and 1440 px, verify mobile bottom navigation,
   tablet rail, and desktop expanded/collapsed branding.
7. Confirm the app tour appears once for a new profile, Skip persists, and
   Settings → Replay app tour opens it again.
8. In Settings, confirm appearance changes the theme, Logout is separate from
   Danger zone, and Delete remains disabled until exact `DELETE` input.

## Automated verification

- `flutter analyze --no-pub`: clean.
- `flutter test --no-pub --reporter expanded`: 21 tests passed, followed by
  the added five-breakpoint shell test (22 total tests passing).
- `supabase db lint --linked --level warning`: no schema errors.
- Web release build: local compiler produced no diagnostic but exceeded the
  ten-minute command limit.
- Android build: not runnable on this workstation because no Android SDK is
  installed (`flutter doctor -v`).
