-- AI Attendance Analytics: peak/quiet hours, floor load (equipment pressure), session patterns.
-- Deterministic SQL from check-in / check-out timestamps (no external AI API).

create or replace function public.format_hour_label(p_hour int)
returns text
language sql
immutable
as $$
  select case
    when p_hour = 0 then '12 AM'
    when p_hour < 12 then p_hour::text || ' AM'
    when p_hour = 12 then '12 PM'
    else (p_hour - 12)::text || ' PM'
  end;
$$;

create or replace function public.get_gym_attendance_analytics(
  p_gym_id uuid,
  p_days int default 30
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  result json;
  days_clamped int;
  period_start timestamptz;
  gym_tz text;
  total_check_ins int;
  completed_sessions int;
  open_sessions int;
  median_session_mins numeric;
  avg_session_mins numeric;
  checkout_rate numeric;
  peak_hour_label text;
  quiet_hour_label text;
  peak_occupancy_label text;
  busiest_day_label text;
  summary_text text;
  insights json;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  days_clamped := greatest(least(coalesce(p_days, 30), 90), 7);
  period_start := timezone('utc', now()) - (days_clamped || ' days')::interval;

  select coalesce(nullif(trim(g.timezone), ''), 'UTC')
  into gym_tz
  from public.gyms g
  where g.id = p_gym_id;

  select coalesce(
    percentile_cont(0.5) within group (
      order by extract(epoch from (ar.check_out_at - ar.check_in_at)) / 60.0
    ),
    75
  )
  into median_session_mins
  from public.attendance_records ar
  where ar.gym_id = p_gym_id
    and ar.check_out_at is not null
    and ar.check_in_at >= period_start;

  select json_build_object(
    'generated_at', timezone('utc', now()),
    'period_days', days_clamped,
    'timezone', gym_tz,
    'summary', '',
    'overview', json_build_object(
      'total_check_ins', coalesce((
        select count(*)::int
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
      ), 0),
      'completed_sessions', coalesce((
        select count(*)::int
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
          and ar.check_out_at is not null
      ), 0),
      'open_sessions', coalesce((
        select count(*)::int
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
          and ar.check_out_at is null
      ), 0),
      'unique_members', coalesce((
        select count(distinct ar.member_id)::int
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
      ), 0),
      'avg_daily_check_ins', coalesce((
        select round(count(*)::numeric / greatest(days_clamped, 1), 1)
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
      ), 0),
      'checkout_rate_percent', coalesce((
        select round(
          100.0 * count(*) filter (where ar.check_out_at is not null)
          / nullif(count(*), 0),
          1
        )
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
      ), 0),
      'avg_session_minutes', coalesce((
        select round(avg(extract(epoch from (ar.check_out_at - ar.check_in_at)) / 60.0)::numeric, 0)
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
          and ar.check_out_at is not null
      ), 0),
      'median_session_minutes', coalesce(round(median_session_mins, 0), 75)
    ),
    'peak_hours', coalesce((
      with hourly as (
        select
          extract(hour from timezone(gym_tz, ar.check_in_at))::int as hour,
          count(*)::int as check_ins
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
        group by 1
      ),
      max_cnt as (
        select coalesce(max(check_ins), 0) as peak from hourly
      )
      select json_agg(row_entry order by (row_entry->>'check_ins')::int desc, row_entry->>'hour')
      from (
        select json_build_object(
          'hour', h.hour,
          'hour_label', public.format_hour_label(h.hour),
          'check_ins', h.check_ins,
          'percent_of_peak', case
            when mc.peak > 0 then round(100.0 * h.check_ins / mc.peak, 0)
            else 0
          end
        ) as row_entry
        from hourly h
        cross join max_cnt mc
        order by h.check_ins desc, h.hour
        limit 5
      ) t
    ), '[]'::json),
    'quiet_hours', coalesce((
      with hourly as (
        select
          extract(hour from timezone(gym_tz, ar.check_in_at))::int as hour,
          count(*)::int as check_ins
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
        group by 1
      ),
      max_cnt as (
        select coalesce(max(check_ins), 0) as peak from hourly
      )
      select json_agg(row_entry order by (row_entry->>'check_ins')::int asc, row_entry->>'hour')
      from (
        select json_build_object(
          'hour', h.hour,
          'hour_label', public.format_hour_label(h.hour),
          'check_ins', h.check_ins,
          'percent_of_peak', case
            when mc.peak > 0 then round(100.0 * h.check_ins / mc.peak, 0)
            else 0
          end
        ) as row_entry
        from hourly h
        cross join max_cnt mc
        where h.check_ins > 0
        order by h.check_ins asc, h.hour
        limit 5
      ) t
    ), '[]'::json),
    'equipment_pressure', json_build_object(
      'note', 'Estimated floor load from overlapping check-in sessions. Higher load usually means busier equipment zones.',
      'peak_occupancy_hour', (
        with sessions as (
          select
            timezone(gym_tz, ar.check_in_at) as check_in_local,
            timezone(gym_tz, coalesce(
              ar.check_out_at,
              ar.check_in_at + (median_session_mins * interval '1 minute')
            )) as check_out_local,
            timezone(gym_tz, ar.check_in_at)::date as local_day
          from public.attendance_records ar
          where ar.gym_id = p_gym_id
            and ar.check_in_at >= period_start
        ),
        occupancy as (
          select
            h.hour,
            round(avg(day_counts.on_floor)::numeric, 1) as avg_on_floor
          from generate_series(0, 23) as h(hour)
          cross join lateral (
            select coalesce(avg(cnt), 0)::numeric as on_floor
            from (
              select s.local_day, count(*)::numeric as cnt
              from sessions s
              where s.check_in_local <= (s.local_day + (h.hour || ' hours')::interval)
                and s.check_out_local > (s.local_day + (h.hour || ' hours')::interval)
              group by s.local_day
            ) daily
          ) day_counts
          group by h.hour
        ),
        peak as (select coalesce(max(avg_on_floor), 0) as val from occupancy)
        select coalesce(
          (
            select json_build_object(
              'hour', o.hour,
              'hour_label', public.format_hour_label(o.hour),
              'avg_on_floor', o.avg_on_floor,
              'pressure_percent', case
                when p.val > 0 then round(100.0 * o.avg_on_floor / p.val, 0)
                else 0
              end
            )
            from occupancy o
            cross join peak p
            order by o.avg_on_floor desc, o.hour
            limit 1
          ),
          'null'::json
        )
      ),
      'by_hour', coalesce((
        with sessions as (
          select
            timezone(gym_tz, ar.check_in_at) as check_in_local,
            timezone(gym_tz, coalesce(
              ar.check_out_at,
              ar.check_in_at + (median_session_mins * interval '1 minute')
            )) as check_out_local,
            timezone(gym_tz, ar.check_in_at)::date as local_day
          from public.attendance_records ar
          where ar.gym_id = p_gym_id
            and ar.check_in_at >= period_start
        ),
        occupancy as (
          select
            h.hour,
            round(avg(day_counts.on_floor)::numeric, 1) as avg_on_floor
          from generate_series(0, 23) as h(hour)
          cross join lateral (
            select coalesce(avg(cnt), 0)::numeric as on_floor
            from (
              select s.local_day, count(*)::numeric as cnt
              from sessions s
              where s.check_in_local <= (s.local_day + (h.hour || ' hours')::interval)
                and s.check_out_local > (s.local_day + (h.hour || ' hours')::interval)
              group by s.local_day
            ) daily
          ) day_counts
          group by h.hour
        ),
        peak as (select coalesce(max(avg_on_floor), 0) as val from occupancy)
        select json_agg(row_entry order by (row_entry->>'hour')::int)
        from (
          select json_build_object(
            'hour', o.hour,
            'hour_label', public.format_hour_label(o.hour),
            'avg_on_floor', o.avg_on_floor,
            'pressure_percent', case
              when p.val > 0 then round(100.0 * o.avg_on_floor / p.val, 0)
              else 0
            end
          ) as row_entry
          from occupancy o
          cross join peak p
          where o.avg_on_floor > 0
        ) t
      ), '[]'::json),
      'session_duration_bands', coalesce((
        select json_agg(row_entry)
        from (
          select json_build_object(
            'band', band,
            'label', label,
            'count', cnt
          ) as row_entry
          from (
            select
              case
                when mins < 45 then 'short'
                when mins <= 90 then 'medium'
                else 'long'
              end as band,
              case
                when mins < 45 then 'Under 45 min'
                when mins <= 90 then '45–90 min'
                else 'Over 90 min'
              end as label,
              count(*)::int as cnt
            from (
              select extract(epoch from (ar.check_out_at - ar.check_in_at)) / 60.0 as mins
              from public.attendance_records ar
              where ar.gym_id = p_gym_id
                and ar.check_in_at >= period_start
                and ar.check_out_at is not null
            ) durations
            group by 1, 2
            order by min(mins)
          ) bands
        ) t
      ), '[]'::json)
    ),
    'day_of_week', coalesce((
      with daily as (
        select
          extract(dow from timezone(gym_tz, ar.check_in_at))::int as dow,
          to_char(timezone(gym_tz, ar.check_in_at), 'Dy') as day_label,
          count(*)::int as check_ins
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
        group by 1, 2
      ),
      max_cnt as (select coalesce(max(check_ins), 0) as peak from daily)
      select json_agg(row_entry order by (row_entry->>'dow')::int)
      from (
        select json_build_object(
          'dow', d.dow,
          'day_label', d.day_label,
          'check_ins', d.check_ins,
          'percent_of_peak', case
            when mc.peak > 0 then round(100.0 * d.check_ins / mc.peak, 0)
            else 0
          end
        ) as row_entry
        from daily d
        cross join max_cnt mc
      ) t
    ), '[]'::json),
    'busiest_day', (
      with daily as (
        select
          extract(dow from timezone(gym_tz, ar.check_in_at))::int as dow,
          to_char(timezone(gym_tz, ar.check_in_at), 'Dy') as day_label,
          count(*)::int as check_ins
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
        group by 1, 2
      )
      select coalesce(
        (
          select json_build_object(
            'dow', dow,
            'day_label', day_label,
            'check_ins', check_ins
          )
          from daily
          order by check_ins desc, dow
          limit 1
        ),
        'null'::json
      )
    ),
    'weekend_vs_weekday', (
      select json_build_object(
        'weekday_check_ins', coalesce(sum(
          case when extract(dow from timezone(gym_tz, ar.check_in_at)) between 1 and 5 then 1 else 0 end
        ), 0),
        'weekend_check_ins', coalesce(sum(
          case when extract(dow from timezone(gym_tz, ar.check_in_at)) in (0, 6) then 1 else 0 end
        ), 0)
      )
      from public.attendance_records ar
      where ar.gym_id = p_gym_id
        and ar.check_in_at >= period_start
    ),
    'check_in_methods', coalesce((
      with method_counts as (
        select
          coalesce(ar.check_in_method, 'legacy') as method_key,
          count(*)::int as cnt
        from public.attendance_records ar
        where ar.gym_id = p_gym_id
          and ar.check_in_at >= period_start
        group by 1
      ),
      total as (select coalesce(sum(cnt), 0) as val from method_counts)
      select json_agg(row_entry order by (row_entry->>'count')::int desc)
      from (
        select json_build_object(
          'method', mc.method_key,
          'label', case mc.method_key
            when 'member_qr' then 'QR scan'
            when 'member_gps' then 'GPS (member app)'
            when 'staff' then 'Staff desk'
            else 'Legacy / untagged'
          end,
          'count', mc.cnt,
          'percent', case
            when t.val > 0 then round(100.0 * mc.cnt / t.val, 1)
            else 0
          end
        ) as row_entry
        from method_counts mc
        cross join total t
      ) rows
    ), '[]'::json),
    'insights', '[]'::json
  )
  into result;

  select (result->'overview'->>'total_check_ins')::int into total_check_ins;
  select (result->'overview'->>'completed_sessions')::int into completed_sessions;
  select (result->'overview'->>'open_sessions')::int into open_sessions;
  select (result->'overview'->>'avg_session_minutes')::numeric into avg_session_mins;
  select (result->'overview'->>'checkout_rate_percent')::numeric into checkout_rate;

  select result->'peak_hours'->0->>'hour_label' into peak_hour_label;
  select result->'quiet_hours'->0->>'hour_label' into quiet_hour_label;
  select result->'equipment_pressure'->'peak_occupancy_hour'->>'hour_label' into peak_occupancy_label;
  select result->'busiest_day'->>'day_label' into busiest_day_label;

  summary_text := format(
    'Last %s days: %s check-ins from %s members. Peak arrival hour: %s. Busiest floor-load hour: %s. Busiest day: %s.',
    days_clamped,
    coalesce(total_check_ins, 0),
    coalesce((result->'overview'->>'unique_members')::int, 0),
    coalesce(peak_hour_label, '—'),
    coalesce(peak_occupancy_label, '—'),
    coalesce(busiest_day_label, '—')
  );

  insights := json_build_array(
    case when peak_hour_label is not null
      then format('Peak check-in hour is %s — schedule extra staff or classes then.', peak_hour_label)
      else 'Not enough check-ins yet to detect peak hours.' end,
    case when quiet_hour_label is not null and total_check_ins > 0
      then format('Quietest active hour is %s — good window for maintenance or personal training promos.', quiet_hour_label)
      else null end,
    case when peak_occupancy_label is not null
      then format('Highest floor load (equipment pressure) is around %s with overlapping sessions.', peak_occupancy_label)
      else null end,
    case when coalesce(avg_session_mins, 0) > 0
      then format('Average completed session is %s minutes (median %s min).',
        round(avg_session_mins)::int,
        coalesce((result->'overview'->>'median_session_minutes')::int, 75))
      else null end,
    case when checkout_rate < 70 and total_check_ins > 5
      then format('Only %s%% of sessions have check-out recorded — enable QR/GPS checkout for better duration analytics.', round(checkout_rate))
      else null end,
    case when open_sessions > 0
      then format('%s sessions are still open without check-out; analytics use estimated duration for those.', open_sessions)
      else null end
  );

  insights := (
    select coalesce(json_agg(elem), '[]'::json)
    from json_array_elements(insights) elem
    where elem::text <> 'null'
  );

  result := jsonb_set(result::jsonb, '{summary}', to_jsonb(summary_text))::json;
  result := jsonb_set(result::jsonb, '{insights}', coalesce(insights, '[]'::json))::json;

  return result;
end;
$$;

grant execute on function public.get_gym_attendance_analytics(uuid, int) to authenticated;
