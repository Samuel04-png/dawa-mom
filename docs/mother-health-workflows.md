# Mother Health Workflows

This page documents maternal/mother health features confirmed from the current repo.

## Mother Profile

Confirmed:

- A mother row is created after patient signup.
- The mother profile is linked to the Supabase profile/user through the compatibility layer.
- Profile completion captures:
  - Name
  - Phone number
  - Date of birth
  - Occupation
  - Address
  - Mother ID based on the generated record ID
- Profile view shows mother name and current user email.
- Edit Profile updates mother demographic fields.

Key files:

- `lib/auth/register/register_widget.dart`
- `lib/auth/create_account/create_account_widget.dart`
- `lib/navbar/profile/profile_widget.dart`
- `lib/navbar/edit_profile/edit_profile_widget.dart`
- `lib/backend/schema/mother_record.dart`
- `supabase/migrations/202605040001_initial_schema.sql`

## Pregnancy Tracking

Confirmed:

- First encounter records contain LNMP and estimated due date fields.
- The home screen queries the mother's first encounter.
- Gestational age is calculated from LNMP.
- The week page reads `pregnancy_weeks` by week number.
- Pregnancy week content includes:
  - General info
  - Body changes
  - Baby development
  - Tips
  - Weekly plan

Key files:

- `lib/navbar/home/home_widget.dart`
- `lib/navbar/week/week_widget.dart`
- `lib/flutter_flow/custom_functions.dart`
- `lib/backend/schema/first_encounter_record.dart`
- `lib/backend/schema/weeks_of_pregenancy_record.dart`

Needs confirmation:

- How first encounter records are created in production.
- Whether mothers can create first encounter data themselves. The RLS design says patients should not write clinical first encounter data.

## Appointments

Confirmed:

- Mothers can view appointments.
- Mothers can schedule an appointment.
- Scheduling collects date, clinic, clinician, and time slot.
- The app checks for existing doctor and mother bookings for the selected date/time.
- New appointments are saved as `encounters` with `status: scheduled`.
- Scheduled appointments can be cancelled.
- Cancelled appointments are hidden from the list.
- Completed appointments can open encounter result details.

Key files:

- `lib/components/booking_bottom_sheet/booking_bottom_sheet_widget.dart`
- `lib/navbar/appointments/encounters/encounters_widget.dart`
- `lib/navbar/appointments/appointment_details/appointment_details_widget.dart`
- `lib/navbar/appointments/encounter_details/encounter_details_widget.dart`
- `lib/backend/schema/encounter_record.dart`

## Visits And Records

Confirmed:

- Encounter records include appointment and clinical result fields.
- Completed appointment details can link to the encounter results page.
- Encounter details show clinical/vitals/lab-style data such as BP, pulse, blood level, urine indicators, fetal heartbeat, baby size, comments, and next visit.

Needs confirmation:

- Whether clinicians enter encounter result data in this app or another app.
- Whether Dawa Clinician writes to the same Supabase `encounters` table.

## Period Tracker

Confirmed:

- Period tracker is a bottom tab.
- The tracker stores:
  - Average cycle length
  - Period length
  - Regular/irregular flag
  - Last period start
  - Daily symptoms
  - Daily notes
  - Sexual activity entries
- The UI calculates:
  - Current cycle day
  - Next predicted period
  - Ovulation estimate
  - Fertile window
  - Late period status

Key files:

- `lib/navbar/period_tracker/period_tracker_widget.dart`
- `lib/backend/period_tracker_service.dart`
- `supabase/migrations/202605040001_initial_schema.sql`
- `test/period_tracker_service_test.dart`

## Symptoms Or Risk Checks

Confirmed:

- First encounter schema includes symptoms and risk-related fields:
  - Sign of imminent eclampsia
  - Signs of anaemia
  - Symptoms of UTI
  - Diabetes mellitus
  - Hypertension
  - Cardiac disease
  - HIV status
  - Asthma, TB, epilepsy, sickle cell
- Encounter detail page includes simple rule-based indicators for some urine/lab result categories.

Needs confirmation:

- Whether these risk checks are reviewed clinically.
- Whether users see formal risk recommendations beyond encounter result labels.

## Reminders

Not confirmed in the current codebase.

I did not find a dedicated reminders table, notification service, local notification setup, or reminder UI. Appointment dates and next visit dates exist, but reminder behavior is not confirmed.

## Education Content

Confirmed:

- Pregnancy week education content exists in `pregnancy_weeks`.
- Rudo backend/training files include maternal health and cervical cancer content in multiple languages.

Needs confirmation:

- Which educational content is final and clinically approved.
- Whether content management happens through Supabase, backend files, or manual imports.

## Dashboard Modules

Confirmed Home modules include:

- Greeting/profile context.
- Upcoming appointment section.
- "What to expect" pregnancy/first encounter section.
- Pregnancy week navigation.
- Schedule appointment button.
- Floating Rudo assistant button.

## Mother-Facing vs Clinician-Facing Logic

Confirmed mother-facing logic:

- Register/login/profile completion.
- Appointment booking/cancellation.
- Pregnancy-week viewing.
- Period tracking.
- Rudo chat.
- Encounter result viewing.

Confirmed clinician/admin backend logic:

- Database roles and RLS policies for doctors/admins.
- Doctor and clinic tables.
- Encounter clinical fields.

Needs confirmation:

- Dedicated clinician/admin UI inside this Flutter app.
