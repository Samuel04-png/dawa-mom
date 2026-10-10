-- Keep appointment lifecycle and cross-project delivery state separate.
--
-- A patient cancellation already creates an integration_outbox job, but the
-- appointment row previously retained its earlier integration_status. That
-- made a queued cancellation indistinguishable from a cancellation already
-- delivered to DAWA Clinician. This additive trigger marks only patient-owned
-- cancellation transitions as queued. The existing outbox completion function
-- remains responsible for moving the row to synced, queued, or failed.

begin;

create or replace function public.mark_patient_cancellation_pending_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status
     and new.status = 'cancelled'
     and coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
     and auth.uid() is not null
     and public.current_app_role() = 'patient'::public.app_role then
    new.integration_status := 'queued';
    new.integration_error_code := null;
    new.patient_safe_status_message := null;
  end if;

  return new;
end;
$$;

revoke all on function public.mark_patient_cancellation_pending_sync()
  from public;

drop trigger if exists z_mark_patient_cancellation_pending_sync
  on public.appointments;
create trigger z_mark_patient_cancellation_pending_sync
  before update of status on public.appointments
  for each row execute function public.mark_patient_cancellation_pending_sync();

comment on function public.mark_patient_cancellation_pending_sync() is
  'Marks a patient cancellation queued until the existing integration outbox records delivery.';

commit;
