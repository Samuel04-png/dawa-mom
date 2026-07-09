begin;

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'mothers'
      and column_name = 'user_id'
  ) then
    alter table public.mothers
      add column user_id uuid generated always as (profile_id) stored;
  end if;
end $$;

comment on column public.mothers.user_id is
  'Generated alias of profile_id for Dawa Clinician database webhook payloads.';

notify pgrst, 'reload schema';

commit;
