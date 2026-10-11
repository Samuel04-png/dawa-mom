# DAWA Mom Release 1 execution checklist

Prepared 2026-10-11. This is a review package only. It authorises no
production database change, Edge Function deployment, payment request, or
patient-data access.

**Decision: NO-GO.** Release 1 is blocked by migration-governance, isolated
validation, controlled-account, Airtel/Lipila sandbox, and Clinician
integration evidence. Release 2 remains disabled and is not on the core launch
path.

## 1. Confirmed booking dependency evidence

### Project identity

All three local/linkage sources identify the same Dawa Mom project:

| Source | Project |
| --- | --- |
| `supabase/config.toml` | `himbfndvsuwiudtzjojh` |
| Flutter default URL in `lib/backend/supabase/supabase_config.dart` | `https://himbfndvsuwiudtzjojh.supabase.co` |
| Supabase linked-project state (`supabase/.temp/project-ref`) | `himbfndvsuwiudtzjojh` |

### `202609220001` status

Read-only `supabase migration list --linked` reports both local and remote
`202609220001`. The earlier claim that this migration was absent remotely is
therefore incorrect.

The checked-in migration adds `appointments.payment_method` and creates the
11-argument `public.book_dawa_mom_appointment` overload. Flutter sends the
same named parameters, including `p_payment_method`, from
`lib/features/appointments/data/appointment_repository.dart`.

A non-authenticated, non-writing REST probe sent that complete 11-parameter
shape to the connected project with synthetic UUIDs. It returned HTTP `401` /
Postgres `42501` (`permission denied for function
book_dawa_mom_appointment`). PostgREST could therefore resolve the exact
function signature; anonymous access was rejected before the function body or
any appointment write could run.

A zero-row read-only schema probe then returned HTTP `200` for
`appointments?select=payment_method&limit=0`, confirming the live column is
present without reading appointment data. The same probe returned HTTP `400` /
Postgres `42703` for `payment_state`, confirming that the pending payment-state
migration has not reached the connected schema.

This is **not** proof of a successful booking or of the full function body.
Those require the controlled authenticated and isolated tests below.

### `202610100001` dependency result

`202610100001_secure_paid_appointment_lifecycle.sql` explicitly depends on the
payment-method work in `202609220001`: it reads/writes
`appointments.payment_method`, preserves the same 11-argument booking RPC, and
adds the `payment_state` contract plus service-role-only
`apply_lipila_payment_status`. It has no SQL dependency on Care Plan tables.

The migration is not listed remotely, and the live `payment_state` probe is
also absent as expected. The active remote Lipila Edge Functions do not make
this missing database contract safe. Do not enable or represent online payment
as verified until this migration and the aligned function bundle pass isolated
and sandbox validation.

## 2. Exact migration inventory and sequencing decision

### Current remote state

| Migration | Release | Remote state | Effect / action |
| --- | --- | --- | --- |
| `202609220001_separate_appointment_payment_state.sql` | Existing core | Applied | Existing `payment_method` and booking-RPC overload. |
| `202610090001_add_care_plan_items.sql` | Excluded | Not applied | Must not be included in Release 1. |
| `202610090002_track_cancellation_sync_state.sql` | Release 1 | Not applied | Queues cancellation synchronization for Clinician delivery. |
| `202610100001_secure_paid_appointment_lifecycle.sql` | Release 1 | Not applied | Payment-state, idempotent provider-event, and reservation safety. |
| `202610100002_secure_dawa_reward_vouchers.sql` | Release 2 | Not applied | Not a Release 1 deployment item. |
| `202610100003_dawa_mom_transactional_email_events.sql` | Release 2 | Not applied | Not a Release 1 deployment item. |

### Proposed controlled strategy — pending governance approval

There is no safe deployment command from the current checkout: its next local
migration is Care Plan (`202610090001`), so a normal push would include an
excluded feature.

The candidate supported strategy is a protected `release/1-core-backend`
branch whose migration directory contains the immutable existing baseline plus
only these already-named Release 1 files:

1. `202610090002_track_cancellation_sync_state.sql`
2. `202610100001_secure_paid_appointment_lifecycle.sql`

The branch must not rename, edit the identifiers of, repair, mark as applied,
or manually execute `202610090001`. Its absence would be an explicit,
reviewed release-scope decision recorded truthfully in remote history—not an
attempt to fabricate that Care Plan was applied. Before this is used, the
migration owner must approve both the non-contiguous version history and the
later, separately reviewed Care Plan release. If that approval is not given,
there is **no executable Release 1 migration path** and Release 1 remains
NO-GO.

The intended order in the isolated release branch is therefore:

```
remote baseline through 202609240002 (already applied)
  -> 202610090002_track_cancellation_sync_state
  -> 202610100001_secure_paid_appointment_lifecycle
```

`202610090001`, `202610100002`, and `202610100003` must not appear in that
branch’s release manifest. No current checkout may receive an automatic full
`supabase db push`.

## 3. Isolated schema validation

### Evidence today

- `supabase db lint --linked --level error --fail-on error` returned no errors
  for the **existing remote** schema. It does not apply or validate pending
  migrations.
- A reproducible local-only GitHub Actions workflow now exists at
  `.github/workflows/release1-migration-validation.yml`. It constructs a
  temporary migration workspace through `202609240002`, seeds synthetic
  legacy paid appointments/payments, then incrementally applies only
  `202610090002` and `202610100001`; Care Plan and Release 2 files are
  asserted absent. Its SQL fixture covers the migration backfill, RLS/grants,
  both booking signatures, idempotency, free/cash compatibility, cancellation
  queuing, pending / processing / successful / failed / cancelled / expired /
  replay / late-success payment states, and Clinician outbox release.
- GitHub Actions run
  [`38134957088`](https://github.com/Samuel04-png/dawa-mom/actions/runs/38134957088)
  passed on 2026-10-11 for commit `b4e27fe`. It applied
  `202610090002` then `202610100001` in a GitHub-hosted disposable Supabase
  stack, passed `supabase db lint --local`, and completed the synthetic
  lifecycle/RLS/idempotency suite. No connected-project credential, patient
  data, payment credential, or Care Plan/Release 2 migration was used.
- That run also exposed and verified the fix for a genuine pre-deployment
  defect: `release_paid_appointment_workflow` selected every mother when
  composing an outbox row. `202610100001` now constrains it to
  `mother.id = appointment_row.mother_id`, so a verified payment releases one
  Clinician workflow for its own appointment.
- `202609170001_recovered_remote_history.sql` is intentionally non-executable
  because its original remote SQL was unavailable. The first CI run is
  structural only, not a representative production baseline, until an
  authorized sanitized schema-only staging baseline is supplied.

Accordingly, isolated validation is **not complete**. Do not substitute the
production project for it.

### Required isolated CI evidence

In a disposable Supabase-compatible stack seeded only with a sanitized
baseline through `202609240002`, the approved release branch must show:

1. both Release 1 migrations apply cleanly, in the stated order;
2. rollback/forward recovery plan is rehearsed (additive corrective migration,
   never deletion of payment/outbox evidence);
3. `appointments.payment_method` and `payment_state` constraints accept only
   permitted values;
4. authenticated callers can execute the booking RPC only for their own
   identity; anonymous callers cannot;
5. `create_lipila_payment` is owner-scoped and
   `apply_lipila_payment_status` is service-role-only;
6. duplicate webhook identifiers and duplicate client idempotency keys do not
   create duplicate booking, charge, or Clinician workflow rows;
7. success releases the appointment workflow exactly once; cancelled, failed,
   expired, and pending payment do not create an active/confirmed visit; and
8. RLS, grants, and outbox delivery continue to work for free and
   pay-at-clinic bookings.
9. synthetic pre-migration paid rows backfill to `not_started`, provider
   `pending`, or preserved `successful` states as appropriate.

The workflow instructions and the baseline limitation are documented in
[`ci/release1/README.md`](../ci/release1/README.md). The exact human-access
requirements and connected verification matrix are in
[`DAWA_MOM_RELEASE_1_TEST_ACCESS_CHECKLIST.md`](DAWA_MOM_RELEASE_1_TEST_ACCESS_CHECKLIST.md).

## 4. Required Release 1 Edge Function manifest

| Edge Function | Release 1 disposition | Required proof |
| --- | --- | --- |
| `lipila-create-payment` | Deploy/reconcile as a bundle with `202610100001`; never independently. | Owner, server-calculated amount/currency, sandbox request. |
| `lipila-webhook` | Deploy/reconcile as the same bundle. | Provider signature, replay, malformed payload, and all terminal-state tests. |
| `lipila-payment-status` | Deploy/reconcile as the same bundle. | Owner-only lookup and pending/terminal state test. |
| `process-dawa-platform-outbox` | Existing function; verify its deployed source/config and worker authentication. | Appointment and cancellation delivery continues while missing Care Plan jobs remain isolated. |
| `receive-dawa-clinician-appointment-status` | Existing function; no new feature deployment implied. | Signed Clinician status update and patient notification test. |
| `clinician-directory` | Existing function; no new feature deployment implied. | Authenticated verified-directory/minimal metadata test. |
| `receive-service-catalog-sync` | Existing function; no new feature deployment implied. | Trusted catalog update, inactive/paid/free service test. |

`process-appointment-emails`, `process-dawa-mom-emails`, and
`receive-dawa-clinician-voucher-redemption` are excluded from Release 1.

## 5. Controlled test environment requirements

Before connected verification, provide an authorized non-patient test setup:

- A newly registered synthetic patient account and controlled mailbox; no real
  patient account, data, or telephone number.
- Test clinic, clinician, and availability slots in the same Dawa Clinician
  test environment, including a free service, pay-at-clinic service, and paid
  service with known active catalog identifiers.
- Dawa Clinician test credentials and a server-to-server callback secret for
  observing appointment delivery and status changes.
- Airtel/Lipila sandbox credentials, test MSISDN, provider webhook target, and
  documented ways to simulate successful, pending, cancelled, failed,
  expired, duplicate/replayed, malformed, and late-success events. No real
  charge is authorized.
- Test access to the Mom project’s in-app notification stream for that account.

The evidence matrix must cover all four Health Profile steps, pregnancy
save/restart, immediate Done/Edit/progress reconciliation, failed-save/no
points/no-celebration, notification unread/read/realtime state, normal and
Rudo booking, rapid retry/idempotency, free/pay-at-clinic booking, every
payment state, and Clinician synchronization. Pending requests may never be
shown as confirmed, and failed/cancelled payments may never schedule a
Clinician visit.

## 6. Release 2 isolation verification

Release 1 builds leave `DAWA_VOUCHER_REDEMPTION_ENABLED` unset/`false`. The
main Rewards, Home, Settings, and direct learning-completion reward dialog all
show points as saved/preparing and expose no claim, QR, code, participating
clinic, or redeem action. The direct dialog is covered by a focused widget
test. Existing points and learning progress remain available.

No Release 2 voucher function, migration, eligibility record, Clinician
redemption route, Resend worker, email scheduler, or reward policy is required
or permitted in Release 1.

## 7. Production commands — review only, do not run

There is currently **no approved production push command**. After migration
governance approval, successful isolated evidence, explicit production
approval, and a reviewed protected release branch, an operator would first
perform these read-only checks:

```sh
git switch release/1-core-backend
supabase migration list --linked
supabase functions list
git diff --name-only <approved-baseline>..HEAD -- supabase/migrations supabase/functions
```

The diff must list exactly `202610090002`, `202610100001`, and the reviewed
Release 1 function sources—never Care Plan, voucher, or email files.

After all gates and a change-window approval, the manual commands proposed for
that protected branch are:

```sh
# These commands are for approved-operator review only. Do not run now.
supabase db push --linked
supabase functions deploy lipila-create-payment --project-ref himbfndvsuwiudtzjojh
supabase functions deploy lipila-webhook --project-ref himbfndvsuwiudtzjojh
supabase functions deploy lipila-payment-status --project-ref himbfndvsuwiudtzjojh
supabase functions deploy process-dawa-platform-outbox --project-ref himbfndvsuwiudtzjojh
```

This is not an automatic full push: it is a manually executed, reviewed push
from the protected branch only after its `supabase/migrations` diff has been
verified to contain no Care Plan, voucher, or email file. The checked-in
function configuration preserves JWT verification for the create/status
endpoints and disables gateway JWT verification only for the signed webhook
and the separately custom-authorized server-to-server outbox worker.

## 8. Post-deployment smoke and recovery

### Smoke test order

1. Verify remote migration history and function versions match the signed
   manifest.
2. Run authenticated synthetic-profile save/reopen and notification-unread
   tests.
3. Run free and pay-at-clinic booking, status synchronization, and cancellation
   delivery tests.
4. Run Airtel/Lipila sandbox payment tests: requested, pending, success,
   cancellation, failure, expiry, duplicate/replay, and late success.
5. Confirm only verified payment success activates the paid appointment and
   triggers one Clinician workflow.
6. Confirm Release 1 app build has voucher redemption disabled and does not
   promise an available voucher.

### Recovery

- Disable online-payment entry through the server-owned active-service
  configuration or issue a reviewed app configuration/build; do not delete
  payment, appointment, webhook, or outbox evidence.
- Stop the outbox worker if Clinician delivery is unsafe; retain idempotency
  keys and queued records for reconciliation.
- Keep voucher redemption disabled.
- Use a reviewed additive forward migration/function correction. Never repair
  migration history, manually mutate production payment states, or roll back
  by dropping ledger data.

## 9. Approval gates and recommendation

| Gate | Status |
| --- | --- |
| Migration `202609220001` recorded and 11-argument RPC resolves remotely | Confirmed |
| Flutter and Supabase CLI point to the same project | Confirmed |
| Care Plan excluded from Release 1 | Locally gated; production sequencing decision pending |
| Isolated Release 1 migration/RLS/idempotency validation | Structural pass — [run 38134957088](https://github.com/Samuel04-png/dawa-mom/actions/runs/38134957088); authoritative representative baseline still required |
| Controlled profile/booking/Clinician connected tests | Blocked |
| Airtel/Lipila sandbox lifecycle evidence | Blocked |
| Release 1 notification connected evidence | Blocked |
| Release 2 redemption and Resend isolation | Local UI gate verified; external systems intentionally deferred |

**GO / NO-GO: NO-GO.** Do not deploy until every blocked Release 1 gate has
independent evidence and the migration owner approves the protected-branch
strategy.
