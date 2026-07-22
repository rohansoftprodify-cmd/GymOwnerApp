-- Ensure member diet plan detail RPC exists and resolves membership via members.user_id.

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
  order by m.created_at desc
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
      select json_agg(meal_row order by meal_row.sort_order, meal_row.meal_label)
      from (
        select
          dm.id,
          dm.meal_label,
          dm.meal_time,
          dm.guidance,
          dm.sort_order,
          coalesce((
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
          ), '[]'::json) as foods
        from public.diet_meals dm
        where dm.diet_plan_id = dp.id
          and dm.gym_id = v_gym_id
      ) meal_row
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
