-- Member self-service profile update (contact + body metrics).

create or replace function public.update_my_member_profile(
  p_phone text default null,
  p_emergency_contact text default null,
  p_date_of_birth date default null,
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
    phone = nullif(trim(p_phone), ''),
    emergency_contact = nullif(trim(p_emergency_contact), ''),
    date_of_birth = p_date_of_birth,
    weight_kg = p_weight_kg,
    height_cm = p_height_cm,
    age = p_age,
    gender = p_gender,
    fitness_goal = p_fitness_goal,
    profile_setup_completed_at = coalesce(profile_setup_completed_at, timezone('utc', now())),
    updated_at = timezone('utc', now())
  where id = v_member_id;
end;
$$;

grant execute on function public.update_my_member_profile(text, text, date, numeric, numeric, int, text, text) to authenticated;
