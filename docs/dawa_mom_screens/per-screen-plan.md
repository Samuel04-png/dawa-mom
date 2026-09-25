# Dawa Mom per-screen implementation plan

This plan was completed before implementation and then executed in full. The 31
reference images share one visual language and were implemented as related
clusters to avoid duplicating layout, navigation, cards, dialog, persistence,
and accessibility logic. Final evidence is recorded in
`verification-report.md` and `implementation-summary.md`.

## Shared design system and navigation

Files to create or modify:

- `lib/design_system/dawa_design_tokens.dart`
- `lib/design_system/dawa_page_scaffold.dart`
- `lib/design_system/dawa_cards.dart`
- `lib/design_system/dawa_buttons.dart`
- `lib/design_system/dawa_app_header.dart`
- `lib/design_system/dawa_bottom_navigation.dart`
- `lib/design_system/dawa_artwork.dart`
- `lib/main.dart`
- `lib/flutter_flow/nav/nav.dart`
- `lib/components/responsive/dawa_mom_responsive_shell.dart`
- `pubspec.yaml`

Shared behavior:

- Poppins typography; warm `#FFFCF8` canvas, Dawa blue primary, green accent, pale lilac/green/pink status surfaces.
- Mobile: five-destination bottom navigation (`Home`, `Track`, `Care`, `Learn`, `Profile`).
- Tablet: compact navigation rail and centered content.
- Desktop: persistent sidebar, content constrained to a readable maximum width, and dense cards promoted into grids.
- Rudo remains state-preserving and available from dashboard, learning, and care.
- At all widths, interactive targets are at least 44 logical pixels, focus is visible, decoration is not announced, status has icon/text equivalents, and text scaling does not create horizontal overflow.

Responsive baseline:

| Width | Layout policy |
|---:|---|
| 390 | Reference composition, single column, bottom navigation, edge padding 16 |
| 768 | Centered content, 20–24 px edge padding, two-column card grids where useful, navigation rail |
| 1024 | Wider two-column grids and modal max widths; navigation rail |
| 1366 | Desktop sidebar, 3–4 summary columns, max content width around 1180 |
| 1440 | Same desktop structure with slightly larger gutters; no unbounded stretching |

## Entry, authentication, and onboarding

Screens: `start.png`, `authentication.png`, `autnentication 2.png`, `onboarding.png`, `onboarding3.png`, `onboardin2.png`, `onboarding 2.png`.

Files:

- replace the presentation of `WelcomeWidget`, `LoginWidget`, `RegisterWidget`, and `ForgotPasswordWidget` while retaining their route names
- create `lib/features/onboarding/dawa_onboarding_page.dart`
- update `AppWalkthroughService` invocation and router

Widget decomposition:

- reusable branded auth background with curved blue footer
- logo/header, form mode selector, validated Dawa field, password visibility button, gradient/blue CTA
- data-driven three-page onboarding hero with progress and skip/back/next controls

State/backend:

- preserve email sign-in/sign-up/reset and Firebase migration fallback
- expose existing phone OTP initiation in the mode selector; verification uses the existing manager
- registration still creates/updates `profiles` and `mothers`
- walkthrough completion still updates `profiles.walkthrough_completed_at`

Tests:

- email and phone mode validation
- password match/show-hide
- loading/error/success navigation
- onboarding skip/complete persistence
- 390/768/1024/1366/1440 visual tests for the shared auth/onboarding scaffold

## Home dashboard

Screen: `home.png`.

Files:

- redesign `lib/components/responsive/responsive_home_dashboard.dart`
- reuse `HealthProfileRepository`, `AppointmentRepository`, `PeriodTrackerService`

Widget decomposition:

- greeting/header
- pregnancy/cycle hero
- period and cycle-day mini cards
- next appointment
- four quick actions
- reward progress
- rotating/static evidence-based tip

Data behavior:

- user display name, pregnancy week, cycle estimate, and appointment are real
- unknown values show setup prompts, never demo patient facts
- `Book Visit`, `Track Cycle`, `Ask Rudo`, `Learn`, and profile affordances navigate or open the actual flows

Tests:

- loading, populated, partially configured, empty, and error states
- navigation actions
- all five target widths and large text

## Cycle tracking and daily check-in

Screens: `track.png`, `check up modal.png`.

Files:

- redesign `lib/navbar/period_tracker/period_tracker_widget.dart`
- redesign/replace `lib/components/symptom_tracker_bottom_sheet`
- retain `lib/backend/period_tracker_service.dart` and period setup/history/settings capabilities

Widget decomposition:

- cycle/pregnancy segmented control
- calendar card with textual legend
- three summary cards
- daily feeling/symptom strip
- pregnancy journey card
- daily check-in sheet with symptoms, pain slider, note, and five-level overall feeling

State/backend:

- selected month/day is local UI state
- all settings, period starts, symptoms, notes, pain and activity upsert through `PeriodTrackerService`
- period history editing/deletion remains available from an overflow/details affordance

Tests:

- calendar calculation and semantics
- open/save/cancel daily check-in
- period history/settings regression tests
- responsive and overflow tests

## Care, appointment details, booking success, and reminders

Screens: `care 1.png`, `appointment details.png`, `appointment booked modal.png`, `set reminder.png`.

Files:

- redesign `lib/navbar/appointments/encounters/encounters_widget.dart`
- redesign the presentation inside `appointment_details_widget.dart`
- refine `booking_bottom_sheet_widget.dart` success state
- add `dawa_appointment_reminder_sheet.dart`

Widget decomposition:

- care header and upcoming appointment hero
- clinician contact card
- quick-action grid and nearby clinic list
- details hero, clinician, bring list, visit notes, clinic location, reschedule/directions actions
- confirmation dialog and reminder sheet

State/backend:

- appointment list/detail/cancel/result summary continue through `AppointmentRepository`
- booking continues through clinician directory and appointment insert
- server-side email and Dawa Platform outboxes remain trigger-driven
- reminder preferences persist locally first with a repository seam; an owner-scoped additive table is used only if durable cross-device reminder state is added

Tests:

- existing appointment/result tests retained
- booking success and failure
- cancellation and result states
- reminder form validation/persistence
- responsive details layout

## Learning, quests, rewards, audio, and library

Screens: `learn.png`, `learn concept1.png`, `learn concept 2.png`, `learn 2.png`, `learning modules concept.png`, `learning concept2.png`, `learning concept4.png`, `learning.png`, `learning2.png`, `learning3.png`, `library.png`, `redeem reward.png`.

Files to create:

- `lib/features/learning/domain/dawa_learning_content.dart`
- `lib/features/learning/data/dawa_learning_repository.dart`
- `lib/features/learning/presentation/dawa_learn_page.dart`
- `lib/features/learning/presentation/dawa_article_page.dart`
- `lib/features/learning/presentation/dawa_quest_pages.dart`
- `lib/features/learning/presentation/dawa_audio_lesson_page.dart`
- `lib/features/learning/presentation/dawa_pregnancy_guides_page.dart`
- `lib/features/learning/presentation/dawa_library_page.dart`
- `lib/features/learning/presentation/dawa_reward_dialog.dart`

Widget decomposition:

- learning header/search/category chips
- reusable featured lesson, article, audio, quest progress, achievement, myth/fact, and guide cards
- Bana guide banner and feedback callout
- quest module list and checkpoint answer
- transcript/audio controller surface
- saved/offline segmented library

State/backend:

- clinical learning copy is bundled and deterministic
- bookmark, completion, streak, coins, language and offline metadata live behind one repository
- repository uses durable local preferences immediately and can synchronize to additive owner-scoped tables without changing widgets
- completion and redemption are idempotent
- Rudo launcher reuses the existing authenticated chat backend
- reward dialog does not produce a real voucher unless the backend confirms it

Tests:

- search/category/bookmark state
- quest order, answer correctness and idempotent rewards
- audio state/transcript availability
- library saved/offline filtering
- all major pages at the five target widths

## Profile, language, and notifications

Screens: `profile.png`, `choose language.png`, `choose language2.png`, `choose language3.png`, `notifications.png`.

Files:

- redesign `lib/features/settings/dawa_mom_settings_page.dart`
- create `lib/features/preferences/dawa_user_preferences_repository.dart`
- create `lib/features/preferences/dawa_language_sheet.dart`
- create `lib/features/notifications/dawa_notifications_page.dart`

Widget decomposition:

- profile hero
- four health-summary facts
- reward progress
- settings rows and profile/records actions
- language radio list with lesson/Rudo toggles
- notification category chips, mark-all-read, accessible notification cards, caught-up illustration

State/backend:

- profile/health facts come from `HealthProfileRepository`
- edit and health profile route to existing forms
- language/notification preferences persist through the preferences repository
- notification feed is derived from real appointment/cycle/learning state; read state is durable

Tests:

- repository snapshot states
- language selection/toggles
- filtering/mark all read
- large-text and keyboard navigation

## Backend decision record

Existing database coverage is sufficient for required core integration:

- `profiles`, `mothers`, `first_encounters`
- `appointments`, `appointment_result_summaries`
- `period_tracker_settings`, `period_tracker_entries`
- `chat_sessions`, `chat_messages`
- appointment email and Dawa Platform outboxes

If implementation requires synchronized learning/preferences state, add one non-destructive migration with:

- owner-scoped `dawa_mom_user_preferences`
- owner-scoped `dawa_mom_learning_progress`
- append-only/idempotent reward ledger and a security-definer redemption RPC with strict ownership checks
- RLS enabled before policies

No migration will alter or remove existing clinical data, relax RLS, or expose privileged keys.

## Verification policy

For every implemented route:

1. run formatter and analyzer
2. run focused widget/service tests
3. render at 390, 768, 1024, 1366 and 1440 widths where practical
4. compare hierarchy, spacing, typography, radii, color, artwork placement, empty/loading/error states
5. record deviations greater than 2 px or platform font-rendering differences
6. verify keyboard focus, semantics order, contrast, text scaling and no horizontal overflow
