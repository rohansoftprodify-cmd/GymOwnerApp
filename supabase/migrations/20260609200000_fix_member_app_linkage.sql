-- Member app login: resolve membership via members.user_id (owner "linked" flag),
-- not only gym_roles.role = 'member'. Backfill missing roles for existing links.

-- 1) RLS helper: linked member row OR explicit member gym_role.
create or replace function public.current_user_is_gym_app_user(target_gym_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.gym_id = target_gym_id
      and m.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role = 'member'
  );
$$;

-- 2) Shared resolver for member-app RPCs.
create or replace function public.current_auth_member_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select m.id
  from public.members m
  where m.user_id = auth.uid()
  limit 1;
$$;

-- 3) Ensure profile + member gym_role exist when members.user_id is set.
create or replace function public.sync_member_app_linkage()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.user_id is null then
    return new;
  end if;

  insert into public.profiles (id, full_name, phone)
  values (new.user_id, new.full_name, new.phone)
  on conflict (id) do update
  set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    phone = coalesce(excluded.phone, public.profiles.phone);

  insert into public.gym_roles (gym_id, user_id, role)
  values (new.gym_id, new.user_id, 'member')
  on conflict (gym_id, user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists members_sync_app_linkage on public.members;

create trigger members_sync_app_linkage
after insert or update of user_id, gym_id, full_name, phone on public.members
for each row
execute function public.sync_member_app_linkage();

-- 4) Backfill existing linked members missing profiles / gym_roles.
insert into public.profiles (id, full_name, phone)
select m.user_id, m.full_name, m.phone
from public.members m
where m.user_id is not null
on conflict (id) do nothing;

insert into public.gym_roles (gym_id, user_id, role)
select m.gym_id, m.user_id, 'member'
from public.members m
where m.user_id is not null
  and not exists (
    select 1
    from public.gym_roles r
    where r.gym_id = m.gym_id
      and r.user_id = m.user_id
  )
on conflict (gym_id, user_id) do nothing;

-- 5) Member app context (login + shell).
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
    'gym_id', m.gym_id,
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
        and ms.gym_id = m.gym_id
        and ms.status = 'active'
      order by ms.end_date desc
      limit 1
    )
  )
  into ctx
  from public.members m
  join public.gyms g on g.id = m.gym_id
  where m.user_id = auth.uid()
  limit 1;

  return ctx;
end;
$$;

grant execute on function public.get_my_member_context() to authenticated;

-- 6) Profile read RPC.
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
    'gym_id', m.gym_id,
    'member_id', m.id,
    'gym_name', g.name,
    'gym_address', g.address,
    'gym_phone', g.phone,
    'full_name', m.full_name,
    'email', m.email,
    'phone', m.phone,
    'address', m.address,
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
    'profile_updated_at', m.profile_updated_at,
    'bmi', case
      when m.weight_kg is not null and m.height_cm is not null and m.height_cm > 0 then
        round((m.weight_kg / power(m.height_cm / 100.0, 2))::numeric, 1)
      else null
    end,
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
        and ms.gym_id = m.gym_id
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
        and ar.gym_id = m.gym_id
    )
  )
  into ctx
  from public.members m
  join public.gyms g on g.id = m.gym_id
  left join auth.users u on u.id = auth.uid()
  where m.user_id = auth.uid()
  limit 1;

  return ctx;
end;
$$;

grant execute on function public.get_my_member_profile() to authenticated;

-- 7) Profile update RPC.
create or replace function public.update_my_member_profile(
  p_phone text default null,
  p_emergency_contact text default null,
  p_date_of_birth date default null,
  p_address text default null,
  p_weight_kg numeric default null,
  p_height_cm numeric default null,
  p_age int default null,
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

  if p_gender is not null and p_gender not in ('male', 'female', 'other', 'prefer_not_to_say') then
    raise exception 'Invalid gender value.';
  end if;

  if p_fitness_goal is not null and p_fitness_goal not in ('weight_loss', 'muscle_gain', 'healthy') then
    raise exception 'Invalid fitness goal value.';
  end if;

  v_member_id := public.current_auth_member_id();

  if v_member_id is null then
    raise exception 'No membership linked to this account.';
  end if;

  update public.members
  set
    phone = nullif(trim(p_phone), ''),
    emergency_contact = nullif(trim(p_emergency_contact), ''),
    date_of_birth = p_date_of_birth,
    address = nullif(trim(p_address), ''),
    weight_kg = p_weight_kg,
    height_cm = p_height_cm,
    age = p_age,
    gender = p_gender,
    fitness_goal = p_fitness_goal,
    profile_setup_completed_at = coalesce(profile_setup_completed_at, timezone('utc', now())),
    profile_updated_at = timezone('utc', now()),
    updated_at = timezone('utc', now())
  where id = v_member_id;
end;
$$;

grant execute on function public.update_my_member_profile(
  text, text, date, text, numeric, numeric, int, text, text
) to authenticated;
