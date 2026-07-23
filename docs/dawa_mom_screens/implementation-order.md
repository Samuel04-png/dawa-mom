# Dawa Mom redesign implementation order

```mermaid
timeline
    title Dawa Mom screens implemented and verified
    Discovery and mapping
        : Catalogued all 31 references and 174 supplied images
        : Inspected navigation, auth, repositories, Supabase, assets, and tests
        : Wrote the screen map and per-screen plan
    Shared foundations
        : Added light-theme tokens, page scaffold, cards, status, buttons, and artwork registry
        : Added five-destination responsive navigation
        : Preserved the stateful Rudo surface
    Entry and onboarding
        : Implemented welcome, registration, login, recovery, and three onboarding states
        : Preserved real email and phone authentication
    Core health surfaces
        : Implemented the real-data home dashboard
        : Implemented cycle calendar, pregnancy mode, history, and daily check-in
        : Verified period-entry persistence
    Care journey
        : Implemented Care using real appointments, clinicians, and clinics
        : Implemented appointment detail presentation, booking success, and reminders
        : Preserved booking, cancellation, results, and durable integration outboxes
    Learn and profile
        : Implemented Learn, articles, quests, checkpoints, audio, guides, and library
        : Implemented profile, language, notifications, preferences, and rewards
        : Added local-first state with owner-scoped remote sync
    Backend hardening
        : Added additive RLS-protected tables
        : Added idempotent server-side learning awards and reward redemption RPCs
        : Added appointment reminder and notification-read persistence
    Verification
        : Captured six 390 px visual baselines
        : Exercised 390, 768, 1024, 1366, and 1440 px layouts
        : Passed analyzer, 72 Flutter tests, web release build, and Android debug build
```
