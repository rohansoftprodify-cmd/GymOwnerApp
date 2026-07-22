-- Primary payment QR flag (one per gym; auto-set when only one option exists).

alter table public.gym_payment_options
  add column if not exists is_primary boolean not null default false;

comment on column public.gym_payment_options.is_primary is
  'Default payment option shown first to members and in owner quick-view.';

create unique index if not exists idx_gym_payment_options_one_primary
  on public.gym_payment_options (gym_id)
  where is_primary = true and is_active = true;

create or replace function public.sync_gym_payment_primary()
returns trigger
language plpgsql
as $$
declare
  target_gym_id uuid;
  active_count int;
  primary_count int;
  default_id uuid;
begin
  target_gym_id := coalesce(new.gym_id, old.gym_id);

  select count(*)::int
  into active_count
  from public.gym_payment_options
  where gym_id = target_gym_id
    and is_active = true;

  if active_count = 0 then
    return coalesce(new, old);
  end if;

  if active_count = 1 then
    update public.gym_payment_options
    set is_primary = true
    where gym_id = target_gym_id
      and is_active = true;
    return coalesce(new, old);
  end if;

  select count(*)::int
  into primary_count
  from public.gym_payment_options
  where gym_id = target_gym_id
    and is_active = true
    and is_primary = true;

  if primary_count > 0 then
    return coalesce(new, old);
  end if;

  select id
  into default_id
  from public.gym_payment_options
  where gym_id = target_gym_id
    and is_active = true
  order by sort_order, created_at
  limit 1;

  update public.gym_payment_options
  set is_primary = (id = default_id)
  where gym_id = target_gym_id
    and is_active = true;

  return coalesce(new, old);
end;
$$;

drop trigger if exists gym_payment_options_sync_primary on public.gym_payment_options;

create trigger gym_payment_options_sync_primary
after insert or update of is_active, sort_order or delete
on public.gym_payment_options
for each row
execute function public.sync_gym_payment_primary();

-- Backfill: mark sole / first active option as primary per gym.
do $$
declare
  gym record;
begin
  for gym in
    select distinct gym_id
    from public.gym_payment_options
    where is_active = true
  loop
    perform 1
    from public.gym_payment_options
    where gym_id = gym.gym_id
      and is_active = true
      and is_primary = true;

    if not found then
      update public.gym_payment_options po
      set is_primary = true
      where po.id = (
        select id
        from public.gym_payment_options
        where gym_id = gym.gym_id
          and is_active = true
        order by sort_order, created_at
        limit 1
      );
    end if;
  end loop;
end;
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
    ), '[]'::json),
    'payment_options', coalesce((
      select json_agg(
        json_build_object(
          'id', po.id,
          'label', po.label,
          'upi_id', po.upi_id,
          'qr_image_path', po.qr_image_path,
          'sort_order', po.sort_order,
          'is_primary', po.is_primary
        )
        order by po.is_primary desc, po.sort_order, po.created_at
      )
      from public.gym_payment_options po
      where po.gym_id = p_gym_id
        and po.is_active = true
        and (
          coalesce(nullif(trim(po.upi_id), ''), null) is not null
          or coalesce(nullif(trim(po.qr_image_path), ''), null) is not null
        )
    ), '[]'::json)
  )
  into result;

  if result is null or result->'gym' is null or json_typeof(result->'gym') = 'null' then
    return null;
  end if;

  return result;
end;
$$;

grant execute on function public.get_directory_gym_detail(uuid) to anon, authenticated;
