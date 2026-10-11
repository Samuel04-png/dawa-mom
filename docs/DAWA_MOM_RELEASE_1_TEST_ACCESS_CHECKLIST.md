# Release 1 controlled test-account and sandbox access checklist

This checklist is for pre-production verification only. Use a dedicated test
environment and synthetic data. No real patient account, phone number, payment,
clinic schedule, or clinician credential is acceptable.

## Access owners and environments

| Item | Required access | Evidence to retain |
| --- | --- | --- |
| Mom backend | Non-production Supabase project with test-only Auth, database, Realtime, and Edge Functions. | Project ref and environment owner; no production write credential in CI. |
| Synthetic patient | A newly created email account on a controlled inbox, plus an app test build. | Account ID and inbox owner recorded outside the app repo. |
| Synthetic clinic/clinician | Dawa Clinician staging staff account, test clinic, known clinician, and future slots. | Test clinic/clinician IDs, availability window, and staff authorization proof. |
| Services | One free, one pay-at-clinic, and one paid Mobile Money service synced from the test Clinician catalog. | Service IDs, price/currency, active state, and catalog-sync timestamp. |
| Mom ↔ Clinician | Staging-only endpoint and rotating test sync secret. | Secret owner, callback version, and an event correlation ID—not the secret. |
| Airtel/Lipila | Sandbox API credential, sandbox test MSISDN, webhook signing secret, and state simulator. | Provider environment confirmation and test-event references. |
| Notifications | Test-device/browser session that can receive Realtime events for the synthetic patient. | Before/after unread-count capture and message IDs. |

## Synthetic patient profile verification

1. Register the controlled email account and sign in fresh.
2. Save each Health Profile step independently; capture the server row ID and
   app state after each save.
3. Reopen/restart the app and confirm each completed section becomes Done/Edit
   and the progress count equals the server-backed completed sections.
4. Save pregnancy information, reopen the app, and verify pregnancy state and
   dates persist.
5. Simulate a rejected/offline save. Confirm there is no success animation,
   point award, or stale local completion state.
6. Re-edit a completed section. Confirm the server treats it as an update and
   does not create another achievement or point award.

## Booking, cancellation, and Clinician synchronization

1. Confirm the test clinic directory exposes only the known verified test
   clinic/clinician/service data.
2. Make a free appointment and a pay-at-clinic appointment; verify both follow
   their supported existing flows and each creates one Clinician event.
3. Make a paid online appointment. Before provider success, verify it is shown
   as awaiting payment—not confirmed/upcoming—and no Clinician scheduling event
   exists.
4. Trigger the same booking action twice with the same idempotency key; verify
   one appointment and one payment ledger record.
5. Cancel a patient-owned eligible appointment. Verify the patient-facing
   status, queued cancellation state, one Clinician cancellation event, and no
   duplicate retry event.
6. Have Clinician staging acknowledge/confirm the event. Verify the signed
   callback changes only the matching appointment and creates one owner-scoped
   in-app notification.
7. Repeat the booking flow through Rudo. Verify it uses the same service IDs,
   idempotency behavior, payment guard, and status display.

## Airtel/Lipila sandbox state matrix

For a unique paid appointment/reference per case, use only the provider’s
sandbox simulator:

| Provider outcome | Required Mom result |
| --- | --- |
| Request accepted / pending | Payment and appointment remain private; no Clinician event or confirmed display. |
| Processing | Still private; no scheduling event. |
| Successful signed callback | One successful ledger state, one released Clinician event, and correct notification. |
| Failed | Appointment is cancelled/not upcoming; no Clinician event. |
| Cancelled | Appointment is cancelled/not upcoming; no Clinician event. |
| Expired | Appointment is cancelled/not upcoming; no Clinician event. |
| Duplicate callback | No duplicate event, appointment, payment, notification, or slot use. |
| Late success after terminal failure | Reconciliation-required state; no Clinician event until reviewed. |
| Invalid signature, bad amount, bad currency, malformed body | Rejected without changing payment/appointment state. |
| Lost client response | Status endpoint reconciles the owner’s record without issuing a duplicate payment request. |

## Notification and privacy checks

- Verify unread badge uses the synthetic user’s actual unread count.
- Verify opening a notification marks only that user’s item read and updates
  the badge/realtime state.
- Confirm notifications and visible payment states contain no phone number,
  secret, provider credential, or unnecessary medical details.
- Capture only redacted IDs, state transitions, timestamps, and screenshots in
  the release evidence. Do not export patient/profile payloads or webhook
  bodies into GitHub Actions logs.

## Sign-off prerequisites

- Environment owner confirms all credentials are sandbox/staging-only.
- Clinician integration owner signs the source/destination correlation report.
- Payment owner signs the provider state matrix and webhook verification log.
- Product/clinical owner signs profile and appointment state screenshots.
- Release owner records the migration/function version, feature flags, and
  rollback contact in the deployment change record.
