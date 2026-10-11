# DAWA Mom launch progress

This document tracks implementation evidence. It does not imply that a local
database migration or Edge Function has been deployed.

## Batch A — Health Profile

- Completed locally on 2026-10-10.
- The fourth real profile step is period-date setup.
- Personal data now uses the existing unique `mothers.profile_id` key through
  a repository-owned upsert rather than a client-chosen maternal record ID.
- Pregnancy writes validate before calling the existing secure RPC, and both
  profile flows keep confirmed local data visible if a later refresh fails.
- The four visible states are reconciled from the returned write/snapshot;
  completed cards now show `Done` and `Edit`.
- No profile points were added: point amounts and eligibility need product
  approval and must be issued server-side.
- Local evidence: profile snapshot and save-reconciliation tests pass.
- Connected-backend evidence: **not completed**. The repository has no safe
  authenticated test account or controlled test mailbox. `TESTING.md` requires
  a separate account; no real patient record was accessed or changed.

## Batch B — Feedback and rewards presentation

- Profile saves use the existing preference-aware sound/haptic pathway only
  after a confirmed persistence response.
- Learning completions can still be saved locally for offline continuation, but
  Flutter no longer increments points optimistically. A balance becomes
  authoritative only after `complete_dawa_mom_learning_item` returns the
  server-owned ledger balance.
- Learning sound/haptic, point count-up, trophy/Champion presentation, and
  voucher-unlock feedback run only after a confirmed higher server balance or
  confirmed voucher claim. Existing preferences and reduced-motion controls
  remain the gate for those effects.
- Cached voucher strings are no longer treated as an active voucher; the wallet
  reads the owner-scoped server record.
- Existing reward values remain unchanged. The current programme remains the
  1,000-point clinic scan voucher. Profile points were not invented.
- Local evidence: learning, game, reward, profile, and feedback-focused tests
  pass. Remote ledger confirmation has not been exercised.

## Batch C — Voucher claiming and clinic redemption

- Prepared locally, not deployed:
  - `202610100002_secure_dawa_reward_vouchers.sql` adds claim identifiers,
    fallback references, claimed/redeemed/expired/cancelled state, expiry
    support, redemption audit events, transactional 1,000-point claim logic,
    and a service-role-only single-use redemption RPC.
  - the wallet supports a QR identifier plus a copyable fallback reference;
    neither is an authorisation credential.
  - `receive-dawa-clinician-voucher-redemption` accepts only the existing
    directional server secret and delegates to the service-only RPC.
- Dawa Clinician is a separate project. Its caller must authenticate staff,
  verify clinic authorization and patient identity, and send an idempotent
  `voucher.redeemed` callback. The exact contract and rollout sequence are in
  `supabase/functions/receive-dawa-clinician-voucher-redemption/README.md`.
- **Launch blocker:** no cross-project Clinician caller, migration, or live
  redemption reconciliation has been deployed or verified.

## Batch D — Notifications and email

- Completed locally: the header badge now uses server unread records, caps at
  `99+`, and does not show the former hard-coded unread dots.
- New realtime notification events refresh the count and use a debounced,
  preference-aware feedback cue. Historical page loads are silent.
- Existing appointment-email outbox and Resend worker are retained. Locally
  prepared appointment-confirmed, appointment-cancelled, and opt-in reminder
  jobs extend that worker without changing payment logic.
- Locally prepared `dawa_mom_email_outbox` and `process-dawa-mom-emails`
  provide private, idempotent welcome, reward-unlocked, and voucher-claimed
  delivery. Templates contain no diagnosis, period, pregnancy, or voucher code.
- No scheduler is created for reminders; a trusted server scheduler must be
  explicitly approved after Resend setup.
- No sender identity, API key, worker secret, Edge Function, migration, or
  patient email has been deployed or sent.

## Batch E — verification status

- Local checks (2026-10-11): `flutter analyze` and the release web build pass. Focused launch,
  learning/game/reward, profile, notification/header, Care/Home, and booking
  feedback tests pass. The prepared Edge Functions pass `deno check`.
  Deterministic 393px review captures are in
  `docs/launch-captures/`.
- Migration lint was attempted but is blocked locally because the Docker-hosted
  Supabase/Postgres stack is not running. No linked-project lint or remote
  migration operation was attempted.
- Responsive capture coverage is fixture-based. It does not prove a connected
  account, provider delivery, or an authenticated browser workflow.
- Remote persistence, all four Profile saves/reopen behavior, reward ledger
  confirmation, voucher redemption, Clinic staff authorization, Resend
  delivery, realtime notification delivery, and payment lifecycle remain
  unverified without safe staging credentials and explicit deployment approval.

## Final integration and deployment readiness — 2026-10-11

- Read-only inspection of the connected project's migration history confirms it
  ends at `202609240002`. The Care Plan/cancellation files (`20261009000x`) and
  the prepared paid-appointment, voucher, and email migrations
  (`202610100001`–`202610100003`) are not applied.
- This creates a release-order blocker: a normal `supabase db push` would try
  the unrelated Care Plan migrations before the approved payment/voucher/email
  work. No migration metadata repair, manual production SQL, or deployment was
  attempted. The deployment package requires a reviewed release branch that
  excludes Care Plan for this release.
- Read-only function inventory confirms the Lipila functions are active in the
  connected project. It does not prove the matching secure database RPCs are
  live; the payment lifecycle requires sandbox verification as a paired
  migration/function release.
- The available Dawa Clinician source has appointment sync but no voucher
  redemption endpoint, scanner/UI, reward data model, or cross-project tests.
  Its migration history is not sufficiently reproducible to implement clinic
  staff authorization safely without Clinician ownership and staging evidence.
- The voucher migration now fails closed on a server-only approved
  reward/clinic/service eligibility mapping. No eligibility rows are seeded:
  operations must configure verified Clinician identifiers before any voucher
  can be redeemed. This avoids inventing a generic scan service or clinic.
- `docs/DAWA_MOM_DEPLOYMENT_READINESS.md` contains the exact proposed Mom
  migration/function manifest, security review, dependency inventory,
  recovery plan, smoke checklist, and GO/NO-GO register.
- Profile end-to-end checks remain blocked: no authorized non-patient test
  account or controlled mailbox was available. No real patient record was
  accessed.
- The release plan is now split in
  `docs/DAWA_MOM_TWO_RELEASE_PLAN.md`: Release 1 is the Core DAWA Mom launch;
  Release 2 contains vouchers and Resend communications. Voucher redemption is
  default-off in the app (`DAWA_VOUCHER_REDEMPTION_ENABLED=false`) so points
  remain visible without advertising an unredeemable claim.

## Release 1 blocker closure audit — 2026-10-11

- Read-only linked-project inspection confirms that Flutter, the Supabase CLI,
  and `supabase/config.toml` all target `himbfndvsuwiudtzjojh`.
- `202609220001` is recorded remotely. A synthetic, unauthenticated,
  non-writing request with the full Flutter `book_dawa_mom_appointment`
  parameter set, including `p_payment_method`, resolved the live RPC and was
  denied with `42501`; it did not create an appointment. A zero-row schema
  read confirmed `appointments.payment_method` exists, while `payment_state`
  correctly returns `42703` because `202610100001` remains pending.
- `202610100001` is still not remote and depends on the earlier migration’s
  `payment_method` column. It adds the missing `payment_state` and idempotent
  payment-event contract, so active Lipila functions are not payment-readiness
  evidence by themselves.
- Docker’s daemon is unavailable and no isolated CI stack exists. Remote lint
  passed only for the already-live schema; isolated migration validation is
  still a Release 1 blocker.
- A direct learning reward-dialog path was also default-gated, so Release 1
  shows saved points without a voucher claim, QR, code, or redemption promise.
- The full review-only deployment checklist is
  `docs/DAWA_MOM_RELEASE_1_EXECUTION_CHECKLIST.md`. No production command,
  migration, Edge Function, payment, or patient-data action was taken.

## Release 1 isolated CI implementation — 2026-10-11

- Added `.github/workflows/release1-migration-validation.yml` and a local-only
  Supabase runner. It creates a temporary migration workspace through
  `202609240002`, seeds synthetic legacy paid appointment/payment rows, then
  incrementally applies only `202610090002` and `202610100001`; it rejects
  Care Plan/Release 2 files by construction. It uses no linked project,
  production credential, provider credential, or patient data.
- Added a synthetic SQL lifecycle suite for function signatures, grants/RLS,
  payment state constraints, booking idempotency, pending/processing/private
  paid reservations, success, duplicate callbacks, failed/cancelled/expired,
  late success reconciliation, cancellation sync, and free/pay-at-clinic
  compatibility.
- The suite uncovered a pre-deployment legacy-client gap: the ten-argument
  booking overload did not set the new paid online initial state. The unapplied
  `202610100001` migration now delegates that overload to the secure
  eleven-argument implementation with `online` explicitly selected.
- Published the protected Release 1 branch at
  `origin/release/1-core-backend` and ran the workflow in GitHub Actions.
  [Run 38134957088](https://github.com/Samuel04-png/dawa-mom/actions/runs/38134957088)
  passed on commit `b4e27fe`: both target migrations applied in a disposable
  local Supabase stack, local schema lint passed, and all synthetic lifecycle
  cases passed with no production credential or patient data.
- The run found and validated a pre-deployment payment-sync correction in the
  pending `202610100001`: `release_paid_appointment_workflow` now scopes its
  outbox insert to `mother.id = appointment_row.mother_id`, preventing duplicate
  Clinician appointment events when multiple mothers exist.
- `202609170001_recovered_remote_history.sql` still has no source schema
  changes. This is therefore a structural CI pass, not a
  production-equivalent representative baseline; a sanitized schema-only
  staging baseline remains required before cutover approval.
- Added `docs/DAWA_MOM_RELEASE_1_TEST_ACCESS_CHECKLIST.md` for the controlled
  profile, booking, cancellation, notification, Airtel/Lipila, and Clinician
  staging evidence required next.

## Defect register / launch decision

| Severity | Item | Current disposition | Evidence / next action |
| --- | --- | --- | --- |
| Critical | Secure voucher redemption not deployed or integrated with Dawa Clinician | Open | Deploy reviewed migration and receiver only after Clinician implements the authenticated callback; reconcile one test voucher. |
| Critical | Connected Profile Batch A test is missing | Open | Use a separately registered test account with a controlled mailbox; execute all four save/reopen/failed-save cases. |
| Critical | Resend sender, secrets, worker and end-to-end delivery are not verified | Open | Configure server-only secrets and a verified sender, then run idempotent test events without patient information. |
| High | Payment/booking lifecycle needs a fresh connected regression after the pending payment migration/function review | Open | Do not deploy or claim payment readiness until a sandbox Airtel flow has completed/cancelled/retried evidence. |
| Medium | Optional `care_plan_items` schema remains absent in the connected backend | Open but isolated | It must not block Home/Care/Cycle; deploy only its own approved migration. |
| Fixed locally | Client-side optimistic learning points and cached-voucher authority | Fixed locally | Focused tests prove no client balance increment and no cached active voucher. |
| Fixed locally | Header unread badge and incoming feedback were hard-coded/rebuild-prone | Fixed locally | Server unread count, realtime refresh, debounced preference-aware feedback. |

**GO / NO-GO: NO-GO.** Local implementation and static tests are green, but
critical connected-backend, Clinician, email, and payment verification gates
are open. No migration, Edge Function, email configuration, or payment change
was deployed by this work.
