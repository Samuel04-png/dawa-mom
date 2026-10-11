\set ON_ERROR_STOP on

-- This script runs only after the temporary CI stack has applied the selected
-- Release 1 migrations. Every ID, user, clinic, service, booking, payment,
-- and webhook below is synthetic and disposable.

create schema if not exists test_release1;

create or replace function test_release1.assert_true(
  p_condition boolean,
  p_message text
)
returns void
language plpgsql
as $$
begin
  if coalesce(p_condition, false) is not true then
    raise exception using errcode = 'P0001', message = p_message;
  end if;
end;
$$;

-- The fixture deliberately switches to authenticated/service_role below to
-- exercise the real RPC grants and RLS paths. Permit those test-only roles to
-- call the assertion helper; this schema exists only in the disposable CI DB.
grant usage on schema test_release1 to authenticated, service_role;
grant execute on all functions in schema test_release1 to authenticated, service_role;

-- These rows existed before 202610100001 was applied. The migration must not
-- reclassify a private legacy reservation as active, and it must preserve a
-- completed legacy visit as successful.
select test_release1.assert_true(
  (select payment_state = 'not_started' from public.appointments where id = '00000000-0000-4000-8000-000000000106'),
  'legacy paid appointment without a provider record was not backfilled to not_started'
);
select test_release1.assert_true(
  (select payment_state = 'pending' from public.appointments where id = '00000000-0000-4000-8000-000000000107'),
  'legacy paid appointment did not inherit its provider pending state'
);
select test_release1.assert_true(
  (select payment_state = 'successful' from public.appointments where id = '00000000-0000-4000-8000-000000000108'),
  'confirmed legacy paid appointment was not preserved as successful'
);

select test_release1.assert_true(
  to_regclass('public.care_plan_items') is null,
  'Care Plan must not exist in the Release 1 workspace'
);
select test_release1.assert_true(
  to_regprocedure('public.book_dawa_mom_appointment(uuid,uuid,date,time without time zone,time without time zone,text,text,text,uuid,uuid)') is not null,
  'legacy 10-argument booking RPC is missing'
);
select test_release1.assert_true(
  to_regprocedure('public.book_dawa_mom_appointment(uuid,uuid,date,time without time zone,time without time zone,text,text,text,uuid,uuid,text)') is not null,
  '11-argument booking RPC is missing'
);
select test_release1.assert_true(
  to_regprocedure('public.apply_lipila_payment_status(uuid,text,text,text,jsonb,text)') is not null,
  'payment-status RPC is missing'
);
select test_release1.assert_true(
  has_function_privilege(
    'authenticated',
    'public.book_dawa_mom_appointment(uuid,uuid,date,time without time zone,time without time zone,text,text,text,uuid,uuid,text)',
    'EXECUTE'
  ),
  'authenticated users lost booking-RPC execution'
);
select test_release1.assert_true(
  not has_function_privilege(
    'anon',
    'public.apply_lipila_payment_status(uuid,text,text,text,jsonb,text)',
    'EXECUTE'
  ),
  'anonymous users can execute the payment-status RPC'
);
select test_release1.assert_true(
  not has_function_privilege(
    'authenticated',
    'public.apply_lipila_payment_status(uuid,text,text,text,jsonb,text)',
    'EXECUTE'
  ),
  'authenticated users can execute the payment-status RPC'
);

-- Seed an authenticated synthetic patient without invoking network services.
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
  '00000000-0000-4000-8000-000000000011',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'release1.patient@example.test',
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
  '00000000-0000-4000-8000-000000000011',
  'release1.patient@example.test',
  'Release 1 Test Patient',
  'patient',
  'patient'
);
insert into public.mothers (id, profile_id, name)
values (
  '00000000-0000-4000-8000-000000000021',
  '00000000-0000-4000-8000-000000000011',
  'Release 1 Test Mother'
);
insert into public.clinics (id, name)
values ('00000000-0000-4000-8000-000000000031', 'Release 1 Test Clinic');
insert into public.doctors (id, clinic_id, name, is_active, is_bookable)
values (
  '00000000-0000-4000-8000-000000000041',
  '00000000-0000-4000-8000-000000000031',
  'Release 1 Test Clinician',
  true,
  true
);
insert into public.service_catalog (
  id, external_service_id, external_clinic_id, name, category,
  is_paid, price, currency, is_active, source
) values
  (
    '00000000-0000-4000-8000-000000000051',
    'release1-paid-service',
    'release1-test-clinic',
    'Release 1 paid service',
    'test', true, 150.00, 'ZMW', true, 'manual'
  ),
  (
    '00000000-0000-4000-8000-000000000052',
    'release1-free-service',
    'release1-test-clinic',
    'Release 1 free service',
    'test', false, 0, 'ZMW', true, 'manual'
  );

-- The booking and payment RPCs must execute in a patient context, not as the
-- database owner. This exercises auth.uid(), grants, and RLS-compatible paths.
set role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', false);
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000011', false);

select public.book_dawa_mom_appointment(
  '00000000-0000-4000-8000-000000000031',
  '00000000-0000-4000-8000-000000000041',
  current_date + 21,
  time '09:00',
  time '09:30',
  'release1 paid',
  null,
  null,
  '00000000-0000-4000-8000-000000000061',
  '00000000-0000-4000-8000-000000000051',
  'online'
);
select test_release1.assert_true(
  (
    select payment_method = 'online'
      and payment_state = 'not_started'
      and status = 'pending'
    from public.appointments
    where client_idempotency_key = '00000000-0000-4000-8000-000000000061'
  ),
  'new paid online booking did not start as a private not_started reservation'
);

-- Outbox internals are intentionally not readable by a patient. Inspect this
-- server-side invariant as the database owner, then resume the patient path.
reset role;
select test_release1.assert_true(
  not exists (
    select 1
    from public.integration_outbox o
    join public.appointments a on a.id = o.aggregate_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000061'
      and o.event_type = 'appointment.created'
  ),
  'unresolved paid appointment was sent to Dawa Clinician'
);
set role authenticated;

-- The same idempotency key returns the same appointment rather than a second
-- reservation or future charge opportunity.
select public.book_dawa_mom_appointment(
  '00000000-0000-4000-8000-000000000031',
  '00000000-0000-4000-8000-000000000041',
  current_date + 21,
  time '09:00',
  time '09:30',
  'release1 paid',
  null,
  null,
  '00000000-0000-4000-8000-000000000061',
  '00000000-0000-4000-8000-000000000051',
  'online'
);
select test_release1.assert_true(
  (select count(*) = 1 from public.appointments where client_idempotency_key = '00000000-0000-4000-8000-000000000061'),
  'duplicate booking idempotency key created a second appointment'
);

select public.create_lipila_payment(
  (select id from public.appointments where client_idempotency_key = '00000000-0000-4000-8000-000000000061'),
  '0977000000'
);
select test_release1.assert_true(
  (
    select a.payment_state = 'pending' and p.status = 'created'
    from public.appointments a
    join public.payments p on p.appointment_id = a.id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000061'
  ),
  'creating a payment did not keep the appointment pending privately'
);

reset role;
set role service_role;
select public.apply_lipila_payment_status(
  (select id from public.payments where appointment_id = (select id from public.appointments where client_idempotency_key = '00000000-0000-4000-8000-000000000061')),
  'release1-webhook-pending',
  'collection.status.changed',
  'pending',
  '{"state":"pending"}'::jsonb,
  'release1-pending'
);
select public.apply_lipila_payment_status(
  (select id from public.payments where appointment_id = (select id from public.appointments where client_idempotency_key = '00000000-0000-4000-8000-000000000061')),
  'release1-webhook-processing',
  'collection.status.changed',
  'processing',
  '{"state":"processing"}'::jsonb,
  'release1-processing'
);
select test_release1.assert_true(
  not exists (
    select 1
    from public.integration_outbox o
    join public.appointments a on a.id = o.aggregate_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000061'
      and o.event_type = 'appointment.created'
  ),
  'pending or processing payment was sent to Dawa Clinician'
);
select public.apply_lipila_payment_status(
  (select id from public.payments where appointment_id = (select id from public.appointments where client_idempotency_key = '00000000-0000-4000-8000-000000000061')),
  'release1-webhook-success',
  'collection.status.changed',
  'successful',
  '{"state":"successful"}'::jsonb,
  'release1-success'
);
select test_release1.assert_true(
  (
    select a.payment_state = 'successful' and p.status = 'successful'
    from public.appointments a
    join public.payments p on p.appointment_id = a.id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000061'
  ),
  'successful payment did not transition appointment and ledger atomically'
);
select test_release1.assert_true(
  (
    select count(*) = 1
    from public.integration_outbox o
    join public.appointments a on a.id = o.aggregate_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000061'
      and o.event_type = 'appointment.created'
  ),
  'successful payment did not release exactly one Clinician workflow'
);
select public.apply_lipila_payment_status(
  (select id from public.payments where appointment_id = (select id from public.appointments where client_idempotency_key = '00000000-0000-4000-8000-000000000061')),
  'release1-webhook-success',
  'collection.status.changed',
  'successful',
  '{"state":"successful"}'::jsonb,
  'release1-success'
);
select test_release1.assert_true(
  (
    select count(*) = 1
    from public.integration_outbox o
    join public.appointments a on a.id = o.aggregate_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000061'
      and o.event_type = 'appointment.created'
  ),
  'duplicate successful webhook released a second Clinician workflow'
);

-- Each terminal failure state cancels the private reservation and never
-- creates a Clinician appointment event.
create temporary table test_release1_terminal_cases (
  payment_status text primary key,
  slot time without time zone,
  idempotency_key uuid,
  webhook_id text
);
insert into test_release1_terminal_cases values
  ('failed', time '10:00', '00000000-0000-4000-8000-000000000062', 'release1-webhook-failed'),
  ('expired', time '11:00', '00000000-0000-4000-8000-000000000063', 'release1-webhook-expired'),
  ('cancelled', time '12:00', '00000000-0000-4000-8000-000000000064', 'release1-webhook-cancelled');
grant select on test_release1_terminal_cases to authenticated;

reset role;
set role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', false);
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000011', false);

do $$
declare
  c record;
  appointment_id uuid;
begin
  for c in select * from test_release1_terminal_cases loop
    select (public.book_dawa_mom_appointment(
      '00000000-0000-4000-8000-000000000031',
      '00000000-0000-4000-8000-000000000041',
      current_date + 21,
      c.slot,
      c.slot + interval '30 minutes',
      'release1 terminal',
      null,
      null,
      c.idempotency_key,
      '00000000-0000-4000-8000-000000000051',
      'online'
    )).id into appointment_id;
    perform public.create_lipila_payment(appointment_id, '0977000000');
  end loop;
end;
$$;

reset role;
set role service_role;
do $$
declare
  c record;
  payment_id uuid;
begin
  for c in select * from test_release1_terminal_cases loop
    select p.id into payment_id
    from public.payments p
    join public.appointments a on a.id = p.appointment_id
    where a.client_idempotency_key = c.idempotency_key;
    perform public.apply_lipila_payment_status(
      payment_id,
      c.webhook_id,
      'collection.status.changed',
      c.payment_status,
      jsonb_build_object('state', c.payment_status),
      'release1-' || c.payment_status
    );
  end loop;
end;
$$;
select test_release1.assert_true(
  not exists (
    select 1
    from test_release1_terminal_cases c
    join public.appointments a on a.client_idempotency_key = c.idempotency_key
    join public.payments p on p.appointment_id = a.id
    where a.status <> 'cancelled' or a.payment_state <> c.payment_status or p.status <> c.payment_status
  ),
  'failed, expired, or cancelled payment left an active appointment'
);
select test_release1.assert_true(
  not exists (
    select 1
    from test_release1_terminal_cases c
    join public.appointments a on a.client_idempotency_key = c.idempotency_key
    join public.integration_outbox o on o.aggregate_id = a.id
    where o.event_type = 'appointment.created'
  ),
  'failed, expired, or cancelled payment synchronized to Dawa Clinician'
);

-- A success that arrives after a terminal state remains held for reconciliation
-- and still cannot release scheduling.
select public.apply_lipila_payment_status(
  (
    select p.id
    from public.payments p
    join public.appointments a on a.id = p.appointment_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000064'
  ),
  'release1-webhook-late-success',
  'collection.status.changed',
  'successful',
  '{"state":"late-success"}'::jsonb,
  'release1-late-success'
);
select test_release1.assert_true(
  (
    select a.payment_state = 'reconciliation_required'
      and p.status = 'reconciliation_required'
    from public.appointments a
    join public.payments p on p.appointment_id = a.id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000064'
  ),
  'late successful payment was not held for reconciliation'
);
select test_release1.assert_true(
  not exists (
    select 1
    from public.integration_outbox o
    join public.appointments a on a.id = o.aggregate_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000064'
      and o.event_type = 'appointment.created'
  ),
  'late success released a Clinician workflow before reconciliation'
);

-- Cash and free appointments remain available and cancel through the existing
-- queue. The Release 1 cancellation trigger must mark that queue state.
reset role;
set role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', false);
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000011', false);
select public.book_dawa_mom_appointment(
  '00000000-0000-4000-8000-000000000031',
  '00000000-0000-4000-8000-000000000041',
  current_date + 21,
  time '13:00',
  time '13:30',
  'release1 cash',
  null,
  null,
  '00000000-0000-4000-8000-000000000065',
  '00000000-0000-4000-8000-000000000051',
  'cash'
);
select test_release1.assert_true(
  (
    select payment_state = 'pay_at_clinic'
    from public.appointments
    where client_idempotency_key = '00000000-0000-4000-8000-000000000065'
  ),
  'pay-at-clinic appointment did not retain its supported payment state'
);
update public.appointments
set status = 'cancelled'
where client_idempotency_key = '00000000-0000-4000-8000-000000000065';
select test_release1.assert_true(
  (
    select integration_status = 'queued'
    from public.appointments
    where client_idempotency_key = '00000000-0000-4000-8000-000000000065'
  ),
  'patient cancellation was not marked queued for Clinician synchronization'
);
select test_release1.assert_true(
  exists (
    select 1
    from public.integration_outbox o
    join public.appointments a on a.id = o.aggregate_id
    where a.client_idempotency_key = '00000000-0000-4000-8000-000000000065'
      and o.event_type = 'appointment.cancelled'
  ),
  'patient cancellation did not enqueue a Clinician cancellation event'
);
select public.book_dawa_mom_appointment(
  '00000000-0000-4000-8000-000000000031',
  '00000000-0000-4000-8000-000000000041',
  current_date + 21,
  time '14:00',
  time '14:30',
  'release1 free',
  null,
  null,
  '00000000-0000-4000-8000-000000000066',
  '00000000-0000-4000-8000-000000000052',
  'online'
);
select test_release1.assert_true(
  (
    select payment_state = 'not_required'
    from public.appointments
    where client_idempotency_key = '00000000-0000-4000-8000-000000000066'
  ),
  'free appointment was incorrectly sent through the payment lifecycle'
);

-- Existing 10-argument clients now delegate safely to the hardened overload.
select public.book_dawa_mom_appointment(
  '00000000-0000-4000-8000-000000000031',
  '00000000-0000-4000-8000-000000000041',
  current_date + 21,
  time '15:00',
  time '15:30',
  'release1 legacy',
  null,
  null,
  '00000000-0000-4000-8000-000000000067',
  '00000000-0000-4000-8000-000000000051'
);
select test_release1.assert_true(
  (
    select payment_method = 'online' and payment_state = 'not_started'
    from public.appointments
    where client_idempotency_key = '00000000-0000-4000-8000-000000000067'
  ),
  'legacy booking RPC bypassed the secure initial payment state'
);

-- RLS must prevent a different authenticated identity from reading the first
-- patient’s payment record.
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000012', false);
select test_release1.assert_true(
  (select count(*) = 0 from public.payments),
  'payment RLS exposed a patient payment to a different authenticated user'
);

reset role;
set role service_role;
do $$
begin
  update public.appointments
  set payment_state = 'not-a-valid-state'
  where client_idempotency_key = '00000000-0000-4000-8000-000000000061';
  raise exception 'payment_state constraint did not reject invalid data';
exception
  when check_violation then null;
end;
$$;

reset role;
drop schema test_release1 cascade;
