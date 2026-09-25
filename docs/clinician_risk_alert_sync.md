# Dawa Mom → Dawa Clinician risk-alert sync

`public.clinician_risk_alerts` is authoritative in Dawa Mom. Migration
`202609240001_add_clinician_risk_alert_sync.sql` enqueues each insert, relevant
update, and delete in the existing private `integration_outbox`. The existing
`process-dawa-platform-outbox` worker delivers those events to Dawa Clinician;
it does not make any client-to-client calls.

## Deployment order

1. Deploy the Dawa Clinician migration
   `202609240001_add_dawa_mom_risk_alert_sync.sql`.
2. Deploy the Clinician `sync-dawa-mom-risk-alert` Edge Function.
3. On Dawa Mom, set `DAWA_CLINICIAN_RISK_ALERT_URL` to:
   `https://eatliepvwrviogsnqavu.supabase.co/functions/v1/sync-dawa-mom-risk-alert`
4. Set the same high-entropy value for `DAWA_CLINICIAN_SYNC_SECRET` in both
   projects. It is server-only.
5. Deploy the Dawa Mom migration and the updated
   `process-dawa-platform-outbox` function.

The new URL is deliberately optional for other queue traffic: while it is
missing, only risk-alert events retry; patient and appointment delivery remains
unaffected. Do not run the demo until it has been set.

## Demo check

Create or update an alert in Dawa Mom, invoke the outbox worker, then verify the
matching Dawa Clinician row by `source_project = 'dawa_mom'` and
`source_alert_id = <Dawa Mom alert UUID>`. The source alert should show
`integration_status = 'synced'`. A deleted source row becomes an archived
Clinician mirror; deleting an alert that was never delivered is also a successful
no-op.

Useful Dawa Mom query:

```sql
select event_type, status, attempt_count, destination_id, last_error_code
from public.integration_outbox
where aggregate_type = 'risk_alert'
order by created_at desc;
```
