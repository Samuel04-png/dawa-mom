# Dawa Mom redesign verification report

Verification date: 2026-07-23

All 31 supplied references were reviewed before implementation. The application
uses their visual hierarchy, Dawa blue/green palette, Poppins typography,
rounded surfaces, curved footer language, and supplied character families.
Route and backend checks below refer to the implemented application state.

| Design | Route/state verified | Backend/data verification | Responsive and visual note |
|---|---|---|---|
| `start.png` | `/welcome` → onboarding/login | Existing auth session redirect retained | 390 capture; welcome rendered at all five target widths |
| `authentication.png` | `/register` | Real email/phone registration through `SupabaseAuthManager` | 390 capture; validation widget test |
| `autnentication 2.png` | `/forgotPassword` | Real email recovery and phone OTP initiation retained | Shared responsive auth scaffold |
| `onboarding.png` | onboarding care page | Completion persists through `AppWalkthroughService` | Responsive data-driven page; live browser verified |
| `onboarding3.png` | onboarding tracker page | Same persisted walkthrough state | Responsive data-driven page |
| `onboardin2.png` | onboarding learning page | Same persisted walkthrough state | Responsive data-driven page |
| `onboarding 2.png` | `/login` | Real email/phone password auth and migration fallback | Shared responsive auth scaffold |
| `home.png` | `/home` | Profile, mother, pregnancy/cycle, appointment, and learning data are repository-backed | Existing responsive dashboard tests and five-width shell verification |
| `track.png` | `/periodTracker` | Real period settings/entries and computed cycle summaries | Mobile calendar; grid promotion at tablet/desktop |
| `check up modal.png` | Track daily check-in sheet | Symptom, pain, feeling, and note upsert verified by widget/service test | Scroll-safe sheet with text equivalents |
| `care 1.png` | `/encounters` / Care primary tab | Real appointment, clinician directory, clinic, and Rudo actions | 390 capture and all five target widths |
| `appointment details.png` | `/appointmentDetails?appointmentId=…` | Real appointment load/cancel and result summary | Existing detail tests cover 390/768/1024/1366/1440 |
| `appointment booked modal.png` | post-booking dialog | Shown only after `AppointmentRepository.bookAppointment` returns a real appointment | Bounded dialog at all widths |
| `set reminder.png` | appointment reminder sheet | Local-first persistence plus owner-scoped Supabase row; due in-app items honor saved lead time/channel | Scroll-safe sheet; channel state has text |
| `profile.png` | `/settings` / Profile primary tab | Profile, mother, first encounter, appointments, preferences, and rewards remain real/derived | Settings tests at phone/tablet/desktop |
| `choose language.png` | language sheet compact state | Local-first preference plus owner-scoped remote sync | 390 visual capture |
| `choose language2.png` | language sheet expanded state | Same repository and remote row | Scroll-safe radio selection |
| `choose language3.png` | language sheet alternate selection | Same repository and remote row | Scroll-safe radio selection |
| `notifications.png` | `/notifications` | Derived from real appointments/cycle/learning; read IDs sync; appointment reminders honor saved preferences | Responsive list with category filters |
| `redeem reward.png` | reward dialog from Rewards | No client-issued voucher: only the server RPC can debit and return a unique voucher; issued code remains visible and copyable | Bounded focusable dialog and 390 capture |
| `learn.png` | `/learn` / Learn primary tab | Bundled reviewed content; bookmark/progress/reward state syncs when signed in | 390 capture and all five target widths |
| `learn concept1.png` | `/learn/article/cervical-awareness` | Saved/completed state through learning repository | Readable max-width article |
| `learn concept 2.png` | `/learn/quests` | Real persisted progress, streak, and server-controlled coins | Responsive quest hub |
| `learn 2.png` | `/learn/quests/completed` | Completion award is idempotent in the server ledger | Responsive completion surface |
| `learning modules concept.png` | `/learn/quests/screening` | Progress comes from completed content IDs | Responsive step list |
| `learning concept2.png` | `/learn/quests/screening/clinic` | Uses the existing Rudo surface; no fake clinical action | Responsive lesson composition |
| `learning concept4.png` | `/learn/quests/screening/checkpoint` | Correctness and coin award use an idempotent RPC | Text/icon correctness feedback |
| `learning.png` | `/learn/lesson/myth-vs-fact` | Saved/completed state sync; share uses the platform share path | 390 visual capture |
| `learning2.png` | `/learn/audio/pregnancy-basics` | Existing voice/audio service with play state and full transcript; no simulated progress | Responsive media controls |
| `learning3.png` | `/learn/pregnancy` and `/learn/pregnancy/:guideId` | Profile-aware copy plus persisted save/completion state | Responsive list/detail layouts |
| `library.png` | `/learn/library` | Saved/offline IDs persist locally and mirror eligible learning state remotely | Responsive filter/list layout |

## Captured comparison set

The render harness saves the following 390×844 application captures:

- `verification/welcome.png`
- `verification/registration.png`
- `verification/learn.png`
- `verification/care.png`
- `verification/myth-fact.png`
- `verification/language-sheet.png`
- `verification/onboarding-track.png`
- `verification/games-hub.png`
- `verification/myth-match-game.png`
- `verification/rewards-center.png`
- `verification/game-complete-modal.png`
- `verification/reward-redemption-modal.png`

The harness is `tool/dawa_visual_capture_test.dart`. It loads the production
Poppins weights and Material icons, precaches all artwork, fails on render
exceptions, and generated all twelve captures successfully.

The new completion surfaces add `/learn/games`,
`/learn/games/myth-match`, `/learn/games/plate-builder`, and
`/learn/rewards`. They are documented reference-by-reference in
`refinement-audit.md`.

## Responsive verification

Automated rendering covers 390×844, 768×1024, 1024×768, 1366×900, and
1440×900. At those widths:

- mobile uses the five-item bottom navigation;
- tablet uses a navigation rail and promoted two-column layouts;
- desktop uses the labelled/collapsible sidebar and constrained content;
- welcome, Learn, Care, settings, appointment details, result summaries, Rudo,
  the shared shell, games hub, game play, and Rewards render without overflow.

## Accessibility verification

- Interactive cards expose button semantics and descriptive labels.
- Decorative artwork is excluded from the semantics tree.
- Status is expressed with icon and text, never color alone.
- Forms keep visible labels/hints, validation copy, autofill, and password
  visibility controls.
- Navigation, dialog, sheet, media, save, and filter controls are keyboard
  reachable.
- Major custom actions and save controls use at least 44 logical pixels.
- Content order follows the visual order and long pages/sheets scroll.
- Game answers expose selected/correct state in text and semantics.
- The completion chime is quiet, generated in memory and paired with haptics;
  failure or reduced platform support never blocks the reward.

## Known visual deviations

Exact pixel identity is not technically possible because the references are
static 941×1672 composited images while the application must render live data,
native controls, dynamic text, and five viewport classes. The following
differences are intentional and can exceed 2 px:

- Real clinic, clinician, date, profile, cycle, pregnancy, progress, and reward
  values replace the reference's sample Zimbabwe/Harare data.
- Some reference scene compositions were supplied only as flattened images.
  The implementation uses the provided transparent character library instead
  of copying the flattened screenshot.
- Native Flutter text rasterization, form controls, calendar cells, and
  platform safe areas vary slightly by device.
- The mother/baby RGB artwork required a non-destructive transparent production
  derivative to avoid a rectangular matte across the curved footer.
- Unsupported claims were omitted: fake review scores, distances, phone
  actions, issued vouchers, medical diagnoses, and simulated audio/download
  state are not shown.

These deviations preserve function, safety, responsiveness, and truthful data
rather than reproducing non-functional screenshot content.

## Backend verification

- Static architecture tests verify all new tables use RLS, authenticated
  owner policies, restricted grants, server-only reward writes, idempotent
  award/redemption paths, and no Flutter service-role secret.
- Repository tests verify local-first learning and reminder persistence,
  idempotent local completions, reward failure safety, and daily check-in data.
- The migration was applied with `ON_ERROR_STOP` to a clean PostgreSQL 17
  database using Supabase-compatible roles, `auth.uid()`, source tables, and
  extension schema. All tables, constraints, RLS policies, grants, triggers,
  comments, and functions were created successfully.
- Runtime behavior checks confirmed that foreign preference and appointment
  reminder writes are rejected, owner writes succeed, the learning award is
  applied only once, and repeat reward redemption returns the same voucher
  without a second debit.
- The additive game-reward migration was applied to a second clean PostgreSQL
  17 database. Myth Match awarded 10 points, replay awarded 0, Plate Builder
  awarded 10, and the final 200-point state contained exactly two ledger rows.
- Local saved/completed/offline/pending IDs, point balance, streak and voucher
  keys are scoped by authenticated owner with a one-time legacy-cache migration.
- The Supabase CLI is installed (`2.109.1`). Its full local stack could not
  start because this machine had no cached Supabase image set and the Docker
  credential helper stalled. The independent PostgreSQL validation therefore
  exercised this migration without modifying the remote project or production
  data.

## Live browser verification

The actual Flutter web build was served locally and exercised at 390×844 and
1440×900. The flow covered Welcome → Track onboarding → Care onboarding →
Learn onboarding → Games/Rewards onboarding → Registration plus blank-form
validation. Navigation, responsive promotion and field errors rendered
correctly, and browser console inspection returned no errors or warnings.
