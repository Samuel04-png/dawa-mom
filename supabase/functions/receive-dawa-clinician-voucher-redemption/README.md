# Dawa Clinician voucher-redemption receiver

This is a **non-deployed** server-to-server receiver. It is required before a
clinic can redeem a DawaMom clinic scan voucher.

## Required Dawa Clinician contract

The Clinician application must authenticate the staff member in its own
project, verify that the staff member is authorised for `clinic_id`, verify the
patient according to the clinic's workflow, then POST exactly once per scan to
this endpoint:

```json
{
  "event_id": "stable UUID for the redemption attempt",
  "event_type": "voucher.redeemed",
  "claim_id": "voucher UUID from QR payload",
  "claim_reference": "DAWA-… fallback reference",
  "clinic_id": "authorised Clinician clinic identifier",
  "clinician_id": "authorised Clinician staff identifier",
  "external_service_id": "approved Clinician screening service identifier"
}
```

It must send `x-dawa-sync-secret` using the existing directional
`DAWA_MOM_SYNC_SECRET`, never a browser or Flutter secret. Retrying the same
`event_id` is safe and returns an idempotent result. A different event cannot
redeem an already redeemed, expired, or cancelled voucher.

The caller must select an active service at the same authorised clinic. Mom
fails closed unless operations has configured that exact `(reward_code,
clinic_id, external_service_id)` triplet in its server-only voucher-eligibility
table. Do not add a fallback clinic or generic "scan" service in Flutter.

## Deployment sequence

1. Review and apply `202610100002_secure_dawa_reward_vouchers.sql`.
2. Deploy this receiver with `SUPABASE_SERVICE_ROLE_KEY` and
   `DAWA_MOM_SYNC_SECRET` configured only on the server.
3. Implement and authenticate the matching Clinician caller.
4. Perform a one-voucher, non-production reconciliation before enabling broad
   clinic use.

No Flutter client can self-redeem and no migration/function has been deployed
by this change.
