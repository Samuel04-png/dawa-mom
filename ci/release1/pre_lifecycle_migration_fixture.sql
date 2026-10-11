\set ON_ERROR_STOP on

-- Synthetic appointments inserted against the baseline through 202609240002.
-- 202610100001 must backfill these rows after this fixture completes.

set session_replication_role = replica;
insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) values (
  '00000000-0000-4000-8000-000000000101',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'release1.legacy@example.test',
  'not-used-in-ci',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
);
set session_replication_role = origin;

insert into public.profiles (id, email, display_name, role, requested_role)
values (
  '00000000-0000-4000-8000-000000000101',
  'release1.legacy@example.test',
  'Release 1 Legacy Patient',
  'patient',
  'patient'
);
insert into public.mothers (id, profile_id, name)
values (
  '00000000-0000-4000-8000-000000000102',
  '00000000-0000-4000-8000-000000000101',
  'Release 1 Legacy Mother'
);
insert into public.clinics (id, name)
values ('00000000-0000-4000-8000-000000000103', 'Release 1 Legacy Clinic');
insert into public.doctors (id, clinic_id, name, is_active, is_bookable)
values (
  '00000000-0000-4000-8000-000000000104',
  '00000000-0000-4000-8000-000000000103',
  'Release 1 Legacy Clinician',
  true,
  true
);
insert into public.service_catalog (
  id, external_service_id, external_clinic_id, name, category,
  is_paid, price, currency, is_active, source
) values (
  '00000000-0000-4000-8000-000000000105',
  'release1-legacy-paid-service',
  'release1-legacy-clinic',
  'Release 1 legacy paid service',
  'test', true, 150.00, 'ZMW', true, 'manual'
);

insert into public.appointments (
  id, mother_id, patient_id, clinician_id, clinic_id, appointment_date,
  start_time, end_time, appointment_type, status, source, created_by,
  integration_status, client_idempotency_key, service_id,
  external_service_id_snapshot, service_name_snapshot, is_paid_snapshot,
  price_snapshot, currency_snapshot, payment_method
) values
  (
    '00000000-0000-4000-8000-000000000106',
    '00000000-0000-4000-8000-000000000102',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000104',
    '00000000-0000-4000-8000-000000000103',
    current_date + 30, time '09:00', time '09:30', 'legacy paid', 'pending',
    'dawa_mom', '00000000-0000-4000-8000-000000000101', 'pending',
    '00000000-0000-4000-8000-000000000111',
    '00000000-0000-4000-8000-000000000105',
    'release1-legacy-paid-service', 'Release 1 legacy paid service', true,
    150.00, 'ZMW', 'online'
  ),
  (
    '00000000-0000-4000-8000-000000000107',
    '00000000-0000-4000-8000-000000000102',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000104',
    '00000000-0000-4000-8000-000000000103',
    current_date + 30, time '10:00', time '10:30', 'legacy pending', 'pending',
    'dawa_mom', '00000000-0000-4000-8000-000000000101', 'pending',
    '00000000-0000-4000-8000-000000000112',
    '00000000-0000-4000-8000-000000000105',
    'release1-legacy-paid-service', 'Release 1 legacy paid service', true,
    150.00, 'ZMW', 'online'
  ),
  (
    '00000000-0000-4000-8000-000000000108',
    '00000000-0000-4000-8000-000000000102',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000104',
    '00000000-0000-4000-8000-000000000103',
    current_date + 30, time '11:00', time '11:30', 'legacy confirmed', 'confirmed',
    'dawa_mom', '00000000-0000-4000-8000-000000000101', 'synced',
    '00000000-0000-4000-8000-000000000113',
    '00000000-0000-4000-8000-000000000105',
    'release1-legacy-paid-service', 'Release 1 legacy paid service', true,
    150.00, 'ZMW', 'online'
  );

insert into public.payments (
  id, user_id, appointment_id, service_id, external_service_id, amount,
  currency, phone_number, status, reference_id
) values (
  '00000000-0000-4000-8000-000000000109',
  '00000000-0000-4000-8000-000000000101',
  '00000000-0000-4000-8000-000000000107',
  '00000000-0000-4000-8000-000000000105',
  'release1-legacy-paid-service',
  150.00, 'ZMW', '260977000000', 'pending', 'release1-legacy-pending'
);
