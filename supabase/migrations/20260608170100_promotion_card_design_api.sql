-- Include offer card_design in public gym detail promotions payload.

create or replace function public.get_directory_gym_detail(p_gym_id uuid)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result json;
begin
  select json_build_object(
    'gym', (
      select json_build_object(
        'id', g.id,
        'name', g.name,
        'address', g.address,
        'phone', g.phone,
        'email', g.email,
        'timezone', g.timezone,
        'latitude', g.latitude,
        'longitude', g.longitude,
        'check_in_radius_meters', g.check_in_radius_meters
      )
      from public.gyms g
      where g.id = p_gym_id
    ),
    'hours', coalesce((
      select json_agg(
        json_build_object(
          'day_of_week', h.day_of_week,
          'is_closed', h.is_closed,
          'open_time', h.open_time,
          'close_time', h.close_time
        )
        order by h.day_of_week
      )
      from public.gym_operating_hours h
      where h.gym_id = p_gym_id
    ), '[]'::json),
    'promotions', coalesce((
      select json_agg(
        json_build_object(
          'id', p.id,
          'title', p.title,
          'description', p.description,
          'start_at', p.start_at,
          'end_at', p.end_at,
          'card_design', p.card_design
        )
        order by p.end_at
      )
      from public.promotions p
      where p.gym_id = p_gym_id
        and p.is_active = true
        and p.start_at <= timezone('utc', now())
        and p.end_at >= timezone('utc', now())
    ), '[]'::json)
  )
  into result;

  if result is null or result->'gym' is null or json_typeof(result->'gym') = 'null' then
    return null;
  end if;

  return result;
end;
$$;
