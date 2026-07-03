# Future Improvements

## Supabase And Migration

- Verify the live Supabase schema, triggers, RLS policies, and function deployments against the repo migrations.
- Run `supabase/POST_MIGRATION_VERIFY.sql` after any migration change.
- Add a safe `.env.example` with placeholders only.
- Document the final production Supabase project setup without exposing secrets.
- Add seed/import scripts or documented import commands if they exist outside the repo.
- Confirm whether Firebase password migration is fully complete or whether reset-password mode is still needed for some users.
- Remove or archive empty Firebase folders if they are truly no longer needed.

## Auth And Security

- Resolve the current user's mother row from `auth.uid()` after login instead of relying on stale persisted references.
- Add tests for sign-up, sign-in, password reset, and Firebase migration fallback.
- Confirm doctor approval/admin promotion workflow.
- Add audit notes for sensitive backend and Edge Function secrets.
- Rotate any credentials that were ever exposed outside secure local storage.

## Database And RLS

- Add role-based integration tests for patient, doctor, and admin access.
- Confirm patient writes cannot modify clinical fields.
- Confirm doctor access is limited to assigned mothers/encounters.
- Add a dedicated reminders/notifications schema if reminders are part of the roadmap.
- Add a dedicated BP readings table if the BP monitor becomes standalone.

## Offline Sync

- Add connectivity detection.
- Add safe local caching for patient-owned read data.
- Add retry queue for low-risk writes such as period tracker entries.
- Keep clinical writes online-only unless reviewed.
- Add clear UI states for offline, syncing, and sync failed.

## Blood Pressure And Health Interpretation

- Turn BP into a full feature if required:
  - Numeric systolic/diastolic inputs.
  - Age handling.
  - Chronic disease context.
  - Result history.
  - Supabase persistence.
  - Clinical escalation guidance.
- Review all health thresholds with a qualified clinician.
- Add unit tests for boundary values and malformed input.
- Version interpretation rules if results are saved.

## Appointments And Records

- Add rescheduling support if needed.
- Add appointment reminders/notifications.
- Add appointment audit/history.
- Add tests for double booking prevention and cancellation.
- Confirm whether encounter result entry happens in Dawa Mom, Dawa Clinician, or another tool.

## Rudo

- Confirm production Rudo backend URL and secrets.
- Add integration tests for `rudo-chat`.
- Add clearer Rudo privacy and medical disclaimer copy.
- Send selected language metadata with Rudo requests when UI language selection exists.
- Add fallback UX for unavailable voice services.

## UI/UX

- Capture real screenshots and add them to GitBook.
- Run small-screen, tablet, web, and accessibility QA.
- Fix typos and generated placeholder comments.
- Confirm final visual direction against any Rudo/Dawa design system decisions.
- Add visual regression screenshots for key flows.

## Testing

- Expand unit tests for:
  - Auth helper behavior.
  - Supabase compatibility mapping.
  - Health interpretation rules.
  - Period tracker predictions.
  - Date formatting and appointment slots.
- Add widget tests for:
  - Login/register.
  - Profile completion.
  - Appointment booking.
  - Period tracker.
- Add integration/manual QA checklist for Supabase environments.

## Documentation

- Keep these docs updated with every major migration or feature change.
- Add screenshots once a stable build is available.
- Add final deployment runbooks.
- Add clinical review notes for health rules.
- Add a confirmed Dawa Clinician integration page if a direct shared backend or workflow is established.
