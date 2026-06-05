-- Member app profile setup: weight, height, age, goal.

alter table public.members
  add column if not exists weight_kg numeric(5, 2),
  add column if not exists height_cm numeric(5, 2),
  add column if not exists age smallint,
  add column if not exists gender text,
  add column if not exists fitness_goal text,
  add column if not exists profile_setup_completed_at timestamptz;

alter table public.members
  drop constraint if exists members_gender_check;

alter table public.members
  add constraint members_gender_check
  check (gender is null or gender in ('male', 'female', 'other', 'prefer_not_to_say'));

alter table public.members
  drop constraint if exists members_fitness_goal_check;

alter table public.members
  add constraint members_fitness_goal_check
  check (fitness_goal is null or fitness_goal in ('weight_loss', 'muscle_gain', 'healthy'));

create or replace function public.save_my_profile_setup(
  p_weight_kg numeric,
  p_height_cm numeric,
  p_age int,
  p_gender text default null,
  p_fitness_goal text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated.';
  end if;

  select m.id
  into v_member_id
  from public.gym_roles r
  join public.members m
    on m.gym_id = r.gym_id
   and m.user_id = r.user_id
  where r.user_id = auth.uid()
    and r.role = 'member'
  limit 1;

  if v_member_id is null then
    raise exception 'No membership linked to this account.';
  end if;

  update public.members
  set
    weight_kg = p_weight_kg,
    height_cm = p_height_cm,
    age = p_age,
    gender = p_gender,
    fitness_goal = p_fitness_goal,
    profile_setup_completed_at = timezone('utc', now()),
    updated_at = timezone('utc', now())
  where id = v_member_id;
end;
$$;

grant execute on function public.save_my_profile_setup(numeric, numeric, int, text, text) to authenticated;

create or replace function public.get_my_member_profile()
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
    'gym_address', g.address,
    'gym_phone', g.phone,
    'full_name', m.full_name,
    'email', m.email,
    'phone', m.phone,
    'member_status', m.status,
    'joined_on', m.joined_on,
    'date_of_birth', m.date_of_birth,
    'emergency_contact', m.emergency_contact,
    'notes', m.notes,
    'weight_kg', m.weight_kg,
    'height_cm', m.height_cm,
    'age', m.age,
    'gender', m.gender,
    'fitness_goal', m.fitness_goal,
    'profile_setup_completed_at', m.profile_setup_completed_at,
    'auth_email', u.email,
    'subscription', (
      select json_build_object(
        'id', ms.id,
        'plan_name', sp.name,
        'plan_description', sp.description,
        'duration_days', sp.duration_days,
        'start_date', ms.start_date,
        'end_date', ms.end_date,
        'payment_status', ms.payment_status,
        'amount_paid', ms.amount_paid,
        'plan_price', sp.price,
        'status', ms.status
      )
      from public.member_subscriptions ms
      join public.subscription_plans sp on sp.id = ms.plan_id
      where ms.member_id = m.id
        and ms.gym_id = r.gym_id
        and ms.status = 'active'
      order by ms.end_date desc
      limit 1
    ),
    'attendance_stats', (
      select json_build_object(
        'total_visits', count(*)::int,
        'last_check_in_at', max(ar.check_in_at),
        'is_checked_in', coalesce(bool_or(ar.check_out_at is null), false)
      )
      from public.attendance_records ar
      where ar.member_id = m.id
        and ar.gym_id = r.gym_id
    )
  )
  into ctx
  from public.gym_roles r
  join public.members m
    on m.gym_id = r.gym_id
   and m.user_id = r.user_id
  join public.gyms g on g.id = r.gym_id
  left join auth.users u on u.id = auth.uid()
  where r.user_id = auth.uid()
    and r.role = 'member'
  limit 1;

  return ctx;
end;
$$;
