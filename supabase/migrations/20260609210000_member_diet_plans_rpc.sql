-- Member app: diet plan list + detail (uses members.user_id linkage).

create or replace function public.get_my_diet_plans()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_gym_id uuid;
  result json;
begin
  if auth.uid() is null then
    return '[]'::json;
  end if;

  select m.gym_id
  into v_gym_id
  from public.members m
  where m.user_id = auth.uid()
  limit 1;

  if v_gym_id is null then
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
        select count(*)::int
        from public.diet_meals dm
        where dm.diet_plan_id = dp.id
      ) as meal_count,
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

create or replace function public.get_my_diet_plan_detail(p_diet_plan_id uuid)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_gym_id uuid;
  result json;
begin
  if auth.uid() is null then
    return null;
  end if;

  select m.gym_id
  into v_gym_id
  from public.members m
  where m.user_id = auth.uid()
  limit 1;

  if v_gym_id is null then
    return null;
  end if;

  if not public.member_can_access_diet_plan(v_gym_id, p_diet_plan_id) then
    return null;
  end if;

  select json_build_object(
    'id', dp.id,
    'name', dp.name,
    'description', dp.description,
    'image_path', dp.image_path,
    'target_calories', dp.target_calories,
    'target_protein_g', dp.target_protein_g,
    'target_carbs_g', dp.target_carbs_g,
    'target_fat_g', dp.target_fat_g,
    'hydration_liters', dp.hydration_liters,
    'duration_days', dp.duration_days,
    'goal_key', dpc.goal_key,
    'category_name', dpc.name,
    'nutrition_tips', dpc.nutrition_tips,
    'meals', coalesce((
      select json_agg(
        json_build_object(
          'id', dm.id,
          'meal_label', dm.meal_label,
          'meal_time', dm.meal_time,
          'guidance', dm.guidance,
          'sort_order', dm.sort_order,
          'foods', coalesce((
            select json_agg(
              json_build_object(
                'id', df.id,
                'food_name', df.food_name,
                'portion', df.portion,
                'calories', df.calories,
                'protein_g', df.protein_g,
                'carbs_g', df.carbs_g,
                'fat_g', df.fat_g,
                'notes', df.notes,
                'sort_order', df.sort_order
              )
              order by df.sort_order, df.food_name
            )
            from public.diet_food_items df
            where df.diet_meal_id = dm.id
          ), '[]'::json)
        )
        order by dm.sort_order, dm.meal_label
      )
      from public.diet_meals dm
      where dm.diet_plan_id = dp.id
    ), '[]'::json)
  )
  into result
  from public.diet_plans dp
  join public.diet_plan_categories dpc on dpc.id = dp.category_id
  where dp.id = p_diet_plan_id
    and dp.gym_id = v_gym_id
    and dp.is_active = true;

  return result;
end;
$$;

grant execute on function public.get_my_diet_plan_detail(uuid) to authenticated;
