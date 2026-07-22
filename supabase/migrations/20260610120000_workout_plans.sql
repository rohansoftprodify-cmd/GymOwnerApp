-- Workout plans: category (goal) -> plan -> sessions -> exercises.
-- AI workout coach + member session logs for plan adjustment.

create table if not exists public.workout_plan_categories (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  goal_key text not null check (goal_key in ('weight_loss', 'muscle_gain', 'healthy')),
  name text not null,
  description text,
  coaching_tips text,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, goal_key)
);

create table if not exists public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  category_id uuid not null references public.workout_plan_categories (id) on delete restrict,
  name text not null,
  description text,
  duration_weeks int not null default 4 check (duration_weeks > 0),
  sessions_per_week int not null default 3 check (sessions_per_week > 0 and sessions_per_week <= 7),
  experience_level text not null default 'beginner'
    check (experience_level in ('beginner', 'intermediate', 'advanced')),
  equipment_hint text,
  member_age int check (member_age is null or (member_age >= 10 and member_age <= 100)),
  member_weight_kg numeric(6, 2) check (member_weight_kg is null or member_weight_kg > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  workout_plan_id uuid not null references public.workout_plans (id) on delete cascade,
  day_label text not null,
  day_number int not null default 1 check (day_number > 0),
  guidance text,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workout_session_exercises (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  workout_session_id uuid not null references public.workout_sessions (id) on delete cascade,
  exercise_id uuid references public.exercises (id) on delete set null,
  exercise_name text not null,
  sets int not null default 3 check (sets > 0),
  reps int not null default 10 check (reps > 0),
  rest_seconds int check (rest_seconds is null or rest_seconds >= 0),
  notes text,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.subscription_plan_workout_plans (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  subscription_plan_id uuid not null references public.subscription_plans (id) on delete cascade,
  workout_plan_id uuid not null references public.workout_plans (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  unique (subscription_plan_id, workout_plan_id)
);

create table if not exists public.member_workout_session_logs (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  workout_plan_id uuid not null references public.workout_plans (id) on delete cascade,
  workout_session_id uuid not null references public.workout_sessions (id) on delete cascade,
  completed_at timestamptz not null default timezone('utc', now()),
  notes text,
  skipped boolean not null default false
);

create index if not exists idx_workout_plan_categories_gym on public.workout_plan_categories (gym_id);
create index if not exists idx_workout_plans_gym on public.workout_plans (gym_id);
create index if not exists idx_workout_plans_category on public.workout_plans (category_id);
create index if not exists idx_workout_sessions_plan on public.workout_sessions (workout_plan_id);
create index if not exists idx_workout_session_exercises_session on public.workout_session_exercises (workout_session_id);
create index if not exists idx_spwp_gym on public.subscription_plan_workout_plans (gym_id);
create index if not exists idx_member_workout_logs_member on public.member_workout_session_logs (member_id, workout_plan_id);

create trigger workout_plan_categories_touch_updated_at
before update on public.workout_plan_categories
for each row execute function public.touch_updated_at();

create trigger workout_plans_touch_updated_at
before update on public.workout_plans
for each row execute function public.touch_updated_at();

create trigger workout_sessions_touch_updated_at
before update on public.workout_sessions
for each row execute function public.touch_updated_at();

alter table public.workout_plan_categories enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.workout_session_exercises enable row level security;
alter table public.subscription_plan_workout_plans enable row level security;
alter table public.member_workout_session_logs enable row level security;

create policy workout_plan_categories_gym_scope_select on public.workout_plan_categories
  for select using (public.current_user_is_gym_member(gym_id));
create policy workout_plan_categories_gym_scope_write on public.workout_plan_categories
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy workout_plans_gym_scope_select on public.workout_plans
  for select using (public.current_user_is_gym_member(gym_id));
create policy workout_plans_gym_scope_write on public.workout_plans
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy workout_sessions_gym_scope_select on public.workout_sessions
  for select using (public.current_user_is_gym_member(gym_id));
create policy workout_sessions_gym_scope_write on public.workout_sessions
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy workout_session_exercises_gym_scope_select on public.workout_session_exercises
  for select using (public.current_user_is_gym_member(gym_id));
create policy workout_session_exercises_gym_scope_write on public.workout_session_exercises
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create or replace function public.validate_subscription_plan_workout_plan_link()
returns trigger language plpgsql as $$
declare sub_gym uuid; wp_gym uuid;
begin
  select gym_id into sub_gym from public.subscription_plans where id = new.subscription_plan_id;
  select gym_id into wp_gym from public.workout_plans where id = new.workout_plan_id;
  if sub_gym is null or wp_gym is null or sub_gym <> wp_gym then
    raise exception 'Subscription plan and workout plan must belong to the same gym.';
  end if;
  new.gym_id := sub_gym;
  return new;
end;
$$;

drop trigger if exists subscription_plan_workout_plans_validate on public.subscription_plan_workout_plans;
create trigger subscription_plan_workout_plans_validate
before insert or update on public.subscription_plan_workout_plans
for each row execute function public.validate_subscription_plan_workout_plan_link();

create policy subscription_plan_workout_plans_gym_scope_select
  on public.subscription_plan_workout_plans for select
  using (public.current_user_is_gym_member(gym_id));
create policy subscription_plan_workout_plans_gym_scope_write
  on public.subscription_plan_workout_plans for all
  using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create or replace function public.member_can_access_workout_plan(p_gym_id uuid, p_workout_plan_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.workout_plans wp
    where wp.id = p_workout_plan_id and wp.gym_id = p_gym_id and wp.is_active = true
  )
  and (
    not exists (
      select 1 from public.subscription_plan_workout_plans spw
      where spw.workout_plan_id = p_workout_plan_id and spw.gym_id = p_gym_id
    )
    or exists (
      select 1 from public.member_subscriptions ms
      join public.subscription_plan_workout_plans spw
        on spw.subscription_plan_id = ms.plan_id and spw.gym_id = ms.gym_id
      where ms.member_id = public.current_user_linked_member_id(p_gym_id)
        and ms.gym_id = p_gym_id and ms.status = 'active'
        and ms.end_date >= current_date
        and spw.workout_plan_id = p_workout_plan_id
    )
  );
$$;

create policy workout_plan_categories_member_select on public.workout_plan_categories
  for select using (public.current_user_is_gym_app_user(gym_id));
create policy workout_plans_member_select on public.workout_plans
  for select using (
    public.current_user_is_gym_app_user(gym_id) and is_active = true
    and public.member_can_access_workout_plan(gym_id, id)
  );
create policy workout_sessions_member_select on public.workout_sessions
  for select using (
    public.current_user_is_gym_app_user(gym_id)
    and public.member_can_access_workout_plan(gym_id, workout_plan_id)
  );
create policy workout_session_exercises_member_select on public.workout_session_exercises
  for select using (
    public.current_user_is_gym_app_user(gym_id)
    and exists (
      select 1 from public.workout_sessions ws
      where ws.id = workout_session_id
        and public.member_can_access_workout_plan(gym_id, ws.workout_plan_id)
    )
  );

create policy member_workout_logs_member_select on public.member_workout_session_logs
  for select using (member_id = public.current_user_linked_member_id(gym_id));
create policy member_workout_logs_member_insert on public.member_workout_session_logs
  for insert with check (member_id = public.current_user_linked_member_id(gym_id));

create or replace function public.set_workout_plan_subscription_links(
  p_gym_id uuid, p_workout_plan_id uuid, p_subscription_plan_ids uuid[]
)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;
  if not exists (
    select 1 from public.workout_plans wp
    where wp.id = p_workout_plan_id and wp.gym_id = p_gym_id
  ) then
    raise exception 'Workout plan not found.';
  end if;
  delete from public.subscription_plan_workout_plans
  where gym_id = p_gym_id and workout_plan_id = p_workout_plan_id;
  insert into public.subscription_plan_workout_plans (gym_id, subscription_plan_id, workout_plan_id)
  select p_gym_id, pid, p_workout_plan_id
  from unnest(coalesce(p_subscription_plan_ids, array[]::uuid[])) as pid
  on conflict (subscription_plan_id, workout_plan_id) do nothing;
end;
$$;

grant execute on function public.set_workout_plan_subscription_links(uuid, uuid, uuid[]) to authenticated;

-- Workout AI quota
alter table public.gym_ai_usage drop constraint if exists gym_ai_usage_feature_check;
alter table public.gym_ai_usage add constraint gym_ai_usage_feature_check
  check (feature in ('diet_ai', 'marketing_ai', 'workout_ai'));

create or replace function public.get_gym_ai_workout_quota(p_gym_id uuid, p_monthly_limit int default 5)
returns json language plpgsql security definer set search_path = public as $$
declare month_start date := date_trunc('month', timezone('utc', now()))::date;
  current_count int := 0;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;
  select coalesce(usage_count, 0) into current_count
  from public.gym_ai_usage
  where gym_id = p_gym_id and feature = 'workout_ai' and usage_month = month_start;
  return json_build_object(
    'used', current_count, 'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0),
    'month', to_char(month_start, 'YYYY-MM')
  );
end;
$$;

create or replace function public.consume_gym_ai_workout_quota(p_gym_id uuid, p_monthly_limit int default 5)
returns json language plpgsql security definer set search_path = public as $$
declare month_start date := date_trunc('month', timezone('utc', now()))::date;
  current_count int := 0;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;
  insert into public.gym_ai_usage (gym_id, feature, usage_month, usage_count)
  values (p_gym_id, 'workout_ai', month_start, 0)
  on conflict (gym_id, feature, usage_month) do nothing;
  select usage_count into current_count from public.gym_ai_usage
  where gym_id = p_gym_id and feature = 'workout_ai' and usage_month = month_start for update;
  if current_count >= p_monthly_limit then
    return json_build_object('allowed', false, 'used', current_count, 'limit', p_monthly_limit, 'remaining', 0);
  end if;
  update public.gym_ai_usage set usage_count = usage_count + 1
  where gym_id = p_gym_id and feature = 'workout_ai' and usage_month = month_start
  returning usage_count into current_count;
  return json_build_object('allowed', true, 'used', current_count, 'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0));
end;
$$;

grant execute on function public.get_gym_ai_workout_quota(uuid, int) to authenticated;
grant execute on function public.consume_gym_ai_workout_quota(uuid, int) to authenticated;

-- Member workout session log
create or replace function public.log_my_workout_session(
  p_workout_plan_id uuid, p_workout_session_id uuid, p_notes text default null, p_skipped boolean default false
)
returns json language plpgsql security definer set search_path = public as $$
declare v_member_id uuid; v_gym_id uuid; v_log_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated.'; end if;
  select m.id, m.gym_id into v_member_id, v_gym_id from public.members m where m.user_id = auth.uid() limit 1;
  if v_member_id is null then raise exception 'No membership linked.'; end if;
  if not public.member_can_access_workout_plan(v_gym_id, p_workout_plan_id) then
    raise exception 'Workout plan not available.';
  end if;
  if not exists (
    select 1 from public.workout_sessions ws
    where ws.id = p_workout_session_id and ws.workout_plan_id = p_workout_plan_id and ws.gym_id = v_gym_id
  ) then raise exception 'Invalid workout session.'; end if;
  insert into public.member_workout_session_logs (gym_id, member_id, workout_plan_id, workout_session_id, notes, skipped)
  values (v_gym_id, v_member_id, p_workout_plan_id, p_workout_session_id, p_notes, coalesce(p_skipped, false))
  returning id into v_log_id;
  return json_build_object('id', v_log_id, 'logged_at', timezone('utc', now()));
end;
$$;

grant execute on function public.log_my_workout_session(uuid, uuid, text, boolean) to authenticated;

create or replace function public.get_my_workout_completion_summary(p_workout_plan_id uuid)
returns json language plpgsql stable security definer set search_path = public as $$
declare v_member_id uuid; v_gym_id uuid;
begin
  select m.id, m.gym_id into v_member_id, v_gym_id from public.members m where m.user_id = auth.uid() limit 1;
  if v_member_id is null then return '[]'::json; end if;
  return coalesce((
    select json_agg(row_to_json(t) order by t.completed_at desc)
    from (
      select l.workout_session_id, ws.day_label, l.completed_at, l.skipped, l.notes
      from public.member_workout_session_logs l
      join public.workout_sessions ws on ws.id = l.workout_session_id
      where l.member_id = v_member_id and l.workout_plan_id = p_workout_plan_id
      order by l.completed_at desc limit 30
    ) t
  ), '[]'::json);
end;
$$;

grant execute on function public.get_my_workout_completion_summary(uuid) to authenticated;

-- Member list + detail RPCs
create or replace function public.get_my_workout_plans()
returns json language plpgsql stable security definer set search_path = public as $$
declare v_gym_id uuid; result json;
begin
  if auth.uid() is null then return '[]'::json; end if;
  select m.gym_id into v_gym_id from public.members m where m.user_id = auth.uid() limit 1;
  if v_gym_id is null then return '[]'::json; end if;
  select coalesce(json_agg(row_to_json(t) order by t.name), '[]'::json) into result
  from (
    select wp.id, wp.name, wp.description, wp.duration_weeks, wp.sessions_per_week,
      wp.experience_level, wp.equipment_hint, wpc.goal_key, wpc.name as category_name,
      (select count(*)::int from public.workout_sessions ws where ws.workout_plan_id = wp.id) as session_count
    from public.workout_plans wp
    join public.workout_plan_categories wpc on wpc.id = wp.category_id
    where wp.gym_id = v_gym_id and wp.is_active = true
      and public.member_can_access_workout_plan(v_gym_id, wp.id)
  ) t;
  return result;
end;
$$;

create or replace function public.get_my_workout_plan_detail(p_workout_plan_id uuid)
returns json language plpgsql stable security definer set search_path = public as $$
declare v_gym_id uuid; result json;
begin
  if auth.uid() is null then return null; end if;
  select m.gym_id into v_gym_id from public.members m where m.user_id = auth.uid() limit 1;
  if v_gym_id is null then return null; end if;
  if not public.member_can_access_workout_plan(v_gym_id, p_workout_plan_id) then return null; end if;
  select json_build_object(
    'id', wp.id, 'name', wp.name, 'description', wp.description,
    'duration_weeks', wp.duration_weeks, 'sessions_per_week', wp.sessions_per_week,
    'experience_level', wp.experience_level, 'equipment_hint', wp.equipment_hint,
    'goal_key', wpc.goal_key, 'category_name', wpc.name, 'coaching_tips', wpc.coaching_tips,
    'sessions', coalesce((
      select json_agg(session_row order by session_row.sort_order, session_row.day_number)
      from (
        select ws.id, ws.day_label, ws.day_number, ws.guidance, ws.sort_order,
          coalesce((
            select json_agg(json_build_object(
              'id', wse.id, 'exercise_id', wse.exercise_id, 'exercise_name', wse.exercise_name,
              'sets', wse.sets, 'reps', wse.reps, 'rest_seconds', wse.rest_seconds, 'notes', wse.notes,
              'sort_order', wse.sort_order
            ) order by wse.sort_order, wse.exercise_name)
            from public.workout_session_exercises wse where wse.workout_session_id = ws.id
          ), '[]'::json) as exercises
        from public.workout_sessions ws where ws.workout_plan_id = wp.id
      ) session_row
    ), '[]'::json)
  ) into result
  from public.workout_plans wp
  join public.workout_plan_categories wpc on wpc.id = wp.category_id
  where wp.id = p_workout_plan_id and wp.gym_id = v_gym_id and wp.is_active = true;
  return result;
end;
$$;

grant execute on function public.get_my_workout_plans() to authenticated;
grant execute on function public.get_my_workout_plan_detail(uuid) to authenticated;

-- Apply AI-adjusted sessions (member or staff with plan access).
create or replace function public.apply_workout_plan_sessions(
  p_workout_plan_id uuid,
  p_sessions json
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_gym_id uuid;
  v_session json;
  v_exercise json;
  v_session_id uuid;
  v_sort int := 0;
  v_ex_sort int;
begin
  select wp.gym_id into v_gym_id
  from public.workout_plans wp
  where wp.id = p_workout_plan_id;

  if v_gym_id is null then
    raise exception 'Workout plan not found.';
  end if;

  if not (
    public.current_user_is_gym_member(v_gym_id)
    or (
      public.current_user_is_gym_app_user(v_gym_id)
      and public.member_can_access_workout_plan(v_gym_id, p_workout_plan_id)
    )
  ) then
    raise exception 'Unauthorized.';
  end if;

  delete from public.workout_session_exercises wse
  using public.workout_sessions ws
  where wse.workout_session_id = ws.id
    and ws.workout_plan_id = p_workout_plan_id;

  delete from public.workout_sessions
  where workout_plan_id = p_workout_plan_id;

  if p_sessions is null or json_typeof(p_sessions) <> 'array' then
    return;
  end if;

  for v_session in select * from json_array_elements(p_sessions)
  loop
    insert into public.workout_sessions (
      gym_id, workout_plan_id, day_label, day_number, guidance, sort_order
    )
    values (
      v_gym_id,
      p_workout_plan_id,
      coalesce(v_session->>'day_label', 'Session'),
      coalesce((v_session->>'day_number')::int, v_sort + 1),
      v_session->>'guidance',
      v_sort
    )
    returning id into v_session_id;

    v_ex_sort := 0;
    if v_session->'exercises' is not null and json_typeof(v_session->'exercises') = 'array' then
      for v_exercise in select * from json_array_elements(v_session->'exercises')
      loop
        insert into public.workout_session_exercises (
          gym_id, workout_session_id, exercise_name, sets, reps, rest_seconds, notes, sort_order
        )
        values (
          v_gym_id,
          v_session_id,
          coalesce(v_exercise->>'exercise_name', 'Exercise'),
          coalesce((v_exercise->>'sets')::int, 3),
          coalesce((v_exercise->>'reps')::int, 10),
          nullif(v_exercise->>'rest_seconds', '')::int,
          v_exercise->>'notes',
          v_ex_sort
        );
        v_ex_sort := v_ex_sort + 1;
      end loop;
    end if;

    v_sort := v_sort + 1;
  end loop;
end;
$$;

grant execute on function public.apply_workout_plan_sessions(uuid, json) to authenticated;
