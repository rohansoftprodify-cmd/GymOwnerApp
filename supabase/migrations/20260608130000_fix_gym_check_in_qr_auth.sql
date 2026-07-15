-- Fix get_gym_check_in_qr: owners/staff were blocked because gym_app_user = member role only.

create or replace function public.get_gym_check_in_qr(p_gym_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  gym_row public.gyms;
begin
  if not public.current_user_is_gym_member(p_gym_id)
     and not public.current_user_is_superadmin() then
    raise exception 'Unauthorized for this gym.';
  end if;

  select * into gym_row from public.gyms where id = p_gym_id;
  if not found then
    raise exception 'Gym not found.';
  end if;

  return json_build_object(
    'gym_id', gym_row.id,
    'gym_name', gym_row.name,
    'qr_payload', public.gym_check_in_qr_payload(gym_row.id),
    'deep_link', 'gymmember://checkin?gymId=' || gym_row.id::text
  );
end;
$$;
