-- Link diet plans to membership (subscription) plans — many-to-many, optional per diet plan.
-- Members see a diet plan when it has no links (general) or their active subscription plan is linked.

create table if not exists public.subscription_plan_diet_plans (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  subscription_plan_id uuid not null references public.subscription_plans (id) on delete cascade,
  diet_plan_id uuid not null references public.diet_plans (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  unique (subscription_plan_id, diet_plan_id)
);

create index if not exists idx_spd_gym on public.subscription_plan_diet_plans (gym_id);
create index if not exists idx_spd_diet_plan on public.subscription_plan_diet_plans (diet_plan_id);
create index if not exists idx_spd_subscription_plan on public.subscription_plan_diet_plans (subscription_plan_id);

create or replace function public.validate_subscription_plan_diet_plan_link()
returns trigger
language plpgsql
as $$
declare
  sub_gym uuid;
  diet_gym uuid;
begin
  select gym_id into sub_gym
  from public.subscription_plans
  where id = new.subscription_plan_id;

  select gym_id into diet_gym
  from public.diet_plans
  where id = new.diet_plan_id;

  if sub_gym is null or diet_gym is null or sub_gym <> diet_gym then
    raise exception 'Subscription plan and diet plan must belong to the same gym.';
  end if;

  new.gym_id := sub_gym;
  return new;
end;
$$;

drop trigger if exists subscription_plan_diet_plans_validate on public.subscription_plan_diet_plans;
create trigger subscription_plan_diet_plans_validate
before insert or update on public.subscription_plan_diet_plans
for each row execute function public.validate_subscription_plan_diet_plan_link();

alter table public.subscription_plan_diet_plans enable row level security;

create policy subscription_plan_diet_plans_gym_scope_select
  on public.subscription_plan_diet_plans
  for select
  using (public.current_user_is_gym_member(gym_id));

create policy subscription_plan_diet_plans_gym_scope_write
  on public.subscription_plan_diet_plans
  for all
  using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create or replace function public.member_can_access_diet_plan(
  p_gym_id uuid,
  p_diet_plan_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.diet_plans dp
    where dp.id = p_diet_plan_id
      and dp.gym_id = p_gym_id
      and dp.is_active = true
  )
  and (
    not exists (
      select 1
      from public.subscription_plan_diet_plans spd
      where spd.diet_plan_id = p_diet_plan_id
        and spd.gym_id = p_gym_id
    )
    or exists (
      select 1
      from public.member_subscriptions ms
      join public.subscription_plan_diet_plans spd
        on spd.subscription_plan_id = ms.plan_id
       and spd.gym_id = ms.gym_id
      where ms.member_id = public.current_user_linked_member_id(p_gym_id)
        and ms.gym_id = p_gym_id
        and ms.status = 'active'
        and ms.end_date >= current_date
        and spd.diet_plan_id = p_diet_plan_id
    )
  );
$$;

drop policy if exists diet_plans_member_select on public.diet_plans;
create policy diet_plans_member_select on public.diet_plans
  for select
  using (
    public.current_user_is_gym_app_user(gym_id)
    and is_active = true
    and public.member_can_access_diet_plan(gym_id, id)
  );

drop policy if exists diet_meals_member_select on public.diet_meals;
create policy diet_meals_member_select on public.diet_meals
  for select
  using (
    public.current_user_is_gym_app_user(gym_id)
    and public.member_can_access_diet_plan(gym_id, diet_plan_id)
  );

drop policy if exists diet_food_items_member_select on public.diet_food_items;
create policy diet_food_items_member_select on public.diet_food_items
  for select
  using (
    public.current_user_is_gym_app_user(gym_id)
    and exists (
      select 1
      from public.diet_meals dm
      where dm.id = diet_meal_id
        and public.member_can_access_diet_plan(gym_id, dm.diet_plan_id)
    )
  );

create or replace function public.set_diet_plan_subscription_links(
  p_gym_id uuid,
  p_diet_plan_id uuid,
  p_subscription_plan_ids uuid[] default '{}'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  plan_ids uuid[];
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  if not exists (
    select 1
    from public.diet_plans dp
    where dp.id = p_diet_plan_id
      and dp.gym_id = p_gym_id
  ) then
    raise exception 'Diet plan not found for this gym.';
  end if;

  plan_ids := coalesce(p_subscription_plan_ids, '{}');

  if exists (
    select 1
    from unnest(plan_ids) as pid(plan_id)
    left join public.subscription_plans sp
      on sp.id = pid.plan_id
     and sp.gym_id = p_gym_id
    where sp.id is null
  ) then
    raise exception 'One or more membership plans are invalid for this gym.';
  end if;

  delete from public.subscription_plan_diet_plans
  where gym_id = p_gym_id
    and diet_plan_id = p_diet_plan_id;

  insert into public.subscription_plan_diet_plans (gym_id, subscription_plan_id, diet_plan_id)
  select p_gym_id, pid.plan_id, p_diet_plan_id
  from unnest(plan_ids) as pid(plan_id)
  on conflict (subscription_plan_id, diet_plan_id) do nothing;
end;
$$;

grant execute on function public.set_diet_plan_subscription_links(uuid, uuid, uuid[]) to authenticated;

create or replace function public.get_my_diet_plans()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_gym_id uuid;
  v_member_id uuid;
  result json;
begin
  if auth.uid() is null then
    return '[]'::json;
  end if;

  select r.gym_id, m.id
  into v_gym_id, v_member_id
  from public.gym_roles r
  join public.members m
    on m.gym_id = r.gym_id
   and m.user_id = r.user_id
  where r.user_id = auth.uid()
    and r.role = 'member'
  limit 1;

  if v_gym_id is null or v_member_id is null then
    return '[]'::json;
  end if;

  select coalesce(json_agg(row_to_json(t) order by t.name), '[]'::json)
  into result
  from (
    select
      dp.id,
      dp.name,
      dp.description,
      dp.image_path,
      dp.target_calories,
      dp.target_protein_g,
      dp.target_carbs_g,
      dp.target_fat_g,
      dp.hydration_liters,
      dp.duration_days,
      dpc.goal_key,
      dpc.name as category_name,
      (
        select coalesce(json_agg(sp.name order by sp.name), '[]'::json)
        from public.subscription_plan_diet_plans spd
        join public.subscription_plans sp on sp.id = spd.subscription_plan_id
        where spd.diet_plan_id = dp.id
          and spd.gym_id = dp.gym_id
      ) as linked_membership_plans
    from public.diet_plans dp
    join public.diet_plan_categories dpc on dpc.id = dp.category_id
    where dp.gym_id = v_gym_id
      and dp.is_active = true
      and public.member_can_access_diet_plan(v_gym_id, dp.id)
  ) t;

  return result;
end;
$$;

grant execute on function public.get_my_diet_plans() to authenticated;

create policy subscription_plan_diet_plans_superadmin_all
  on public.subscription_plan_diet_plans
  for all
  using (public.current_user_is_superadmin())
  with check (public.current_user_is_superadmin());
