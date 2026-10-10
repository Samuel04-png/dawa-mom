# Dawa Clinician Service Catalog Sync

This contract is implemented on the DawaMom Supabase project. The Dawa Clinician project will be the future management interface; it must not be queried directly by Flutter or Rudo.

## Destination

`POST https://himbfndvsuwiudtzjojh.supabase.co/functions/v1/receive-service-catalog-sync`

The destination is the DawaMom project. The exact host should be read from the DawaMom deployment configuration rather than copied into client code.

## Authentication

Send the DawaMom server-to-server secret in `x-dawa-sync-secret`. The secret is the existing `DAWA_MOM_SYNC_SECRET` Supabase secret. Never put it in Flutter, Rudo responses, or a browser request.

The Edge Function has JWT verification disabled because it is called by the future Clinician server, not by a patient. The function performs its own shared-secret comparison and uses the Supabase service role only server-side.

## Payload

```json
{
  "external_service_id": "screening-cervical-001",
  "external_clinic_id": "clinic-001",
  "name": "Cervical Cancer Screening",
  "description": "Screening service description",
  "category": "screening",
  "is_paid": true,
  "price": 50,
  "currency": "ZMW",
  "is_active": true,
  "source_updated_at": "2026-09-15T10:00:00Z"
}
```

Required fields: `external_service_id`, `name`, and `source_updated_at`.

`external_service_id` is the stable Clinician-owned identifier. It must remain unchanged when the name or price changes. `price` must be non-negative; free services must use `is_paid: false` and `price: 0`. Currency is a three-letter uppercase code.

## Upsert and stale updates

DawaMom upserts by `external_service_id`. Repeated delivery updates the same row. A message whose `source_updated_at` is earlier than or equal to the stored value is acknowledged as stale and does not overwrite the current record.

Deactivation uses `is_active: false`; services are never deleted. This preserves appointment snapshots and payment history.

## Responses

- `200`: accepted or safely ignored as stale; response includes `updated` and `stale`.
- `400`: malformed JSON or missing/invalid required fields.
- `401`: missing or invalid `x-dawa-sync-secret`.
- `500`: DawaMom configuration or database failure; sender should retry with backoff.

## DawaMom behavior

The active service catalog is readable by authenticated patients. Administrative writes and sync writes are server-controlled. New appointments snapshot service ID, external service ID, name, paid/free state, amount, and currency. Later catalog changes do not alter existing appointments or payments.

Flutter sends only the selected service ID. The booking RPC reads the active catalog and rejects inactive services. Payment creation reads the appointment snapshot, not the current catalog, and never trusts an amount supplied by a client.

## Expected Clinician workflow

1. Clinician admin creates or edits a service in the Clinician project.
2. Clinician backend emits the full current service record with a monotonic source timestamp.
3. Clinician backend retries failed requests with the same stable external ID and timestamp.
4. Clinician backend sends `is_active: false` when retiring a service.
5. DawaMom acknowledges the event and becomes the runtime source for Flutter, Rudo, appointments, and Lipila.

The Clinician project does not need to send provider credentials, patient medical details, appointment payment records, or Mobile Money information.
