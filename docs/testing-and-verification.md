# Testing And Verification

## Automated Tests

Current tests found:

| Test File | Coverage |
|---|---|
| `test/widget_test.dart` | Checks `AuthUserInfo` stores profile fields. |
| `test/period_tracker_service_test.dart` | Checks period tracker date formatting and Supabase row mapping. |

Run:

```powershell
flutter test --no-pub
```

## Static Analysis

Run:

```powershell
flutter analyze --no-pub
```

## Manual QA Checklist

### Auth

- [ ] New patient can register.
- [ ] Password confirmation mismatch blocks registration.
- [ ] Profile row is created.
- [ ] Mother row is created.
- [ ] Profile completion saves mother details.
- [ ] Login succeeds with Supabase user.
- [ ] Password reset sends email.
- [ ] Sign out clears app session.
- [ ] Expired session refresh works.
- [ ] Firebase password migration fallback works for a legacy user.
- [ ] Invalid legacy credentials fail safely.

### Supabase

- [ ] Migrations apply in order.
- [ ] `POST_MIGRATION_VERIFY.sql` returns expected tables, policies, triggers, and functions.
- [ ] RLS is enabled on required tables.
- [ ] Patient can only read/update own mother data.
- [ ] Patient cannot write clinical encounter fields.
- [ ] Doctor can access assigned patients only.
- [ ] Admin access matches intended process.
- [ ] Edge Functions deploy successfully.
- [ ] Required secrets are present.

### Mother Health Workflows

- [ ] Mother profile displays correct data.
- [ ] Edit profile updates Supabase.
- [ ] Home loads without stale `motherRef`.
- [ ] Pregnancy week content opens from home.
- [ ] Missing pregnancy data state displays correctly.

### Appointments

- [ ] Appointment list loads.
- [ ] No appointments state displays correctly.
- [ ] Booking requires date, clinic, clinician, and time.
- [ ] Booking prevents mother double booking.
- [ ] Booking prevents doctor double booking.
- [ ] Scheduled appointment can be cancelled.
- [ ] Cancelled appointment is hidden.
- [ ] Completed appointment opens encounter result details.

### Period Tracker

- [ ] Settings save and reload.
- [ ] Last period start saves and reloads.
- [ ] Symptoms save and reload.
- [ ] Notes save and reload.
- [ ] Sexual activity entries save and reload.
- [ ] Current cycle day calculation is sensible.
- [ ] Next period prediction displays correctly.
- [ ] Fertile window and late period indicators work.

### Blood Pressure And Health Interpretation

- [ ] Encounter result displays BP label for valid `120/80` style input.
- [ ] Invalid BP input displays `Invalid Input`.
- [ ] Boundary values are reviewed and tested.
- [ ] Hydration/pH/pulse helpers are tested.
- [ ] Clinical review is completed before production health guidance.

### Rudo

- [ ] Chat modal opens from Home.
- [ ] Existing session/messages load.
- [ ] New message sends through `rudo-chat`.
- [ ] Assistant reply persists in `chat_messages`.
- [ ] Duplicate taps do not duplicate persisted messages.
- [ ] Error state displays if assistant service is unavailable.
- [ ] Voice mode starts with microphone permission.
- [ ] TTS works through ElevenLabs function.
- [ ] Device TTS fallback works when configured service fails.

### Offline Mode

- [ ] App starts with valid persisted session.
- [ ] App signs out locally if session refresh fails.
- [ ] Theme mode persists.
- [ ] `motherRef` persistence does not cross users.
- [ ] Offline writes are not advertised until implemented.

### UI Responsiveness

- [ ] Small Android phone.
- [ ] Common Android phone.
- [ ] iPhone size.
- [ ] Tablet.
- [ ] Web desktop.
- [ ] Text does not overflow forms/buttons/cards.
- [ ] Bottom navigation works on all target sizes.

## Test Coverage Gaps

- No auth integration tests.
- No Supabase RLS integration tests.
- No appointment booking tests.
- No Rudo Edge Function tests.
- No health interpretation unit tests.
- No widget tests for major screens.
- No visual regression screenshots.
