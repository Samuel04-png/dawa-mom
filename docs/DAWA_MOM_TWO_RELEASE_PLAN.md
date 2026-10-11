# DAWA Mom two-release plan

Prepared 2026-10-11. This plan separates the launch-critical maternal-health
application from reward redemption and email infrastructure. It authorises no
production change. The connected project remains **NO-GO** until the Release 1
checklist is complete.

The current execution evidence, controlled-branch proposal, test-account
requirements, and recovery checklist are in
[`DAWA_MOM_RELEASE_1_EXECUTION_CHECKLIST.md`](DAWA_MOM_RELEASE_1_EXECUTION_CHECKLIST.md).

## Shared migration-history constraint

Read-only inspection shows the connected Dawa Mom project ends at
`202609240002`. The local migration directory then contains, in this order:

1. `202610090001_add_care_plan_items.sql` — unrelated Care Plan;
2. `202610090002_track_cancellation_sync_state.sql` — core appointment sync;
3. `202610100001_secure_paid_appointment_lifecycle.sql` — core payment safety;
4. `202610100002_secure_dawa_reward_vouchers.sql` — Release 2;
5. `202610100003_dawa_mom_transactional_email_events.sql` — Release 2.

Do **not** rename, mark applied, repair, manually apply, or selectively push
migration history to get around this ordering. A normal `supabase db push`
from the current checkout would include Care Plan before the core payment
migration. The safe release mechanics are therefore currently blocked pending
an approved migration-governance decision that preserves every migration and
truthful production history. Until then, validate only in isolated CI.

This is not a reason to ship Care Plan accidentally: its absence must remain
safe for Home, Care, Track, Profile, booking, and payment.

Read-only follow-up evidence also confirms that `202609220001` is recorded on
the connected project and its 11-parameter appointment RPC resolves the exact
Flutter payload including `p_payment_method`. That proves neither the pending
`202610100001` payment-state contract nor a successful booking; those still
require the isolated and authenticated evidence in the execution checklist.

## Release 1 — Core DAWA Mom

### Scope

- Authenticated Health Profile management and persisted pregnancy data.
- Cycle and pregnancy tracking, including existing clinical-calculation and
  period-tracker behaviour.
- Learning, locally resilient progress, and server-confirmed points.
- Verified clinic discovery and appointment booking.
- Secure Mobile Money lifecycle: requested, pending, successful, cancelled,
  failed, expired, and reconciliation-required states.
- Essential owner-scoped in-app notifications and appointment status updates.

### Explicit exclusions

- Care Plan tables, UI data, and clinician Care Plan delivery.
- Voucher issuance/redemption, QR use, and participating-clinic claims.
- Resend welcome/reward/voucher/appointment email delivery and reminder
  scheduling.
- Any new rewards policy or point amount.

### Required migration baseline already present remotely

These migrations supply the existing core contracts and are already listed as
applied by the connected project:

| Capability | Applied migrations |
| --- | --- |
| Auth, maternal identity, period tables | `202605040001`, `202607150002` |
| Appointments and health journey RPCs | `202607150001`, `202607150002`, `202607270002` |
| Pregnancy persistence | `202607210002` |
| Learning/progress/preferences | `202607230001`, `202607230002`, `202607280002` |
| In-app notification records/realtime policy | `202607270003` |
| Clinic service catalog and payment ledger | `202609150001`, `202609160002`, `202609160003`, `202609160004` |
| Payment-method separation | `202609220001` |
| Existing Dawa Clinician appointment/status integration | `202607170001`, `202607180001`, `202607270004`, `202609240001`, `202609240002` |

### New core migrations proposed, but not yet deployable

| Migration | Why Release 1 needs it | Care Plan dependency |
| --- | --- | --- |
| `202610090002_track_cancellation_sync_state.sql` | Marks a patient cancellation as queued until existing Clinician delivery completes. | None in SQL; blocked only by the preceding unreleased Care Plan migration. |
| `202610100001_secure_paid_appointment_lifecycle.sql` | Makes online payment a private reservation until verified provider success, records idempotent webhooks, and handles failed/cancelled/expired/late-success reconciliation. | None. |

The connected payment functions cannot be declared safe for Release 1 merely
because they are active: the remote migration history does not include
`202610100001`. Validate and deploy the payment migration/function bundle
together, or keep paid Mobile Money unavailable. Never enable a provider route
against an unverified database RPC contract.

### Required Mom Edge Functions

| Function | Role in Release 1 | Gate |
| --- | --- | --- |
| `clinician-directory` | Authenticated verified clinic/clinician discovery. | Directory/RLS smoke test. |
| `receive-service-catalog-sync` | Accepts server-to-server catalog updates. | Shared-secret and active-service test. |
| `lipila-create-payment` | Creates an owner-bound Mobile Money request without accepting a client amount. | Deploy only with `202610100001` and sandbox test. |
| `lipila-webhook` | Validates signed provider callbacks and drives server transition. | Deploy only with `202610100001`; replay and signature tests. |
| `lipila-payment-status` | Returns only the owner’s payment status. | Owner/RLS test. |
| `process-dawa-platform-outbox` | Delivers booked/cancelled appointment events to Clinician. Its Care Plan endpoint is optional and must not block appointment events. | Worker authentication and appointment delivery test. |
| `receive-dawa-clinician-appointment-status` | Applies protected Clinician status updates and creates in-app notifications. | Signed callback/status-transition test. |

No new Mom Edge Function is needed for profile, cycle, pregnancy, learning, or
in-app notification reads. Existing database RLS/RPCs are the contract for
those features.

### Release 1 feature controls

| Control | Release 1 value | Behaviour |
| --- | --- | --- |
| `DAWA_VOUCHER_REDEMPTION_ENABLED` build define | `false` (the code default) | Keeps points and learning visible, but hides voucher claim/use controls, QR, and “ready” marketing. |
| Voucher eligibility records | none | No clinic can redeem a voucher. |
| `receive-dawa-clinician-voucher-redemption` | not deployed | No Release 1 voucher path exists. |
| `process-dawa-mom-emails` and email scheduler | not deployed/not scheduled | No new Resend communications are sent. |
| Care Plan endpoint | unset | Existing outbox retries only Care Plan jobs; appointment delivery continues independently. |

The flag is deliberately build-time, not a client preference. Enabling it is a
Release 2 deployment decision after cross-project verification—not something a
patient can toggle.

### Release 1 GO/NO-GO checklist

| Gate | Required evidence | Current state |
| --- | --- | --- |
| Migration governance | Approved solution that preserves all migration history and does not push Care Plan; no `migration repair` or manual production SQL. | **NO-GO** |
| Isolated database | CI/disposable PostgreSQL baseline at `202609240002`; migration lint, grants/RLS review, repeatable recovery rehearsal. | **NO-GO** — local Docker/server unavailable. |
| Profile | New controlled patient account completes all four steps, pregnancy persists after restart, counter/Done/Edit states reconcile, failed writes never celebrate or award. | **NO-GO** — no controlled mailbox/account. |
| Booking | Verified directory, real availability, idempotent double-tap retry, cancellation delivery, pending vs confirmed distinction. | **NO-GO** — connected test required. |
| Airtel/Lipila | Sandbox-only success, pending, cancellation, failure, expiry, signed replay, bad amount/currency, lost response, and late-success reconciliation; normal and Rudo booking. | **NO-GO** — no sandbox evidence. |
| In-app notifications | Owner-only badge/read/realtime flow after appointment transitions; no Care Plan interruption. | **NO-GO** — connected test required. |
| Reward separation | Default-off voucher control verified in a Release 1 build; no claim, QR, “participating”, or “ready to use” copy. | **Local pass; connected build review required** |
| Rollback drill | Disable provider UI/endpoint and stop workers, preserve ledger/outbox evidence, roll forward only after provider reconciliation. | **NO-GO** |

**Release 1 decision today: NO-GO.** The core can be launched independently of
vouchers and Resend only after the first six gates are verified.

### Release 1 rollback

- Disable online-payment entry points through the server-owned active service
  configuration or take the payment routes out of the next app build; do not
  delete payment rows or infer charge outcome from a client.
- Stop the platform outbox worker if the Clinician endpoint is unhealthy;
  queued events and their idempotency keys remain for reconciliation.
- Keep `DAWA_VOUCHER_REDEMPTION_ENABLED=false`; points/learning remain intact.
- Use a reviewed forward-only corrective migration/function release. Do not
  drop ledger tables or edit Supabase migration history.

## Release 2 — Rewards and Communications

### Scope

- Server-authoritative 1,000-point clinic scan voucher claim lifecycle.
- Configured reward/clinic/service eligibility, QR/reference, and wallet
  states.
- Authenticated Dawa Clinician staff redemption and cross-project status
  consistency.
- Reward-related in-app notification refinements.
- Resend welcome, reward, voucher, appointment lifecycle, and approved
  reminder email workflows.

### Required migrations and functions

| Item | Purpose | Gate |
| --- | --- | --- |
| `202610100002_secure_dawa_reward_vouchers.sql` | Claim/redeem states, unique references, audit trail, service-only atomic redemption, fail-closed clinic/service eligibility. | Clinician implementation plus isolated DB tests. |
| `202610100003_dawa_mom_transactional_email_events.sql` | Private email outbox, idempotent jobs, approved appointment-event extensions. | Verified sender, consent decision, controlled-recipient test. |
| `receive-dawa-clinician-voucher-redemption` | Mom receiver for trusted Clinician redemption events. | Directional secret, eligibility records, bilateral test. |
| Clinician authenticated redemption endpoint/UI | Verifies staff session, active staff/clinic assignment, chosen clinic service, patient workflow, offline retry, then makes one server callback. | Must be implemented and tested in the Clinician project. |
| `process-dawa-mom-emails` | Claims and sends private Resend jobs. | Worker secret, sender verification, delivery/retry checks. |
| `process-appointment-emails` | Existing outbox worker extended for approved lifecycle templates. | Existing delivery infrastructure test and privacy review. |

### Release 2 feature controls

- Keep `DAWA_VOUCHER_REDEMPTION_ENABLED=false` until all voucher checks pass.
  Set it to `true` only in the reviewed Release 2 build after the Mom receiver,
  Clinician caller, and eligibility records are live.
- Keep `process-dawa-mom-emails` unscheduled until Resend sender, secrets,
  consent classification, test-recipient evidence, and retry monitoring are
  approved.
- Do not expose an existing historical claim as “ready to use” while the
  feature flag is off. The patient may keep points; no new claim is offered.

### Release 2 dependency plan

1. Obtain Clinician project ownership/staging access and a canonical
   staff-to-clinic-to-service authorization source. Its checked-in migration
   history is not sufficient proof today.
2. Configure actual approved `(reward_code, clinic_id, external_service_id)`
   rows server-side—do not seed generic clinic/service guesses.
3. In isolated environments test claim, duplicate claim, scan/replay,
   wrong staff/clinic/service, expired/cancelled voucher, offline retry, and
   wallet state on both applications.
4. Verify Resend domain/sender and legal/product basis for each email type.
   Test one controlled recipient per approved event and duplicate worker run.
5. Complete the Release 2 migration-governance and isolated validation gates,
   then enable the build flag in a separately approved patient release.

### Release 2 rollback

- Ship a build with voucher redemption flag false and disable the Clinician
  receiver/caller; do not remove issued voucher or audit evidence.
- Stop email workers/schedulers and retain queued jobs with safe delivery
  metadata for diagnosis.
- Repair with additive migrations/functions only. A redemption/payment/email
  state must never be erased to make a dashboard look successful.

## Smallest safe sequence to launch core

1. Keep the current application and Release 1 rewards gate in place; no
   voucher or Resend deployment work is on the core critical path.
2. Obtain a written migration-governance decision. The current chronology
   prevents a safe normal push of the required core payment migration without
   encountering Care Plan. Do not work around that mechanically.
3. Provision isolated CI with Docker/PostgreSQL and a sanitized baseline at
   `202609240002`. Execute the approved migration strategy, lint, RLS/grant
   audit, and restoration rehearsal.
4. Provision a controlled patient test account/mailbox and Airtel/Lipila
   sandbox account. Run Profile, booking, provider-state, Rudo, and in-app
   notification evidence matrices without real charges or patient data.
5. Review evidence, deployment manifest, secrets, worker configuration, and
   rollback owner; obtain explicit production approval.
6. Only then deploy the approved **Release 1** paired database/function bundle
   and run post-deployment smoke tests. Release 2 remains disabled.
