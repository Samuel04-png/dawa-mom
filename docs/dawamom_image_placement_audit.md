# DawaMom image-placement audit

Updated: 28 July 2026

## Summary

All active placements using `assets/dawa_learning_assets` were inspected in code and in phone/tablet captures. The audit also covered the app’s transparent character art, logos, clinician avatars, and legacy empty-state illustrations.

The dominant problems were:

- Home used a 3:4 portrait crop inside a separate rounded box, even though the source was a landscape editorial image.
- Care used a 2.22:1 crop that removed too much of the consultation.
- lesson and game screens mixed ad-hoc `.85`, 1:1, 4:3, 16:9, 16:8, 16:7, and 16:7.2 ratios;
- the same photos were treated like transparent character illustrations inside `DawaIllustratedHeroCard`;
- several compact placements had locally selected radii and crop rules.

All active registry-backed placements now use a named `DawaImageVariant` and registry focal alignment. No active learning-image placement uses `BoxFit.fill`.

## Registry-backed placements

| Screen | Widget/file | Asset | Container | Ratio / fit | Focal behavior | Intended role | Previous problem | Implemented treatment | Status |
|---|---|---|---|---|---|---|---|---|---|
| Home | `_HomeJourneyHeroCard`, `responsive_home_dashboard.dart` | journey-specific `period_tracking_01`, `antenatal_stages_01`, or `cervical_awareness_02` | full card width below 430 or text scale above 1.2; 42% editorial region on larger layouts | `journeyHero`, 4:3, cover | registry variant alignment | primary journey identity | narrow nested photo card; face/calendar or pregnancy chart cropped | mobile text-first full-bleed composition; tablet integrated side region; outer card supplies the only clip | Implemented |
| Home | server announcement | announcement `asset_id` | 88 logical px side image | `cardSideImage`, 1:1, cover | registry | authenticated announcement thumbnail | local square crop logic | centralized square treatment and fallback | Implemented |
| Home | daily spotlight/tip | selected topic asset | 48 logical px | `compactThumbnail`, 1:1, cover | registry | small contextual cue | random local radius | compact variant; no visual flood | Implemented |
| Care | `_NextAppointmentCard`, `dawa_care_page.dart` | `clinic_visit_02` when planning; `clinic_visit_01` for booked visit | full-width top card section | `featuredBanner`, 16:9, cover | raised feature focal point | care hero | 2.22:1 crop; background poster visually dominant | stable 16:9 crop, both faces and planning gesture visible, no image inset | Implemented |
| Care | preparation link | `clinic_visit_05` | 78 logical px | `cardSideImage`, 1:1, cover | registry | preparation support | local square crop | named side-image treatment | Implemented |
| Booking success | `dawa_booking_success_dialog.dart` | `clinic_visit_02` | full card width | `featuredBanner`, 16:9, cover | feature focal override | confirm planning task | portrait source forced into a 16:7 strip | cleaner landscape source and standard ratio | Implemented |
| Appointment details | `_AppointmentPreparationCard` | `clinic_visit_03` | 104 logical px | `cardSideImage`, 1:1, cover | top centre | preparation cue after real booking data | local image geometry | standardized compact crop; booking facts remain above it | Implemented |
| Learn | featured recommendation | weekly selected topic image | full card width | `featuredBanner`, 16:9, cover | registry | editorial feature | extra-wide 16:7.2 crop | standard 16:9 cover with all faces visible | Implemented |
| Learn | Screening Without Fear continuation | stable quest cover | 82 logical px | `cardSideImage`, 1:1, cover | registry | recognizable course identity | local aspect declaration | centralized square treatment | Implemented |
| Learn | compact game entry | `myths_vs_fact_04` | 58 logical px | `compactThumbnail`, 1:1, cover | registry | game cue | local crop | compact variant | Implemented |
| Learn | two-column lesson cards | stable module cover | card width | `moduleThumbnail`, 4:3, cover | registry | editorial module cover | mixed ratios between cards | one stable 4:3 cover system | Implemented |
| Learn | standard lesson cards | stable module cover | card width | `moduleThumbnail`, 4:3, cover | registry | editorial module cover | 16:9 applied regardless of composition | 4:3 treatment preserves people, food, and teaching objects | Implemented |
| Learn | audio row | `pregnancy_basics_01` | 52 logical px | `compactThumbnail`, 1:1, cover | registry | audio cover | icon-led treatment | real topic cover with no floating overlay icon | Implemented |
| Library | saved/downloaded card | item’s stable cover | 88 logical px | `cardSideImage`, 1:1, cover | registry | content recognition | local square crop | stable named variant | Implemented |
| Topic hub | nine topic cards | each stable cover | responsive card width | `moduleThumbnail`, 4:3, cover | registry | topic identity | local aspect declaration | equal editorial covers | Implemented |
| Topic guide | guide hero | topic cover | page width, max 420 high | `articleHeader`, 16:9, cover | registry | article identity | generic 16:9 without variant policy | standard header with placeholder/fallback | Implemented |
| Topic guide | step cards | remaining topic images | card width | `moduleThumbnail`, 4:3, cover | registry | supporting teaching | all images forced into wide headers | 4:3 reduces face and hand cropping | Implemented |
| Cervical article | `DawaIllustratedHeroCard` | `cervical_awareness_01` | full card width | `articleHeader`, 16:9, cover | registry | article hero | photo treated as a small illustration beside text | full-width image section with text below | Implemented |
| Clinic lesson | `DawaIllustratedHeroCard` | clinic topic image | full card width | `articleHeader`, 16:9, cover | registry | article hero | photo in narrow side box | full-width editorial header | Implemented |
| Screening quest hub/module/completion | `DawaIllustratedHeroCard` | `screening_without_fear_01`, `_02`, `_05` | full card width | `articleHeader`, 16:9, cover | registry | stable quest/chapter/completion identity | repeated narrow photo-card treatment | full-bleed header, separate text surface | Implemented |
| Screening quest story | step explanation | `screening_without_fear_03` | full width on mobile; half width on tablet | `moduleThumbnail`, 4:3, cover | registry | chapter support | local geometry | responsive 4:3 image; stacks below copy on phone | Implemented |
| Screening result/related cards | result and completion images | `_04`, `_05` | 85 / 72 logical px | `cardSideImage`, 1:1, cover | registry | reassurance and next step | local square crop | centralized crop | Implemented |
| Myth lesson | lesson art | `myths_vs_fact_01` | full card width on mobile; 230 logical px on larger screens | `moduleThumbnail`, 4:3, cover | registry | approved explanation support | `.85` portrait crop and small pasted image | full-width phone cover or intentional desktop column | Implemented |
| Audio detail | audio cover | `pregnancy_basics_01` | full card width | `articleHeader`, 16:9, cover | registry | audio lesson identity | `.85` side crop inside fixed 250-high container | editorial header with copy and controls below | Implemented |
| Related guide row | stable module covers | 92 logical px | `cardSideImage`, 1:1, cover | registry | related learning | local square crop | centralized crop | Implemented |
| Games hub | each game family cover | game asset | 96 mobile / 112 larger | `cardSideImage`, 1:1, cover | registry | game recognition | arbitrary local crop | stable named variant | Implemented |
| Game question | game family cover | game asset | card width | `articleHeader`, 16:9, cover | registry | question context | 16:8 or 16:7 based on breakpoint | one 16:9 editorial treatment | Implemented |
| Game completion | completion asset | 154 logical px circular frame | `compactThumbnail`, 1:1, cover | registry | completion reinforcement | locally selected square | stable compact crop; no answer clue overlays | Implemented |
| Track first-use setup | period-products image | `period_tracking_03` | 90 logical px | `cardSideImage`, 1:1, cover | centre | period preparation | local crop | square side-image role | Implemented |
| Track cycle history | calendar image | `period_tracking_07` | 82 logical px | `cardSideImage`, 1:1, cover | registry | empty/insufficient-history education | local crop | stable side-image role | Implemented |
| Pregnancy Track | antenatal image | `antenatal_stages_03` | 66 logical px | `cardSideImage`, 1:1, cover | registry | visit education | local crop | stable side-image role | Implemented |
| Track educational heroes | `DawaIllustratedHeroCard` | period or antenatal asset | full card width | `articleHeader`, 16:9, cover | registry | educational header | photo treated as isolated character art | full-width editorial section | Implemented |
| Notifications | notification thumbnail | allowlisted item asset | 48 logical px | `compactThumbnail`, 1:1, cover | registry | local authenticated context | local square crop | centralized thumbnail; external notifications remain image-free | Implemented |
| Notifications | end/empty illustration | `screening_without_fear_05` | 116 logical px | `emptyState`, 4:3, cover | registry | calm empty state | square crop | less cramped 4:3 treatment | Implemented |

## Existing non-learning image systems inspected

| Surface | Assets / widget | Current treatment | Audit result | Status |
|---|---|---|---|---|
| App header and responsive shell | DawaMom logo, Rudo avatar, mother avatar | `contain`, `scaleDown`, or circular `cover` with explicit dimensions | correct for transparent logos and avatar art; no distortion | Retained |
| Onboarding and walkthrough | transparent character illustrations | constrained `BoxFit.contain`, separate text region | correct isolated-illustration pattern; no photo-card issue | Retained |
| Authentication | brand/character illustrations | constrained `contain` / `scaleDown` | preserves full transparent art | Retained |
| Profile completion and Rewards | `DawaIllustratedHeroCard` with transparent character assets | side illustration, `contain`, capped height | correct Pattern A treatment; contextual-photo path now uses a separate full-width Pattern B | Retained |
| Care clinician row | clinician character avatar | 67×67 circular container, `contain`, top centre | appropriate because source is an isolated character, not a photograph | Retained |
| Appointment reminder | clinic character illustration | 64×76, `contain` | clear supportive decoration; booking facts remain primary | Retained |
| Legacy generic empty states | menstrual calendar and no-data illustrations | fixed reserved height, `contain` | stable geometry and no stretch; active Track/Care surfaces use newer contextual content | Retained |
| Legacy FlutterFlow Home/Week pages | older photos and transparent illustrations | existing `cover` or `contain` | not part of the active responsive shell; no `BoxFit.fill` found | No functional redesign |

## Generated text and localization

Some period and clinic source art contains incidental English text on calendars or posters. Current crops keep it secondary, and every health instruction is repeated as real localized Flutter text. The app does not infer a result, status, prediction, diet, or action from text inside an image.

Text-free replacement masters are recommended for a future art refresh of `period_tracking_02`, `_06`, `_07`, `_08`, `_09`, `clinic_visit_01`, and `clinic_visit_02`, especially before fully localized image campaigns.

## Responsive and navigation verification

Captured and inspected:

- 360×800
- 390×844
- 412×915
- 768×1024 tablet portrait

Automated layout tests cover text scales 1.0, 1.3, and 1.5. Active scroll surfaces retain shell-managed bottom padding for the fixed navigation, safe area, decorative wave, and Rudo launcher. Final controls and cards can scroll fully above the navigation.
