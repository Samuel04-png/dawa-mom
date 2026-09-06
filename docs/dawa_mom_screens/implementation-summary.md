# Dawa Mom redesign implementation summary

## Outcome

All 31 supplied screen references are mapped to functioning routes, pages,
dialogs, or sheets. The application now has a unified light Dawa Mom visual
system and responsive Home, Track, Care, Learn, and Profile navigation while
preserving authentication, appointments, cycle tracking, health profile, Rudo,
and result delivery. A second refinement pass adds a complete games/rewards
loop, expanded walkthrough, support surfaces, subtle feedback, and owner-scoped
local reward data.

## Reusable UI introduced

- `DawaPageScaffold`, `DawaWavePainter`, and `DawaBottomSheetFrame`
- `DawaCard`, `DawaAppHeader`, `DawaSectionHeader`, and `DawaResponsiveGrid`
- `DawaIconBadge`, `DawaStatusPill`, `DawaProgressBar`, and
  `DawaPrimaryButton`
- Central Dawa colors, spacing, radii, breakpoints, shadows, text styles, and
  supplied-artwork registry
- Shared responsive five-destination shell and persistent Rudo controller

## Functional clusters

- Entry/auth: welcome, login, registration, recovery, four onboarding pages,
  and a replayable six-step product tour
- Home: real profile/pregnancy/cycle/appointment/learning dashboard
- Track: cycle calendar, pregnancy mode, summaries, daily check-in,
  setup/history/settings
- Care: appointment hero, clinician, quick actions, clinics, details, booking
  confirmation, results, cancellation, and reminders
- Learn: search/categories, articles, myths, quests, checkpoints, completion,
  two replayable health games, audio/transcript, pregnancy guides, and library
- Rewards: balance, earning paths, achievements, activity history, a
  server-issued voucher and retained/copyable voucher state
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
  `/learn/quests/screening/checkpoint`, `/learn/quests/completed`,
  `/learn/games`, `/learn/games/:gameId`, and `/learn/rewards`.
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

`202607230002_add_dawa_mom_game_rewards.sql` additively extends the existing
completion RPC with two whitelisted 10-point game IDs. It reuses the same
owner-scoped state and idempotent server award ledger.

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
- pass/fail/replay and one-time reward behavior for both health games;
- reward history, achievements and retained voucher presentation;
- games, game play and rewards at all five required breakpoints;
- account-scoped local points, progress and voucher architecture;
- twelve deterministic 390 px visual captures.

The full suite passes 82 tests. Analyzer, web release build, and Android debug
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
docker run --rm -d --name dawa-mom-sql-check postgres:17-alpine
psql -v ON_ERROR_STOP=1 -f 202607230001_add_dawa_mom_learning_and_preferences.sql
psql -v ON_ERROR_STOP=1 -f 202607230002_add_dawa_mom_game_rewards.sql
flutter run -d web-server --web-port 7357 --web-hostname 127.0.0.1
```

The Supabase full-stack commands confirmed CLI/Docker availability but could not
prepare the absent Supabase image set through the machine's credential helper.
A clean PostgreSQL 17 container then successfully parsed and applied the
migration. Follow-up SQL verified owner and foreign-row RLS behavior plus
idempotent learning awards and reward redemption. The temporary container was
removed, and no command connected to, migrated, or changed the remote project.
The second migration was also applied to a fresh PostgreSQL 17 container:
Myth Match awarded 10 then 0 on replay, Plate Builder awarded 10, and the final
balance was 200 with exactly two award-ledger rows.

## Final checklist

- [x] 31/31 references inventoried and mapped
- [x] Five primary responsive destinations implemented
- [x] Supplied character and illustration assets used
- [x] RGB line-art matte replaced with transparent production derivative
- [x] Real auth/profile/appointment/cycle/Rudo flows preserved
- [x] Learning/preferences/reminders wired local-first and owner-scoped remote
- [x] Rewards controlled and confirmed server-side
- [x] Health games pass, fail, replay, animate and award once
- [x] Completion has subtle haptics and a low-volume generated chime
- [x] Local learning and voucher data is scoped by signed-in owner
- [x] RLS remains enabled; no service role key in Flutter
- [x] Migration applied and RLS/RPC behavior exercised in clean PostgreSQL 17
- [x] 390/768/1024/1366/1440 rendering exercised
- [x] Accessibility semantics and non-color status patterns included
- [x] Live browser flow verified at 390 and 1440 px with no console errors
- [x] Analyzer, 82 tests, visual capture harness, web build, and APK build pass
- [x] No changes pushed to GitHub
