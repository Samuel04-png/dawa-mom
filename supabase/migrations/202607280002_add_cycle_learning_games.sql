-- Interactive cycle-learning progress and idempotent first-completion awards.
-- No symptom answers are stored: only round index, score, version and progress
-- timestamps are synced for the authenticated owner.

begin;

create table if not exists public.dawa_mom_cycle_game_progress (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  game_id text not null,
  current_round integer not null default 0,
  correct_answers integer not null default 0,
  content_version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (profile_id, game_id),
  constraint dawa_mom_cycle_game_round_check check (current_round between 0 and 20),
  constraint dawa_mom_cycle_game_score_check check (correct_answers between 0 and 20),
  constraint dawa_mom_cycle_game_version_check check (content_version > 0)
);

alter table public.dawa_mom_cycle_game_progress enable row level security;

drop policy if exists dawa_mom_cycle_game_progress_select_owner
  on public.dawa_mom_cycle_game_progress;
create policy dawa_mom_cycle_game_progress_select_owner
  on public.dawa_mom_cycle_game_progress
  for select
  to authenticated
  using (profile_id = auth.uid());

drop policy if exists dawa_mom_cycle_game_progress_insert_owner
  on public.dawa_mom_cycle_game_progress;
create policy dawa_mom_cycle_game_progress_insert_owner
  on public.dawa_mom_cycle_game_progress
  for insert
  to authenticated
  with check (profile_id = auth.uid());

drop policy if exists dawa_mom_cycle_game_progress_update_owner
  on public.dawa_mom_cycle_game_progress;
create policy dawa_mom_cycle_game_progress_update_owner
  on public.dawa_mom_cycle_game_progress
  for update
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

drop policy if exists dawa_mom_cycle_game_progress_delete_owner
  on public.dawa_mom_cycle_game_progress;
create policy dawa_mom_cycle_game_progress_delete_owner
  on public.dawa_mom_cycle_game_progress
  for delete
  to authenticated
  using (profile_id = auth.uid());

revoke all on table public.dawa_mom_cycle_game_progress
  from anon, authenticated;
grant select, insert, update, delete
  on table public.dawa_mom_cycle_game_progress
  to authenticated;

drop trigger if exists dawa_mom_cycle_game_progress_set_updated_at
  on public.dawa_mom_cycle_game_progress;
create trigger dawa_mom_cycle_game_progress_set_updated_at
before update on public.dawa_mom_cycle_game_progress
for each row execute function public.set_updated_at();

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
    when 'game-myth-match' then 10
    when 'game-nutrition-sort' then 10
    when 'cycle-game-phase-match' then 10
    when 'cycle-game-calendar-detective' then 10
    when 'cycle-game-log-meaning' then 10
    when 'cycle-game-period-kit' then 10
    when 'cycle-game-myth-fact' then 10
    when 'cycle-game-self-care-or-help' then 10
    when 'cycle-game-pattern-detective' then 10
    when 'cycle-game-products-match' then 10
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

  delete from public.dawa_mom_cycle_game_progress
  where profile_id = v_profile_id
    and game_id = p_content_id;

  return jsonb_build_object(
    'content_id', p_content_id,
    'coin_award', case when v_inserted = 1 then v_award else 0 end,
    'coin_balance', v_balance,
    'completed_content_ids', v_completed
  );
end;
$$;

revoke all on function public.complete_dawa_mom_learning_item(text) from public;
grant execute on function public.complete_dawa_mom_learning_item(text)
  to authenticated;

comment on table public.dawa_mom_cycle_game_progress is
  'Owner-scoped resumable round progress for DawaMom cycle-learning games; no symptom response content is stored.';
comment on function public.complete_dawa_mom_learning_item(text) is
  'Completes a DawaMom lesson or game and grants the configured award once per profile.';

commit;
