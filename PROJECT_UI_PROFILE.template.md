---
name: dawa-project-ui-profile
project: Dawa Health — Clinician
inherits: high-fidelity-ui-ux
platform: Flutter (Android, iOS, Web)
status: active
last_reviewed: 2026-09-22
---

# Dawa Health — PROJECT_UI_PROFILE

## 0. Purpose

This file specializes the shared `high-fidelity-ui-ux` skill for **Dawa Clinician**.

It is the product-specific source of truth for agents designing or implementing Dawa UI. It does **not** replace the universal UI/UX skill. The universal skill governs quality, accessibility, state completeness, anti-template behavior, and general interaction principles. This profile defines what those principles mean specifically for Dawa.

When rules conflict:

1. Clinical safety and truthful system state win.
2. Accessibility wins over visual styling.
3. This Dawa profile wins over generic visual preferences.
4. Existing coherent Dawa patterns should be extended before new patterns are invented.
5. Legacy/generated UI is not automatically a design precedent.

---

# 1. Product Identity

## Product

**Dawa Health — Clinician**

Dawa Clinician is a clinical workflow application focused on maternal and women's health. It brings patient records, appointments, encounters, screening tools, device-assisted care workflows, AI-assisted interpretation, and follow-up into one clinician-facing environment.

The current repository is Flutter-based and targets Android, iOS, and web.

## Product family

Dawa Clinician is part of the wider Dawa Health ecosystem.

It should visually feel related to patient-facing Dawa products such as Dawa Mom, but it should **not** copy their information density or interaction model blindly.

Shared family traits:
- recognizable Dawa branding,
- calm blue-led visual language,
- accessible controls,
- warm but professional communication,
- simple terminology,
- strong trust cues,
- restrained motion,
- clear health-state communication.

Different product roles:
- **Dawa Mom**: patient-facing, lower cognitive load, education-oriented, warmer and more guided.
- **Dawa Clinician**: clinician-facing, more information-dense, task-oriented, precise, faster to scan, and optimized for repeat professional use.

---

# 2. Primary Users

## Primary users

Licensed or supervised clinical staff working with maternal and women's health patients.

Typical tasks include:
- finding a patient,
- reviewing history,
- registering a new patient,
- checking appointment requests,
- scheduling or rescheduling appointments,
- recording encounters,
- launching screening tools,
- reviewing results,
- identifying patients/results needing attention,
- interpreting device or AI-assisted output,
- saving clinical records,
- and planning follow-up.

## Secondary users

Depending on deployment and permissions:
- clinic administrators,
- supervisors,
- screening operators,
- technical support/admin staff.

Do not expose administrative or engineering controls to ordinary clinicians unless permission and workflow require them.

---

# 3. Usage Environment

Design for real clinical and field conditions, not a perfect office demo.

Assume some users may be:
- using Android phones,
- using tablets,
- using browser-based clinic workstations,
- working under intermittent or poor internet,
- switching between patients quickly,
- wearing gloves or moving between equipment,
- entering information under time pressure,
- working in bright environments,
- returning to an interrupted form,
- interacting with external screening hardware,
- and reviewing sensitive health information in semi-public clinical spaces.

Implications:
- controls must be easy to hit,
- hierarchy must be immediately scannable,
- state must survive interruptions where practical,
- loading/offline/device states must be explicit,
- error recovery must preserve entered information,
- decorative motion must never slow the workflow,
- sensitive information should not be unnecessarily exposed in large decorative text.

---

# 4. Trust Level

**Trust level: Very high / clinical**

Dawa UI must never visually imply more certainty than the underlying system has.

The interface must clearly distinguish:
- recorded facts,
- clinician-entered observations,
- device output,
- AI-assisted analysis,
- secondary/online opinions,
- pending data,
- locally queued data,
- synced data,
- incomplete records,
- and clinician decisions.

Never use visual polish to make experimental, mock, or unvalidated functionality appear clinically authoritative.

---

# 5. Core Experience Principles

Every Dawa screen should embody these principles.

## 5.1 Calm, not sterile

Dawa should feel:
- composed,
- capable,
- trustworthy,
- approachable,
- and human.

It should not feel:
- cold,
- futuristic,
- aggressively corporate,
- playful in serious clinical moments,
- or visually like a generic hospital management template.

## 5.2 Clear before clever

A clinician should understand:
- where they are,
- which patient they are viewing,
- what the current state is,
- what requires attention,
- and what action comes next

without decoding decorative UI.

## 5.3 Familiar before novel

Prefer patterns clinicians already understand:
- lists,
- timelines,
- clearly labeled fields,
- appointment rows,
- screening histories,
- direct actions,
- structured forms,
- and predictable navigation.

Do not turn routine clinical tasks into experimental gesture-driven interfaces.

## 5.4 Patient context must stay visible

When a clinician enters a patient-linked flow, preserve enough patient identity to prevent accidental context loss.

At minimum, patient-linked workflows should make it easy to confirm:
- patient name,
- patient ID,
- and relevant context for the action.

Do not repeatedly force the clinician to reselect the same patient inside a workflow launched from that patient's record.

## 5.5 Attention must be meaningful

Do not make every abnormal, incomplete, pending, new, or overdue item visually scream.

Reserve strong visual emphasis for:
- clinically meaningful risk,
- blocked actions,
- genuine failure,
- urgent review,
- or destructive consequences.

---

# 6. Existing Repository Context

The current codebase is a Flutter project originally shaped by FlutterFlow, then extended with:
- Supabase,
- offline support,
- device communication,
- care tools,
- AI-assisted screening,
- responsive layouts,
- and a newer Dawa design system.

Important paths:

```text
lib/components/dawa_design_system.dart
lib/flutter_flow/flutter_flow_theme.dart
lib/main.dart

lib/application/home/
lib/application/moms/
lib/application/patient_details/
lib/application/mom_details/
lib/application/mom_details2/
lib/application/scheduled_encounters/
lib/application/care_tools/
lib/application/cacx/
lib/application/bp_monitor/
lib/application/ultrasound/
lib/application/hemonix/
lib/application/ct_scan/

lib/features/appointments/
lib/services/offline_connectivity_service.dart
lib/components/offline_status_banner.dart
```

Important implementation reality:
- newer and legacy UI coexist,
- some large screens remain FlutterFlow-generated,
- two patient-detail experiences currently exist,
- some clinical tool modules still use mock/local state,
- app-wide localization is not yet implemented,
- offline support is partial rather than full offline EHR behavior.

Agents must not hide these facts behind visual polish.

---

# 7. Brand Personality

Dawa should feel:

**Professional**
- clinically credible,
- orderly,
- precise.

**Human**
- approachable language,
- warm whitespace,
- non-intimidating controls.

**Local and practical**
- built for actual clinic and field conditions,
- not a Silicon Valley health-tech concept mockup.

**Modern**
- clean,
- responsive,
- fast,
- but not trend-driven.

**Quietly confident**
- strong identity without excessive decoration.

Keywords:
- calm,
- capable,
- trustworthy,
- grounded,
- clear,
- useful,
- compassionate,
- efficient.

Avoid:
- luxury,
- futuristic,
- cyber,
- playful gamification in clinician workflows,
- glossy fintech styling,
- generic corporate hospital blue everywhere,
- sterile monochrome,
- decorative medical icon overload.

---

# 8. Existing Brand Assets

Current assets include:
- full Dawa Health logo,
- Dawa cross mark,
- Dawa wordmark,
- clinician illustration,
- empty-state illustration.

Relevant paths:

```text
assets/images/Logos-06.png
assets/images/dawa_cross.png
assets/images/dawa_text.png
assets/images/doctor_graphic.png
assets/images/no_data.png
assets/images/trasnsparent assets/
```

## Asset usage rules

Use the Dawa cross/wordmark as identity, not decoration.

Do not:
- repeat the logo inside ordinary cards,
- watermark screens with the logo,
- place the medical cross beside every clinical feature,
- recolor the logo arbitrarily,
- stretch the wordmark,
- or use the clinician illustration to fill otherwise weak layouts.

Illustrations should appear only when they improve:
- onboarding,
- an empty state,
- education,
- or orientation.

Clinical workspaces should generally prioritize data and tasks over illustration.

---

# 9. Color System

The current Dawa design system is blue-led.

## Existing source-of-truth tokens

```text
brandPrimary       #1E3A8A
brandPrimaryLight  #3B5FCF
brandPrimaryPale   #EEF2FF
brandAccent        #4B5F8F

success            #16A34A
successText        #15803D
successBg          #DCFCE7

warning            #D97706
warningText        #B45309
warningBg          #FEF3C7

danger             #DC2626
dangerText         #B91C1C
dangerBg           #FEE2E2

info               #1E3A8A
infoBg             #EEF2FF

surface            #FFFFFF
surfaceSecondary   #F8FAFC
surfaceTertiary    #F1F5F9

border             #E2E8F0
borderStrong       #CBD5E1

textPrimary        #0F172A
textSecondary      #475569
textMuted          #94A3B8
textInverse        #FFFFFF
```

Primary implementation source:

```text
lib/components/dawa_design_system.dart
```

## Color rules

Blue is the brand anchor, not permission to make every surface blue.

Use primary blue for:
- primary actions,
- selected navigation,
- focus,
- meaningful links,
- brand moments,
- and selected states.

Use semantic colors for actual semantic meaning.

Do not:
- invent additional blues screen-by-screen,
- use danger red for routine decoration,
- make every tool a different saturated color,
- create rainbow status systems,
- use purple AI styling,
- use blue gradients as generic visual interest.

## Clinical risk colors

Risk must never be communicated by color alone.

Always pair risk color with:
- text,
- explicit level,
- icon/marker when useful,
- or structured explanation.

Examples:
- `Low risk`
- `Needs review`
- `High risk`

Avoid vague color-only interpretation.

---

# 10. Typography

## Primary family

**DM Sans**

The current design system and theme use DM Sans.

Do not introduce another primary UI font unless the Dawa brand direction is intentionally changed.

## Existing role direction

Current repository roles include approximately:

```text
Page title       22px / 700
Card title       15px / 600
Body             14px / regular
Secondary        13px / regular
Label            12px / 600
Stat number      28px / 700
```

FlutterFlow theme also contains larger display sizes. These are not permission to use oversized display typography inside clinical workflows.

## Typography rules

Clinical interfaces should favor:
- compact page titles,
- clear section headings,
- readable body text,
- strong patient names,
- quiet secondary metadata.

Avoid:
- giant dashboard headlines,
- all-caps paragraphs,
- excessive letter spacing,
- tiny grey metadata,
- shrinking clinical information to preserve a decorative layout.

Uppercase may be used sparingly for very small structural labels such as:
- `MOST RECENT`
- `PATIENT ID`

but sentence case is the default.

---

# 11. Geometry

Current Dawa radius tokens:

```text
radiusSm  6
radiusMd  10
radiusLg  14
radiusXl  20
```

## Recommended use

```text
6   compact controls / small inner surfaces
10  standard controls / inputs / buttons
14  cards or grouped content where a bounded surface is justified
20  dialogs or special high-level surfaces only
```

Do not:
- introduce `24`, `28`, `32`, or pill-shaped global surfaces without reason,
- make every container rounded,
- apply `radiusXl` to all cards,
- create nested rounded rectangles inside rounded rectangles repeatedly.

---

# 12. Borders and Shadows

The app already includes subtle shadow tokens.

Use shadows only for genuine layering:
- floating menus,
- dialogs,
- temporary overlay surfaces,
- sticky overlapping controls.

For ordinary content grouping, prefer:
- whitespace,
- subtle borders,
- background contrast,
- section dividers.

`DawaCard` existing in the repository is a reusable option, **not the default answer for every section**.

A page made almost entirely from `DawaCard` is usually a warning sign.

---

# 13. Spacing System

Prefer a small, repeatable scale.

Recommended Dawa working scale:

```text
4
6
8
10
12
16
20
24
32
40
48
```

Primary layout rhythm:
- 4–8: tight relationship,
- 10–16: component internal spacing,
- 20–24: section internal spacing,
- 24–32: separation between page sections,
- 40–48: major visual breaks.

Do not generate arbitrary spacing values without a geometry reason.

---

# 14. Density

## Desktop/web

Density: **moderate to high**

Clinicians should be able to scan multiple records and actions without excessive scrolling.

Use:
- structured rows,
- grouped information,
- tables where appropriate,
- side-by-side context,
- persistent navigation.

Do not enlarge all controls and whitespace merely to make the UI appear premium.

## Tablet

Density: **moderate**

Preserve clinical context while allowing touch interaction.

## Phone

Density: **moderate with larger hit targets**

Recompose content:
- stack sections,
- prioritize patient identity and immediate actions,
- collapse secondary data intentionally,
- preserve bottom navigation,
- avoid horizontally cramped action bars.

---

# 15. Responsive Strategy

Current repository behavior commonly uses widths around:

```text
< 560   small/mobile composition
< 700   compact home/navigation composition
< 900   stacked/tablet composition
>= 900  wider multi-column layouts
1200    common content max width
```

These are existing implementation patterns, not universal immutable breakpoints.

Agents should preserve consistency with these values unless a component demonstrates a better domain-specific breakpoint.

## Required test widths

At minimum:

```text
390 x 820
820 x 900
1200 x 900
```

Also inspect at least one smaller Android width when modifying dense forms or clinical result screens.

---

# 16. Navigation Architecture

## Current primary destinations

Clinician mobile bottom navigation:

1. Home
2. Patients
3. Appointments
4. Tools
5. Settings

This is a good top-level mental model and should remain stable unless product requirements materially change.

## Desktop

Use persistent left navigation for frequent top-level destinations.

Current desktop sidebar width is approximately:

```text
240px
```

Do not let the desktop sidebar become a list of every individual medical tool.

Care tools belong primarily under **Tools**.

Direct shortcuts may exist only when:
- usage frequency clearly justifies them,
- they do not make the navigation hierarchy confusing,
- and they remain consistent with the Tools hub.

## Navigation naming

Use clinician-facing labels:
- Patients
- Appointments
- Care Tools
- Settings

Avoid leaking implementation names such as:
- `MotherRecord`
- `MomDetails2`
- `ScheduledEncountersWidget`
- raw database/table names.

---

# 17. Home Screen Contract

The Home screen exists to answer:

- What needs my attention?
- What is happening today?
- Which patient should I return to?
- What common action do I need next?

Current content includes:
- greeting/date,
- clinical summary,
- patient/appointment statistics,
- recent patients,
- calendar/activity,
- quick actions.

## Rules

Do not turn Home into a generic executive dashboard.

A statistic earns space only if it helps the clinician decide what to do next.

Useful examples:
- appointments today,
- records missing required data,
- flagged screenings requiring review.

Weak examples:
- arbitrary growth percentages,
- decorative weekly trends,
- vanity totals with no workflow consequence.

## Quick Actions

Quick actions should contain genuinely frequent actions.

Do not duplicate every Care Tool on Home simply because it can fit.

Prefer a compact set such as:
- New patient
- Schedule appointment
- Start common screening
- Continue flagged work

with a clear path to the complete Tools area.

---

# 18. Patient List Contract

The Patients area should optimize:

**Find → identify → open → act**

Primary needs:
- search,
- meaningful filtering,
- patient identity,
- record completeness/state,
- last relevant activity where useful,
- fast access to the patient record.

## Desktop

Prefer structured list/table-like presentation over a wall of patient cards.

## Mobile

Use compact patient rows or domain-specific list items.

Each patient item should make identity unmistakable without exposing unnecessary health details in the list.

## Search

Search should support the fields clinicians actually know, such as:
- patient name,
- patient ID,
- phone where appropriate.

Do not add complex filter UI until there is a clear workflow need.

---

# 19. Patient Detail Contract

The newer `PatientDetailsWidget` represents the preferred direction for screening-centered patient context.

The page should establish:

1. patient identity,
2. contact/demographic context,
3. current risk/attention state,
4. latest screening,
5. screening history,
6. relevant actions,
7. route to complete maternal/encounter record.

## Primary actions

Examples:
- Add Screening
- Open Full Record

Avoid a generic "Quick Actions" area containing unrelated commands.

Actions should be directly related to the current patient.

## Two-record-experience rule

The repository currently contains:
- newer patient details,
- legacy maternal record screens.

Do not casually create a third patient-detail experience.

New work should converge these experiences over time rather than multiplying them.

Until consolidation is complete:
- the newer page is the screening-oriented summary,
- legacy maternal screens remain the fuller encounter/pregnancy record,
- transitions between them must be explicit.

---

# 20. Appointments Contract

Appointments connect Dawa Clinician and Dawa Mom.

The clinician needs to understand:
- who requested/owns the appointment,
- scheduled date/time,
- current status,
- whether an action affects the patient-facing app,
- and what happens after confirm/decline/reschedule/cancel.

## Status actions

High-consequence status changes should be explicit.

When an action sends or changes a patient-facing status, say so in human language.

Example:

`This updates the appointment and sends a status message to Dawa Mom.`

## Modal use

Short scheduling/rescheduling tasks may use a dialog if:
- the form remains short,
- context is clear,
- no second modal is required,
- keyboard/mobile behavior remains usable.

Move longer appointment workflows to a dedicated route.

No modal-on-modal chains.

---

# 21. Care Tools Contract

Current care tools include:
- CaCx Screening,
- HemoNix,
- CT Scan,
- BP Monitor,
- Ultrasound.

The Tools page is a clinical module launcher and status overview.

## Design goal

Help clinicians answer:
- Which tool do I need?
- Are there records requiring review?
- What happened recently?

## Do not build a generic app-store grid

Each tool surface should show only useful operational context.

Avoid:
- giant colorful icons,
- identical cards filled with decorative metrics,
- unrelated marketing descriptions,
- excessive badges.

The tool name and clinical purpose should dominate.

---

# 22. CaCx Screening Contract

CaCx is one of the most mature and clinically important workflows in the repository.

Current intended sequence:

```text
Patient
→ image source
→ local device analysis when available
→ primary result
→ online second opinion when applicable
→ result interpretation
→ save
→ patient history / follow-up
```

## Patient continuity

When launched from Patient Details:
- preload the patient,
- do not ask the clinician to select the patient again,
- preserve the return path,
- refresh screening history after save.

## Image acquisition

Camera/gallery choice must be obvious.

Do not obscure the source choice behind ambiguous icons.

## Results hierarchy

Results should generally appear in this order:

1. patient / screening identity,
2. primary result,
3. risk level,
4. confidence/context,
5. image,
6. prediction breakdown where useful,
7. device/second-opinion distinction,
8. recommendation,
9. clinician action,
10. save/share/history.

Do not make AI confidence visually more important than the clinical result or review requirement.

---

# 23. Clinical AI & Decision-Support Rules

Dawa may use AI/device analysis, but the UI must not imply autonomous medical authority.

## Mandatory distinctions

Where applicable, label:
- device result,
- AI-assisted result,
- online second opinion,
- confidence,
- pending review,
- clinician-reviewed state.

Do not merge multiple sources into one unexplained "AI result."

## Confidence

Confidence is supporting information.

It must not be:
- the biggest number on the page,
- treated as clinical certainty,
- represented by celebratory animation,
- or used alone to determine visual urgency.

## Recommendations

Recommendations should be:
- concise,
- actionable,
- cautious,
- tied to the result context,
- and reviewed/validated before being treated as clinical guidance.

Do not generate patient-specific clinical guidance in UI copy merely because a model can produce it.

## Explainability

Where prediction breakdowns exist, show them only if they help a qualified user interpret the output.

Do not add fake "AI reasoning" panels.

---

# 24. Other Clinical Tools

## HemoNix

Current implementation includes quick-access/dashboard behavior but still contains mock/prototype data paths.

Future UI must anticipate:
- units,
- decimal precision,
- quality flags,
- patient linking,
- review state,
- device state.

## CT Scan

Current module is not yet a complete radiology workflow.

Do not visually imply:
- completed PACS integration,
- radiologist sign-off,
- real imaging persistence,
- or production review infrastructure

unless implemented.

## Ultrasound

Current implementation includes:
- manual/AI-guided modes,
- image capture/upload,
- AI service integration,
- local/mock scan records,
- incomplete hardware bridge work.

UI must distinguish:
- acquired image,
- uploaded image,
- analysis state,
- persisted scan,
- and mock/demo records.

## BP Monitor

Current module interprets:
- systolic/diastolic,
- age,
- notes,
- risk context such as pregnancy or chronic disease.

Before production expansion, support:
- patient linking,
- persistent history,
- clear units,
- repeat-reading workflows,
- clinician review.

---

# 25. Mock & Prototype Data

This is a critical Dawa rule.

The repository currently contains mock/local records in some Care Tool implementations.

## Never allow mock data to masquerade as patient truth

Development data must be:
- isolated,
- clearly scoped,
- disabled in production,
- or visibly marked as demo data in demo environments.

Do not show fictional patient names, results, confidence values, or totals as if they are live tenant data.

Never create fake:
- screening counts,
- patient trends,
- clinical outcomes,
- AI performance numbers,
- appointment volumes,
- or "success" metrics

to fill empty UI.

A truthful empty state is better than a convincing fake dashboard.

---

# 26. Offline & Connectivity UX

Offline support is an important Dawa product characteristic.

Current implementation supports parts of:
- cached identity,
- cached rows,
- connectivity status,
- local device availability checks,
- offline CaCx device flow,
- queued CaCx results.

It is **not** yet a complete offline EHR.

## Required states

The UI should distinguish:

```text
Online
Offline with cached data
Offline with local device available
Offline with local device unavailable
Queued locally
Sync pending
Sync failed
Synced
Stale cached data
```

Do not collapse all of these into one generic "Offline" state when the distinction affects workflow.

## Offline banner

Connectivity status should be noticeable but not permanently dominate the workspace.

If an action will not work offline, communicate that near the action.

## Saved vs queued

Never say `Saved` when the record is only queued locally.

Use truthful wording such as:
- Saved on this device
- Waiting to sync
- Synced
- Sync failed — retry

---

# 27. Device & Hardware UX

Dawa interacts with local/external clinical hardware.

Device UI should answer:

- Is the device detected?
- Is it ready?
- Is analysis running?
- Did the device return a result?
- Is the result saved?
- Was an online second opinion requested?
- What should the clinician do if the device fails?

## Device state vocabulary

Prefer explicit states:

```text
Device connected
Device unavailable
Checking device
Sending image
Analyzing
Result received
Retrying
```

Avoid abstract loading messages such as:
- Processing magic
- AI working
- Please wait...

## Failure

A device failure must not look like a negative clinical result.

Technical failure and medical result are different categories.

---

# 28. Status Language

Use stable clinical/operational terminology.

Examples already present:
- Completed
- Needs Review
- Suspicious
- Normal
- Pending
- Scheduled
- Missing Data
- New
- Active

## Rules

Avoid near-duplicate words for the same state.

For example, do not mix:
- `Needs Review`
- `Review Needed`
- `Flagged`
- `Attention`

unless they have intentionally different meanings.

Create a state vocabulary and reuse it.

## Pill restraint

Not every status needs a pill.

Use pills/badges when they materially improve scanning.

For dense lists, a small text/marker treatment may be better.

---

# 29. Forms

Dawa forms may contain sensitive and medically meaningful data.

## Required behavior

- persistent labels,
- explicit units,
- logical grouping,
- inline validation,
- preservation after recoverable failure,
- correct keyboard/input type,
- clear optional vs required fields,
- safe date handling,
- no accidental clearing.

## Long forms

Large clinical intake or encounter forms should be divided according to real clinical concepts, not arbitrary "Step 1 / Step 2" screens.

Potential sections:
- Patient details
- Pregnancy context
- Vitals
- Screening
- Clinical notes
- Follow-up

Only use a stepper when sequence matters.

## Inputs

Inputs should use the existing Dawa theme:
- light neutral fill,
- visible border,
- blue focus,
- approximately 10px radius,
- adequate touch height.

Do not create floating glass inputs or borderless fields that are difficult to locate.

---

# 30. Buttons

Existing theme direction:
- minimum interactive height approximately 48dp,
- primary blue,
- white primary text,
- approximately 10px radius,
- low/no elevation.

## Hierarchy

Primary:
- one dominant action per local decision area.

Secondary:
- outlined or quieter action.

Tertiary:
- text action.

Destructive:
- explicit destructive semantics; do not style as ordinary brand action.

## Labels

Use specific verbs:
- Add Screening
- Schedule Appointment
- Save Result
- Reschedule
- Open Full Record
- Retry Sync

Avoid vague labels such as:
- Submit
- Proceed
- Do it
- Continue

when the next action can be named.

---

# 31. Icons

The repository currently uses Material icons extensively.

Future work should reduce visual inconsistency rather than adding more icon families.

## Rules

- Do not mix multiple outline/filled icon languages within one surface without reason.
- Keep optical size consistent.
- Icons must support recognition, not decorate labels.
- Do not add icons to every statistic.
- Avoid generic hearts for unrelated medical functions.
- Avoid using the medical cross as a generic bullet.
- Icon-only actions require accessible labels/tooltips.

When introducing a dedicated icon library or custom SVG set, migrate deliberately rather than partially mixing styles across one screen.

---

# 32. Empty States

Current Dawa includes an empty-state illustration.

Use illustration sparingly.

An empty state must say:
1. what is empty,
2. what that means,
3. what useful action is available.

Good:
- `No screenings yet`
- explanation,
- `Add Screening`

Avoid:
- `No data`
- giant illustration,
- no next step.

For data-heavy views, preserve enough page/table structure that the clinician still understands what will appear there.

---

# 33. Loading

Use localized loading.

Examples:
- button spinner during schedule/save,
- skeleton for patient summary,
- row-level loading for a status change,
- small connection check state.

Do not block the entire application because one card is refreshing.

## Loading text

Prefer task language:
- Saving screening…
- Checking device…
- Scheduling…
- Syncing…

Avoid vague:
- Loading…
- Processing…

when context can be stated.

---

# 34. Errors

Errors must distinguish:
- validation error,
- connectivity failure,
- device failure,
- server failure,
- permission failure,
- unavailable appointment slot,
- missing clinical data.

Do not expose raw Supabase, Postgres, Flutter, HTTP, or device stack traces to clinicians.

Preserve form data after recoverable errors.

Critical failures should be visible in context, not only through short-lived SnackBars.

---

# 35. Motion

Dawa motion should feel:
- restrained,
- fast,
- predictable.

Use motion for:
- state changes,
- content expansion,
- navigation continuity,
- calendar/month changes,
- save completion,
- context transitions.

Do not use:
- bouncing medical icons,
- animated gradients,
- floating cards,
- looping pulse effects,
- celebratory confetti,
- dramatic result reveals.

Clinical results should appear calmly and immediately.

Respect reduced-motion preferences.

---

# 36. Haptics

Use selectively on supported mobile devices for:
- meaningful confirmation,
- important selection,
- successful capture,
- or high-confidence tactile feedback around a direct physical action.

Do not trigger haptics on every button.

Web/desktop behavior must not depend on haptics.

---

# 37. Accessibility

## Touch targets

Target at least:

```text
48 x 48 logical pixels
```

for common interactive controls in the Flutter clinician app.

## Text scaling

Test:
- navigation labels,
- buttons,
- status indicators,
- patient names,
- risk summaries,
- clinical recommendations,
- tables/lists

with increased text scaling.

Do not hide critical text behind ellipsis simply to preserve card height.

## Contrast

Verify:
- secondary text,
- muted text,
- warning backgrounds,
- disabled controls,
- focus,
- chips/badges,
- charts/progress bars.

## Semantics

Important icons, images, controls, and result states should have useful semantics.

## Keyboard

Web/desktop flows must support keyboard navigation where practical, especially:
- search,
- forms,
- dialogs,
- tables,
- patient lists,
- appointment controls.

---

# 38. Localization & Language

Current full application locale support is effectively English-only.

CaCx includes recommendation-level support for:
- English,
- Nyanja,
- Bemba,
- Tonga,
- Shona,
- Ndebele.

This is not equivalent to full app localization.

## Rules

Do not claim the entire app is multilingual until navigation, forms, validation, statuses, and core workflows use a real localization system.

Clinical translations require review.

When localized recommendation text is not fully clinically approved, preserve the approved/source language as appropriate.

Design all result surfaces to survive longer translated strings.

---

# 39. Dawa Mom Interoperability

Dawa Clinician and Dawa Mom should feel like two views of the same care relationship.

Cross-product workflows include appointment updates and patient-related data synchronization.

## Shared visual identity

Keep:
- Dawa blue,
- typography family where appropriate,
- semantic state consistency,
- recognizable logo treatment,
- similar control quality.

## Do not make both apps identical

Clinician:
- denser,
- faster,
- more operational,
- structured data,
- professional terminology.

Mom:
- simpler,
- more explanatory,
- more supportive,
- more guided,
- patient-friendly language.

## Cross-app consequences

When a clinician action changes the patient's Dawa Mom experience, surface that consequence when relevant.

Example:
`The patient will receive an updated appointment status.`

---

# 40. Privacy & Sensitive Information

Dawa handles health data.

UI must minimize unnecessary exposure.

Avoid:
- large full-width displays of sensitive details when not necessary,
- showing more patient data than needed in list views,
- putting health details into decorative notifications,
- leaking patient data into debug banners,
- using screenshots containing real patient data in documentation without approval.

When designing shared/public-facing states, use safe demo fixtures rather than real records.

---

# 41. Flutter-Specific Rules

This profile is used with the Flutter adapter from the shared skill.

## Theme

Use:
```text
DawaTokens
DawaTextStyles
ThemeData
FlutterFlowTheme only where legacy compatibility requires it
```

New code should prefer centralized Dawa tokens over arbitrary inline values.

## Safe areas

Respect:
- top system areas,
- bottom navigation,
- keyboard insets.

## State preservation

Preserve:
- form input,
- selected patient,
- search/filter context,
- scroll position where it aids return workflows,
- selected calendar date,
- unfinished safe local workflows.

Do not add `AutomaticKeepAliveClientMixin` blindly to every screen.

## Navigation

Use real route/state behavior rather than visually swapping entire pseudo-pages inside one widget when a route is appropriate.

## Scrolling

Use native Flutter scrolling.

Do not:
- suppress scrolling to hide overflow,
- lock whole screens to viewport height,
- create nested scroll views without a clear need.

---

# 42. Legacy FlutterFlow Migration Rules

The repository still contains large generated screens and compatibility code.

## Do not rewrite everything at once

When touching a legacy screen:

1. identify the workflow,
2. preserve business behavior,
3. isolate the section being improved,
4. move new visual choices toward Dawa tokens/components,
5. regression test,
6. avoid unrelated rewrites.

## Generated code is not automatically design truth

If legacy code contains:
- arbitrary spacing,
- oversized buttons,
- inconsistent radius,
- mixed typography,
- old colors,
- duplicated wrappers,

do not copy those patterns into new components.

Prefer the current Dawa design system.

## New domain components

Create meaningful components for repeated Dawa concepts, for example:

```text
PatientIdentityHeader
ScreeningSummary
RiskSummary
ScreeningHistoryRow
AppointmentRequestRow
SyncStateIndicator
DeviceStateIndicator
ClinicalToolRow
EncounterTimelineItem
```

Avoid generic names such as:

```text
NiceCard
BlueBox
FancyContainer
InfoTile2
```

---

# 43. Anti-"AI Slop" Rules Specific to Dawa

The following are explicitly forbidden unless a real requirement justifies them:

- blue/purple gradients,
- glassmorphism,
- giant rounded clinical cards,
- glow around AI results,
- sparkles for AI,
- floating chatbot orb as the main clinical interface,
- "AI powered" badges beside routine screens,
- robot/neural-network illustrations,
- a medical icon beside every heading,
- heart icons for every health feature,
- a four-KPI-card wall copied onto every module,
- huge "94% CONFIDENCE" hero numbers,
- fake clinical statistics,
- rainbow tool cards,
- decorative ECG lines running through page backgrounds,
- fake medical charts,
- oversized doctor stock illustrations in operational screens,
- giant empty-state art that pushes the CTA below the fold,
- green = safe / red = danger without text,
- animated result reveals,
- "Everything looks great!" language for medical results,
- celebratory confetti after screening completion,
- rounded cards nested three levels deep.

---

# 44. Screen-Specific Visual Direction

## Home

Visual character:
- quiet overview,
- actionable,
- not executive-dashboard theatre.

Prefer:
- one page header,
- concise attention summary,
- recent patients,
- appointments/activity,
- a small useful action group.

## Patients

Visual character:
- searchable registry,
- high scan speed,
- strong identity alignment.

Prefer:
- rows,
- compact structured metadata,
- stable columns on desktop,
- direct open action.

## Patient Details

Visual character:
- patient context first,
- clinical chronology,
- clear screening state.

Prefer:
- identity header,
- risk/latest summary,
- history timeline/list,
- patient-specific actions.

## Appointments

Visual character:
- scheduling workspace,
- status clarity,
- date/time first.

Prefer:
- chronological grouping,
- readable status,
- clear reschedule/confirm/decline actions.

## Care Tools

Visual character:
- clinical tool index,
- operational status.

Prefer:
- restrained module surfaces,
- purpose + state,
- direct open action.

## Screening Result

Visual character:
- serious,
- evidence-oriented,
- calm.

Prefer:
- result + risk,
- source attribution,
- supporting confidence,
- recommendation,
- clinician action.

---

# 45. Visual QA Checklist for Dawa

Before declaring a Dawa screen complete, inspect the rendered UI.

## Brand

- Does it use Dawa tokens rather than arbitrary colors?
- Is DM Sans used consistently?
- Is the logo used correctly and sparingly?
- Does it look like Dawa rather than generic health SaaS?

## Hierarchy

- Can the clinician identify the primary task in 2–3 seconds?
- Is patient identity obvious in patient-linked flows?
- Is clinically important state stronger than decorative metadata?
- Are too many elements competing for attention?

## Cards

- Is every card actually needed?
- Could two cards become one structured section?
- Could a bordered row replace a card?
- Are nested cards appearing?

## Actions

- Is the primary action obvious?
- Are action labels specific?
- Are destructive/status-changing actions clear?
- Are there duplicate actions in multiple places?

## Clinical truth

- Is mock data clearly isolated?
- Is AI/device output labeled accurately?
- Is confidence being overemphasized?
- Are technical failures separate from clinical results?
- Is saved vs queued vs synced truthfully represented?

## Responsive

- 390 x 820 checked?
- 820 x 900 checked?
- 1200 x 900 checked?
- Does content recompose rather than only shrink?
- Are bottom actions above navigation and safe areas?

## Accessibility

- Touch targets at least ~48dp?
- Text scaling tested?
- Contrast acceptable?
- Statuses understandable without color?
- Icon-only actions labeled?
- Keyboard focus usable on web?

## State completeness

- Loading?
- Empty?
- Error?
- Offline?
- Device unavailable?
- Sync pending?
- Permission failure?
- Partial/mock data where applicable?

---

# 46. Agent Workflow for Dawa UI Tasks

When asked to create or modify Dawa UI, follow this sequence.

## Step 1 — Inspect

Read:
- the target screen,
- nearby components,
- `dawa_design_system.dart`,
- relevant domain/repository/service code,
- responsive tests,
- and existing navigation.

Do not design from the prompt alone if the repository is available.

## Step 2 — State the screen's job internally

Determine:
- primary user,
- primary task,
- required patient/context state,
- primary action,
- secondary action,
- important failure states.

## Step 3 — Reuse the product grammar

Use:
- existing tokens,
- existing typography,
- existing navigation,
- existing domain components where good.

Do not create a local micro-design-system inside one screen.

## Step 4 — Remove weak patterns

Actively look for:
- card walls,
- duplicate headers,
- excessive icons,
- meaningless badges,
- unnecessary modal flows,
- fake data,
- arbitrary spacing.

## Step 5 — Implement states

Implement the non-happy paths relevant to the feature.

## Step 6 — Render

Inspect representative mobile, tablet, and desktop sizes.

## Step 7 — Critique

Ask:
- Does this look like Dawa?
- Does this look like a real clinical product?
- Could this be mistaken for an AI-generated health dashboard?
- Is the actual clinical task obvious?
- Is anything visually claiming more certainty than the system knows?

## Step 8 — Refine

Remove or correct unnecessary visual elements.

## Step 9 — Regression check

Verify:
- navigation,
- patient context,
- data behavior,
- offline behavior where relevant,
- and existing tests.

---

# 47. Definition of Done — Dawa

A Dawa UI feature is complete only when:

## Product fit
- It supports a real clinician workflow.
- It uses Dawa terminology.
- It does not resemble a generic dashboard template.

## Brand
- Dawa color/token system is used.
- DM Sans hierarchy is coherent.
- Radius/border language is consistent.
- Logo and illustrations are restrained.

## Clinical trust
- Patient context is clear.
- AI/device source is clear.
- Mock data does not appear live.
- Risk is not communicated by color alone.
- Technical errors are not presented as clinical outcomes.
- Saved/synced state is truthful.

## Interaction
- Primary action is obvious.
- Buttons have clear labels.
- Loading is local where possible.
- Errors preserve work.
- Destructive actions are explicit.
- Motion is restrained.

## Responsive
- Phone tested.
- Tablet tested.
- Desktop/web tested.
- Navigation adapts correctly.
- Content recomposes appropriately.

## Accessibility
- 48dp interaction target where appropriate.
- text scaling works,
- contrast works,
- semantics are present,
- keyboard/focus behavior works on web.

## State completeness
- loading,
- empty,
- error,
- offline,
- sync/device states where relevant.

## Repository quality
- new values are tokenized,
- no unnecessary duplication,
- no raw backend errors shown,
- no new third patient-detail pattern,
- legacy changes are regression tested.

## Visual QA
- rendered screen reviewed,
- "Remove 30%" test applied,
- "Could this belong to any product?" test applied,
- no obvious AI-slop patterns remain.

---

# 48. Current Known Design/UX Debt

Agents should be aware of these existing areas and avoid compounding them:

1. Newer and legacy patient-detail flows coexist.
2. Some legacy FlutterFlow screens are very large and visually mixed.
3. Some Care Tool data is mock/local rather than persisted production data.
4. Full localization is not yet implemented.
5. Offline support is partial.
6. HemoNix and CT are not yet complete clinical workflows.
7. Ultrasound persistence/device integration is incomplete.
8. BP Monitor persistence/patient linking is incomplete.
9. Clinical translations and recommendation content require qualified review.
10. Visual consistency still needs testing on smaller Android devices and browser tablets.

When improving these areas, prefer convergence and simplification over introducing parallel patterns.

---

# 49. Future Product Profile Decisions

When the team formalizes them, add:

- exact spacing token source,
- final icon family,
- formal breakpoint constants,
- full localization strategy,
- approved clinical terminology dictionary,
- approved Dawa Mom ↔ Clinician shared component rules,
- dark mode policy if ever required,
- privacy/screenshot redaction standards,
- final offline sync-state vocabulary,
- hardware connection visual standard,
- role/permission-specific navigation,
- and clinically approved result/recommendation content templates.

Until those decisions exist, agents should not invent them as established product truth.
