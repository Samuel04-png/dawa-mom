# Dawa Mom readiness report

Date: 2026-07-15

This report records the discovery baseline before the readiness changes in this branch. It covers only the Dawa Mom repository and its Supabase project.

## Current application architecture

- The client is a Flutter application whose generated FlutterFlow pages and record classes are retained under `lib/`.
- `lib/main.dart` initializes Supabase, persisted FlutterFlow app state, Provider, and GoRouter. The authenticated root is `NavBarPage`.
- `lib/flutter_flow/nav/nav.dart` owns route definitions. The primary authenticated routes are Home, Encounters (labelled Appointments), Period Tracker, Profile, Edit Profile, pregnancy Week, and appointment/encounter details.
- `lib/backend/supabase/supabase_config.dart` points to Dawa Mom Supabase project `himbfndvsuwiudtzjojh` and supports `SUPABASE_URL`/`SUPABASE_ANON_KEY` Dart-define overrides.
- `lib/backend/supabase/supabase_database.dart` is a compatibility adapter. It maps the old FlutterFlow/Firestore collection and field names to Supabase tables and columns. For example, `encounter` maps to `encounters`, `date` to `appointment_date`, and `time` to `appointment_time`.
- `lib/auth/supabase_auth/` supplies Supabase auth/session streams, refreshes expiring sessions, and supports the legacy Firebase-password migration Edge Function. Active app code does not initialize Firebase.
- `lib/backend/backend.dart` exposes generated record queries over the compatibility adapter. These compatibility streams are one-shot `Stream.fromFuture` reads rather than realtime subscriptions.
- `lib/app_state.dart` persists the currently resolved mother reference in SharedPreferences. It is cleared on logout and resolved from `mothers.profile_id = auth.uid()` by Home and booking code.
- Rudo chat and voice use authenticated Dawa Mom Edge Functions under `supabase/functions/`. Private provider keys are not stored in Flutter.
- There is no active notification service and no offline appointment queue. Local persistence is limited to theme and the resolved mother reference.

## Current responsive behaviour

- `NavBarPage` in `lib/main.dart` always renders a mobile `BottomNavigationBar`, including on tablet and desktop.
- Home, Appointments, and Period Tracker are full-screen generated pages without a shared maximum-width content container.
- `lib/navbar/home/home_widget.dart` places small empty-state illustrations in vertically large sections, producing the stretched layout shown in the supplied desktop screenshot.
- `lib/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart` has a sheet width cap, but the surrounding application shell remains mobile-shaped.
- `lib/navbar/period_tracker/period_tracker_widget.dart` scrolls safely, but its sections remain a single long column and its calendar has a fixed 350 px height at every breakpoint.

## Current appointment flow and 403 root cause

1. Home opens `BookingBottomSheetWidget`.
2. Clinics are read from `public.clinics` through `ClinicRecord`.
3. Clinicians are read from Dawa Mom's imported `public.doctors` rows through `DoctorRecord`, filtered by the legacy `clinic_name_legacy` value.
4. Time chips are generated from the selected doctor's legacy text start/end times.
5. The form resolves the signed-in user's mother row via `mothers.profile_id = auth.uid()`.
6. Duplicate checks query `public.encounters` for the mother/doctor/date/time.
7. `EncounterRecord.collection.doc().set(...)` uses a PostgREST upsert into `public.encounters` with `mother_id`, `doctor_id`, `appointment_date`, `appointment_time`, and `status = scheduled`.
8. Failures are caught, logged, and reduced to a generic snackbar. The form has no submitting/success/error state and no field-level validation.

The exact browser failure is an RLS rejection on `POST /rest/v1/encounters`. The repository contains `supabase/migrations/202607090001_fix_encounters_mother_insert_rls.sql`, but `supabase migration list --linked` shows that migration only locally; the linked remote database ends at `202607080001`. The corrective insert policy therefore has not been deployed to the project used by the web app. This deployment drift is why the repository appears to contain a fix while the browser still receives 403.

There is also a design defect independent of deployment: `public.encounters` combines scheduling fields with blood pressure, urinalysis, fetal assessment, and other clinician-owned fields. Patient appointment requests should not be stored as clinical encounters. The readiness implementation introduces a dedicated appointment aggregate and leaves legacy encounters as clinical/history data.

## Current appointment target and schema

- Current target table: `public.encounters`.
- There is no `public.appointments` table in the migrations before this readiness work.
- `public.encounters` is created in `supabase/migrations/202605040001_initial_schema.sql`. Scheduling fields are `mother_id`, `doctor_id`, `clinic_id`, `appointment_date`, `appointment_time`, `status`, and `is_instant`; the same row also contains clinical fields.
- Duplicate partial indexes currently protect doctor and mother slots in `encounters`.
- Initial RLS allows owner reads and patient scheduling/cancellation states. A trigger blocks patient writes to clinical columns.

## Current period tracker implementation

- `lib/backend/period_tracker_service.dart` reads/writes `period_tracker_settings` and `period_tracker_entries` using the authenticated profile ID.
- `lib/navbar/period_tracker/period_tracker_widget.dart` predicts the next period, a nominal ovulation day, and a six-day fertile window from the most recent period and average cycle length.
- Only today's symptoms, notes, and sexual activity are loaded. `loadDateRangeData` exists but is unused, so historic markers are absent after a restart.
- A persisted `last_period_start` is loaded into `_lastPeriodStart`, but `_selectedPeriodStart` and `_currentPeriodDays` are not restored, so the calendar does not re-highlight the saved period.
- Settings accept any integer and background save errors are only printed. Database constraints reject invalid values, but the user sees no feedback.
- Predictions are shown even when the user marks the cycle irregular, and the UI does not clearly label predictions as estimates rather than contraception or diagnostic advice.

## Current clinician data source

- The dropdown is not a literal hardcoded name list. It reads legacy/imported `public.doctors` rows from Dawa Mom through `queryDoctorRecord` in `lib/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart`.
- It filters on a legacy clinic-name string rather than the canonical `doctors.clinic_id` relationship.
- The generic `doctors_read_authenticated` RLS policy permits authenticated reads of the whole doctor row, including `phone_number`; a booking directory should expose a narrower shape.
- Dawa Mom and Dawa Clinician use separate projects. Dawa Mom is `himbfndvsuwiudtzjojh`; `supabase/DAWA_CLINICIAN_WEBHOOK.md` identifies the Dawa Clinician receiver in project `eatliepvwrviogsnqavu`.
- Flutter must not call the second project with privileged credentials. The readiness implementation therefore uses a repository abstraction, a safe local booking-directory view as a temporary cache/fallback, and a Dawa Mom Edge Function adapter for a future protected clinician endpoint.

## Files requiring changes

- `lib/main.dart`: responsive authenticated shell.
- `lib/navbar/home/home_widget.dart` plus responsive dashboard components: balanced tablet/desktop dashboard and appointment refresh.
- `lib/components/booking_bottom_sheet/`: authenticated booking, canonical clinic/clinician IDs, validation, state, and clear feedback.
- `lib/navbar/appointments/`: dedicated appointment list/details/cancellation.
- `lib/navbar/period_tracker/period_tracker_widget.dart` and `lib/backend/period_tracker_service.dart`: persistence restoration, range loading, validation, and error feedback.
- New appointment and clinician repositories/models under `lib/features/appointments/`.
- A versioned migration under `supabase/migrations/` for appointments, ownership RLS, update guardrails, indexes, and the safe clinician directory.
- A Dawa Mom Edge Function under `supabase/functions/clinician-directory/` for future cross-project directory access.
- Tests under `test/` and Supabase verification SQL under `supabase/`.

## Database changes required

- Create a dedicated `appointments` table with mother/patient/clinician/clinic identity, date/time, request details, lifecycle status, source, creator, timestamps, integration status, and external ID.
- Add duplicate slot indexes and canonical clinic/clinician relationship validation.
- Enable RLS and add owner-select, owner-insert, restricted owner-cancel, and admin-read policies without disabling RLS or using service credentials in Flutter.
- Add a trigger that prevents a patient from changing ownership, schedule, integration, or clinician fields after creation.
- Add public-booking metadata to the local clinician cache and expose only safe fields through `get_bookable_clinicians`.
- Update post-migration verification to include the new table, policies, trigger, and directory view.

## Deferred until the Dawa Clinician phase

- The authoritative clinician directory, cross-project clinician UUID mapping, and authoritative availability endpoint must be supplied by Dawa Clinician.
- Dawa Clinician must accept appointment delivery, return an external appointment ID, and send status changes (confirmed, declined, rescheduled, completed, missed, or cancelled) back through an authenticated server-to-server channel.
- Dawa Clinician notification UI, appointment UI, schema, RLS, migrations, and deployment remain explicitly out of scope.
- Until that contract is implemented, `integration_status` remains pending and Dawa Mom's safe local imported clinician rows are a temporary directory/cache, not proof that cross-project integration is complete.

## Readiness implementation outcome

Completed in Dawa Mom:

- `DawaMomResponsiveShell` now keeps the three-item bottom navigation below 700 px, uses a navigation rail from 700–1099 px, and uses a collapsible branded sidebar at 1100 px and above.
- Tablet/desktop Home now has bounded content, summary cards, a two-column care overview, quick actions, recent appointment activity, useful empty states, and no pregnancy assumptions when clinical pregnancy data is absent.
- Patient bookings now insert once into `public.appointments` through `AppointmentRepository`; the returned appointment ID is retained and an app-wide change notifier refreshes Home and Appointments immediately.
- The booking form validates auth/profile, clinic, clinician, date, time, clinician/clinic membership, duplicates, and live slot availability. Loading, success, retry, disabled, and inline error states are visible without exposing PostgREST/SQL details.
- Appointments has dedicated list, detail, and eligible cancellation UI. Patient cancellation is enforced by RLS plus a trigger that rejects changes to schedule, ownership, clinician, clinic, notes, and integration fields.
- Clinician choices now come through `ClinicianDirectoryRepository`. The deployed Dawa Mom Edge Function is ready for a future protected Dawa Clinician endpoint and currently falls back to booking-safe Dawa Mom RPCs over imported cache rows.
- Period Tracker restores the saved period range, loads historical calendar entries by date range, validates settings before database writes, surfaces save/load failures, uses a responsive calendar/summary layout, and suppresses fertile-window predictions for irregular cycles. Estimate and medical-safety language is explicit.
- `docs/dawa-clinician-integration-contract.md` defines clinician directory, availability, appointment delivery, callback, idempotency, authentication, and error shapes for the next phase.

Deployed Dawa Mom state on 2026-07-15:

- Remote migrations are aligned through `202607150001`.
- The previously missing `202607090001` encounter insert-policy repair is now applied.
- `202607150001_create_patient_appointments.sql` is applied.
- Dawa Mom `clinician-directory` Edge Function version 1 is active.
- `supabase db lint --linked --level warning` reports no schema errors.

Verification:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 11 tests passed.
- Responsive widget coverage exercises mobile, tablet, and desktop shells.
- `supabase/APPOINTMENTS_RLS_VERIFY.sql` provides transactional owner, non-owner, unauthenticated, cancellation, and field-mutation checks for SQL Editor/local database execution.
- A release web build and a debug web build emitted no compiler diagnostics but exceeded this machine's 10-minute and 5-minute command limits respectively; no successful web bundle is claimed from those runs.
