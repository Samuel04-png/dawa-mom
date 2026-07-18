# Dawa Platform Integration

## Scope and project boundary

Dawa Mom and Dawa Clinician remain separate applications and separate Supabase projects. Dawa Mom uses project `himbfndvsuwiudtzjojh`; Dawa Clinician uses `eatliepvwrviogsnqavu`. Public identifiers cross the boundary only through authenticated Edge Functions. Service-role keys and directional secrets never belong in either Flutter client.

The production backend rollout was completed on 18 July 2026: migrations and Edge Functions were deployed, both Vault-backed one-minute workers were scheduled, the legacy mother webhook inventory was checked, the existing-mother backfill was run in gated batches, and the two projects were reconciled.

## Identifier mapping and ownership

| Entity | Dawa Mom identity | Dawa Clinician mapping |
| --- | --- | --- |
| Patient | `mothers.id` UUID | `source_project = 'dawa_mom'` plus `source_mother_id`; returned native patient ID is stored in `mothers.dawa_clinician_patient_id` |
| Clinician | Local cache UUID in `doctors.id` | Stable Clinician `doctor.integration_id` is stored separately as `dawa_clinician_clinician_id` |
| Clinic | Local cache UUID in `clinics.id` | Stable Clinician `clinic.integration_id` is stored separately as `dawa_clinician_clinic_id` |
| Appointment | `appointments.id` UUID | Clinician native appointment ID is returned to `dawa_clinician_appointment_id` |
| Event | One UUID per outbox event | Receiver records `(source, event_id)` and returns the previous safe result on replay |

Names, phone numbers, email addresses and NRC values may help a human identify a possible duplicate, but they are not cross-project keys. Dawa Mom owns imported demographics and appointment requests. Dawa Clinician owns clinical notes, encounters, diagnoses and clinician-controlled appointment status.

## Patient synchronisation

Profile changes enqueue an approved demographic payload in the private `integration_outbox`. `process-dawa-platform-outbox` claims rows with recoverable leases and sends them to Clinician `sync-dawa-mom-patient`. The receiver upserts by the stable source mapping, rejects stale versions, soft-archives source deletions and preserves clinician-owned medical data. A mapping is written back only through service RPCs.

Failures are retryable and bounded. The profile completion page exposes a safe retry action when the mapping requires attention. The resumable backfill tool defaults to dry-run and requires `--execute` for writes.

## Directory and appointment flow

1. Dawa Mom calls `clinician-directory`, which requests the authoritative Clinician `list-bookable-clinicians` function and updates a booking-safe local cache.
2. The booking UI offers only active, bookable clinicians with valid stable mappings. A safely cached directory can be displayed during degradation, but live slot availability still requires a connection.
3. A committed appointment enqueues an idempotent delivery event.
4. Clinician `receive-dawa-mom-appointment` validates the mapped patient, assignment and slot under a transaction/advisory lock, creates the request and notification once, and returns the destination mapping.
5. Assigned clinicians use guarded status transitions. Clinician queues the callback and `process-dawa-mom-status-outbox` sends the permitted status/schedule fields to Dawa Mom.
6. `receive-dawa-clinician-appointment-status` applies a validated transition and updates the patient-safe message. Realtime refreshes the appointment list and details.

Email delivery state is separate from cross-project integration state; an email worker cannot overwrite appointment synchronisation state.

## Security boundaries

- RLS remains enabled on affected client tables.
- `integration_outbox` and processed-event ledgers expose no policies to `anon` or `authenticated`.
- Flutter users cannot write destination IDs, integration audit fields or clinician-controlled statuses.
- Directional secrets are compared in Edge Functions and stored only in Supabase secrets.
- Worker credentials are stored in Supabase Vault and injected into scheduled requests.
- Retry and replay paths reuse stable event IDs, preventing duplicate patients, appointments and notifications.

## Deployment order

For a new environment: back up both projects; deploy the Clinician integration migration/functions first; verify RLS and invalid-secret/replay behavior; deploy the Mom migration/functions; populate and verify the directory; test one patient and one appointment; configure both Vault worker secrets and schedules; then run the Mom backfill as dry-run, one reviewed record, a small batch and finally the approved remainder.

Do not run a blind Clinician `supabase db push`: `202607130001_add_patient_registration_identifiers.sql` is versioned for the enhanced local patient-registration form but was not part of the verified production integration rollout and requires its own review before live application.

## Verified production result and limitations

The rollout reconciled 19 usable Dawa Mom patients to 19 Clinician source-patient rows, with one incomplete Mom record intentionally skipped, zero duplicate mappings and zero mapping errors. The authoritative directory returned 26 bookable clinicians. Both scheduled workers reported successful runs.

Remaining release work is client-side: complete Android release compilation when Maven/Google artifacts are reachable, install full Xcode for iOS build/signing, and run one designated non-production end-to-end UI appointment flow before publishing a mobile or hosted-web release.
