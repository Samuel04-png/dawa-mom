-- Transactional appointment RLS verification.
-- Run as a project database owner after all migrations. The transaction is
-- rolled back, so no test patient data remains.

begin;

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'appointments-owner@example.invalid',
    extensions.crypt(
      'not-a-real-password',
      extensions.gen_salt('bf')
    ),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'appointments-non-owner@example.invalid',
    extensions.crypt(
      'not-a-real-password',
      extensions.gen_salt('bf')
    ),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

insert into public.mothers (id, profile_id, name)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Appointment Owner'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Appointment Non Owner'
  );

insert into public.clinics (id, name)
values ('30000000-0000-0000-0000-000000000001', 'RLS Test Clinic');

insert into public.doctors (
  id,
  clinic_id,
  name,
  is_active,
  is_bookable,
  start_time,
  end_time
) values (
  '40000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  'RLS Test Clinician',
  true,
  true,
  '08:00',
  '16:00'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

-- Authenticated owner insert must succeed.
insert into public.appointments (
  id,
  mother_id,
  patient_id,
  clinician_id,
  clinic_id,
  appointment_date,
  start_time,
  end_time,
  status,
  source,
  created_by,
  integration_status
) values (
  '50000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  '2099-01-10',
  '09:00',
  '09:30',
  'pending',
  'dawa_mom',
  '10000000-0000-0000-0000-000000000001',
  'pending'
);

do $$
begin
  if (select count(*) from public.appointments) <> 1 then
    raise exception 'Owner could not read the owned appointment';
  end if;
end;
$$;

-- A patient may not change schedule fields while cancelling.
do $$
begin
  begin
    update public.appointments
    set status = 'cancelled', start_time = '10:00', end_time = '10:30'
    where id = '50000000-0000-0000-0000-000000000001';
    raise exception 'Owner schedule mutation unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

-- An eligible owner cancellation must succeed.
update public.appointments
set status = 'cancelled'
where id = '50000000-0000-0000-0000-000000000001';

-- Authenticated non-owner cannot read or create against the owner's mother row.
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  true
);

do $$
begin
  if (select count(*) from public.appointments) <> 0 then
    raise exception 'Non-owner could read another patient appointment';
  end if;

  begin
    insert into public.appointments (
      mother_id,
      patient_id,
      clinician_id,
      clinic_id,
      appointment_date,
      start_time,
      end_time,
      status,
      source,
      created_by,
      integration_status
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000002',
      '40000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001',
      '2099-01-11',
      '09:00',
      '09:30',
      'pending',
      'dawa_mom',
      '10000000-0000-0000-0000-000000000002',
      'pending'
    );
    raise exception 'Non-owner insert unexpectedly succeeded';
  exception
    when insufficient_privilege or check_violation then null;
  end;
end;
$$;

-- Unauthenticated requests cannot read or create appointments.
set local role anon;
select set_config('request.jwt.claim.sub', '', true);

do $$
begin
  if (select count(*) from public.appointments) <> 0 then
    raise exception 'Anonymous request could read appointments';
  end if;

  begin
    insert into public.appointments (
      mother_id,
      patient_id,
      clinician_id,
      clinic_id,
      appointment_date,
      start_time,
      end_time,
      status,
      source,
      created_by,
      integration_status
    ) values (
      '20000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '40000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000001',
      '2099-01-12',
      '09:00',
      '09:30',
      'pending',
      'dawa_mom',
      '10000000-0000-0000-0000-000000000001',
      'pending'
    );
    raise exception 'Anonymous insert unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

reset role;
rollback;
