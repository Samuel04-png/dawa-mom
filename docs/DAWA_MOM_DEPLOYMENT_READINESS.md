# DAWA Mom deployment-readiness package

Prepared on 2026-10-11. This is an approval package, not a deployment runbook
that authorises production changes. No migration, Edge Function, payment
configuration, email configuration, or customer data was changed while
preparing it.

## Decision

**NO-GO.** The local implementation is ready for an isolated staging
validation, but there are unresolved production dependencies: a controlled
test account, an executable Clinician redemption path, an isolated PostgreSQL
migration run, verified Resend sender/consent, and Airtel/Lipila sandbox
callbacks.

The approved scope split is documented in
`docs/DAWA_MOM_TWO_RELEASE_PLAN.md`. Release 1 keeps voucher redemption
default-off; Release 2 owns voucher and Resend dependencies.

## Evidence collected

- Read-only `supabase migration list --linked` confirms the connected Mom
  project is at `202609240002`. It has **not** applied
  `202610090001`, `202610090002`, or any `20261010000x` migration.
- Read-only `supabase functions list` confirms the three Lipila functions are
  currently active, but this does not prove that their required database RPCs
  exist or that the deployed sources match this checkout.
- The deployed migration history therefore cannot establish that the current
  Lipila functions and the local secure lifecycle migration are compatible.
  Treat this as a release blocker until it is demonstrated in sandbox.
- The Dawa Clinician source is available at
  `/Users/premierpluspawn/Documents/Dawa_work/dawa_clinician-ui-brand-blue-refresh`.
  It has established authenticated appointment-sync patterns, but no voucher,
  reward, redemption endpoint, scanner, or redemption tests. Its checked-in
  migration folder also contains two one-line placeholders rather than a
  complete reproducible schema history. It is not safe to infer clinic-staff
  authorization from that repository alone.
- `flutter analyze`, the focused launch test suite, release web build, and
  `deno check` for the prepared Mom functions passed locally. These are not a
  substitute for connected-system verification.

## Exact Mom release contents

The following are the only new Mom database changes proposed for this release:

| Order | Migration | Purpose | Preconditions |
| --- | --- | --- | --- |
| 1 | `202610100001_secure_paid_appointment_lifecycle.sql` | Server-owned paid appointment state, idempotent provider events, and release only after verified success. | Baseline through `202609240002`; isolated migration and Lipila sandbox validation. |
| 2 | `202610100002_secure_dawa_reward_vouchers.sql` | Owner-scoped voucher claims, claim references, expiry/cancellation, audit events, and service-only atomic redemption. | Migration 1 validated; Clinician counterpart ready before redemption is enabled. |
| 3 | `202610100003_dawa_mom_transactional_email_events.sql` | Private idempotent welcome/reward/voucher email outbox and appointment lifecycle queue extensions. | Migration 2, a verified Resend sender, email-policy approval, and worker secrets. |

`202610090001_add_care_plan_items.sql` and
`202610090002_track_cancellation_sync_state.sql` are intentionally **not** in
this release. Care Plan remains optional and must not be deployed merely to
unblock this release.

### Migration-history gate

Supabase pushes migrations in chronological order. Because the connected
project lacks the two `20261009000x` files, running `supabase db push` from
this checkout would attempt them before the proposed release migrations. Do
not bypass them with a metadata repair or manual production SQL.

Before deployment, create a reviewed release branch containing the three
approved `20261010000x` files and excluding the unrelated pending Care Plan
migrations. Validate that branch against an isolated database whose migration
history ends at `202609240002`. This preserves a truthful history and lets the
Care Plan be reviewed as its own later release.

### Edge Functions proposed after the matching migration succeeds

| Function | JWT setting | Deployment condition |
| --- | --- | --- |
| `lipila-create-payment` | required | Deploy with migration 1 only after a non-charging provider sandbox run. |
| `lipila-webhook` | disabled; signature checked internally | Deploy with migration 1 after signed sandbox callback tests. |
| `lipila-payment-status` | required | Deploy with migration 1 after owner/status tests. |
| `receive-dawa-clinician-voucher-redemption` | disabled; shared-secret checked internally | Deploy only after the Clinician authenticated caller passes contract tests. |
| `process-dawa-mom-emails` | disabled; worker secret checked internally | Deploy after migration 3, Resend sender verification, and email-policy approval. |
| `process-appointment-emails` | disabled; worker secret checked internally | Redeploy after migration 3 and test its existing appointment pipeline. |

No scheduler is proposed in this release. In particular, appointment reminders
remain disabled until a trusted scheduler, opt-in rule, and test evidence are
separately approved.

## Dependency inventory

| Dependency | Current state | Release gate |
| --- | --- | --- |
| Dawa Mom Supabase (`himbfndvsuwiudtzjojh`) | Read-only migration/function inventory completed. | Isolated migration validation and explicit production approval. |
| Dawa Clinician (`eatliepvwrviogsnqavu`) | Appointment integration exists; voucher redemption is absent. | Authenticated clinician caller, verified clinic/service mapping, and bilateral test. |
| Airtel/Lipila | Local lifecycle code is prepared; no sandbox credentials/callback evidence. | Non-charging sandbox success, pending, cancellation, failure, expiry, replay, and late-success tests. |
| Resend | Workers and outboxes are prepared locally; no verified sender or secrets. | Verified sender, approved consent basis, controlled-recipient delivery and retry test. |
| Trusted scheduler/job runner | No new scheduler enabled. | Separate operating/monitoring approval, initially only for worker invocation. |
| Care Plan | Remote schema remains absent and is intentionally excluded. | Separate approved release; it must remain optional. |

## Security and RLS review

### Payments

- The booking RPC snapshots the selected server-side service price and payment
  requirement. The client does not submit an amount.
- `create_lipila_payment` requires an authenticated appointment owner,
  normalizes the phone number, rejects completed/cancelled/non-online visits,
  and keeps one active payment per appointment.
- The webhook verifies its signed raw payload and delegates state transitions
  to a service-role-only, idempotent database RPC. Terminal failure/cancelled/
  expired states cannot silently become success; a late success is placed in
  `reconciliation_required`.
- The Rudo booking path uses the same server booking and service-catalog rules;
  it must be exercised in the same sandbox matrix as the normal booking UI.

### Vouchers

- The wallet reads only the current owner’s redemption row. Flutter has no
  direct redeem permission and the QR/reference is an identifier, not an
  authorisation credential.
- The proposed redemption RPC is service-role-only, locks the claim, records
  a unique external event, verifies claimed/not-expired/not-cancelled status,
  verifies a server-only approved reward/clinic/service mapping, and changes
  it to redeemed atomically. The eligibility table starts empty so no clinic
  can redeem until operations configures a verified Clinician service ID.
- The Mom receiver accepts only the directional server secret. The secret must
  never enter a Flutter build, QR code, request log, or clinician browser.
- **Missing:** the Clinician project must authenticate a staff session and
  prove that the staff identity is active and assigned to the submitted clinic
  before it makes the server-to-server callback. This is not implemented or
  verified in the available Clinician source, so voucher redemption is not
  launch-ready.

### Email and notifications

- Both queues are private: Flutter cannot read recipient addresses, provider
  identifiers, or delivery state.
- Job claiming uses locked rows, worker ownership, bounded retries, and a
  stable Resend idempotency key.
- Templates intentionally omit diagnoses, period/pregnancy details, voucher
  codes, payment data, and other private health content.
- Appointment reminders already require the saved `email_notification` opt-in.
  Product/legal must explicitly classify welcome, reward-available, and
  voucher-claimed email as transactional or add a persisted opt-in before
  migration 3 is approved. Do not infer consent from an email address alone.

## Required configuration (values must remain server-side)

| Area | Required configuration |
| --- | --- |
| Lipila/Airtel | `LIPILA_API_KEY`, `LIPILA_BASE_URL` pointing to sandbox, `LIPILA_WEBHOOK_SECRET`; provider callback allowlist and replay-test configuration. |
| Mom-to-Clinician voucher callback | `DAWA_MOM_SYNC_SECRET` in both server environments, plus the approved Mom receiver URL in the Clinician server configuration. |
| Email | `RESEND_API_KEY`, verified `DAWA_MOM_EMAIL_FROM`, `DAWA_MOM_EMAIL_WORKER_SECRET`, existing `APPOINTMENT_EMAIL_FROM`, and `APPOINTMENT_EMAIL_WORKER_SECRET`. |
| Worker access | An authenticated scheduler or job runner that sends only the relevant worker-secret header; do not expose service keys or worker secrets to clients. |

Use only controlled test mailboxes and provider sandbox credentials. No secret
values belong in Git, Flutter defines, screenshots, logs, or this document.

## Isolated migration validation

The required non-production migration lint has **not** completed.

- `supabase db lint --local --level error --fail-on error` and a linked schema
  dump both require Docker here; Docker is unavailable.
- This machine has PostgreSQL client tools, but no `postgres` server binary,
  so it cannot host an isolated cluster without installing additional runtime.
- No remote SQL, linked-project lint, migration push, or production database
  write was attempted as a substitute.

Run the following in isolated CI or a disposable staging project built from a
sanitized schema snapshot (never patient rows):

1. Start a clean Supabase/PostgreSQL stack at migration history `202609240002`.
2. Use the reviewed release branch that excludes `20261009000x`.
3. Apply the three `20261010000x` migrations in order and run `supabase db
   lint --local --level error --fail-on error`.
4. Inspect grants, RLS policies, function ownership, extensions, indexes, and
   trigger order. Capture the migration output and schema diff.
5. Execute transaction tests for duplicate payment webhooks, failed/cancelled/
   expired payments, replayed voucher events, expired/cancelled vouchers, and
   duplicate email events.
6. Restore a fresh isolated database from the same baseline and repeat the
   migration. This is the rollback/recovery rehearsal; these migrations are
   additive and should be rolled forward rather than destructively reversed.

## Connected verification matrix

### Health Profile — blocked pending a safe test account

Use a newly registered, non-staff test account with a controlled mailbox. Do
not use or alter a patient record. Verify all four profile steps; pregnancy
save and restart persistence; immediate Done/Edit cards; accurate progress;
failed write has no points/success effect; and re-editing has no duplicate
achievement. No credentials or controlled mailbox are available in this
workspace, so this has not been performed.

### Payments — blocked pending sandbox credentials

For a single disposable appointment per case, with no real charge:

1. Provider-successful callback: payment becomes successful and only then is
   the visit released to the Clinician workflow.
2. Provider-cancelled and provider-failed callbacks: payment and appointment
   become terminal/cancelled; no visit is sent or occupies a clinic slot.
3. Expired callback: same private-reservation release behaviour.
4. Pending/processing callback and provider-response loss: no false success,
   no duplicate payment request, clear status retry path.
5. Signed webhook replay, altered amount/currency, late success after a
   terminal result, and Rudo-initiated booking: verify rejection or
   reconciliation as appropriate.

### Vouchers — blocked pending Clinician implementation

The exact Mom receiver contract is in
`supabase/functions/receive-dawa-clinician-voucher-redemption/README.md`.
The Clinician side must add an authenticated staff redemption endpoint and UI
or scanner workflow, enforce staff-to-clinic authorization from a reviewed
canonical table, and forward one stable redemption event to Mom. Test a claim,
replay, wrong clinic/staff, expired/cancelled state, offline retry, and status
sync shown in both applications. Until these tests run against both projects,
do not state that voucher redemption is integrated.

### Resend — blocked pending sender and policy

Verify the sender domain and test recipient, configure the listed secrets,
then send one idempotent test per approved event: welcome, reward available,
voucher claim, appointment request, confirmation, cancellation, and opted-in
reminder. Confirm duplicate worker runs do not duplicate email; inspect only
safe delivery metadata; and confirm notification badge read/unread/realtime
behaviour in an authenticated session.

## Deployment order after written approval

1. Approve the release branch/migration-history resolution and the email
   consent classification.
2. Complete isolated CI migration/lint/recovery validation and obtain a schema
   review sign-off.
3. Complete the Clinician redemption implementation and cross-project test.
4. Configure test-only provider and Resend secrets, then run the complete
   connected matrix above.
5. Review results, all RLS/grant diffs, and the P0 list. Obtain explicit
   approval to deploy.
6. Back up schema metadata and record the current function versions.
7. Apply the approved migrations in order, then deploy the matching functions.
   Enable no reminder scheduler yet.
8. Run the post-deployment smoke list before exposing payments, vouchers, or
   new email events to patients.

## Recovery plan

- Stop the worker scheduler and disable the new receiver/function routes first
  if an external dependency is unhealthy; do not delete voucher, payment, or
  email audit records.
- For a payment conflict, leave the appointment/payment in
  `reconciliation_required` and reconcile against the provider; never infer a
  charge result from the client.
- For voucher or email failures, preserve the immutable event/reference and
  retry only through the server worker after diagnosis.
- Roll forward with an approved corrective migration/function version. Do not
  `migration repair` away an applied schema change or run destructive down SQL
  against production.
- Retain the deployment timestamp, migration/function versions, and test
  evidence with the incident record.

## Post-deployment smoke checklist

- Confirm exactly the approved migration ids and function versions are live.
- Sign in with the controlled test account and run the four Health Profile
  save/reopen cases.
- Run every payment sandbox state and inspect appointment visibility/slot
  release in both applications.
- Claim and redeem one controlled voucher, then replay the event and verify
  wrong-clinic/wrong-service/expired rejection.
- Send one approved email event to the controlled mailbox and rerun the worker
  to prove idempotency.
- Verify notification badge count/read state and preference-aware feedback.
- Confirm optional Care Plan failures do not block Home, Care, Track, profile,
  payment, or voucher flows.

## P0/P1 register

| Severity | Issue | Required closure |
| --- | --- | --- |
| P0 | Migration-history gap prevents a safe `db push` of the payment/voucher/email release without also attempting Care Plan. | Approved release branch that excludes `20261009000x`, followed by isolated validation. |
| P0 | Current Lipila functions are active but the connected migration history lacks the secure lifecycle migration. | Sandbox proof of the required RPC/schema and deployment of the reviewed paired migration/function bundle. |
| P0 | No authenticated Clinician voucher redemption endpoint, authorization proof, approved clinic/service eligibility mapping, or cross-project test. | Configure verified eligibility server-side, implement/validate Clinician side, and perform controlled end-to-end redemption. |
| P0 | No safe connected Profile verification account/mailbox. | Provide or create a separate controlled test account and execute the matrix. |
| P0 | Resend sender/secrets/consent policy and delivery checks are absent. | Approve policy, configure non-production secrets, and run idempotent test deliveries. |
| P1 | Local migration lint/recovery exercise is blocked by unavailable Docker/PostgreSQL server. | Run isolated CI or disposable staging validation. |
| P1 | Reminder scheduler has no approved operator/monitoring plan. | Keep disabled until separately approved. |
| P1 | `care_plan_items` remains absent remotely. | Keep optional and release under its own approved migration. |
