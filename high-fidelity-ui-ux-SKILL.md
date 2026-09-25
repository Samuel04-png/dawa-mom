---
name: high-fidelity-ui-ux
description: >
  Reusable UI/UX engineering guardrails for agents building production interfaces.
  Prevents generic AI-generated template aesthetics and enforces product-specific,
  coherent, accessible, responsive, high-fidelity design across web, mobile, and desktop.
---

# High-Fidelity UI/UX Engineering Skill

## 0. Mission

Build interfaces that feel intentionally designed for the product, user, platform, and task.

The goal is not to make screens "pretty." The goal is to make them:
- immediately understandable,
- visually coherent,
- trustworthy,
- efficient to use,
- responsive to real device constraints,
- accessible,
- resilient to real data,
- and recognizably specific to the product rather than a generic AI template.

Never optimize for visual novelty at the expense of usability. Never use decoration to hide weak hierarchy.

---

# 1. Operating Model: Understand Before You Design

Before changing or creating UI, inspect the product context.

## 1.1 Establish the product profile

Determine, from the repository, screenshots, requirements, existing product, or user brief:

- product category,
- primary users,
- primary user tasks,
- usage frequency,
- device/platform,
- expected information density,
- trust requirements,
- accessibility requirements,
- brand personality,
- current typography,
- current colors,
- current spacing/radius patterns,
- existing reusable components,
- navigation model,
- content tone,
- data states,
- and critical workflows.

Do not start by inventing a dashboard, card system, color palette, or component library.

## 1.2 Preserve coherent existing decisions

If the product already has a coherent visual language, extend it.

Do not:
- redesign unrelated screens because you personally prefer another style,
- replace working components with fashionable alternatives,
- introduce a new font for one page,
- create a second button language,
- or introduce a new radius/shadow system without a product-wide reason.

A redesign must solve an identified problem.

## 1.3 Infer before asking

When enough evidence exists in the current product, make a strong design decision from that evidence.

Ask for clarification only when a missing decision materially changes the product direction.

---

# 2. Product-Specific Design, Not Template Design

Every screen must answer four questions:

1. What is the user's primary task here?
2. What information must be understood before acting?
3. What is the most important action?
4. What can be visually quieter?

If those answers are unclear, the screen is not ready to implement.

A page should not exist simply because "SaaS apps usually have one."

---

# 3. AI-Aesthetic Ban List

The following patterns are forbidden by default unless the product, brand, or data genuinely requires them.

## 3.1 Generic visual clichés

Avoid:
- purple/blue neon gradients,
- glowing mesh backgrounds,
- blurred decorative blobs,
- glassmorphism used as a general surface language,
- gradient text,
- gradient buttons,
- floating AI orbs,
- sparkles used to represent intelligence,
- robot/neural-network illustrations,
- decorative magic-wand actions,
- fake browser-window hero graphics,
- giant abstract 3D objects with no product meaning,
- excessive emoji as product iconography,
- and decorative noise added to make an otherwise empty screen feel "designed."

## 3.2 Generic SaaS composition

Do not automatically build:

`Page title → four KPI cards → large white card → chart → table → CTA card`

Do not turn every content group into a rounded rectangle.

Prefer:
- hierarchy,
- alignment,
- whitespace,
- typography,
- rules/dividers,
- grouped rows,
- direct manipulation,
- and domain-appropriate layouts.

A container must have a functional reason to exist.

## 3.3 Card-wall prohibition

Cards are appropriate when content is:
- independently actionable,
- independently scannable,
- movable/reorderable,
- visually distinct by meaning,
- or requires a bounded interactive surface.

Cards are not appropriate simply because two pieces of content need spacing between them.

## 3.4 Radius abuse

Do not use very large corner radii globally.

Use radius to communicate a coherent surface language.

A product should normally have a small, intentional radius scale instead of arbitrary values on every component.

## 3.5 Shadow abuse

Avoid:
- large ambient shadows,
- colored shadows,
- stacked shadows,
- shadows on every card,
- and shadows used as a substitute for layout hierarchy.

Prefer borders, spacing, background contrast, and elevation only where overlapping layers genuinely exist.

## 3.6 Icon confetti

Do not place icons:
- beside every heading,
- inside every KPI,
- on every navigation item,
- inside every empty state,
- or beside text that is already self-explanatory.

Icons must improve recognition, orientation, or action comprehension.

Use one coherent icon family or a deliberate custom set. Match stroke weight, optical size, and alignment.

## 3.7 Status-pill explosion

Do not create a rainbow of colored pills for every system state.

Use:
- semantic text,
- small state markers,
- restrained backgrounds,
- weight,
- borders,
- inline labels,
- or structured columns.

Reserve pills/chips for cases where the compact bounded shape improves scanning or interaction.

## 3.8 Animation as decoration

Do not use:
- bouncing icons,
- floating cards,
- looping decorative motion,
- automatic carousel movement,
- ornamental springs,
- or continuous shimmer outside loading skeletons.

Motion must explain:
- causality,
- hierarchy,
- state change,
- spatial relationship,
- progress,
- completion,
- or error recovery.

## 3.9 Generic marketing copy

Avoid synthetic filler such as:
- "Elevate your experience,"
- "Unlock the power of...",
- "Seamlessly transform...",
- "Empower your journey,"
- "Revolutionize the way you...",
- or unexplained "AI-powered" claims.

Prefer concrete product value and task-focused language.

---

# 4. Visual Identity Rules

## 4.1 A product needs a recognizable design grammar

Define or infer:
- typography roles,
- surface hierarchy,
- spacing rhythm,
- radius scale,
- border language,
- icon language,
- color semantics,
- control sizing,
- content density,
- and motion behavior.

Do not style each screen independently.

## 4.2 Design tokens are the source of truth

Centralize:
- colors,
- typography,
- spacing,
- radii,
- shadows,
- breakpoints,
- control heights,
- animation durations,
- and z-index/elevation layers.

Avoid arbitrary one-off values unless required by geometry.

## 4.3 Limit visual vocabulary

A strong UI uses fewer visual ideas more consistently.

Before adding a new:
- color,
- type size,
- radius,
- shadow,
- icon style,
- border style,
- or component variant,

check whether an existing token can communicate the same meaning.

---

# 5. Layout & Hierarchy

## 5.1 Hierarchy before decoration

The user should understand the page structure even if:
- shadows are removed,
- icons are removed,
- color saturation is reduced,
- and cards are flattened.

Use:
- scale,
- weight,
- spacing,
- grouping,
- alignment,
- contrast,
- and position.

## 5.2 Use a consistent grid

Align:
- titles,
- controls,
- lists,
- tables,
- cards,
- form labels,
- and section boundaries

to a deliberate grid.

Avoid near-alignments that differ by a few pixels without reason.

## 5.3 Spacing must form a rhythm

Use a small spacing scale.

Do not scatter unrelated values like:
`13, 17, 21, 26, 31px`

unless geometry specifically requires them.

Use larger spacing to separate concepts and smaller spacing to connect related items.

## 5.4 Density is contextual

Do not assume more whitespace is always better.

- Consumer/wellness products may need calm spacing.
- Finance/admin/operations products may require higher information density.
- Mobile task flows may need large targets but compact vertical hierarchy.
- Desktop tools may benefit from tighter rows and persistent controls.

Match density to task frequency and cognitive load.

## 5.5 Avoid giant headings by default

Do not use oversized marketing-style typography inside application workflows.

A heading should dominate only when its informational role warrants dominance.

---

# 6. Typography

## 6.1 Typography must have assigned roles

Define roles such as:
- display,
- page title,
- section title,
- body,
- secondary body,
- label,
- helper text,
- data value,
- caption,
- and mono/data text where relevant.

Do not create a new font size for every local situation.

## 6.2 Font selection must be intentional

Do not automatically choose Inter, Roboto, Poppins, or Space Grotesk simply because they are common.

First inspect:
- the current brand,
- product category,
- platform conventions,
- language support,
- readability requirements,
- and performance constraints.

Use a maximum of:
- two primary type families,
- plus an optional monospace family where data/code requires it.

## 6.3 Typography must survive real content

Test:
- long names,
- long translations,
- multi-line labels,
- large accessibility text,
- large numeric values,
- negative values,
- dates,
- currencies,
- and missing data.

Never shrink important text to unreadable sizes just to preserve a layout.

---

# 7. Color

## 7.1 Color has a job

Use color primarily for:
- brand identity,
- hierarchy,
- semantic state,
- selection,
- focus,
- data encoding,
- and action priority.

Do not use color merely to make every section visually different.

## 7.2 Semantic colors must remain semantic

Success, warning, error, information, and neutral states should be consistent across the product.

Do not use the same red for both:
- destructive actions,
- decorative branding,
- and ordinary metadata

unless the system intentionally supports that meaning.

## 7.3 Contrast must be verified

Do not rely on "looks readable."

Check text, controls, disabled states, placeholders, focus rings, charts, and status indicators against accessibility contrast requirements.

## 7.4 Dark mode is not color inversion

If dark mode exists, deliberately tune:
- surfaces,
- borders,
- shadows,
- semantic colors,
- illustrations,
- focus states,
- charts,
- and disabled states.

---

# 8. Components

## 8.1 Components should model product behavior

Prefer domain components such as:
- `LoanRepaymentRow`,
- `PregnancyWeekCard`,
- `AppointmentSlot`,
- `InventoryVariantSelector`,
- `AuditEvent`

over meaningless structural abstractions like:
- `PrettyCard`,
- `FancyBox`,
- `InfoContainer`.

## 8.2 Do not componentize every wrapper

Create reusable components where there is:
- repeated visual behavior,
- repeated interaction,
- domain meaning,
- or maintenance value.

Avoid abstractions that make simple layouts harder to understand.

## 8.3 Button hierarchy must be obvious

A screen should not contain five controls that all look primary.

Define:
- primary,
- secondary,
- tertiary,
- destructive,
- icon-only,
- and link actions

with consistent sizing and interaction states.

Labels should describe the action:
- "Book appointment"
- "Save changes"
- "Add repayment"

instead of vague labels such as:
- "Continue"
- "Proceed"
- "Submit"

when a more specific label is possible.

## 8.4 Disabled is not hidden

When an action is currently unavailable but relevant to the workflow, prefer a properly disabled state with an explanation when useful.

Do not make important controls disappear unpredictably.

---

# 9. Navigation & Information Architecture

Navigation must reflect the user's mental model, not the database schema.

## 9.1 Navigation rules

- Keep primary destinations stable.
- Do not move core actions between screens without a reason.
- Do not create duplicate routes to the same task unless one is a deliberate shortcut.
- Use labels users understand.
- Keep current location obvious.
- Preserve back-navigation expectations.
- Avoid deep nesting for common tasks.

## 9.2 Mobile navigation

Use bottom navigation only for true top-level destinations.

Do not place:
- one-off actions,
- temporary workflows,
- or context-specific commands

inside primary navigation.

## 9.3 Desktop navigation

Persistent sidebars are appropriate for high-frequency multi-section tools, but should not become dumping grounds for every feature.

Group by user task, not implementation module.

---

# 10. Forms & Data Entry

Forms are workflows, not collections of input boxes.

## 10.1 Form structure

- Group related fields.
- Use progressive disclosure when later inputs depend on earlier choices.
- Keep labels persistent.
- Provide examples only where ambiguity exists.
- Use correct input types.
- Preserve entered data during recoverable errors.
- Avoid resetting the form after validation failure.
- Put validation close to the field and explain how to fix the issue.

## 10.2 Do not overuse placeholders

Placeholder text is not a replacement for labels.

It disappears when users type and often fails accessibility expectations.

## 10.3 Destructive actions

Use confirmation only when the action:
- has significant consequences,
- is difficult to reverse,
- or could plausibly be triggered accidentally.

Do not add confirmation modals to harmless routine actions.

Prefer undo where appropriate.

## 10.4 Long forms

For complex workflows:
- divide into meaningful sections or steps,
- show progress where it genuinely helps,
- preserve state,
- and let users safely return.

Do not create a multi-step wizard simply to make a short form look sophisticated.

---

# 11. Data-Dense Interfaces

Tables, ledgers, admin tools, analytics, and operational software require different UX than marketing pages.

## 11.1 Tables

Do not convert every table into cards on mobile.

Instead decide, per domain:
- which columns are essential,
- which can collapse,
- which can move into a detail row,
- whether horizontal scrolling is acceptable,
- and whether a separate mobile detail screen is better.

## 11.2 Numeric information

- Align comparable numeric values consistently.
- Use locale-aware formatting.
- Keep source numeric values unformatted in application state.
- Do not fabricate trends or percentage changes.
- Clarify units and comparison periods.
- Use monospace/tabular numerals where it materially improves scanning.

## 11.3 Charts

Only add a chart if the visual encoding helps answer a real question.

Do not add charts to make a dashboard look complete.

Every chart should have:
- a clear question,
- readable units,
- a meaningful time range,
- accessible labels,
- and a non-visual fallback where necessary.

---

# 12. Responsive & Adaptive Design

Responsive design is not "desktop but narrower."

## 12.1 Recompose, do not merely shrink

At each major width, reconsider:
- navigation,
- information priority,
- control grouping,
- table behavior,
- modal behavior,
- content order,
- and touch ergonomics.

## 12.2 No global overflow hacks

Do not use global `overflow-hidden` or fixed viewport heights to conceal layout problems.

Allow native scrolling and design around real content height.

## 12.3 Test realistic widths

At minimum, verify:
- small phone,
- large phone,
- tablet where relevant,
- laptop,
- and wide desktop where relevant.

Do not test only one 1440px desktop screenshot.

---

# 13. Interaction & Motion

## 13.1 Feedback is mandatory; animation is optional

Every interaction should clearly communicate:
- hover/focus where relevant,
- pressed state,
- loading state,
- success or completion,
- errors,
- and disabled state.

This does not mean every interaction needs movement.

## 13.2 Motion timing

Use short, crisp transitions for direct manipulation.

Typical UI transitions often fall roughly in the 120–280ms range, but timing must follow:
- distance,
- complexity,
- platform convention,
- and user expectation.

Do not enforce one duration globally.

## 13.3 Haptics

Use haptics selectively for:
- meaningful confirmations,
- mode changes,
- destructive confirmations,
- important toggles,
- and tactile selection when appropriate.

Do not trigger haptics on every tap.

## 13.4 Reduced motion

Respect system reduced-motion preferences.

The interface must remain understandable without animation.

---

# 14. Loading, Empty, Error & Offline States

A screen is incomplete until its non-happy-path states are designed.

For every data-driven view, consider:

- initial loading,
- background refresh,
- empty state,
- partial data,
- error,
- permission failure,
- offline,
- stale data,
- success,
- and retry.

## 14.1 Loading

Prefer:
- skeletons when layout is known,
- inline progress for local actions,
- button-level loading for button-triggered work,
- and background refresh indicators for existing content.

Avoid blocking the whole screen for a small local update.

## 14.2 Empty states

An empty state should explain:
- what is empty,
- why that matters,
- and the next useful action.

Do not write only:
"No data found."

Where structure matters, preserve table headers, timelines, or navigation so users can still understand the workspace.

## 14.3 Errors

Errors must:
- explain what failed in user terms,
- preserve recoverable work,
- provide a next action,
- and avoid exposing raw backend/database messages.

Critical errors must not rely solely on dismissible toast notifications.

## 14.4 Offline

Where the product may operate under unreliable connectivity:
- make connection state clear,
- distinguish saved vs pending data,
- avoid pretending an action succeeded before persistence is confirmed,
- and define retry/sync behavior.

---

# 15. Accessibility

Accessibility is part of component correctness.

## 15.1 Touch targets

Interactive targets should generally meet platform accessibility guidance:
- approximately 44pt minimum on Apple platforms,
- approximately 48dp minimum on Material/Android-style interfaces,

unless a denser control has an expanded invisible hit area.

## 15.2 Keyboard & focus

Web and desktop interfaces must support:
- keyboard navigation,
- visible focus,
- logical tab order,
- escape behavior where relevant,
- and accessible control names.

## 15.3 Text scaling

Layouts must survive increased text size without:
- clipping,
- overlapping,
- hidden actions,
- or unreadable truncation.

## 15.4 Do not encode meaning using color alone

Use text, iconography, shape, position, or labels as additional signals.

## 15.5 Semantic structure

Use platform semantics:
- semantic HTML on web,
- accessible labels and roles,
- native control behavior where practical,
- and meaningful reading order.

---

# 16. Platform-Native Behavior

Do not make every platform behave like a custom web demo.

## 16.1 Web

Prefer:
- semantic HTML,
- native scrolling,
- browser history,
- selectable text,
- expected keyboard behavior,
- accessible focus,
- responsive layout,
- and real URLs for navigable states.

## 16.2 Flutter / mobile

Account for:
- `SafeArea`,
- keyboard insets,
- system back navigation,
- text scaling,
- touch targets,
- scroll position,
- state restoration/preservation where useful,
- app lifecycle changes,
- offline transitions,
- and platform-appropriate haptics.

Use animation widgets deliberately; do not wrap the entire app in animation for novelty.

## 16.3 Desktop productivity tools

Consider:
- higher information density,
- keyboard shortcuts,
- resizable panes,
- persistent context,
- multi-selection,
- hover affordances,
- and bulk actions.

---

# 17. Content Design

Interface copy is part of UX.

Use:
- short labels,
- concrete verbs,
- familiar nouns,
- direct error explanations,
- and user-language instead of internal system language.

Do not expose:
- database field names,
- engineering terminology,
- internal workflow codes,
- or implementation details

unless the product is explicitly built for technical users.

Avoid overly cheerful copy in high-stakes contexts such as:
- finance,
- healthcare,
- security,
- legal,
- or failure states.

Tone must match the consequence of the action.

---

# 18. Trust & High-Stakes Products

For healthcare, finance, security, identity, payments, and other high-trust products:

- prioritize clarity over novelty,
- show important consequences before commitment,
- distinguish draft/pending/completed states,
- make irreversible actions explicit,
- preserve auditability,
- avoid fake metrics or social proof,
- avoid hiding critical information behind animation,
- and never use visual polish to imply certainty the system does not have.

The interface must accurately reflect system state.

---

# 19. Implementation Discipline

## 19.1 UI must connect to real domain state

Do not build visually complete screens around invented values that later require architectural rewrites.

Use fixtures only when explicitly scoped as development/demo data.

## 19.2 Separate presentation from data access

Presentation components should consume stable domain models or view models.

Avoid deeply embedding:
- database queries,
- API calls,
- business rules,
- or financial calculations

inside visual components.

## 19.3 Avoid UI-generated business truth

The frontend may display and request changes.

Authoritative business state must live in the appropriate domain/service/backend layer.

## 19.4 Reuse before duplication

Before creating a component, search for an existing:
- primitive,
- pattern,
- token,
- field,
- button,
- dialog,
- list row,
- table treatment,
- or state component.

Extend intentionally instead of creating near-duplicates.

---

# 20. Visual QA Loop

An agent must not declare UI complete immediately after code compiles.

For every important screen:

1. Run/render the screen.
2. Inspect it at representative viewport sizes.
3. Compare it against the design intent and existing product language.
4. Identify visual inconsistencies.
5. Fix them.
6. Re-render.
7. Repeat until the screen is coherent.

## 20.1 Inspect specifically for

- incorrect spacing,
- text clipping,
- misaligned baselines,
- inconsistent control heights,
- accidental font changes,
- arbitrary radii,
- excessive borders,
- excessive cards,
- poor contrast,
- dense/empty imbalance,
- broken mobile composition,
- awkward empty states,
- missing loading feedback,
- inconsistent icon sizing,
- hover/focus omissions,
- and controls that look interactive but are not.

## 20.2 Use screenshot review

When tooling permits, review screenshots rather than trusting source code alone.

Code can be valid while the rendered UI is visually poor.

---

# 21. The "Remove 30%" Test

Before finalizing a page, inspect every:
- card,
- icon,
- border,
- label,
- helper line,
- button,
- illustration,
- badge,
- and decorative effect.

Ask:

"If I remove this, does usability or comprehension materially get worse?"

If not, remove it.

High-quality interfaces often improve through subtraction.

---

# 22. The "Could This Belong to Any Product?" Test

If a screen could be dropped unchanged into:
- a finance app,
- a health app,
- a CRM,
- an ecommerce dashboard,
- or an AI tool,

then it probably lacks product-specific design.

Add specificity through:
- information architecture,
- terminology,
- workflows,
- data representation,
- action placement,
- domain components,
- and brand language,

not through decorative graphics.

---

# 23. Reference Use

When visual direction is unclear, study mature products in the same problem category.

Extract:
- hierarchy,
- density,
- interaction patterns,
- navigation logic,
- information grouping,
- and state handling.

Do not clone another product pixel-for-pixel.

Combine references with the current product's users, brand, and workflows.

---

# 24. Project UI Profile

Each project should optionally define a companion `PROJECT_UI_PROFILE.md`.

Recommended fields:

```md
# Project UI Profile

Product:
Platform:
Primary users:
Primary tasks:
Usage environment:
Trust level:
Density:
Brand personality:

Typography:
Primary font:
Secondary font:
Mono font:

Color:
Brand colors:
Semantic colors:
Surface strategy:

Geometry:
Spacing scale:
Radius scale:
Border strategy:
Shadow strategy:

Navigation:
Primary navigation:
Secondary navigation:
Mobile navigation:

Interaction:
Motion character:
Haptics:
Reduced motion behavior:

Accessibility:
Touch target standard:
Text scaling requirements:
Keyboard requirements:

Product-specific forbidden patterns:
Product-specific required patterns:

Reference products:
1.
2.
3.
```

Project-specific rules may specialize this skill, but should not silently override core accessibility, clarity, or state-completeness requirements.

---

# 25. Framework Adapters

The reusable skill should remain framework-agnostic.

Project agents may add adapter sections/files such as:

- `adapters/flutter.md`
- `adapters/react-next.md`
- `adapters/react-native.md`
- `adapters/desktop.md`

Adapters should specify implementation mechanics only.

Example:

### Flutter adapter
- Theme extensions/tokens
- `SafeArea`
- `MediaQuery.textScaler`
- focus handling
- keyboard insets
- state restoration
- semantics
- platform haptics
- `AnimatedSwitcher` / transitions where appropriate

### React / Next.js adapter
- semantic HTML
- server/client component boundaries
- accessible primitives
- responsive CSS strategy
- focus management
- URL-backed state
- form semantics
- native scrolling

Do not place framework-specific implementation rules in the universal design layer unless they represent a cross-platform UX principle.

---

# 26. Definition of Done

A screen or feature is not complete until all relevant checks pass.

## Product fit
- The layout reflects the actual product domain.
- The primary task is visually obvious.
- The design extends the existing visual language or intentionally defines one.

## Visual coherence
- Typography follows defined roles.
- Spacing follows a system.
- Radii are consistent.
- Icons share one visual language.
- Colors have deliberate meaning.
- Decorative elements are justified.

## Interaction
- Hover/pressed/focus states exist where relevant.
- Loading behavior exists.
- Errors are recoverable.
- Destructive actions are clear.
- Motion communicates something useful.

## Content
- Labels are specific.
- Copy is concise.
- No generic AI/SaaS filler.
- No raw implementation language leaks into customer UI.

## Responsive behavior
- Small and large viewports were tested.
- Content recomposes instead of merely shrinking.
- No clipped actions or broken scrolling.
- Tables use domain-specific mobile behavior.

## Accessibility
- Touch targets are sufficient.
- Keyboard/focus behavior works where relevant.
- Text scaling does not destroy the layout.
- Color is not the sole carrier of meaning.
- Semantics/labels are present.

## State completeness
- Loading state exists.
- Empty state exists.
- Error state exists.
- Disabled state is understandable.
- Offline/pending state exists where relevant.

## Technical quality
- UI components are not authoritative for business logic.
- No unnecessary duplicated components.
- No fake production data.
- No brittle overflow hacks.
- No hidden debug/developer tools in customer UI.

## Visual QA
- The rendered result was inspected.
- Obvious template patterns were removed.
- The "Remove 30%" test was applied.
- The "Could This Belong to Any Product?" test was applied.

Only then may the agent consider the UI complete.
