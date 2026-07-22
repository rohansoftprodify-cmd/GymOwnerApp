-- Provision gym owner after Auth user exists.
--
-- BEFORE RUNNING:
-- 1) Supabase Dashboard → Authentication → Users → Add user
--    Email:    clubguptafitness@gmail.com
--    Password: (the password you chose)
--    Auto Confirm User: ON
-- 2) Then run this script in SQL Editor.
--
-- Leaves setup_completed_at NULL so first login opens the owner setup wizard.

do $$
declare
  v_user_id uuid;
  v_gym_id uuid := gen_random_uuid();
  v_email text := 'clubguptafitness@gmail.com';
  v_gym_name text := 'Gupta Fitness Club';
  v_owner_name text := 'Gupta Fitness Owner';
begin
  select id into v_user_id
  from auth.users
  where lower(email) = lower(v_email)
  limit 1;

  if v_user_id is null then
    raise exception
      'Auth user % not found. Create the user first in Authentication → Users (Auto Confirm ON), then re-run this script.',
      v_email;
  end if;

  insert into public.profiles (id, full_name, phone)
  values (v_user_id, v_owner_name, null)
  on conflict (id) do update
  set full_name = excluded.full_name;

  insert into public.gyms (
    id,
    name,
    email,
    phone,
    address,
    timezone,
    currency_code,
    setup_completed_at
  )
  values (
    v_gym_id,
    v_gym_name,
    v_email,
    null,
    null,
    'Asia/Kolkata',
    'INR',
    null
  );

  insert into public.gym_roles (gym_id, user_id, role)
  values (v_gym_id, v_user_id, 'owner')
  on conflict (gym_id, user_id) do update
  set role = 'owner';

  raise notice 'Owner ready. user_id=%, gym_id=%, gym=%', v_user_id, v_gym_id, v_gym_name;
end $$;

-- Verify:
select
  u.email,
  p.full_name,
  g.name as gym_name,
  r.role,
  g.setup_completed_at
from auth.users u
join public.profiles p on p.id = u.id
join public.gym_roles r on r.user_id = u.id
join public.gyms g on g.id = r.gym_id
where lower(u.email) = 'clubguptafitness@gmail.com';
