# Current UI and Workflows

## Responsive shell

Dawa Mom uses a bottom-navigation experience on phones and a bounded, wider shell for tablet/desktop layouts. Dashboard cards, appointment content and Rudo use responsive containers instead of stretching across the browser. Mouse and touch scrolling are supported.

## Branding and theme

- The application is light-mode only. System/dark preference persistence and user-facing dark-mode controls were removed.
- `assets/dawa_intro.gif` is a transparent animated splash rendered with `BoxFit.contain` on Dawa Mom blue (`#1945CD`).
- Web and Android startup surfaces use the same brand blue before the light app surface appears.
- Verified foreground illustrations use the transparent assets directory, while true backgrounds and unmatched illustrations remain unchanged.

## Profile and Settings

Profile completion distinguishes personal/contact, pregnancy and Period Tracker information. It also shows clinic-connection retry state without exposing internal error payloads.

Settings includes account/profile editing, health profile, Period Tracker setup, password change, tour replay, logout and guarded permanent deletion. The responsive page is tested at phone, tablet and desktop widths. Its cards use Material surfaces so list interactions and ink effects render correctly.

## Period and pregnancy experiences

Period setup can be completed or intentionally skipped during onboarding and revisited later. Cycle summaries distinguish unconfigured data from recorded settings. Pregnancy content distinguishes pregnant, not-pregnant and not-provided states, and the “What to expect” view uses the shared calculated pregnancy overview when dates are available.

## Rudo

Rudo launches from the responsive shell and uses bounded chat panels at phone, tablet and desktop sizes. Conversation state is preserved while the shell layout changes. Rudo history and preferences remain Dawa Mom-owned and are never synchronised to Dawa Clinician.

## Appointments

Appointment booking uses the real Clinician directory, mapped clinics, live slot availability and the dedicated `appointments` table. The list and detail pages refresh through Realtime and show patient-safe pending, retry and clinician-returned status messages. Clinical encounter results remain separate clinician-owned records.
