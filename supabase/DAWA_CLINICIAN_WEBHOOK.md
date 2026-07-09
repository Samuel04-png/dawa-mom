# Dawa Mom to Dawa Clinician Patient Sync

This integration is one-way:

`Dawa Mom public.mothers -> Database Webhook -> Dawa Clinician sync-dawa-mom-patient -> Dawa Clinician public.patients`

Dawa Mom Flutter must not call the Dawa Clinician project directly and must not contain the shared sync secret or any service-role key.

## Current Dawa Mom Source Schema

`public.mothers` stores demographic profile data:

- `id`
- `profile_id` unique auth/profile UUID
- `user_id` generated alias of `profile_id` for webhook compatibility
- `name`
- `phone_number`
- `date_of_birth`
- `occupation`
- `address`
- `created_at`
- `updated_at`

Email is owned by `public.profiles` / Supabase Auth, not by `public.mothers`.

## Database Webhook

Create this webhook in the Dawa Mom Supabase Dashboard after the Dawa Clinician receiver is deployed and `DAWA_SYNC_SECRET` is configured there.

- Name: `sync_mothers_to_dawa_clinician`
- Source table: `public.mothers`
- Events: `INSERT`, `UPDATE`, `DELETE`
- Method: `POST`
- URL: `https://eatliepvwrviogsnqavu.supabase.co/functions/v1/sync-dawa-mom-patient`
- Headers:
  - `Content-Type: application/json`
  - `x-dawa-sync-secret: <shared secret>`

Do not store the shared secret in Flutter, checked-in source files, public environment files, or browser-visible configuration.

## Manual Dashboard Steps

1. Open the Dawa Mom Supabase Dashboard.
2. Go to `Database` -> `Webhooks`.
3. Create a new webhook named `sync_mothers_to_dawa_clinician`.
4. Choose table `public.mothers`.
5. Enable `Insert`, `Update`, and `Delete`.
6. Set method to `POST`.
7. Paste the endpoint above.
8. Add the two required headers.
9. Save but enable only after testing the Dawa Clinician Edge Function with the same secret.

## Backfill

Database webhooks only handle future changes. Use `tools/backfill_dawa_clinician_patients.ts` for a one-time server-side backfill of existing Dawa Mom mothers.

Required environment variables:

- `DAWA_MOM_SUPABASE_URL`
- `DAWA_MOM_SERVICE_ROLE_KEY`
- `DAWA_SYNC_SECRET`

Optional:

- `DAWA_CLINICIAN_SYNC_ENDPOINT`

Example dry run:

```powershell
$env:DAWA_MOM_SUPABASE_URL = "https://himbfndvsuwiudtzjojh.supabase.co"
$env:DAWA_MOM_SERVICE_ROLE_KEY = "<dawa-mom-service-role-key>"
$env:DAWA_SYNC_SECRET = "<shared-secret>"
deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts --dry-run
```

Run for real:

```powershell
deno run --allow-env --allow-net tools/backfill_dawa_clinician_patients.ts --batch-size=100
```

The script logs source IDs and status only. It does not log full patient records or secrets.
