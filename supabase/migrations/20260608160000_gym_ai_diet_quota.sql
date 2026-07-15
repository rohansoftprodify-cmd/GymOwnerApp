-- Monthly quota for paid AI diet enhancements (template generation is unlimited).

create table if not exists public.gym_ai_usage (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  feature text not null check (feature in ('diet_ai')),
  usage_month date not null,
  usage_count int not null default 0 check (usage_count >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, feature, usage_month)
);

create index if not exists idx_gym_ai_usage_gym_month
  on public.gym_ai_usage (gym_id, feature, usage_month);

create trigger gym_ai_usage_touch_updated_at
before update on public.gym_ai_usage
for each row execute function public.touch_updated_at();

alter table public.gym_ai_usage enable row level security;

create policy gym_ai_usage_select on public.gym_ai_usage
  for select using (public.current_user_is_gym_member(gym_id));

create or replace function public.get_gym_ai_diet_quota(
  p_gym_id uuid,
  p_monthly_limit int default 5
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
    and feature = 'diet_ai'
    and usage_month = month_start;

  return json_build_object(
    'used', current_count,
    'limit', p_monthly_limit,
    'remaining', greatest(p_monthly_limit - current_count, 0),
    'month', to_char(month_start, 'YYYY-MM')
  );
end;
$$;

create or replace function public.consume_gym_ai_diet_quota(
  p_gym_id uuid,
  p_monthly_limit int default 5
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
  values (p_gym_id, 'diet_ai', month_start, 0)
  on conflict (gym_id, feature, usage_month) do nothing;

  select usage_count
  into current_count
  from public.gym_ai_usage
  where gym_id = p_gym_id
    and feature = 'diet_ai'
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
    and feature = 'diet_ai'
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

grant execute on function public.get_gym_ai_diet_quota(uuid, int) to authenticated;
grant execute on function public.consume_gym_ai_diet_quota(uuid, int) to authenticated;
