-- Ensure authenticated mothers can create appointment encounter rows only for
-- their own Supabase mother profile.

begin;

alter table public.encounters enable row level security;

drop policy if exists encounters_insert_patient_appointment
  on public.encounters;

create policy encounters_insert_patient_appointment
  on public.encounters
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.mothers m
      where m.id = mother_id
        and m.profile_id = auth.uid()
    )
    and public.is_patient_appointment_status(status)
  );

comment on policy encounters_insert_patient_appointment
  on public.encounters
  is 'Allows authenticated mothers to create scheduled/canceled appointment encounters only for their own mothers row.';

commit;
