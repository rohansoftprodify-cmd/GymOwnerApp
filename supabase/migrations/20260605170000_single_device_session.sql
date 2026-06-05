-- One active owner/staff app session per user (single-device login).

create table if not exists public.user_active_sessions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  session_id uuid not null,
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.user_active_sessions is
  'Tracks the currently active gym owner app session per auth user.';

alter table public.user_active_sessions enable row level security;

create policy user_active_sessions_self_select on public.user_active_sessions
  for select using (user_id = auth.uid());

create policy user_active_sessions_self_write on public.user_active_sessions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.claim_active_session()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session_id uuid := gen_random_uuid();
  v_had_session boolean;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select exists(
    select 1 from public.user_active_sessions where user_id = v_user_id
  ) into v_had_session;

  insert into public.user_active_sessions (user_id, session_id, updated_at)
  values (v_user_id, v_session_id, timezone('utc', now()))
  on conflict (user_id) do update
  set
    session_id = excluded.session_id,
    updated_at = excluded.updated_at;

  return jsonb_build_object(
    'session_id', v_session_id,
    'had_previous_session', v_had_session
  );
end;
$$;

create or replace function public.release_active_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return;
  end if;

  delete from public.user_active_sessions
  where user_id = v_user_id
    and session_id = p_session_id;
end;
$$;

grant execute on function public.claim_active_session() to authenticated;
grant execute on function public.release_active_session(uuid) to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.user_active_sessions;
  end if;
exception
  when duplicate_object then null;
end $$;
