-- Require members to be within gym coordinates for self check-in (QR + location).

create or replace function public.haversine_distance_meters(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
)
returns double precision
language sql
immutable
as $$
  select 6371000.0 * 2 * asin(
    sqrt(
      power(sin(radians(lat2 - lat1) / 2), 2)
      + cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lon2 - lon1) / 2), 2)
    )
  );
$$;

create or replace function public.assert_member_near_gym(
  p_gym_id uuid,
  p_latitude double precision,
  p_longitude double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  gym_lat double precision;
  gym_lng double precision;
  gym_radius int;
  distance_m double precision;
begin
  if p_latitude is null or p_longitude is null then
    raise exception 'Location is required for gym check-in.';
  end if;

  select g.latitude, g.longitude, g.check_in_radius_meters
  into gym_lat, gym_lng, gym_radius
  from public.gyms g
  where g.id = p_gym_id;

  if not found then
    raise exception 'Gym not found.';
  end if;

  if gym_lat is null or gym_lng is null then
    raise exception 'Gym check-in location is not configured. Ask the owner to set coordinates in gym profile.';
  end if;

  distance_m := public.haversine_distance_meters(p_latitude, p_longitude, gym_lat, gym_lng);

  if distance_m > gym_radius then
    raise exception 'You are % m from the gym. Move within % m to check in.',
      round(distance_m::numeric, 0),
      gym_radius;
  end if;
end;
$$;

drop function if exists public.member_mark_my_attendance(uuid, text);

create or replace function public.member_mark_my_attendance(
  p_gym_id uuid,
  p_action text,
  p_latitude double precision,
  p_longitude double precision
)
returns public.attendance_records
language plpgsql
security definer
set search_path = public
as $$
declare
  linked_member_id uuid;
  open_record public.attendance_records;
  created_record public.attendance_records;
begin
  if p_action not in ('check_in', 'check_out') then
    raise exception 'Invalid action. Use check_in or check_out.';
  end if;

  if not public.current_user_is_gym_app_user(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  perform public.assert_member_near_gym(p_gym_id, p_latitude, p_longitude);

  linked_member_id := public.current_user_linked_member_id(p_gym_id);
  if linked_member_id is null then
    raise exception 'No membership linked to this account.';
  end if;

  select *
  into open_record
  from public.attendance_records ar
  where ar.gym_id = p_gym_id
    and ar.member_id = linked_member_id
    and ar.check_out_at is null
  order by ar.check_in_at desc
  limit 1;

  if p_action = 'check_in' then
    if open_record.id is not null then
      raise exception 'You are already checked in.';
    end if;

    insert into public.attendance_records (gym_id, member_id, check_in_at, marked_by)
    values (p_gym_id, linked_member_id, timezone('utc', now()), auth.uid())
    returning * into created_record;

    return created_record;
  end if;

  if open_record.id is null then
    raise exception 'No open check-in found to check out.';
  end if;

  update public.attendance_records
  set check_out_at = timezone('utc', now())
  where id = open_record.id
  returning * into created_record;

  return created_record;
end;
$$;

grant execute on function public.member_mark_my_attendance(uuid, text, double precision, double precision) to authenticated;

drop function if exists public.member_mark_attendance_from_qr(text, text);

create or replace function public.member_mark_attendance_from_qr(
  p_raw text,
  p_action text,
  p_latitude double precision,
  p_longitude double precision
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  parsed_gym_id uuid;
  att_row public.attendance_records;
  member_name text;
begin
  if p_action not in ('check_in', 'check_out') then
    raise exception 'Invalid action. Use check_in or check_out.';
  end if;

  parsed_gym_id := public.parse_gym_check_in_qr_raw(p_raw);
  if parsed_gym_id is null then
    raise exception 'Invalid gym QR code.';
  end if;

  select m.full_name
  into member_name
  from public.members m
  where m.gym_id = parsed_gym_id
    and m.user_id = auth.uid();

  att_row := public.member_mark_my_attendance(parsed_gym_id, p_action, p_latitude, p_longitude);

  return json_build_object(
    'success', true,
    'action', p_action,
    'gym_id', parsed_gym_id,
    'member_name', coalesce(member_name, 'Member'),
    'attendance_id', att_row.id,
    'check_in_at', att_row.check_in_at,
    'check_out_at', att_row.check_out_at
  );
end;
$$;

grant execute on function public.member_mark_attendance_from_qr(text, text, double precision, double precision) to authenticated;
