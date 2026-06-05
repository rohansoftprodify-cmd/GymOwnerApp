-- Enrich public gym list with today's hours and active promotion count for directory cards.

create or replace function public.list_directory_gyms()
returns table (
  id uuid,
  name text,
  address text,
  phone text,
  email text,
  timezone text,
  today_hours_label text,
  is_open_today boolean,
  active_promotions_count int
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
    case
      when h.gym_id is null then null
      when h.is_closed then 'Closed today'
      else 'Open · ' || left(h.open_time::text, 5) || ' – ' || left(h.close_time::text, 5)
    end as today_hours_label,
    coalesce(h.is_closed = false, false) as is_open_today,
    coalesce(promo.cnt, 0)::int as active_promotions_count
  from public.gyms g
  left join lateral (
    select oh.gym_id, oh.is_closed, oh.open_time, oh.close_time
    from public.gym_operating_hours oh
    where oh.gym_id = g.id
      and oh.day_of_week = extract(isodow from current_date)::int
    limit 1
  ) h on true
  left join lateral (
    select count(*)::int as cnt
    from public.promotions pr
    where pr.gym_id = g.id
      and pr.is_active = true
      and pr.start_at <= timezone('utc', now())
      and pr.end_at >= timezone('utc', now())
  ) promo on true
  order by g.name asc;
$$;

grant execute on function public.list_directory_gyms() to anon, authenticated;
