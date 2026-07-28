# DawaMom image variants

Updated: 28 July 2026

## Runtime variants

`DawaContextualImage` owns the geometry, crop strategy, radius, maximum height, overlay policy, full-bleed policy, shimmer, fade-in, fallback, and semantics for each editorial role.

| Variant | Ratio | Fit | Default radius | Maximum height | Overlay | Full bleed | Intended use |
|---|---:|---|---:|---:|---|---|---|
| `journeyHero` | 4:3 | cover | 28 | 420 | allowed | yes | Home cycle, pregnancy, postpartum, and general journey hero |
| `featuredBanner` | 16:9 | cover | 28 | 380 | allowed | yes | Learn feature, Care hero, booking confirmation |
| `moduleThumbnail` | 4:3 | cover | 18 | 320 | no | yes | Learning module and visual-guide cards |
| `compactThumbnail` | 1:1 | cover | 12 | 128 | no | no | Audio, game, tip, and notification thumbnails |
| `cardSideImage` | 1:1 | cover | 18 | 168 | no | no | Continue learning, appointment preparation, related content |
| `articleHeader` | 16:9 | cover | 24 | 420 | allowed | yes | Lesson, quest, game, and audio headers |
| `announcementBanner` | 16:9 | cover | 18 | 280 | allowed | yes | Future full-width in-app announcements |
| `emptyState` | 4:3 | cover | 24 | 320 | no | no | Learning and tracker empty states |
| `avatarIllustration` | 1:1 | contain | circular | 160 | no | no | Transparent isolated character art only |

Product screens should select a named variant instead of supplying a local aspect ratio. The component retains a compatibility ratio override for external or transitional code, but the active learning-image placements do not use it.

## Focal-point handling

The registry stores:

- a default normalized `Alignment`;
- `focalX` and `focalY` accessors;
- optional variant-specific alignments;
- the set of supported variants for each image.

Notable overrides:

| Asset | Default | Variant override | Reason |
|---|---|---|---|
| `period_tracking_01` | `(0, -0.12)` | journey `(0, -0.24)` | Keep the woman’s face and cycle calendar visible in the Home crop |
| `period_tracking_01` | `(0, -0.12)` | compact `(.12, -.20)` | Bias a square crop toward the calendar without losing the face |
| `period_tracking_05` | `(.18, -.08)` | compact `(.28, -.16)` | Preserve the woman rather than centring the background poster |
| `clinic_visit_01` | `(0, -.20)` | feature `(0, -.42)` | Keep both faces visible and reduce the visual weight of the background poster |
| `clinic_visit_02` | `(0, -.18)` | feature `(0, -.38)` | Keep both faces and the visit-planning gesture in the 16:9 Care crop |

Other images retain their supplied top-centre or centre focal point because contact-sheet inspection showed that the people and teaching object remain visible at all supported ratios.

## Generated bitmap crop variants

No additional `_wide`, `_card`, or `_square` files are currently shipped.

Contact-sheet and device-size inspection showed that the visible failures came from unsuitable widget geometry—especially portrait side crops and 2.22:1 banners—not insufficient source resolution. Correct full-bleed layouts, 16:9/4:3/1:1 roles, and focal metadata resolved the crops without adding duplicate files to the bundle.

If a future source cannot support more than one crop, create only the required derivatives using:

```text
<asset_id>_wide.webp
<asset_id>_card.webp
<asset_id>_square.webp
```

Any generated derivative must preserve the source subject, be added to the registry, and receive a file-existence and visual-regression test.

## Source-art text

The following source images contain incidental English poster or chart text:

- `period_tracking_02`
- `period_tracking_06`
- `period_tracking_07`
- `period_tracking_08`
- `period_tracking_09`
- `clinic_visit_01`
- `clinic_visit_02`

Their current crops keep that text secondary to the people or task. No medical instruction, status, or CTA depends on it; equivalent teaching is rendered as localizable Flutter text. Cleaner text-free masters would still be preferable for a future fully localized art refresh.
