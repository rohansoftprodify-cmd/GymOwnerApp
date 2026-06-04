-- Member app accounts: link auth users to gym members with role = 'member'.
-- Requires 20260603180000_member_role_enum.sql applied first.

alter table public.members
  add column if not exists user_id uuid references auth.users (id) on delete set null;

create unique index if not exists idx_members_user_id_unique
  on public.members (user_id)
  where user_id is not null;

-- Restrict CRM/staff helper to owner + staff only (exclude member role).
create or replace function public.current_user_is_gym_member(target_gym_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role in ('owner', 'staff')
  );
$$;

create or replace function public.current_user_is_gym_app_user(target_gym_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role = 'member'
  );
$$;

create or replace function public.current_user_linked_member_id(target_gym_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select m.id
  from public.members m
  where m.gym_id = target_gym_id
    and m.user_id = auth.uid()
  limit 1;
$$;

-- Member can read own CRM row (staff policies still apply for owner/staff).
create policy members_self_select on public.members
  for select
  using (id = public.current_user_linked_member_id(gym_id));

create policy gyms_member_select on public.gyms
  for select
  using (public.current_user_is_gym_app_user(id));

create policy attendance_self_select on public.attendance_records
  for select
  using (member_id = public.current_user_linked_member_id(gym_id));

create policy subscriptions_self_select on public.member_subscriptions
  for select
  using (member_id = public.current_user_linked_member_id(gym_id));

create policy plans_member_select on public.subscription_plans
  for select
  using (public.current_user_is_gym_app_user(gym_id) and is_active = true);

create policy promotions_member_select on public.promotions
  for select
  using (public.current_user_is_gym_app_user(gym_id) and is_active = true);

create policy gym_hours_member_select on public.gym_operating_hours
  for select
  using (public.current_user_is_gym_app_user(gym_id));

create policy exercise_categories_member_select on public.exercise_categories
  for select
  using (public.current_user_is_gym_app_user(gym_id));

create policy exercises_member_select on public.exercises
  for select
  using (public.current_user_is_gym_app_user(gym_id) and is_active = true);

create policy diet_categories_member_select on public.diet_plan_categories
  for select
  using (public.current_user_is_gym_app_user(gym_id));

create policy diet_plans_member_select on public.diet_plans
  for select
  using (public.current_user_is_gym_app_user(gym_id) and is_active = true);

create policy diet_meals_member_select on public.diet_meals
  for select
  using (public.current_user_is_gym_app_user(gym_id));

create policy diet_food_items_member_select on public.diet_food_items
  for select
  using (public.current_user_is_gym_app_user(gym_id));

create policy exercise_images_member_select on storage.objects
  for select
  using (
    bucket_id = 'exercise-images'
    and public.current_user_is_gym_app_user(((storage.foldername(name))[1])::uuid)
  );

create policy diet_images_member_select on storage.objects
  for select
  using (
    bucket_id = 'diet-images'
    and public.current_user_is_gym_app_user(((storage.foldername(name))[1])::uuid)
  );

-- Context payload for the member mobile app.
create or replace function public.get_my_member_context()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  ctx json;
begin
  if auth.uid() is null then
    return null;
  end if;

  select json_build_object(
    'gym_id', r.gym_id,
    'member_id', m.id,
    'gym_name', g.name,
    'full_name', m.full_name,
    'email', m.email,
    'phone', m.phone,
    'member_status', m.status,
    'subscription', (
      select json_build_object(
        'id', ms.id,
        'plan_name', sp.name,
        'start_date', ms.start_date,
        'end_date', ms.end_date,
        'payment_status', ms.payment_status,
        'amount_paid', ms.amount_paid,
        'plan_price', sp.price
      )
      from public.member_subscriptions ms
      join public.subscription_plans sp on sp.id = ms.plan_id
      where ms.member_id = m.id
        and ms.gym_id = r.gym_id
        and ms.status = 'active'
      order by ms.end_date desc
      limit 1
    )
  )
  into ctx
  from public.gym_roles r
  join public.members m
    on m.gym_id = r.gym_id
   and m.user_id = r.user_id
  join public.gyms g on g.id = r.gym_id
  where r.user_id = auth.uid()
    and r.role = 'member'
  limit 1;

  return ctx;
end;
$$;

grant execute on function public.get_my_member_context() to authenticated;
