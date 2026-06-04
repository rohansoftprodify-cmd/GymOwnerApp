-- Public gym directory for member app discovery (anon + authenticated).

create or replace function public.list_directory_gyms()
returns table (
  id uuid,
  name text,
  address text,
  phone text,
  email text,
  timezone text
)
language sql
stable
security definer
set search_path = public
as $$
  select g.id, g.name, g.address, g.phone, g.email, g.timezone
  from public.gyms g
  order by g.name asc;
$$;

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
        'timezone', g.timezone
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
          'end_at', p.end_at
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

grant execute on function public.list_directory_gyms() to anon, authenticated;
grant execute on function public.get_directory_gym_detail(uuid) to anon, authenticated;
