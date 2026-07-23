-- Add idempotent Dawa Mom health-game awards to the existing completion RPC.
-- Game progress continues to use the owner-scoped learning state and the
-- server-owned award ledger introduced in 202607230001.

begin;

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

revoke all on function public.complete_dawa_mom_learning_item(text) from public;
grant execute on function public.complete_dawa_mom_learning_item(text)
  to authenticated;

comment on function public.complete_dawa_mom_learning_item(text) is
  'Completes a Dawa Mom lesson or health game and grants its award once per profile.';

commit;
