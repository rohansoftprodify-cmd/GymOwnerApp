-- AI Marketing Assistant quota (template generation is unlimited on-device).

alter table public.gym_ai_usage
  drop constraint if exists gym_ai_usage_feature_check;

alter table public.gym_ai_usage
  add constraint gym_ai_usage_feature_check
  check (feature in ('diet_ai', 'marketing_ai'));

create or replace function public.get_gym_ai_marketing_quota(
  p_gym_id uuid,
  p_monthly_limit int default 10
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  month_start date := date_trunc('month', timezone('utc', now()))::date;
  current_count int := 0;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  select coalesce(usage_count, 0)
  into current_count
  from public.gym_ai_usage
  where gym_id = p_gym_id
    and feature = 'marketing_ai'
    and usage_month = month_start;

  return json_build_object(
    'used', current_count,
    'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0),
    'month', to_char(month_start, 'YYYY-MM')
  );
end;
$$;

create or replace function public.consume_gym_ai_marketing_quota(
  p_gym_id uuid,
  p_monthly_limit int default 10
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  month_start date := date_trunc('month', timezone('utc', now()))::date;
  current_count int := 0;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  insert into public.gym_ai_usage (gym_id, feature, usage_month, usage_count)
  values (p_gym_id, 'marketing_ai', month_start, 0)
  on conflict (gym_id, feature, usage_month) do nothing;

  select usage_count
  into current_count
  from public.gym_ai_usage
  where gym_id = p_gym_id
    and feature = 'marketing_ai'
    and usage_month = month_start
  for update;

  if current_count >= p_monthly_limit then
    return json_build_object(
      'allowed', false,
      'used', current_count,
      'limit', p_monthly_limit,
      'remaining', 0,
      'month', to_char(month_start, 'YYYY-MM')
    );
  end if;

  update public.gym_ai_usage
  set usage_count = usage_count + 1
  where gym_id = p_gym_id
    and feature = 'marketing_ai'
    and usage_month = month_start
  returning usage_count into current_count;

  return json_build_object(
    'allowed', true,
    'used', current_count,
    'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0),
    'month', to_char(month_start, 'YYYY-MM')
  );
end;
$$;

grant execute on function public.get_gym_ai_marketing_quota(uuid, int) to authenticated;
grant execute on function public.consume_gym_ai_marketing_quota(uuid, int) to authenticated;
