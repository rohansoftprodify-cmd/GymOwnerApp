-- Gym amenities / facilities offered (selectable by owner, shown in member app).

alter table public.gyms
  add column if not exists amenities text[] not null default '{}';

comment on column public.gyms.amenities is
  'Facility feature keys offered by this gym (e.g. yoga, swimming_pool, crossfit).';

create or replace function public.sanitize_gym_amenities(p_amenities text[])
returns text[]
language sql
immutable
as $$
  select coalesce(
    array_agg(distinct a order by a),
    '{}'::text[]
  )
  from unnest(coalesce(p_amenities, '{}'::text[])) as a
  where a in (
    'personal_training',
    'gym_floor',
    'spa',
    'zumba',
    'bhangra',
    'yoga',
    'steam_bath',
    'swimming_pool',
    'open_gym',
    'cafe',
    'sauna',
    'crossfit',
    'pool'
  );
$$;

-- Return type adds amenities column; must drop before replace.
drop function if exists public.list_directory_gyms();

create function public.list_directory_gyms()
returns table (
  id uuid,
  name text,
  address text,
  phone text,
  email text,
  timezone text,
  amenities text[]
)
language sql
stable
security definer
set search_path = public
as $$
  select
    g.id,
    g.name,
    g.address,
    g.phone,
    g.email,
    g.timezone,
    public.sanitize_gym_amenities(g.amenities)
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
        'timezone', g.timezone,
        'latitude', g.latitude,
        'longitude', g.longitude,
        'check_in_radius_meters', g.check_in_radius_meters,
        'amenities', to_json(public.sanitize_gym_amenities(g.amenities))
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

grant execute on function public.sanitize_gym_amenities(text[]) to authenticated;

create or replace function public.gyms_sanitize_amenities_trigger()
returns trigger
language plpgsql
as $$
begin
  new.amenities := public.sanitize_gym_amenities(new.amenities);
  return new;
end;
$$;

drop trigger if exists gyms_sanitize_amenities on public.gyms;

create trigger gyms_sanitize_amenities
before insert or update of amenities on public.gyms
for each row
execute function public.gyms_sanitize_amenities_trigger();

grant execute on function public.list_directory_gyms() to anon, authenticated;
grant execute on function public.get_directory_gym_detail(uuid) to anon, authenticated;
