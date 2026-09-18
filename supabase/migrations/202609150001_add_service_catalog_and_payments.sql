-- Add the Dawa Mom service/pricing boundary and payment ledger.
-- Prices are server authoritative; appointment rows retain immutable snapshots.

begin;

create table if not exists public.service_catalog (
  id uuid primary key default extensions.gen_random_uuid(),
  external_service_id text,
  external_clinic_id text,
  name text not null,
  description text,
  category text,
  is_paid boolean not null default false,
  price numeric(12,2) not null default 0,
  currency text not null default 'ZMW',
  is_active boolean not null default true,
  source text not null default 'manual',
  source_updated_at timestamptz,
  synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_catalog_name_check check (length(trim(name)) between 2 and 160),
  constraint service_catalog_price_check check (price >= 0),
  constraint service_catalog_paid_price_check check (
    (is_paid and price > 0) or (not is_paid and price = 0)
  ),
  constraint service_catalog_currency_check check (currency ~ '^[A-Z]{3}$'),
  constraint service_catalog_source_check check (source in ('manual', 'clinician_sync')),
  constraint service_catalog_external_id_check check (
    external_service_id is null or length(trim(external_service_id)) between 1 and 240
  )
);

create unique index if not exists service_catalog_external_id_uidx
  on public.service_catalog(external_service_id);

create index if not exists service_catalog_active_idx
  on public.service_catalog(is_active, name);

create index if not exists service_catalog_clinic_idx
  on public.service_catalog(external_clinic_id, is_active)
  where external_clinic_id is not null;

drop trigger if exists set_service_catalog_updated_at on public.service_catalog;
create trigger set_service_catalog_updated_at
  before update on public.service_catalog
  for each row execute function public.set_updated_at();

alter table public.service_catalog enable row level security;
revoke all on table public.service_catalog from anon;

drop policy if exists service_catalog_read_active on public.service_catalog;
create policy service_catalog_read_active
  on public.service_catalog
  for select
  to authenticated
  using (is_active);

drop policy if exists service_catalog_admin_manage on public.service_catalog;
create policy service_catalog_admin_manage
  on public.service_catalog
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

insert into public.service_catalog (
  external_service_id,
  name,
  description,
  category,
  is_paid,
  price,
  currency,
  source
) values (
  'dawa-mom-general-consultation',
  'General consultation',
  'General DawaMom appointment service.',
  'consultation',
  false,
  0,
  'ZMW',
  'manual'
)
on conflict (external_service_id) do nothing;

alter table public.appointments
  add column if not exists service_id uuid references public.service_catalog(id) on delete restrict,
  add column if not exists external_service_id_snapshot text,
  add column if not exists service_name_snapshot text,
  add column if not exists is_paid_snapshot boolean not null default false,
  add column if not exists price_snapshot numeric(12,2) not null default 0,
  add column if not exists currency_snapshot text not null default 'ZMW';

update public.appointments appointment
set service_id = service.id,
    external_service_id_snapshot = service.external_service_id,
    service_name_snapshot = service.name,
    is_paid_snapshot = service.is_paid,
    price_snapshot = service.price,
    currency_snapshot = service.currency
from public.service_catalog service
where service.external_service_id = 'dawa-mom-general-consultation'
  and appointment.service_id is null;

alter table public.appointments
  alter column service_id set not null;

alter table public.appointments
  add constraint appointments_price_snapshot_check check (price_snapshot >= 0),
  add constraint appointments_paid_price_snapshot_check check (
    is_paid_snapshot or price_snapshot = 0
  ),
  add constraint appointments_currency_snapshot_check check (
    currency_snapshot ~ '^[A-Z]{3}$'
  );

create index if not exists appointments_service_idx
  on public.appointments(service_id, created_at desc);

create table if not exists public.payments (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  appointment_id uuid not null references public.appointments(id) on delete restrict,
  service_id uuid not null references public.service_catalog(id) on delete restrict,
  external_service_id text,
  amount numeric(12,2) not null,
  currency text not null,
  phone_number text not null,
  payment_method text not null default 'mobile_money',
  provider text not null default 'lipila',
  status text not null default 'created',
  reference_id text not null unique,
  provider_identifier text,
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz,
  failed_at timestamptz,
  constraint payments_amount_check check (amount > 0),
  constraint payments_currency_check check (currency ~ '^[A-Z]{3}$'),
  constraint payments_status_check check (
    status in ('created', 'pending', 'successful', 'failed', 'cancelled', 'expired')
  ),
  constraint payments_method_check check (payment_method = 'mobile_money'),
  constraint payments_provider_check check (provider = 'lipila')
);

create unique index if not exists payments_one_active_per_appointment_uidx
  on public.payments(appointment_id)
  where status in ('created', 'pending', 'successful');

create index if not exists payments_user_created_idx
  on public.payments(user_id, created_at desc);

create index if not exists payments_status_idx
  on public.payments(status, updated_at);

drop trigger if exists set_payments_updated_at on public.payments;
create trigger set_payments_updated_at
  before update on public.payments
  for each row execute function public.set_updated_at();

create table if not exists public.payment_events (
  id uuid primary key default extensions.gen_random_uuid(),
  payment_id uuid references public.payments(id) on delete cascade,
  webhook_id text not null,
  event_type text not null,
  provider text not null default 'lipila',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint payment_events_webhook_unique unique (provider, webhook_id),
  constraint payment_events_payload_object_check check (jsonb_typeof(payload) = 'object')
);

alter table public.payments enable row level security;
alter table public.payment_events enable row level security;
revoke all on table public.payment_events from anon, authenticated;

drop policy if exists payments_select_owner on public.payments;
create policy payments_select_owner
  on public.payments
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists payments_admin_read on public.payments;
create policy payments_admin_read
  on public.payments
  for select
  to authenticated
  using (public.is_admin());

create or replace function public.apply_service_catalog_sync(
  p_external_service_id text,
  p_external_clinic_id text,
  p_name text,
  p_description text,
  p_category text,
  p_is_paid boolean,
  p_price numeric,
  p_currency text,
  p_is_active boolean,
  p_source_updated_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing public.service_catalog%rowtype;
  result_row public.service_catalog%rowtype;
  normalized_id text := nullif(trim(p_external_service_id), '');
  normalized_currency text := upper(trim(coalesce(p_currency, 'ZMW')));
begin
  if normalized_id is null or length(normalized_id) > 240 then
    raise exception using errcode = '22023', message = 'A valid external service ID is required';
  end if;
  if length(trim(coalesce(p_name, ''))) < 2 then
    raise exception using errcode = '22023', message = 'A valid service name is required';
  end if;
  if p_price is null or p_price < 0 or (not coalesce(p_is_paid, false) and p_price <> 0) then
    raise exception using errcode = '22023', message = 'Invalid service price';
  end if;
  if normalized_currency !~ '^[A-Z]{3}$' then
    raise exception using errcode = '22023', message = 'Invalid service currency';
  end if;
  if p_source_updated_at is null then
    raise exception using errcode = '22023', message = 'source_updated_at is required';
  end if;

  select * into existing
  from public.service_catalog
  where external_service_id = normalized_id
  for update;

  if existing.id is not null
     and existing.source_updated_at is not null
     and p_source_updated_at <= existing.source_updated_at then
    return jsonb_build_object(
      'ok', true,
      'updated', false,
      'stale', true,
      'service_id', existing.id,
      'external_service_id', existing.external_service_id,
      'source_updated_at', existing.source_updated_at
    );
  end if;

  insert into public.service_catalog (
    external_service_id,
    external_clinic_id,
    name,
    description,
    category,
    is_paid,
    price,
    currency,
    is_active,
    source,
    source_updated_at,
    synced_at
  ) values (
    normalized_id,
    nullif(trim(p_external_clinic_id), ''),
    trim(p_name),
    nullif(trim(p_description), ''),
    nullif(trim(p_category), ''),
    coalesce(p_is_paid, false),
    p_price,
    normalized_currency,
    coalesce(p_is_active, false),
    'clinician_sync',
    p_source_updated_at,
    now()
  )
  on conflict (external_service_id) do update set
    external_clinic_id = excluded.external_clinic_id,
    name = excluded.name,
    description = excluded.description,
    category = excluded.category,
    is_paid = excluded.is_paid,
    price = excluded.price,
    currency = excluded.currency,
    is_active = excluded.is_active,
    source = excluded.source,
    source_updated_at = excluded.source_updated_at,
    synced_at = excluded.synced_at
  returning * into result_row;

  return jsonb_build_object(
    'ok', true,
    'updated', true,
    'stale', false,
    'service_id', result_row.id,
    'external_service_id', result_row.external_service_id,
    'is_active', result_row.is_active,
    'source_updated_at', result_row.source_updated_at
  );
end;
$$;

revoke all on function public.apply_service_catalog_sync(
  text, text, text, text, text, boolean, numeric, text, boolean, timestamptz
) from public, anon, authenticated;
grant execute on function public.apply_service_catalog_sync(
  text, text, text, text, text, boolean, numeric, text, boolean, timestamptz
) to service_role;

create or replace function public.release_paid_appointment_workflow(
  p_payment_id uuid,
  p_webhook_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  payment_row public.payments%rowtype;
  appointment_row public.appointments%rowtype;
begin
  select * into payment_row
  from public.payments
  where id = p_payment_id
  for update;
  if payment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Payment was not found';
  end if;
  if payment_row.status <> 'successful' then
    raise exception using errcode = '23514', message = 'Payment is not successful';
  end if;

  select * into appointment_row
  from public.appointments
  where id = payment_row.appointment_id
  for update;
  if appointment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment was not found';
  end if;
  if not appointment_row.is_paid_snapshot then
    raise exception using errcode = '23514', message = 'Appointment is not paid';
  end if;

  perform set_config('dawa.integration_transition', 'allowed', true);

  insert into public.integration_outbox (
    event_type,
    aggregate_type,
    aggregate_id,
    payload
  )
  select
    'appointment.created',
    'appointment',
    appointment_row.id,
    jsonb_strip_nulls(jsonb_build_object(
      'source', 'dawa_mom',
      'source_appointment_id', appointment_row.id,
      'source_mother_id', appointment_row.mother_id,
      'dawa_clinician_patient_id', mother.dawa_clinician_patient_id,
      'dawa_clinician_clinician_id', doctor.dawa_clinician_clinician_id,
      'dawa_clinician_clinic_id', clinic.dawa_clinician_clinic_id,
      'appointment_date', appointment_row.appointment_date,
      'start_time', appointment_row.start_time,
      'end_time', appointment_row.end_time,
      'appointment_type', appointment_row.appointment_type,
      'reason', appointment_row.reason,
      'notes', appointment_row.notes,
      'status', appointment_row.status,
      'service_id', appointment_row.service_id,
      'external_service_id', appointment_row.external_service_id_snapshot,
      'price', appointment_row.price_snapshot,
      'currency', appointment_row.currency_snapshot,
      'created_at', appointment_row.created_at,
      'updated_at', appointment_row.updated_at
    ))
  from public.mothers mother
  join public.doctors doctor on doctor.id = appointment_row.clinician_id
  join public.clinics clinic on clinic.id = appointment_row.clinic_id
  where not exists (
    select 1 from public.integration_outbox queued
    where queued.event_type = 'appointment.created'
      and queued.aggregate_type = 'appointment'
      and queued.aggregate_id = appointment_row.id
  );

  insert into public.appointment_email_outbox (
    appointment_id,
    recipient_kind,
    template_key
  ) values
    (appointment_row.id, 'patient', 'appointment_requested'),
    (appointment_row.id, 'clinician', 'appointment_requested')
  on conflict (appointment_id, recipient_kind, template_key) do nothing;

  return jsonb_build_object(
    'ok', true,
    'appointment_id', appointment_row.id,
    'payment_id', payment_row.id,
    'released', true,
    'webhook_id', p_webhook_id
  );
end;
$$;

revoke all on function public.release_paid_appointment_workflow(uuid, text)
  from public, anon, authenticated;
grant execute on function public.release_paid_appointment_workflow(uuid, text)
  to service_role;

create or replace function public.book_dawa_mom_appointment(
  p_clinic_id uuid,
  p_clinician_id uuid,
  p_appointment_date date,
  p_start_time time without time zone,
  p_end_time time without time zone,
  p_appointment_type text,
  p_reason text,
  p_notes text,
  p_idempotency_key uuid,
  p_service_id uuid
)
returns public.appointments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  profile_id uuid := auth.uid();
  mother_id uuid;
  selected_service public.service_catalog%rowtype;
  existing public.appointments;
  result_row public.appointments;
  local_now timestamp without time zone := timezone('Africa/Lusaka', now());
begin
  if profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;
  if p_idempotency_key is null then
    raise exception using errcode = '23514', message = 'An idempotency key is required';
  end if;

  select * into existing
  from public.appointments
  where patient_id = profile_id
    and client_idempotency_key = p_idempotency_key;
  if found then return existing; end if;

  select * into selected_service
  from public.service_catalog
  where id = coalesce(
    p_service_id,
    (select id from public.service_catalog
     where external_service_id = 'dawa-mom-general-consultation'
       and is_active limit 1)
  );
  if selected_service.id is null or not selected_service.is_active then
    raise exception using errcode = '23514', message = 'Service is not available';
  end if;
  if p_appointment_date is null or p_start_time is null or p_end_time is null
     or p_end_time <= p_start_time
     or (p_appointment_date + p_start_time) <= local_now then
    raise exception using errcode = '23514', message = 'Appointment time is invalid';
  end if;
  if length(trim(coalesce(p_appointment_type, ''))) < 2
     or length(trim(coalesce(p_appointment_type, ''))) > 80
     or length(coalesce(p_reason, '')) > 500
     or length(coalesce(p_notes, '')) > 1000 then
    raise exception using errcode = '23514', message = 'Appointment details are invalid';
  end if;

  select mother_row.id into mother_id
  from public.mothers mother_row
  where mother_row.profile_id = profile_id;
  if mother_id is null then
    raise exception using errcode = '23514', message = 'A health profile is required';
  end if;
  if not exists (
    select 1 from public.doctors
    where doctors.id = p_clinician_id
      and doctors.clinic_id = p_clinic_id
      and doctors.is_active and doctors.is_bookable
  ) then
    raise exception using errcode = '23514', message = 'Clinician is not bookable at this clinic';
  end if;

  begin
    insert into public.appointments (
      mother_id, patient_id, clinician_id, clinic_id, appointment_date,
      start_time, end_time, appointment_type, reason, notes, status, source,
      created_by, integration_status, client_idempotency_key, service_id,
      external_service_id_snapshot, service_name_snapshot, is_paid_snapshot,
      price_snapshot, currency_snapshot
    ) values (
      mother_id, profile_id, p_clinician_id, p_clinic_id, p_appointment_date,
      p_start_time, p_end_time, trim(p_appointment_type),
      nullif(trim(coalesce(p_reason, '')), ''),
      nullif(trim(coalesce(p_notes, '')), ''), 'pending', 'dawa_mom',
      profile_id, 'pending', p_idempotency_key, selected_service.id,
      selected_service.external_service_id, selected_service.name,
      selected_service.is_paid, selected_service.price, selected_service.currency
    ) returning * into result_row;
  exception when unique_violation then
    select * into existing from public.appointments
    where patient_id = profile_id and client_idempotency_key = p_idempotency_key;
    if found then return existing; end if;
    raise exception using errcode = '23505', message = 'The selected appointment time is no longer available';
  end;
  return result_row;
end;
$$;

revoke all on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid
) from public, anon;
grant execute on function public.book_dawa_mom_appointment(
  uuid, uuid, date, time without time zone, time without time zone,
  text, text, text, uuid, uuid
) to authenticated;

create or replace function public.create_lipila_payment(
  p_appointment_id uuid,
  p_phone_number text
)
returns public.payments
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  profile_id uuid := auth.uid();
  appointment_row public.appointments%rowtype;
  existing public.payments;
  normalized_phone text := regexp_replace(coalesce(p_phone_number, ''), '[^0-9+]', '', 'g');
  payment_row public.payments;
begin
  if profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;
  normalized_phone := regexp_replace(normalized_phone, '^00', '');
  if normalized_phone like '0%' then normalized_phone := '260' || substr(normalized_phone, 2); end if;
  if normalized_phone !~ '^260[0-9]{9}$' then
    raise exception using errcode = '22023', message = 'A valid Zambian mobile number is required';
  end if;

  select * into appointment_row
  from public.appointments
  where id = p_appointment_id and patient_id = profile_id
  for update;
  if appointment_row.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment was not found';
  end if;
  if not appointment_row.is_paid_snapshot or appointment_row.price_snapshot <= 0 then
    raise exception using errcode = '23514', message = 'This appointment does not require payment';
  end if;
  if appointment_row.status in ('cancelled', 'declined', 'completed', 'missed') then
    raise exception using errcode = '23514', message = 'This appointment cannot be paid';
  end if;

  select * into existing from public.payments
  where appointment_id = appointment_row.id
    and status in ('created', 'pending', 'successful')
  order by created_at desc limit 1;
  if found then return existing; end if;

  insert into public.payments (
    user_id, appointment_id, service_id, external_service_id,
    amount, currency, phone_number, status, reference_id
  ) values (
    profile_id, appointment_row.id, appointment_row.service_id,
    appointment_row.external_service_id_snapshot, appointment_row.price_snapshot,
    appointment_row.currency_snapshot, normalized_phone, 'created',
    'dawa-' || replace(gen_random_uuid()::text, '-', '')
  ) returning * into payment_row;
  return payment_row;
end;
$$;

revoke all on function public.create_lipila_payment(uuid, text) from public, anon;
grant execute on function public.create_lipila_payment(uuid, text) to authenticated;

-- The booking RPC owns these snapshots. Existing callers remain compatible by
-- resolving the seeded manual service when they do not supply one explicitly.
create or replace function public.apply_service_snapshot_to_appointment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_service public.service_catalog%rowtype;
begin
  if new.service_id is null then
    select * into selected_service
    from public.service_catalog
    where external_service_id = 'dawa-mom-general-consultation'
      and is_active
    limit 1;
    if selected_service.id is null then
      raise exception using errcode = 'P0002', message = 'Default service is unavailable';
    end if;
    new.service_id := selected_service.id;
  else
    select * into selected_service
    from public.service_catalog
    where id = new.service_id;
  end if;

  if selected_service.id is null or not selected_service.is_active then
    raise exception using errcode = '23514', message = 'Service is not available';
  end if;

  new.external_service_id_snapshot := selected_service.external_service_id;
  new.service_name_snapshot := selected_service.name;
  new.is_paid_snapshot := selected_service.is_paid;
  new.price_snapshot := selected_service.price;
  new.currency_snapshot := selected_service.currency;
  return new;
end;
$$;

drop trigger if exists apply_service_snapshot_to_appointment
  on public.appointments;
create trigger apply_service_snapshot_to_appointment
  before insert on public.appointments
  for each row execute function public.apply_service_snapshot_to_appointment();

revoke all on function public.apply_service_snapshot_to_appointment() from public;

-- Replace the existing appointment integrations after the older migrations have
-- installed them. Paid rows wait for release_paid_appointment_workflow().
create or replace function public.enqueue_dawa_mom_appointment_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.is_paid_snapshot then
    return new;
  end if;
  if tg_op = 'INSERT' then
    insert into public.integration_outbox (
      event_type, aggregate_type, aggregate_id, payload
    ) values (
      'appointment.created', 'appointment', new.id,
      jsonb_strip_nulls(jsonb_build_object(
        'source', 'dawa_mom',
        'source_appointment_id', new.id,
        'source_mother_id', new.mother_id,
        'dawa_clinician_patient_id', (
          select mother.dawa_clinician_patient_id
          from public.mothers mother
          where mother.id = new.mother_id
        ),
        'dawa_clinician_clinician_id', (
          select doctor.dawa_clinician_clinician_id
          from public.doctors doctor
          where doctor.id = new.clinician_id
        ),
        'dawa_clinician_clinic_id', (
          select clinic.dawa_clinician_clinic_id
          from public.clinics clinic
          where clinic.id = new.clinic_id
        ),
        'appointment_date', new.appointment_date,
        'start_time', new.start_time,
        'end_time', new.end_time,
        'appointment_type', new.appointment_type,
        'reason', new.reason,
        'notes', new.notes,
        'status', new.status,
        'service_id', new.service_id,
        'external_service_id', new.external_service_id_snapshot,
        'price', new.price_snapshot,
        'currency', new.currency_snapshot,
        'created_at', new.created_at,
        'updated_at', new.updated_at
      ))
    );
  elsif coalesce(current_setting('dawa.integration_transition', true), '') <> 'allowed'
        and auth.uid() is not null
        and public.current_app_role() = 'patient'::public.app_role
        and old.status is distinct from new.status
        and new.status = 'cancelled' then
    insert into public.integration_outbox (
      event_type, aggregate_type, aggregate_id, payload
    ) values (
      'appointment.cancelled', 'appointment', new.id,
      jsonb_build_object('source', 'dawa_mom', 'source_appointment_id', new.id)
    );
  end if;
  return new;
end;
$$;

create or replace function public.enqueue_appointment_email_jobs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_paid_snapshot then
    return new;
  end if;
  insert into public.appointment_email_outbox (
    appointment_id, recipient_kind, template_key
  ) values
    (new.id, 'patient', 'appointment_requested'),
    (new.id, 'clinician', 'appointment_requested')
  on conflict (appointment_id, recipient_kind, template_key) do nothing;
  return new;
end;
$$;

comment on table public.service_catalog is
  'DawaMom service source of truth. Clinician service IDs are stable external identifiers.';
comment on table public.payments is
  'Server-owned Lipila payment ledger with booking-time amount and currency.';
comment on table public.payment_events is
  'Private append-oriented Lipila webhook event ledger for replay protection and audit.';
comment on column public.appointments.price_snapshot is
  'Immutable commercial amount captured when this appointment was created.';

notify pgrst, 'reload schema';

commit;