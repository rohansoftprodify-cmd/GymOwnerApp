-- ONE-OFF: Wipe all app data + auth users so you can create a fresh owner and members.
-- Run in Supabase Dashboard → SQL Editor.
-- WARNING: Irreversible. Do not commit this as a migration.
--
-- Note: storage.objects cannot be deleted via SQL (protect_delete trigger).
-- Clear Storage buckets from Dashboard → Storage after running this, or via Storage API.

begin;

-- 1) Wipe every public table (keeps schema / RLS / functions)
do $$
declare
  stmt text;
begin
  select 'truncate table '
    || string_agg(format('%I.%I', schemaname, tablename), ', ')
    || ' restart identity cascade'
  into stmt
  from pg_tables
  where schemaname = 'public';

  if stmt is not null then
    execute stmt;
  end if;
end $$;

-- 2) Clear Auth users and related rows
-- (Ignore tables that may not exist on older Auth schemas)
do $$
begin
  begin delete from auth.mfa_amr_claims; exception when undefined_table then null; end;
  begin delete from auth.mfa_challenges; exception when undefined_table then null; end;
  begin delete from auth.mfa_factors; exception when undefined_table then null; end;
  begin delete from auth.one_time_tokens; exception when undefined_table then null; end;
  begin delete from auth.refresh_tokens; exception when undefined_table then null; end;
  begin delete from auth.sessions; exception when undefined_table then null; end;
  begin delete from auth.identities; exception when undefined_table then null; end;
  delete from auth.users;
end $$;

commit;

-- Verify empty:
select
  (select count(*) from auth.users) as auth_users,
  (select count(*) from public.gyms) as gyms,
  (select count(*) from public.members) as members,
  (select count(*) from public.profiles) as profiles;
