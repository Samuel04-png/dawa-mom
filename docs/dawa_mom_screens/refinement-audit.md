# Dawa Mom second-pass visual and product audit

Audit date: 2026-07-23

## Outcome

All 31 supplied 941×1672 reference compositions were compared again with the
implemented routes and states. The live application keeps the references'
cream canvas, cobalt and green palette, Poppins hierarchy, white rounded cards,
compact status pills, transparent character scenes, and curved footer language.
The comparison also covered real form states, navigation, empty states,
responsive promotion, backend truthfulness, keyboard/semantics, and replay
behavior that a static reference cannot show.

## Reference-by-reference result

| Reference | Implemented route or state | Second-pass result |
|---|---|---|
| `start.png` | `/welcome` | Logo, line art, curved footer, CTA hierarchy and mobile composition verified in the live browser |
| `authentication.png` | `/register` | Form order, segmented email/phone mode, artwork and validation states verified at 390 and 1440 |
| `autnentication 2.png` | `/forgotPassword` | Recovery composition and real email/phone recovery paths retained |
| `onboarding.png` | onboarding care step | Floating appointment cards, pregnant-mother artwork and footer progress verified |
| `onboarding3.png` | onboarding tracker step | Calendar/period cards and first-step composition verified in browser and capture |
| `onboardin2.png` | onboarding Learn step | Learning cards, typography and progress sequence verified |
| `onboarding 2.png` | `/login` | Responsive sign-in composition and real auth behavior retained |
| `home.png` | `/home` | Real-data summary cards, quick actions and Dawa visual language retained |
| `track.png` | `/periodTracker` | Calendar hierarchy, legends, summaries and pregnancy state retained |
| `check up modal.png` | daily check-in sheet | Symptom, pain, feeling and note controls remain functional and scroll-safe |
| `care 1.png` | `/encounters` | Supplied clinician/mother artwork and real appointment states remain aligned |
| `appointment details.png` | `/appointmentDetails` | Status, clinician, clinic and actionable information hierarchy retained |
| `appointment booked modal.png` | post-booking confirmation | Confirmation appears only after a real booking result and preserves reminder choices |
| `set reminder.png` | appointment reminder sheet | Lead time and channel controls remain owner-scoped and persisted |
| `profile.png` | `/settings` | Profile facts, reward summary, setting rows and supplied artwork retained |
| `choose language.png` | compact language sheet | Sheet proportions, radio state and action placement retained |
| `choose language2.png` | expanded language sheet | Expanded language list remains scroll-safe |
| `choose language3.png` | alternate selection state | Selected state remains visible in icon, text and semantics |
| `notifications.png` | `/notifications` | Category filters, unread text state and supplied artwork retained |
| `redeem reward.png` | reward redemption dialog | Balance, cost and clinic copy retained; successful RPC now keeps the issued voucher visible and copyable |
| `learn.png` | `/learn` | Featured card, content tiles, audio card, quest and metrics retained; Games is an additive card |
| `learn concept1.png` | cervical-awareness article | Reading width, headings, actions and clinical wording retained |
| `learn concept 2.png` | `/learn/quests` | Bana hero, quest progress, action cards and rewards link retained |
| `learn 2.png` | quest completion | Celebration art, idempotent points and follow-up actions retained |
| `learning modules concept.png` | screening quest modules | Step order, progress and locked/completed states retained |
| `learning concept2.png` | clinic lesson | Illustrated conversation and Rudo hand-off retained |
| `learning concept4.png` | quest checkpoint | Answer feedback remains text/icon based and awards only once |
| `learning.png` | myth-versus-fact lesson | Swipe/card concept, explanation and lesson reward retained |
| `learning2.png` | pregnancy audio lesson | Playback controls, language, transcript and truthful progress retained |
| `learning3.png` | pregnancy guides | Guide hierarchy, search/filter and profile-aware state retained |
| `library.png` | `/learn/library` | Saved/offline filters, search and local-first states retained |

## Completion surfaces added after the audit

| Surface | Route/state | Functional behavior |
|---|---|---|
| Expanded first-run walkthrough | `/onboarding` step 4 | Introduces games, one-time points and care rewards using supplied Bana artwork |
| Replayable product tour | Profile → Replay app tour | Six steps cover care, cycle, games/rewards, health profile and Rudo |
| Health games hub | `/learn/games` | Shows completion, balance, rules, urgent-care boundary and two games |
| Myth Match | `/learn/games/myth-match` | Five questions, explanations, 80% pass threshold, replay and one-time 10-point award |
| Plate Builder | `/learn/games/plate-builder` | Five pregnancy food-safety choices, explanations, replay and one-time 10-point award |
| Game completion dialog | passing game overlay | Animated celebration, score, reward state, replay and Rewards action |
| Rewards center | `/learn/rewards` | Balance, voucher progress, earning paths, achievements and activity history |
| Active voucher state | Rewards and redemption dialog | Server-issued code is retained, reopenable, selectable and copyable |
| Help and support sheet | Profile → Help & support | Routes to Rudo or Care and states urgent-care boundaries explicitly |

## Reward and data invariants

- A game passes at 80% and awards 10 points only on its first successful
  completion.
- Replays remain available but the server award ledger returns a zero award.
- The server RPC is the source of truth for signed-in balances.
- Reward redemption remains server-only, validates the fixed cost, issues one
  voucher, and returns the same voucher on a repeat request.
- Local points, completions, pending sync IDs and vouchers are scoped to the
  signed-in owner. Pre-existing single-user cache data migrates once to the
  first signed-in owner after this update.
- Unknown content IDs receive no award.

## Motion, sound and accessibility

- Question changes use a short fade/slide; answer feedback expands without
  reflow jumps; completion art uses a restrained scale-in.
- Correct/wrong answers use subtle haptics. A successful completion plays a
  short, low-volume two-note WAV generated in memory, so no unlicensed audio
  asset or network request is required. Sound failure never blocks completion.
- Answer state is announced as text and semantics, not color only.
- Score, pass threshold, reward, completion, urgent-care guidance and voucher
  state all have readable text equivalents.
- Buttons keep at least 44 logical pixels, dialogs are bounded, and every new
  long surface scrolls.

## Verification performed

- Widget interactions cover pass, fail, replay, one-time local points, game
  rules, reward history, achievements and stored vouchers.
- Game hub, game play and rewards render without overflow at 390×844,
  768×1024, 1024×768, 1366×900 and 1440×900.
- A clean PostgreSQL 17 run applied both reward migrations. Myth Match returned
  `coin_award: 10`, its replay returned `coin_award: 0`, Plate Builder returned
  `coin_award: 10`, and the final balance was 200.
- The live web build was exercised in the in-app browser at 390 and 1440
  pixels. Welcome → all four onboarding steps → registration and blank-form
  validation worked with no browser console errors.
- Twelve deterministic 390×844 captures cover the original comparison set plus
  onboarding, games, rewards and both new completion/redemption dialogs.

## Intentional deviations

Pixel-for-pixel identity is constrained by dynamic content, device safe areas,
native text rasterization and real backend values. Real clinic/profile/cycle
data replaces sample text, and unsafe or simulated claims remain excluded. The
new games and reward center deliberately extend the reference set while using
the same design system and supplied assets.
