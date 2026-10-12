-- Secure, additive reward-voucher lifecycle.
--
-- Deployment gate: do not apply this migration until the Dawa Clinician
-- receiver described in supabase/DAWA_CLINICIAN_WEBHOOK.md is deployed with a
-- directional secret and authorised staff verification. This file does not
-- grant Flutter a way to redeem a voucher at a clinic.
--
-- Rollback: disable the receiver and revoke execute from the new RPCs. Keep
-- the audit records: deleting them would remove single-use redemption proof.

begin;

alter table public.dawa_mom_reward_redemptions
  add column if not exists claim_id uuid,
  add column if not exists claim_reference text,
  add column if not exists status text not null default 'claimed',
  add column if not exists claimed_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists cancelled_at timestamptz,
  add column if not exists redeemed_by_clinic_id text,
  add column if not exists redeemed_by_clinician_id text,
  add column if not exists redemption_event_id uuid;

-- The previous schema used redeemed_at as an issuance timestamp. Preserve it
-- as the claim time instead of treating every historic voucher as redeemed.
alter table public.dawa_mom_reward_redemptions
  alter column redeemed_at drop not null;

update public.dawa_mom_reward_redemptions
set claim_id = coalesce(claim_id, extensions.gen_random_uuid()),
    claim_reference = coalesce(
      claim_reference,
      'DAWA-' || upper(substr(replace(extensions.gen_random_uuid()::text, '-', ''), 1, 12))
    ),
    claimed_at = coalesce(claimed_at, redeemed_at, now()),
    redeemed_at = null,
    status = case
      when status in ('claimed', 'redeemed', 'expired', 'cancelled') then status
      else 'claimed'
    end;

alter table public.dawa_mom_reward_redemptions
  alter column claim_id set not null,
  alter column claim_reference set not null,
  alter column claimed_at set not null;

-- Keep the deployed legacy RPC operational during a rolling client release.
-- New clients call claim_dawa_mom_reward without a client supplied cost; the
-- defaults below prevent an older client from creating an unusable row.
alter table public.dawa_mom_reward_redemptions
  alter column claim_id set default extensions.gen_random_uuid(),
  alter column claim_reference set default (
    'DAWA-' || upper(substr(replace(extensions.gen_random_uuid()::text, '-', ''), 1, 12))
  ),
  alter column claimed_at set default now();

create unique index if not exists dawa_mom_reward_redemptions_claim_id_uidx
  on public.dawa_mom_reward_redemptions(claim_id);
create unique index if not exists dawa_mom_reward_redemptions_claim_reference_uidx
  on public.dawa_mom_reward_redemptions(claim_reference);
create unique index if not exists dawa_mom_reward_redemptions_event_uidx
  on public.dawa_mom_reward_redemptions(redemption_event_id)
  where redemption_event_id is not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'dawa_mom_reward_redemptions_status_check'
      and conrelid = 'public.dawa_mom_reward_redemptions'::regclass
  ) then
    alter table public.dawa_mom_reward_redemptions
      add constraint dawa_mom_reward_redemptions_status_check check (
        status in ('claimed', 'redeemed', 'expired', 'cancelled')
      );
  end if;
end $$;

create table if not exists public.dawa_mom_voucher_redemption_events (
  event_id uuid primary key,
  redemption_id uuid not null references public.dawa_mom_reward_redemptions(id)
    on delete restrict,
  clinician_event_id text not null,
  clinic_id text not null,
  clinician_id text not null,
  external_service_id text not null,
  redeemed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.dawa_mom_voucher_redemption_events enable row level security;
revoke all on table public.dawa_mom_voucher_redemption_events
  from anon, authenticated;

-- A voucher is redeemable only against a real, approved clinic-service pair.
-- This table intentionally starts empty: product/clinic operations must enter
-- the verified Dawa Clinician IDs before any claim can be redeemed. It avoids
-- inventing an eligible clinic or service in application code.
create table if not exists public.dawa_mom_voucher_eligibility (
  reward_code text not null,
  clinic_id text not null,
  external_service_id text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (reward_code, clinic_id, external_service_id)
);

alter table public.dawa_mom_voucher_eligibility enable row level security;
revoke all on table public.dawa_mom_voucher_eligibility from anon, authenticated;

-- New claims deliberately accept no point-cost parameter. The server retains
-- the existing 1,000-point clinic scan voucher policy and locks the balance
-- update together with voucher issuance.
create or replace function public.claim_dawa_mom_reward(
  p_reward_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile_id uuid := auth.uid();
  v_expected_cost integer;
  v_balance integer;
  v_redemption public.dawa_mom_reward_redemptions%rowtype;
begin
  if v_profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;

  v_expected_cost := case p_reward_code
    when 'free_scan_voucher' then 1000
    else null
  end;
  if v_expected_cost is null then
    raise exception using errcode = '23514', message = 'Reward selection is invalid';
  end if;

  select * into v_redemption
  from public.dawa_mom_reward_redemptions
  where profile_id = v_profile_id and reward_code = p_reward_code
  for update;

  if found then
    select coin_balance into v_balance
    from public.dawa_mom_learning_state
    where profile_id = v_profile_id;
    return jsonb_build_object(
      'id', v_redemption.id,
      'claim_id', v_redemption.claim_id,
      'claim_reference', v_redemption.claim_reference,
      'voucher_code', v_redemption.voucher_code,
      'reward_code', v_redemption.reward_code,
      'status', v_redemption.status,
      'expires_at', v_redemption.expires_at,
      'coin_balance', coalesce(v_balance, 0),
      'already_redeemed', true
    );
  end if;

  insert into public.dawa_mom_learning_state(profile_id)
  values (v_profile_id)
  on conflict (profile_id) do nothing;

  update public.dawa_mom_learning_state
  set coin_balance = coin_balance - v_expected_cost
  where profile_id = v_profile_id and coin_balance >= v_expected_cost
  returning coin_balance into v_balance;
  if v_balance is null then
    raise exception using errcode = '23514', message = 'Not enough reward points';
  end if;

  insert into public.dawa_mom_reward_redemptions (
    profile_id, reward_code, coin_cost, voucher_code, claim_id,
    claim_reference, status, claimed_at, redeemed_at
  ) values (
    v_profile_id,
    p_reward_code,
    v_expected_cost,
    'DAWA-' || upper(substr(replace(extensions.gen_random_uuid()::text, '-', ''), 1, 12)),
    extensions.gen_random_uuid(),
    'DAWA-' || upper(substr(replace(extensions.gen_random_uuid()::text, '-', ''), 1, 12)),
    'claimed', now(), null
  ) returning * into v_redemption;

  return jsonb_build_object(
    'id', v_redemption.id,
    'claim_id', v_redemption.claim_id,
    'claim_reference', v_redemption.claim_reference,
    -- The QR payload is an identifier, not an authorisation credential. The
    -- receiving Clinician service must verify its own staff session and the
    -- patient before calling the service-only redemption RPC below.
    'qr_payload', 'dawa-mom://voucher/' || v_redemption.claim_id::text ||
      '?ref=' || v_redemption.claim_reference,
    'voucher_code', v_redemption.voucher_code,
    'reward_code', v_redemption.reward_code,
    'status', v_redemption.status,
    'expires_at', v_redemption.expires_at,
    'coin_balance', v_balance,
    'already_redeemed', false
  );
end;
$$;

-- Only the authenticated Dawa Clinician receiver may call this function via
-- Dawa Mom's service role. A patient session can never redeem a voucher.
-- Remove the earlier five-argument draft if it exists: keeping it as a
-- PostgreSQL overload would let a server caller bypass clinic-service
-- eligibility during a rolling function release.
drop function if exists public.redeem_dawa_mom_reward_voucher(
  uuid, uuid, text, text, text
);
create or replace function public.redeem_dawa_mom_reward_voucher(
  p_event_id uuid,
  p_claim_id uuid,
  p_claim_reference text,
  p_clinic_id text,
  p_clinician_id text,
  p_external_service_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_redemption public.dawa_mom_reward_redemptions%rowtype;
  v_existing public.dawa_mom_voucher_redemption_events%rowtype;
begin
  if p_event_id is null or p_claim_id is null
    or nullif(trim(p_claim_reference), '') is null
    or nullif(trim(p_clinic_id), '') is null
    or nullif(trim(p_clinician_id), '') is null
    or nullif(trim(p_external_service_id), '') is null then
    raise exception using errcode = '22023', message = 'A complete redemption event is required';
  end if;

  select * into v_existing
  from public.dawa_mom_voucher_redemption_events
  where event_id = p_event_id;
  if found then
    select * into v_redemption
    from public.dawa_mom_reward_redemptions
    where id = v_existing.redemption_id;
    return jsonb_build_object(
      'id', v_redemption.id,
      'claim_reference', v_redemption.claim_reference,
      'status', v_redemption.status,
      'redeemed_at', v_redemption.redeemed_at,
      'idempotent', true
    );
  end if;

  select * into v_redemption
  from public.dawa_mom_reward_redemptions
  where claim_id = p_claim_id
    and claim_reference = trim(p_claim_reference)
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Voucher not found';
  end if;

  if v_redemption.status = 'redeemed' then
    raise exception using errcode = '23514', message = 'Voucher has already been redeemed';
  end if;
  if v_redemption.status in ('expired', 'cancelled') then
    raise exception using errcode = '23514', message = 'Voucher is not active';
  end if;
  if v_redemption.expires_at is not null and v_redemption.expires_at <= now() then
    update public.dawa_mom_reward_redemptions
    set status = 'expired'
    where id = v_redemption.id;
    raise exception using errcode = '23514', message = 'Voucher has expired';
  end if;

  if not exists (
    select 1
    from public.dawa_mom_voucher_eligibility eligibility
    where eligibility.reward_code = v_redemption.reward_code
      and eligibility.clinic_id = trim(p_clinic_id)
      and eligibility.external_service_id = trim(p_external_service_id)
      and eligibility.is_active
  ) then
    raise exception using errcode = '23514',
      message = 'Voucher is not eligible for this clinic service';
  end if;

  update public.dawa_mom_reward_redemptions
  set status = 'redeemed',
      redeemed_at = now(),
      redeemed_by_clinic_id = trim(p_clinic_id),
      redeemed_by_clinician_id = trim(p_clinician_id),
      redemption_event_id = p_event_id
  where id = v_redemption.id
  returning * into v_redemption;

  insert into public.dawa_mom_voucher_redemption_events (
    event_id, redemption_id, clinician_event_id, clinic_id, clinician_id,
    external_service_id
  ) values (
    p_event_id, v_redemption.id, p_event_id::text,
    trim(p_clinic_id), trim(p_clinician_id), trim(p_external_service_id)
  );

  return jsonb_build_object(
    'id', v_redemption.id,
    'claim_reference', v_redemption.claim_reference,
    'status', v_redemption.status,
    'redeemed_at', v_redemption.redeemed_at,
    'idempotent', false
  );
end;
$$;

-- Compatibility wrapper for already-released Flutter clients. The supplied
-- cost is only validated; it is never used as the debit source.
create or replace function public.redeem_dawa_mom_reward(
  p_reward_code text,
  p_cost integer
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_reward_code <> 'free_scan_voucher' or p_cost <> 1000 then
    raise exception using errcode = '23514', message = 'Reward selection is invalid';
  end if;
  return public.claim_dawa_mom_reward(p_reward_code);
end;
$$;

revoke all on function public.claim_dawa_mom_reward(text) from public;
grant execute on function public.claim_dawa_mom_reward(text) to authenticated;
revoke all on function public.redeem_dawa_mom_reward(text, integer) from public;
grant execute on function public.redeem_dawa_mom_reward(text, integer) to authenticated;
revoke all on function public.redeem_dawa_mom_reward_voucher(uuid, uuid, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.redeem_dawa_mom_reward_voucher(uuid, uuid, text, text, text, text)
  to service_role;

comment on table public.dawa_mom_reward_redemptions is
  'Server-issued clinic scan voucher claims. Status changes are audited and clinic redemption is service-only.';
comment on function public.redeem_dawa_mom_reward_voucher(uuid, uuid, text, text, text, text) is
  'Service-only single-use voucher redemption for an authenticated Clinician staff member and approved clinic service.';

notify pgrst, 'reload schema';

commit;
