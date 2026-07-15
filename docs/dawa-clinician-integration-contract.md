# Dawa Mom to Dawa Clinician integration contract

Status: Dawa Mom adapter ready; Dawa Clinician implementation deferred.

The products use separate Supabase projects. Dawa Mom Flutter calls only the authenticated Dawa Mom `clinician-directory` Edge Function. That function will call a protected Dawa Clinician endpoint with a server-side shared secret. No service-role or cross-project secret may be shipped in Flutter.

## Authentication and transport

- HTTPS and JSON are required.
- Dawa Mom sends `x-dawa-directory-secret` from its Edge Function secret store.
- Dawa Clinician must validate that secret using a constant-time comparison and should rotate it without a client release.
- Dawa Mom also sends `x-dawa-request-user` for audit correlation. Dawa Clinician must not treat that header alone as authorization.
- Responses must never include auth metadata, private email/phone numbers, clinical notes, or internal credentials.

## Clinician directory request

```json
{
  "action": "list",
  "clinic_id": "optional-dawa-clinician-clinic-uuid",
  "clinician_id": null,
  "date": null,
  "source": "dawa_mom"
}
```

Successful response:

```json
{
  "clinicians": [
    {
      "id": "uuid",
      "display_name": "Dr Jane Banda",
      "professional_title": "Medical Doctor",
      "speciality": "Maternal Health",
      "clinic_id": "uuid",
      "clinic_name": "Kabulonga Clinic",
      "profile_image_url": null,
      "is_active": true,
      "is_bookable": true,
      "availability_summary": {
        "start_time": "08:00",
        "end_time": "16:00",
        "slot_minutes": 30
      }
    }
  ]
}
```

Only active, bookable clinicians should be returned. When `clinic_id` is supplied, every returned clinician must currently work at that clinic.

## Availability request

```json
{
  "action": "availability",
  "clinic_id": "uuid",
  "clinician_id": "uuid",
  "date": "2026-07-20",
  "source": "dawa_mom"
}
```

Successful response:

```json
{
  "clinician_id": "uuid",
  "date": "2026-07-20",
  "timezone": "Africa/Lusaka",
  "slots": [
    {
      "start_time": "09:00",
      "end_time": "09:30",
      "is_available": true
    }
  ]
}
```

Dawa Mom rechecks availability immediately before insertion. The authoritative server must still enforce slot uniqueness because two users can submit concurrently.

## Appointment delivery contract for the next phase

Dawa Mom stores a complete request in `public.appointments` with:

- `id`, `mother_id`, and `patient_id`
- `clinician_id` and `clinic_id`
- `appointment_date`, `start_time`, and `end_time`
- `appointment_type`, `reason`, and `notes`
- `status = pending` and `source = dawa_mom`
- `created_by`, `created_at`, and `updated_at`
- `integration_status` and `external_appointment_id`

The future delivery endpoint should accept an idempotency key equal to the Dawa Mom appointment `id`. It should return:

```json
{
  "external_appointment_id": "uuid",
  "status": "pending",
  "received_at": "2026-07-15T06:00:00Z"
}
```

Dawa Mom's server-side worker/Edge Function will set `integration_status` to `sent` or `synced` and store `external_appointment_id`. Flutter must not perform this privileged cross-project delivery directly.

## Status callback contract

Dawa Clinician should later send authenticated, idempotent status events containing the Dawa Mom appointment ID, external ID, status, effective timestamp, and optional patient-safe message. Supported statuses are `pending`, `confirmed`, `declined`, `rescheduled`, `completed`, `cancelled`, and `missed`.

## Error shape

```json
{
  "code": "DIRECTORY_UNAVAILABLE",
  "message": "Clinician availability is temporarily unavailable",
  "retryable": true
}
```

Use HTTP 400 for invalid input, 401/403 for failed server authentication, 409 for a slot conflict, 429 for throttling, and 5xx for temporary server failure. Do not return database errors or stack traces.

## Temporary Dawa Mom fallback

Before the Dawa Clinician endpoint exists, Dawa Mom reads imported clinician cache rows through `get_bookable_clinicians` and occupied times through `get_clinician_booked_slots`. These RPCs expose booking-safe fields only. This fallback is development/readiness infrastructure, not completed cross-project integration.
