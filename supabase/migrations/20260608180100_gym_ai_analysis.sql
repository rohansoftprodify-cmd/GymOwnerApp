-- Deterministic gym intelligence report (no external AI API required).

create or replace function public.get_gym_ai_analysis(
  p_gym_id uuid,
  p_months int default 12
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  result json;
  period_start timestamptz;
  months_clamped int;
  summary_text text;
  joined_period int;
  left_period int;
  active_now int;
  total_revenue numeric;
  preferred_method text;
  preferred_label text;
  peak_join_month text;
  peak_sales_month text;
  top_product_name text;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  months_clamped := greatest(least(coalesce(p_months, 12), 24), 3);
  period_start := date_trunc('month', timezone('utc', now())) - ((months_clamped - 1) || ' months')::interval;

  select count(*)::int
  into joined_period
  from public.members m
  where m.gym_id = p_gym_id
    and m.joined_on >= period_start::date;

  select count(*)::int
  into left_period
  from public.members m
  where m.gym_id = p_gym_id
    and m.status = 'inactive'
    and m.updated_at >= period_start;

  select count(*)::int
  into active_now
  from public.members m
  where m.gym_id = p_gym_id
    and m.status = 'active';

  select coalesce(sum(so.total_amount), 0)
  into total_revenue
  from public.sales_orders so
  where so.gym_id = p_gym_id
    and so.created_at >= period_start;

  with method_counts as (
    select
      coalesce(ar.check_in_method, 'legacy') as method_key,
      count(*)::int as cnt
    from public.attendance_records ar
    where ar.gym_id = p_gym_id
      and ar.check_in_at >= period_start
    group by 1
  ),
  ranked as (
    select method_key, cnt,
      row_number() over (order by cnt desc) as rn
    from method_counts
  )
  select method_key into preferred_method
  from ranked where rn = 1;

  preferred_label := case coalesce(preferred_method, 'legacy')
    when 'member_qr' then 'QR scan check-in'
    when 'member_gps' then 'Member app GPS check-in'
    when 'staff' then 'Staff desk check-in'
    else 'Earlier check-ins (no method tag)'
  end;

  with monthly_joins as (
    select to_char(date_trunc('month', m.joined_on::timestamp), 'YYYY-MM') as month_key,
           count(*)::int as joined_count
    from public.members m
    where m.gym_id = p_gym_id
      and m.joined_on >= period_start::date
    group by 1
  )
  select month_key into peak_join_month
  from monthly_joins
  order by joined_count desc, month_key desc
  limit 1;

  with monthly_sales as (
    select to_char(date_trunc('month', so.created_at), 'YYYY-MM') as month_key,
           coalesce(sum(so.total_amount), 0) as sales_total
    from public.sales_orders so
    where so.gym_id = p_gym_id
      and so.created_at >= period_start
    group by 1
  )
  select month_key into peak_sales_month
  from monthly_sales
  order by sales_total desc, month_key desc
  limit 1;

  select p.name into top_product_name
  from public.sales_order_items soi
  join public.sales_orders so on so.id = soi.order_id
  join public.products p on p.id = soi.product_id
  where soi.gym_id = p_gym_id
    and so.created_at >= period_start
  group by p.id, p.name
  order by sum(soi.line_total) desc
  limit 1;

  summary_text := format(
    'In the last %s months: %s members joined, %s became inactive, and you have %s active members now. Store revenue was ₹%s. %s is the most used check-in method.%s%s',
    months_clamped,
    joined_period,
    left_period,
    active_now,
    trim(to_char(coalesce(total_revenue, 0), 'FM999,999,990.00')),
    preferred_label,
    case when peak_join_month is not null
      then format(' Peak join month: %s.', to_char(to_date(peak_join_month || '-01', 'YYYY-MM-DD'), 'Mon YYYY'))
      else '' end,
    case when top_product_name is not null
      then format(' Top seller: %s.', top_product_name)
      else '' end
  );

  select json_build_object(
    'generated_at', timezone('utc', now()),
    'period_months', months_clamped,
    'summary', summary_text,
    'membership', json_build_object(
      'joined_in_period', joined_period,
      'left_in_period', left_period,
      'net_change', joined_period - left_period,
      'active_now', active_now,
      'inactive_total', (
        select count(*)::int from public.members m
        where m.gym_id = p_gym_id and m.status = 'inactive'
      ),
      'peak_join_month', (
        with monthly_joins as (
          select to_char(date_trunc('month', m.joined_on::timestamp), 'YYYY-MM') as month_key,
                 to_char(date_trunc('month', m.joined_on::timestamp), 'Mon YYYY') as month_label,
                 count(*)::int as joined_count
          from public.members m
          where m.gym_id = p_gym_id and m.joined_on >= period_start::date
          group by 1, 2
        )
        select coalesce(
          (select json_build_object(
            'month_key', month_key,
            'month_label', month_label,
            'joined_count', joined_count
          ) from monthly_joins order by joined_count desc, month_key desc limit 1),
          'null'::json
        )
      ),
      'monthly_joins', coalesce((
        select json_agg(entry order by entry->>'month_key')
        from (
          select json_build_object(
            'month_key', to_char(date_trunc('month', m.joined_on::timestamp), 'YYYY-MM'),
            'month_label', to_char(date_trunc('month', m.joined_on::timestamp), 'Mon YYYY'),
            'joined_count', count(*)::int
          ) as entry
          from public.members m
          where m.gym_id = p_gym_id and m.joined_on >= period_start::date
          group by date_trunc('month', m.joined_on::timestamp)
        ) rows
      ), '[]'::json)
    ),
    'sales', json_build_object(
      'total_revenue', coalesce(total_revenue, 0),
      'total_orders', (
        select count(*)::int from public.sales_orders so
        where so.gym_id = p_gym_id and so.created_at >= period_start
      ),
      'peak_sales_month', (
        with monthly_sales as (
          select to_char(date_trunc('month', so.created_at), 'YYYY-MM') as month_key,
                 to_char(date_trunc('month', so.created_at), 'Mon YYYY') as month_label,
                 coalesce(sum(so.total_amount), 0) as sales_total,
                 count(*)::int as order_count
          from public.sales_orders so
          where so.gym_id = p_gym_id and so.created_at >= period_start
          group by 1, 2
        )
        select coalesce(
          (select json_build_object(
            'month_key', month_key,
            'month_label', month_label,
            'sales_total', sales_total,
            'order_count', order_count
          ) from monthly_sales order by sales_total desc, month_key desc limit 1),
          'null'::json
        )
      ),
      'top_products', coalesce((
        select json_agg(row_entry)
        from (
          select json_build_object(
            'product_id', p.id,
            'name', p.name,
            'qty_sold', sum(soi.qty)::int,
            'revenue', coalesce(sum(soi.line_total), 0)
          ) as row_entry
          from public.sales_order_items soi
          join public.sales_orders so on so.id = soi.order_id
          join public.products p on p.id = soi.product_id
          where soi.gym_id = p_gym_id and so.created_at >= period_start
          group by p.id, p.name
          order by sum(soi.line_total) desc
          limit 5
        ) t
      ), '[]'::json),
      'monthly_sales', coalesce((
        select json_agg(entry order by entry->>'month_key')
        from (
          select json_build_object(
            'month_key', to_char(date_trunc('month', so.created_at), 'YYYY-MM'),
            'month_label', to_char(date_trunc('month', so.created_at), 'Mon YYYY'),
            'sales_total', coalesce(sum(so.total_amount), 0),
            'order_count', count(*)::int
          ) as entry
          from public.sales_orders so
          where so.gym_id = p_gym_id and so.created_at >= period_start
          group by date_trunc('month', so.created_at)
        ) rows
      ), '[]'::json)
    ),
    'attendance', json_build_object(
      'total_check_ins', (
        select count(*)::int from public.attendance_records ar
        where ar.gym_id = p_gym_id and ar.check_in_at >= period_start
      ),
      'preferred_method', (
        with method_counts as (
          select coalesce(ar.check_in_method, 'legacy') as method_key,
                 count(*)::int as cnt
          from public.attendance_records ar
          where ar.gym_id = p_gym_id and ar.check_in_at >= period_start
          group by 1
        ),
        totals as (
          select coalesce(sum(cnt), 0) as total from method_counts
        )
        select coalesce(
          (select json_build_object(
            'method', mc.method_key,
            'label', case mc.method_key
              when 'member_qr' then 'QR scan'
              when 'member_gps' then 'GPS (member app)'
              when 'staff' then 'Staff desk'
              else 'Legacy / untagged'
            end,
            'count', mc.cnt,
            'percent', case when t.total > 0 then round((mc.cnt::numeric / t.total) * 100, 1) else 0 end
          )
          from method_counts mc cross join totals t
          order by mc.cnt desc limit 1),
          'null'::json
        )
      ),
      'methods', coalesce((
        with method_counts as (
          select coalesce(ar.check_in_method, 'legacy') as method_key,
                 count(*)::int as cnt
          from public.attendance_records ar
          where ar.gym_id = p_gym_id and ar.check_in_at >= period_start
          group by 1
        ),
        totals as (select coalesce(sum(cnt), 0) as total from method_counts)
        select json_agg(
          json_build_object(
            'method', mc.method_key,
            'label', case mc.method_key
              when 'member_qr' then 'QR scan'
              when 'member_gps' then 'GPS (member app)'
              when 'staff' then 'Staff desk'
              else 'Legacy / untagged'
            end,
            'count', mc.cnt,
            'percent', case when t.total > 0 then round((mc.cnt::numeric / t.total) * 100, 1) else 0 end
          )
          order by mc.cnt desc
        )
        from method_counts mc cross join totals t
      ), '[]'::json),
      'peak_month', (
        with monthly_att as (
          select to_char(date_trunc('month', ar.check_in_at), 'YYYY-MM') as month_key,
                 to_char(date_trunc('month', ar.check_in_at), 'Mon YYYY') as month_label,
                 count(*)::int as check_ins
          from public.attendance_records ar
          where ar.gym_id = p_gym_id and ar.check_in_at >= period_start
          group by 1, 2
        )
        select coalesce(
          (select json_build_object(
            'month_key', month_key,
            'month_label', month_label,
            'check_ins', check_ins
          ) from monthly_att order by check_ins desc, month_key desc limit 1),
          'null'::json
        )
      )
    ),
    'members', json_build_object(
      'most_consistent', coalesce((
        select json_agg(
          json_build_object(
            'member_id', m.id,
            'full_name', m.full_name,
            'check_in_count', stats.visits,
            'note', format('%s visits in last 90 days', stats.visits)
          )
          order by stats.visits desc
        )
        from (
          select ar.member_id, count(*)::int as visits
          from public.attendance_records ar
          where ar.gym_id = p_gym_id
            and ar.check_in_at >= timezone('utc', now()) - interval '90 days'
          group by ar.member_id
          order by visits desc
          limit 5
        ) stats
        join public.members m on m.id = stats.member_id
      ), '[]'::json),
      'oldest_member', (
        select coalesce(
          (select json_build_object(
            'member_id', m.id,
            'full_name', m.full_name,
            'joined_on', m.joined_on,
            'days_as_member', (current_date - m.joined_on)
          )
          from public.members m
          where m.gym_id = p_gym_id
          order by m.joined_on asc, m.created_at asc
          limit 1),
          'null'::json
        )
      ),
      'longest_tenure', coalesce((
        select json_agg(entry)
        from (
          select json_build_object(
            'member_id', m.id,
            'full_name', m.full_name,
            'joined_on', m.joined_on,
            'days_as_member', (current_date - m.joined_on)
          ) as entry
          from public.members m
          where m.gym_id = p_gym_id and m.status = 'active'
          order by m.joined_on asc
          limit 5
        ) t
      ), '[]'::json)
    ),
    'insights', (
      select coalesce(json_agg(insight order by ord), '[]'::json)
      from (
        select 1 as ord, format(
          '%s members joined and %s left in the last %s months (net %+s).',
          joined_period, left_period, months_clamped, joined_period - left_period
        ) as insight
        union all
        select 2, format('You currently have %s active members.', active_now)
        union all
        select 3, case when peak_join_month is not null then format(
          'Highest member growth month: %s.',
          to_char(to_date(peak_join_month || '-01', 'YYYY-MM-DD'), 'Mon YYYY')
        ) else 'Not enough join data for a peak month yet.' end
        union all
        select 4, case when peak_sales_month is not null then format(
          'Highest sales month: %s.',
          to_char(to_date(peak_sales_month || '-01', 'YYYY-MM-DD'), 'Mon YYYY')
        ) else 'No store sales recorded in this period yet.' end
        union all
        select 5, case when top_product_name is not null then format(
          'Best-selling product: %s.', top_product_name
        ) else 'No product sales data yet — promote items in the Store tab.' end
        union all
        select 6, format('Members prefer %s for attendance.', preferred_label)
        union all
        select 7, (
          select case when cm.member_id is not null then format(
            'Most consistent member: %s (%s check-ins in 90 days).',
            cm.full_name, cm.visits
          ) else 'Encourage regular visits — no repeat check-in pattern yet.' end
          from (
            select m.full_name, m.id as member_id, count(*)::int as visits
            from public.attendance_records ar
            join public.members m on m.id = ar.member_id
            where ar.gym_id = p_gym_id
              and ar.check_in_at >= timezone('utc', now()) - interval '90 days'
            group by m.id, m.full_name
            order by visits desc
            limit 1
          ) cm
        )
        union all
        select 8, (
          select case when om.full_name is not null then format(
            'Longest-standing member: %s (since %s).',
            om.full_name, to_char(om.joined_on, 'Mon DD, YYYY')
          ) else null end
          from (
            select full_name, joined_on from public.members
            where gym_id = p_gym_id order by joined_on asc limit 1
          ) om
        )
      ) x
      where insight is not null
    )
  )
  into result;

  return result;
end;
$$;

grant execute on function public.get_gym_ai_analysis(uuid, int) to authenticated;
