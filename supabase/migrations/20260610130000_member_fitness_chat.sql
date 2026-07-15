-- AI Chat Fitness Assistant for members (24/7 coach chat).

alter table public.gym_ai_usage drop constraint if exists gym_ai_usage_feature_check;
alter table public.gym_ai_usage add constraint gym_ai_usage_feature_check
  check (feature in ('diet_ai', 'marketing_ai', 'workout_ai', 'coach_chat_ai'));

create or replace function public.get_gym_ai_coach_chat_quota(
  p_gym_id uuid,
  p_monthly_limit int default 100
)
returns json language plpgsql security definer set search_path = public as $$
declare month_start date := date_trunc('month', timezone('utc', now()))::date;
  current_count int := 0;
begin
  select coalesce(usage_count, 0) into current_count
  from public.gym_ai_usage
  where gym_id = p_gym_id and feature = 'coach_chat_ai' and usage_month = month_start;
  return json_build_object(
    'used', current_count, 'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0),
    'month', to_char(month_start, 'YYYY-MM')
  );
end;
$$;

create or replace function public.consume_gym_ai_coach_chat_quota(
  p_gym_id uuid,
  p_monthly_limit int default 100
)
returns json language plpgsql security definer set search_path = public as $$
declare month_start date := date_trunc('month', timezone('utc', now()))::date;
  current_count int := 0;
begin
  insert into public.gym_ai_usage (gym_id, feature, usage_month, usage_count)
  values (p_gym_id, 'coach_chat_ai', month_start, 0)
  on conflict (gym_id, feature, usage_month) do nothing;

  select usage_count into current_count from public.gym_ai_usage
  where gym_id = p_gym_id and feature = 'coach_chat_ai' and usage_month = month_start
  for update;

  if current_count >= p_monthly_limit then
    return json_build_object('allowed', false, 'used', current_count, 'limit', p_monthly_limit, 'remaining', 0);
  end if;

  update public.gym_ai_usage set usage_count = usage_count + 1
  where gym_id = p_gym_id and feature = 'coach_chat_ai' and usage_month = month_start
  returning usage_count into current_count;

  return json_build_object(
    'allowed', true, 'used', current_count, 'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0)
  );
end;
$$;

grant execute on function public.get_gym_ai_coach_chat_quota(uuid, int) to authenticated;
grant execute on function public.consume_gym_ai_coach_chat_quota(uuid, int) to authenticated;

-- Context bundle for the fitness chat assistant.
create or replace function public.get_member_fitness_chat_context()
returns json language plpgsql stable security definer set search_path = public as $$
declare
  v_member_id uuid;
  v_gym_id uuid;
  result json;
begin
  if auth.uid() is null then return null; end if;

  select m.id, m.gym_id into v_member_id, v_gym_id
  from public.members m where m.user_id = auth.uid() limit 1;

  if v_member_id is null then return null; end if;

  select json_build_object(
    'gym_id', v_gym_id,
    'member', json_build_object(
      'full_name', m.full_name,
      'age', m.age,
      'gender', m.gender,
      'weight_kg', m.weight_kg,
      'height_cm', m.height_cm,
      'fitness_goal', m.fitness_goal,
      'bmi', case when m.height_cm > 0 and m.weight_kg > 0
        then round((m.weight_kg / power(m.height_cm / 100.0, 2))::numeric, 1) else null end
    ),
    'gym', json_build_object(
      'name', g.name,
      'phone', g.phone,
      'address', g.address
    ),
    'subscription', (
      select json_build_object(
        'plan_name', sp.name,
        'status', ms.status,
        'end_date', ms.end_date
      )
      from public.member_subscriptions ms
      join public.subscription_plans sp on sp.id = ms.plan_id
      where ms.member_id = v_member_id and ms.gym_id = v_gym_id and ms.status = 'active'
      order by ms.end_date desc limit 1
    ),
    'attendance', json_build_object(
      'total_visits', (
        select count(*)::int from public.attendance_records ar
        where ar.member_id = v_member_id and ar.gym_id = v_gym_id
      ),
      'visits_last_30_days', (
        select count(*)::int from public.attendance_records ar
        where ar.member_id = v_member_id and ar.gym_id = v_gym_id
          and ar.check_in_at >= timezone('utc', now()) - interval '30 days'
      ),
      'last_check_in', (
        select max(ar.check_in_at) from public.attendance_records ar
        where ar.member_id = v_member_id and ar.gym_id = v_gym_id
      )
    ),
    'diet_plans', coalesce((
      select json_agg(json_build_object('name', dp.name, 'goal_key', dpc.goal_key) order by dp.name)
      from public.diet_plans dp
      join public.diet_plan_categories dpc on dpc.id = dp.category_id
      where dp.gym_id = v_gym_id and dp.is_active = true
        and public.member_can_access_diet_plan(v_gym_id, dp.id)
    ), '[]'::json),
    'workout_plans', coalesce((
      select json_agg(json_build_object(
        'name', wp.name,
        'goal_key', wpc.goal_key,
        'sessions_per_week', wp.sessions_per_week,
        'experience_level', wp.experience_level
      ) order by wp.name)
      from public.workout_plans wp
      join public.workout_plan_categories wpc on wpc.id = wp.category_id
      where wp.gym_id = v_gym_id and wp.is_active = true
        and public.member_can_access_workout_plan(v_gym_id, wp.id)
    ), '[]'::json),
    'recent_workout_logs', coalesce((
      select json_agg(json_build_object(
        'day_label', ws.day_label,
        'completed_at', l.completed_at,
        'skipped', l.skipped
      ) order by l.completed_at desc)
      from (
        select l.completed_at, l.skipped, ws.day_label
        from public.member_workout_session_logs l
        join public.workout_sessions ws on ws.id = l.workout_session_id
        where l.member_id = v_member_id
        order by l.completed_at desc limit 8
      ) l
    ), '[]'::json)
  )
  into result
  from public.members m
  join public.gyms g on g.id = m.gym_id
  where m.id = v_member_id;

  return result;
end;
$$;

grant execute on function public.get_member_fitness_chat_context() to authenticated;
