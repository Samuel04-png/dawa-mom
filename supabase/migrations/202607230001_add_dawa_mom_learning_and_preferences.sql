-- Additive persistence for the redesigned Dawa Mom language, learning and
-- rewards screens. Clinical records and existing policies are not modified.

begin;

create table if not exists public.dawa_mom_user_preferences (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  language text not null default 'English',
  lesson_language_enabled boolean not null default true,
  rudo_language_enabled boolean not null default true,
  appointment_notifications boolean not null default true,
  learning_notifications boolean not null default true,
  cycle_notifications boolean not null default true,
  reward_notifications boolean not null default true,
  read_notification_ids text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dawa_mom_user_preferences_language_check check (
    language in ('English', 'Nyanja', 'Bemba', 'Tonga', 'Lozi', 'Shona', 'Ndebele')
  )
);

create table if not exists public.dawa_mom_learning_state (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  saved_content_ids text[] not null default '{}'::text[],
  completed_content_ids text[] not null default '{}'::text[],
  coin_balance integer not null default 180,
  streak_days integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dawa_mom_learning_state_coin_balance_check check (coin_balance >= 0),
  constraint dawa_mom_learning_state_streak_check check (streak_days >= 0)
);

create table if not exists public.dawa_mom_reward_redemptions (
  id uuid primary key default extensions.gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reward_code text not null,
  coin_cost integer not null,
  voucher_code text not null unique,
  redeemed_at timestamptz not null default now(),
  constraint dawa_mom_reward_redemptions_coin_cost_check check (coin_cost > 0),
  constraint dawa_mom_reward_redemptions_once unique (profile_id, reward_code)
);

create table if not exists public.dawa_mom_learning_awards (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  content_id text not null,
  coin_award integer not null,
  awarded_at timestamptz not null default now(),
  primary key (profile_id, content_id),
  constraint dawa_mom_learning_awards_coin_check check (coin_award >= 0)
);

create table if not exists public.dawa_mom_appointment_reminders (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  enabled boolean not null default true,
  days_before integer not null default 1,
  app_notification boolean not null default true,
  sms_notification boolean not null default false,
  email_notification boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (profile_id, appointment_id),
  constraint dawa_mom_appointment_reminders_days_check check (
    days_before in (1, 2, 7)
  ),
  constraint dawa_mom_appointment_reminders_channel_check check (
    enabled = false
    or app_notification
    or sms_notification
    or email_notification
  )
);

alter table public.dawa_mom_user_preferences enable row level security;
alter table public.dawa_mom_learning_state enable row level security;
alter table public.dawa_mom_reward_redemptions enable row level security;
alter table public.dawa_mom_learning_awards enable row level security;
alter table public.dawa_mom_appointment_reminders enable row level security;

drop policy if exists dawa_mom_user_preferences_owner
  on public.dawa_mom_user_preferences;
create policy dawa_mom_user_preferences_owner
  on public.dawa_mom_user_preferences
  for all
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

drop policy if exists dawa_mom_learning_state_owner
  on public.dawa_mom_learning_state;
create policy dawa_mom_learning_state_owner
  on public.dawa_mom_learning_state
  for all
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

drop policy if exists dawa_mom_reward_redemptions_select_owner
  on public.dawa_mom_reward_redemptions;
create policy dawa_mom_reward_redemptions_select_owner
  on public.dawa_mom_reward_redemptions
  for select
  to authenticated
  using (profile_id = auth.uid());

drop policy if exists dawa_mom_learning_awards_select_owner
  on public.dawa_mom_learning_awards;
create policy dawa_mom_learning_awards_select_owner
  on public.dawa_mom_learning_awards
  for select
  to authenticated
  using (profile_id = auth.uid());

drop policy if exists dawa_mom_appointment_reminders_owner
  on public.dawa_mom_appointment_reminders;
create policy dawa_mom_appointment_reminders_owner
  on public.dawa_mom_appointment_reminders
  for all
  to authenticated
  using (profile_id = auth.uid())
  with check (
    profile_id = auth.uid()
    and exists (
      select 1
      from public.appointments appointment
      where appointment.id = appointment_id
        and appointment.patient_id = auth.uid()
    )
  );

revoke all on table public.dawa_mom_user_preferences from anon, authenticated;
grant select, insert, update, delete
  on table public.dawa_mom_user_preferences to authenticated;

revoke all on table public.dawa_mom_learning_state from anon, authenticated;
grant select on table public.dawa_mom_learning_state to authenticated;
grant insert (profile_id, saved_content_ids, completed_content_ids)
  on table public.dawa_mom_learning_state to authenticated;
grant update (saved_content_ids, completed_content_ids, updated_at)
  on table public.dawa_mom_learning_state to authenticated;

revoke all on table public.dawa_mom_reward_redemptions from anon, authenticated;
grant select on table public.dawa_mom_reward_redemptions to authenticated;
revoke all on table public.dawa_mom_learning_awards from anon, authenticated;
grant select on table public.dawa_mom_learning_awards to authenticated;
revoke all on table public.dawa_mom_appointment_reminders
  from anon, authenticated;
grant select, insert, update, delete
  on table public.dawa_mom_appointment_reminders to authenticated;

drop trigger if exists dawa_mom_user_preferences_set_updated_at
  on public.dawa_mom_user_preferences;
create trigger dawa_mom_user_preferences_set_updated_at
before update on public.dawa_mom_user_preferences
for each row execute function public.set_updated_at();

drop trigger if exists dawa_mom_learning_state_set_updated_at
  on public.dawa_mom_learning_state;
create trigger dawa_mom_learning_state_set_updated_at
before update on public.dawa_mom_learning_state
for each row execute function public.set_updated_at();

drop trigger if exists dawa_mom_appointment_reminders_set_updated_at
  on public.dawa_mom_appointment_reminders;
create trigger dawa_mom_appointment_reminders_set_updated_at
before update on public.dawa_mom_appointment_reminders
for each row execute function public.set_updated_at();

create or replace function public.redeem_dawa_mom_reward(
  p_reward_code text,
  p_cost integer
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
  v_voucher text;
begin
  if v_profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;

  v_expected_cost := case p_reward_code
    when 'free_scan_voucher' then 1000
    else null
  end;
  if v_expected_cost is null or p_cost <> v_expected_cost then
    raise exception using errcode = '23514', message = 'Reward selection is invalid';
  end if;

  select redemption.voucher_code
    into v_voucher
  from public.dawa_mom_reward_redemptions redemption
  where redemption.profile_id = v_profile_id
    and redemption.reward_code = p_reward_code;

  if v_voucher is not null then
    select state.coin_balance
      into v_balance
    from public.dawa_mom_learning_state state
    where state.profile_id = v_profile_id;
    return jsonb_build_object(
      'reward_code', p_reward_code,
      'voucher_code', v_voucher,
      'coin_balance', coalesce(v_balance, 180),
      'already_redeemed', true
    );
  end if;

  insert into public.dawa_mom_learning_state (profile_id)
  values (v_profile_id)
  on conflict (profile_id) do nothing;

  update public.dawa_mom_learning_state
  set coin_balance = coin_balance - v_expected_cost
  where profile_id = v_profile_id
    and coin_balance >= v_expected_cost
  returning coin_balance into v_balance;

  if v_balance is null then
    raise exception using errcode = '23514', message = 'Not enough reward points';
  end if;

  v_voucher := upper(
    substr(replace(extensions.gen_random_uuid()::text, '-', ''), 1, 12)
  );
  insert into public.dawa_mom_reward_redemptions (
    profile_id,
    reward_code,
    coin_cost,
    voucher_code
  )
  values (
    v_profile_id,
    p_reward_code,
    v_expected_cost,
    v_voucher
  );

  return jsonb_build_object(
    'reward_code', p_reward_code,
    'voucher_code', v_voucher,
    'coin_balance', v_balance,
    'already_redeemed', false
  );
end;
$$;

create or replace function public.complete_dawa_mom_learning_item(
  p_content_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile_id uuid := auth.uid();
  v_award integer;
  v_inserted integer;
  v_balance integer;
  v_completed text[];
begin
  if v_profile_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;

  v_award := case p_content_id
    when 'myth-vs-fact' then 5
    when 'pregnancy-basics' then 5
    when 'screening-checkpoint' then 5
    when 'screening-without-fear' then 20
    else 0
  end;

  insert into public.dawa_mom_learning_state (profile_id)
  values (v_profile_id)
  on conflict (profile_id) do nothing;

  insert into public.dawa_mom_learning_awards (
    profile_id,
    content_id,
    coin_award
  )
  values (
    v_profile_id,
    p_content_id,
    v_award
  )
  on conflict (profile_id, content_id) do nothing;
  get diagnostics v_inserted = row_count;

  update public.dawa_mom_learning_state
  set completed_content_ids = case
        when p_content_id = any(completed_content_ids)
          then completed_content_ids
        else array_append(completed_content_ids, p_content_id)
      end,
      coin_balance = coin_balance + case when v_inserted = 1 then v_award else 0 end
  where profile_id = v_profile_id
  returning coin_balance, completed_content_ids
    into v_balance, v_completed;

  return jsonb_build_object(
    'content_id', p_content_id,
    'coin_award', case when v_inserted = 1 then v_award else 0 end,
    'coin_balance', v_balance,
    'completed_content_ids', v_completed
  );
end;
$$;

revoke all on function public.redeem_dawa_mom_reward(text, integer) from public;
grant execute on function public.redeem_dawa_mom_reward(text, integer)
  to authenticated;
revoke all on function public.complete_dawa_mom_learning_item(text) from public;
grant execute on function public.complete_dawa_mom_learning_item(text)
  to authenticated;

comment on table public.dawa_mom_user_preferences is
  'Owner-scoped Dawa Mom language and notification preferences.';
comment on table public.dawa_mom_learning_state is
  'Owner-scoped bookmarks, lesson completion, streak and coin balance.';
comment on table public.dawa_mom_reward_redemptions is
  'Server-issued, idempotent Dawa Mom reward vouchers.';
comment on table public.dawa_mom_learning_awards is
  'Server-owned idempotency ledger for learning coin awards.';
comment on table public.dawa_mom_appointment_reminders is
  'Owner-scoped delivery preferences for a patient appointment reminder.';

commit;
