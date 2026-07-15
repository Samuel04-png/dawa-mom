# Appointment email worker

This server-only Edge Function claims `appointment_email_outbox` rows, resolves trusted recipient addresses, and sends pending-request emails through Resend. Booking never calls this function and does not wait for email delivery.

Required Supabase secrets:

```powershell
supabase secrets set RESEND_API_KEY="re_..." APPOINTMENT_EMAIL_FROM="Dawa Mom <appointments@your-verified-domain.example>" APPOINTMENT_EMAIL_WORKER_SECRET="a-long-random-secret"
```

Optional secrets:

- `APPOINTMENT_EMAIL_MAX_ATTEMPTS` (default `4`)
- `DAWA_CLINICIAN_EMAIL_RESOLVER_URL`
- `DAWA_CLINICIAN_EMAIL_RESOLVER_TOKEN`

Deploy without JWT verification because scheduler calls are authenticated by the dedicated `x-worker-secret` header:

```powershell
supabase functions deploy process-appointment-emails --no-verify-jwt
```

Run every minute with Supabase Cron/`pg_net` or another trusted scheduler. Store the worker secret in Vault; do not paste it into migration source.

```sql
select cron.schedule(
  'process-appointment-emails',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://PROJECT_REF.supabase.co/functions/v1/process-appointment-emails',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-worker-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'appointment_email_worker_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
```

If the clinician is represented by a local `doctors.profile_id`, the worker resolves `profiles.email`. Otherwise the optional resolver contract receives:

```json
{
  "action": "resolve_appointment_recipient",
  "clinician_id": "uuid",
  "appointment_id": "uuid",
  "source": "dawa_mom"
}
```

It must authenticate `x-dawa-integration-secret` and return `{ "email": "verified@example.com" }`. This contract is prepared for Dawa Clinician; that application is not changed here.
