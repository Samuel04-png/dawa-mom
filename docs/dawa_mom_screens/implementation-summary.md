# Dawa Mom redesign implementation summary

## Outcome

All 31 supplied screen references are mapped to functioning routes, pages,
dialogs, or sheets. The application now has a unified light Dawa Mom visual
system and responsive Home, Track, Care, Learn, and Profile navigation while
preserving authentication, appointments, cycle tracking, health profile, Rudo,
and result delivery.

## Reusable UI introduced

- `DawaPageScaffold`, `DawaWavePainter`, and `DawaBottomSheetFrame`
- `DawaCard`, `DawaAppHeader`, `DawaSectionHeader`, and `DawaResponsiveGrid`
- `DawaIconBadge`, `DawaStatusPill`, `DawaProgressBar`, and
  `DawaPrimaryButton`
- Central Dawa colors, spacing, radii, breakpoints, shadows, text styles, and
  supplied-artwork registry
- Shared responsive five-destination shell and persistent Rudo controller

## Functional clusters

- Entry/auth: welcome, login, registration, recovery, three onboarding pages
- Home: real profile/pregnancy/cycle/appointment/learning dashboard
- Track: cycle calendar, pregnancy mode, summaries, daily check-in,
  setup/history/settings
- Care: appointment hero, clinician, quick actions, clinics, details, booking
  confirmation, results, cancellation, and reminders
- Learn: search/categories, articles, myths, quests, checkpoints, completion,
  rewards, audio/transcript, pregnancy guides, and library
- Profile: health facts, language, notification preferences, notification
  inbox, learning/reward summary, and account actions

## Routes added or redirected

- Existing `/welcome`, `/login`, `/register`, `/forgotPassword`, `/home`,
  `/periodTracker`, `/encounters`, `/appointmentDetails`, and `/settings`
  routes now render the redesigned presentation or primary-tab equivalent.
- Added `/onboarding`, `/learn`, `/notifications`,
  `/learn/article/cervical-awareness`, `/learn/lesson/myth-vs-fact`,
  `/learn/audio/pregnancy-basics`, `/learn/pregnancy`,
  `/learn/pregnancy/:guideId`, `/learn/library`, `/learn/quests`,
  `/learn/quests/screening`, `/learn/quests/screening/clinic`,
  `/learn/quests/screening/checkpoint`, and `/learn/quests/completed`.
- All application routes remain authentication-protected except entry,
  authentication, recovery, and onboarding.

## Backend added

`202607230001_add_dawa_mom_learning_and_preferences.sql` is additive and adds:

- owner-scoped user language/notification/read preferences;
- owner-scoped learning bookmarks/completion state;
- server-owned learning award ledger;
- server-issued reward redemption ledger;
- owner-scoped appointment reminder preferences;
- RLS, narrow grants, update triggers, and table documentation;
- idempotent `complete_dawa_mom_learning_item` and
  `redeem_dawa_mom_reward` RPCs.

No Edge Function was needed for the new tables. Existing authenticated Supabase
access handles owner state; privileged coin/voucher mutation stays inside
security-definer database functions. Existing Rudo, TTS, clinician directory,
email outbox, Dawa platform outbox, and appointment result functions remain
unchanged.

## Tests and captures added

- auth validation and phone normalization;
- learning persistence, completion, queue, and reward safety;
- reminder persistence and channel normalization;
- Care real-data rendering at five breakpoints;
- daily check-in save behavior;
- backend/RLS/secret architecture checks;
- welcome and Learn rendering at all five required breakpoints;
- six deterministic 390 px visual captures.

The full suite passes 72 tests. Analyzer, web release build, and Android debug
build also pass.

## Commands used for final verification

```text
flutter analyze --no-fatal-infos
flutter test
flutter test tool/dawa_visual_capture_test.dart --update-goldens
flutter build web --release
flutter build apk --debug
supabase --version
supabase status
supabase start
supabase db lint --local
```

The last three Supabase runtime commands confirmed CLI/Docker availability but
could not start a database because the local Supabase image set was absent.
They did not connect to, migrate, or change the remote project.

## Final checklist

- [x] 31/31 references inventoried and mapped
- [x] Five primary responsive destinations implemented
- [x] Supplied character and illustration assets used
- [x] RGB line-art matte replaced with transparent production derivative
- [x] Real auth/profile/appointment/cycle/Rudo flows preserved
- [x] Learning/preferences/reminders wired local-first and owner-scoped remote
- [x] Rewards controlled and confirmed server-side
- [x] RLS remains enabled; no service role key in Flutter
- [x] 390/768/1024/1366/1440 rendering exercised
- [x] Accessibility semantics and non-color status patterns included
- [x] Analyzer, 72 tests, visual capture harness, web build, and APK build pass
- [x] No changes pushed to GitHub
