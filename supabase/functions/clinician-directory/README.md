# Clinician directory proxy

This authenticated DawaMom Edge Function is the future server-to-server adapter for the separate Dawa Clinician project. Flutter never receives the cross-project secret.

Until Dawa Clinician implements the endpoint, the Flutter repository falls back to DawaMom's narrow `get_bookable_clinicians` RPC over imported cache rows.

Required secrets for activation:

```powershell
supabase secrets set DAWA_CLINICIAN_DIRECTORY_URL="https://<clinician-project>/functions/v1/dawa-mom-directory" --project-ref himbfndvsuwiudtzjojh
supabase secrets set DAWA_CLINICIAN_DIRECTORY_TOKEN="<shared-server-secret>" --project-ref himbfndvsuwiudtzjojh
supabase functions deploy clinician-directory --project-ref himbfndvsuwiudtzjojh
```

The upstream request and response contract is documented in `docs/dawa-clinician-integration-contract.md`.
