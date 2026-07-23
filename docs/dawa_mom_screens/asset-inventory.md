# Dawa Mom screen and asset inventory

Inventory date: 2026-07-23

The supplied `dawa_mom_screens` package contains 174 usable image files:

- 31 mobile screen references
- 87 character files (including 13 source sheets and one contact sheet)
- 15 supporting illustrations
- 41 legacy/application images
- 4 `.DS_Store` metadata files, deliberately excluded from the application

All 31 screen references are `941 × 1672` PNGs (9:16 portrait). They are treated as a mobile baseline; tablet and desktop are responsive adaptations rather than separate supplied designs.

## Screen references

| Filename | Dimensions | Feature area | Variant | Prominent referenced assets |
|---|---:|---|---|---|
| `start.png` | 941×1672 | Entry/splash | Mobile portrait | Dawa Health mark, mother-and-baby line art |
| `authentication.png` | 941×1672 | Registration | Mobile portrait | Dawa Health mark, mother-and-baby line art |
| `autnentication 2.png` | 941×1672 | Password recovery | Mobile portrait | Dawa Health mark, mother-and-baby line art |
| `onboarding.png` | 941×1672 | Care onboarding | Mobile portrait | Pregnant mother hero, appointment/clinician/reminder cards |
| `onboarding3.png` | 941×1672 | Cycle onboarding | Mobile portrait | Pregnant mother hero, cycle calendar |
| `onboardin2.png` | 941×1672 | Learning onboarding | Mobile portrait | Pregnant mother hero, learning topic cards |
| `onboarding 2.png` | 941×1672 | Login | Mobile portrait | Dawa Health mark, mother-and-baby line art |
| `home.png` | 941×1672 | Dashboard | Mobile portrait | Pregnant mother line art, reward gift |
| `track.png` | 941×1672 | Cycle tracker | Mobile portrait | Pregnant mother line art |
| `check up modal.png` | 941×1672 | Daily symptom log | Mobile bottom sheet | Pregnant mother line art |
| `care 1.png` | 941×1672 | Care hub | Mobile portrait | Mother line art, clinician portrait |
| `appointment details.png` | 941×1672 | Appointment detail | Mobile portrait | Mother line art, clinician portrait, map |
| `appointment booked modal.png` | 941×1672 | Booking success | Mobile dialog | Mother line art |
| `set reminder.png` | 941×1672 | Appointment reminder | Mobile bottom sheet | Mother line art |
| `profile.png` | 941×1672 | Profile/settings | Mobile portrait | Main mother portrait, mother-and-baby line art, reward gift |
| `choose language.png` | 941×1672 | Language preference | Mobile bottom sheet, compact languages | Language line art |
| `choose language2.png` | 941×1672 | Language preference | Mobile bottom sheet, expanded languages | Language line art |
| `choose language3.png` | 941×1672 | Language preference | Mobile bottom sheet, expanded alternate | Language line art |
| `notifications.png` | 941×1672 | Notifications | Mobile portrait | Pregnancy/cycle line art |
| `redeem reward.png` | 941×1672 | Reward redemption | Mobile dialog | Gift/reward illustration |
| `learn.png` | 941×1672 | Learning hub | Mobile portrait | Cervical-health, nutrition, clinic, audio illustrations |
| `learn concept1.png` | 941×1672 | Article detail | Mobile portrait | Cervical-health awareness illustrations |
| `learn concept 2.png` | 941×1672 | Learning/quest hub | Mobile portrait | Bana Chenjela, quest path, cohort/reward artwork |
| `learn 2.png` | 941×1672 | Quest completion | Mobile portrait | Bana Chenjela, clinic path, achievements |
| `learning modules concept.png` | 941×1672 | Quest module list | Mobile portrait | Bana Chenjela, screening/clinic assets |
| `learning concept2.png` | 941×1672 | Lesson checkpoint | Mobile portrait | Cervical-health clinician conversation |
| `learning concept4.png` | 941×1672 | Quest checkpoint answer | Mobile portrait | Bana Chenjela, clinician, badge/reward |
| `learning.png` | 941×1672 | Myth vs fact lesson | Mobile portrait | Main mother, nutrition/clinic line art |
| `learning2.png` | 941×1672 | Audio lesson | Mobile portrait | Mother/audio line art, lesson artwork |
| `learning3.png` | 941×1672 | Pregnancy guide list | Mobile portrait | Pregnancy/nutrition/clinic illustrations |
| `library.png` | 941×1672 | Saved/offline library | Mobile portrait | Cervical-health, nutrition, pregnancy/audio illustrations |

## Character library

All production character cut-outs have transparent alpha channels.

| Folder/family | Files | Dimensions | Intended use |
|---|---|---:|---|
| `assets/characters/bana_chenjela` | `Calendar_Guidance`, `Celebrating_Reward`, `Explaining`, `Listening`, `Reassuring`, `Welcoming` | heights 320 px; widths 118–185 px | Learning guide, quest feedback, rewards |
| `assets/characters/cervical_health` | `At_Clinic`, `Awareness`, `Booking`, `Considering_Screening`, `Follow_Up`, `Waiting_Results` | heights 320 px; widths 152–322 px | Cervical-health journey and clinic education |
| `assets/characters/clinicians` | `Clinical_Officer-Reviewing`, `Community_Health_Worker`, `Doctor-Explaining`, `Midwife-Listening`, `Nurse-Greeting`, `Nurse-Referral` | heights 320 px; widths 121–230 px | Care cards, appointment details, trusted tips |
| `assets/characters/cycle` | `Fertile_Window-Education`, `Follicular-Energy`, `Irregular-Concerned`, `Luteal-Low_Energy`, `Menstruation-Cramps`, `Ovulation_Estimate-Calendar` | heights 320 px; widths 144–210 px | Cycle state, daily check-in, symptom education |
| `assets/characters/main_mother` | `Asking_Question`, `Greeting`, `Learning`, `Listening`, `Neutral`, `Receiving_Reward` | heights 320 px; widths 130–219 px | Profile, dashboard, general learning/reward states |
| `assets/characters/pregnancy` | `Postpartum-Newborn`, `Preconception`, `T1-Early`, `T2-Phone`, `T3-Birth_Preparation`, `Privacy-Neutral` | heights 320 px; widths 121–152 px | Pregnancy journey states and privacy choice |
| `assets/characters/_penpot` | the same 36 named production cut-outs | heights 240 px; widths 88–242 px | Smaller Penpot exports; keep as source/reference |
| `assets/characters/_source` | `bana-poses-alpha/chroma`, `cervical-journey-alpha/chroma`, `cervical-journey-v2-alpha/chroma`, `clinicians-alpha/chroma`, `cycle-phases-alpha/chroma`, `main-mother-poses-alpha/chroma`, `pregnancy-stages-alpha/chroma` | mostly 1536×1024; clinicians 1448×1086 | Source sprite sheets; alpha versions preferred |
| `assets/characters/character-library-contact-sheet.png` | one contact sheet | 1440×2340 | Visual index only; not shipped in UI |

The exact production filenames share the prefix visible in the folder, for example `CHAR-BANA-Calendar_Guidance.png` and `CHAR-MOTHER-PREG-T2-Phone.png`.

## Supporting illustrations

| Filename | Dimensions | Alpha | Intended use |
|---|---:|---|---|
| `clinic-conversation-crop.png` | 470×580 | No | Large clinic education panel |
| `clinic-conversation-penpot.png` | 162×200 | No | Compact clinic education panel |
| `guide-avatar-crop.png` | 620×620 | Yes | Bana avatar/header |
| `guide-avatar-penpot.png` | 120×120 | Yes | Compact Bana avatar |
| `guide-character-chroma.png` | 1086×1448 | No | Source/reference only |
| `guide-character-penpot.png` | 180×240 | Yes | Compact Bana full-body |
| `guide-character.png` | 1086×1448 | Yes | Large Bana full-body |
| `mother-baby-line-crop-final.png` | 330×520 | No | Authentication/onboarding ornament |
| `mother-baby-line-crop-v2.png` | 390×600 | No | Authentication/onboarding ornament |
| `mother-baby-line-crop-v3.png` | 330×600 | No | Authentication/onboarding ornament |
| `mother-baby-line-crop.png` | 470×680 | No | Authentication/onboarding ornament |
| `mother-baby-line-penpot.png` | 152×240 | No | Compact authentication ornament |
| `pregnant-mother-chroma.png` | 1024×1536 | No | Source/reference only |
| `pregnant-mother-penpot.png` | 160×240 | Yes | Compact onboarding hero |
| `pregnant-mother.png` | 1024×1536 | Yes | Large onboarding hero |

## Legacy/application images

The `images` folder contains 26 top-level assets and 15 alpha-corrected variants.

| Asset group | Files and dimensions | Decision |
|---|---|---|
| Brand marks | `app_launcher_icon.jpeg` 1024²; `app_launcher_icon.png` 127×121; `app_logo_2.png` 422²; `dawa_cross.png` 1506×1428; `dawa_cross2.png` 1795×1552; `dawa_mom_app_icon.png` 1024²; `dawa_mom_cross.png` 1312²; `dawa_mom_full.png` 2100×2394; `dawa_mom_wordmark.png` 2086×859; `dawa_text.png` 2495×1135; `dawa_text2.png` 2645×1195; `Logos-06.png` 4500²; `adaptive_foreground_icon.png` 4500²; `favicon.png` 16² | Use existing production logo component and transparent variants; do not rasterize text into new UI |
| Existing people/scene art | `female-doctor.png` 1024²; `female-doctor2.png` 373×504; `login-page-img.png` 716×471; `register-page-img.png` 700×442; `background.jpg` 6000×4000 | Retain for existing Rudo/legacy flows where the new character library has no equivalent |
| Existing state art | `Frame_41.png` 81²; `Frame_7.png` 1024²; `Group_1_dark.png` 369×200; `Menstrual_calendar-pana.png` 584×421; `No_data-pana.png` 578×444; `Pregnancy_stages-pana.png` 634×347; `Pregnancy_test-pana.png` 419×429; `Status_update-pana.png` 624×388 | Prefer alpha-corrected copies below |
| `images/transparent assets` | `Frame_41.png` 81²; `Logos-06.png` 500²; `Menstrual_calendar-pana.png` 584×421; `No_data-pana.png` 570×438; `Pregnancy_stages-pana.png` 634×347; `Pregnancy_test-pana.png` 419×429; `Status_update-pana.png` 624×388; `adaptive_foreground_icon.png` 500²; `dawa_cross2.png` 537×464; `dawa_mom_app_icon.png` 500²; `dawa_mom_cross.png` 500²; `dawa_mom_full.png` 468×533; `dawa_text2.png` 743×336; `login-page-img.png` 616×405 | Preferred legacy variants; all have alpha |

## Usage rules

- New character and transparent illustration assets use `BoxFit.contain`.
- Source/chroma sheets are not used directly in production widgets.
- Decorative images are excluded from semantics; informative images receive concise labels.
- Mobile artwork is bounded so text scaling cannot force horizontal overflow.
- The supplied Poppins Regular/Medium/SemiBold font family remains the application font.
