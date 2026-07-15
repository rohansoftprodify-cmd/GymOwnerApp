-- Membership sales forecasting: revenue trend, renewals pipeline, churn rate.
-- Deterministic projections from subscription history (no external AI API).

create or replace function public.get_gym_sales_forecast(
  p_gym_id uuid,
  p_forecast_months int default 3
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  result json;
  months_clamped int;
  history_start date;
  summary_text text;
  insights json;
  renewal_rate numeric;
  churn_rate numeric;
  projected_churn numeric;
  next_month_revenue numeric;
  renewal_30_count int;
  at_risk_renewals int;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  months_clamped := greatest(least(coalesce(p_forecast_months, 3), 6), 1);
  history_start := (date_trunc('month', current_date) - interval '11 months')::date;

  with renewal_history as (
    select
      e.member_id,
      exists (
        select 1
        from public.member_subscriptions ms2
        where ms2.member_id = e.member_id
          and ms2.gym_id = p_gym_id
          and ms2.start_date >= e.end_date - 7
          and ms2.start_date <= e.end_date + 45
      ) as did_renew
    from public.member_subscriptions e
    where e.gym_id = p_gym_id
      and e.end_date between current_date - 180 and current_date
  ),
  churn_history as (
    select
      count(*) filter (
        where m.status = 'inactive'
          and m.updated_at >= timezone('utc', now()) - interval '30 days'
      )::int as churned_recent,
      count(*) filter (where m.status = 'active')::int as active_now
    from public.members m
    where m.gym_id = p_gym_id
  ),
  at_risk as (
    select count(*)::int as cnt
    from public.members m
    where m.gym_id = p_gym_id
      and m.status = 'active'
      and (
        not exists (
          select 1
          from public.attendance_records ar
          where ar.member_id = m.id
            and ar.gym_id = p_gym_id
            and ar.check_in_at >= timezone('utc', now()) - interval '14 days'
        )
        or exists (
          select 1
          from public.member_subscriptions ms
          where ms.member_id = m.id
            and ms.gym_id = p_gym_id
            and ms.status = 'active'
            and ms.payment_status in ('due', 'partial')
        )
        or exists (
          select 1
          from public.member_subscriptions ms
          where ms.member_id = m.id
            and ms.gym_id = p_gym_id
            and ms.status = 'active'
            and ms.end_date between current_date and current_date + 30
            and not exists (
              select 1
              from public.attendance_records ar
              where ar.member_id = m.id
                and ar.gym_id = p_gym_id
                and ar.check_in_at >= timezone('utc', now()) - interval '7 days'
            )
        )
      )
  )
  select coalesce((
    select round(
      100.0 * count(*) filter (where did_renew) / nullif(count(*), 0),
      1
    )
    from renewal_history
  ), 70) into renewal_rate;

  select coalesce((
    select round(
      100.0 * churned_recent / nullif(active_now + churned_recent, 0),
      1
    )
    from churn_history
  ), 0) into churn_rate;

  select cnt into at_risk_renewals from at_risk;

  projected_churn := round(
    greatest(
      least(
        coalesce(churn_rate, 0) * 0.6
        + coalesce(at_risk_renewals, 0) * 100.0
          / nullif((select count(*) from public.members where gym_id = p_gym_id and status = 'active'), 0)
          * 0.4,
        0
      ),
      35
    ),
    1
  );

  select json_build_object(
    'generated_at', timezone('utc', now()),
    'forecast_months', months_clamped,
    'summary', '',
    'overview', json_build_object(
      'active_members', (
        select count(*)::int from public.members m
        where m.gym_id = p_gym_id and m.status = 'active'
      ),
      'active_subscriptions', (
        select count(*)::int from public.member_subscriptions ms
        where ms.gym_id = p_gym_id and ms.status = 'active'
      ),
      'estimated_mrr', coalesce((
        select round(sum(sp.price * 30.0 / nullif(sp.duration_days, 0))::numeric, 2)
        from public.member_subscriptions ms
        join public.subscription_plans sp on sp.id = ms.plan_id
        where ms.gym_id = p_gym_id
          and ms.status = 'active'
      ), 0),
      'pending_dues', coalesce((
        select pending_amount from public.report_dues_summary rds
        where rds.gym_id = p_gym_id
        limit 1
      ), 0),
      'historical_renewal_rate_percent', coalesce(renewal_rate, 70),
      'recent_churn_rate_percent', coalesce(churn_rate, 0),
      'projected_churn_rate_percent', coalesce(projected_churn, 0),
      'at_risk_members', coalesce(at_risk_renewals, 0)
    ),
    'monthly_history', coalesce((
      select json_agg(entry order by entry->>'month_key')
      from (
        select json_build_object(
          'month_key', to_char(m.month_start, 'YYYY-MM'),
          'month_label', to_char(m.month_start, 'Mon YYYY'),
          'membership_revenue', coalesce(rev.membership_revenue, 0),
          'new_subscriptions', coalesce(rev.new_subscriptions, 0),
          'store_revenue', coalesce(store.store_revenue, 0),
          'total_revenue', coalesce(rev.membership_revenue, 0) + coalesce(store.store_revenue, 0)
        ) as entry
        from (
          select generate_series(
            date_trunc('month', history_start::timestamp),
            date_trunc('month', current_date::timestamp),
            interval '1 month'
          )::date as month_start
        ) m
        left join (
          select
            date_trunc('month', ms.start_date::timestamp)::date as month_start,
            coalesce(sum(ms.amount_paid), 0) as membership_revenue,
            count(*)::int as new_subscriptions
          from public.member_subscriptions ms
          where ms.gym_id = p_gym_id
            and ms.start_date >= history_start
          group by 1
        ) rev on rev.month_start = m.month_start
        left join (
          select
            date_trunc('month', so.created_at)::date as month_start,
            coalesce(sum(so.total_amount), 0) as store_revenue
          from public.sales_orders so
          where so.gym_id = p_gym_id
            and so.created_at >= history_start::timestamptz
          group by 1
        ) store on store.month_start = m.month_start
      ) rows
    ), '[]'::json),
    'monthly_forecast', coalesce((
      with history as (
        select
          to_char(date_trunc('month', ms.start_date::timestamp), 'YYYY-MM') as month_key,
          coalesce(sum(ms.amount_paid), 0) as membership_revenue
        from public.member_subscriptions ms
        where ms.gym_id = p_gym_id
          and ms.start_date >= (date_trunc('month', current_date) - interval '5 months')::date
        group by 1
        order by 1
      ),
      stats as (
        select
          coalesce(avg(membership_revenue), 0) as avg_rev,
          coalesce(
            (
              (array_agg(membership_revenue order by month_key desc))[1]
              - (array_agg(membership_revenue order by month_key asc))[1]
            ) / nullif(count(*) - 1, 0),
            0
          ) as monthly_slope
        from history
      ),
      forecast as (
        select
          gs.i,
          (date_trunc('month', current_date) + (gs.i || ' months')::interval)::date as month_start
        from generate_series(1, months_clamped) gs(i)
      )
      select json_agg(entry order by entry->>'month_key')
      from (
        select json_build_object(
          'month_key', to_char(f.month_start, 'YYYY-MM'),
          'month_label', to_char(f.month_start, 'Mon YYYY'),
          'predicted_membership_revenue', round(
            greatest(s.avg_rev + s.monthly_slope * f.i, 0)::numeric,
            2
          ),
          'predicted_renewal_revenue', round(
            greatest(
              coalesce((
                select sum(sp.price) * (renewal_rate / 100.0)
                from public.member_subscriptions ms
                join public.subscription_plans sp on sp.id = ms.plan_id
                where ms.gym_id = p_gym_id
                  and ms.status = 'active'
                  and ms.end_date >= f.month_start
                  and ms.end_date < (f.month_start + interval '1 month')::date
              ), 0),
              0
            )::numeric,
            2
          ),
          'confidence', case
            when (select count(*) from history) >= 4 then 'high'
            when (select count(*) from history) >= 2 then 'medium'
            else 'low'
          end
        ) as entry
        from forecast f
        cross join stats s
      ) rows
    ), '[]'::json),
    'renewals', json_build_object(
      'historical_renewal_rate_percent', coalesce(renewal_rate, 70),
      'next_30_days', (
        select json_build_object(
          'count', count(*)::int,
          'expected_revenue', round(coalesce(sum(sp.price) * (renewal_rate / 100.0), 0)::numeric, 2),
          'full_potential_revenue', coalesce(sum(sp.price), 0),
          'at_risk_count', coalesce(sum(
            case
              when ms.payment_status in ('due', 'partial') then 1
              when not exists (
                select 1 from public.attendance_records ar
                where ar.member_id = ms.member_id
                  and ar.gym_id = p_gym_id
                  and ar.check_in_at >= timezone('utc', now()) - interval '14 days'
              ) then 1
              else 0
            end
          ), 0)::int
        )
        from public.member_subscriptions ms
        join public.subscription_plans sp on sp.id = ms.plan_id
        where ms.gym_id = p_gym_id
          and ms.status = 'active'
          and ms.end_date between current_date and current_date + 30
      ),
      'next_60_days', (
        select json_build_object(
          'count', count(*)::int,
          'expected_revenue', round(coalesce(sum(sp.price) * (renewal_rate / 100.0), 0)::numeric, 2),
          'full_potential_revenue', coalesce(sum(sp.price), 0)
        )
        from public.member_subscriptions ms
        join public.subscription_plans sp on sp.id = ms.plan_id
        where ms.gym_id = p_gym_id
          and ms.status = 'active'
          and ms.end_date between current_date and current_date + 60
      ),
      'upcoming', coalesce((
        select json_agg(row_entry order by row_entry->>'end_date')
        from (
          select json_build_object(
            'member_id', m.id,
            'full_name', m.full_name,
            'plan_name', sp.name,
            'plan_price', sp.price,
            'end_date', ms.end_date,
            'payment_status', ms.payment_status,
            'renewal_likelihood', case
              when ms.payment_status in ('due', 'partial') then 'low'
              when not exists (
                select 1 from public.attendance_records ar
                where ar.member_id = m.id
                  and ar.gym_id = p_gym_id
                  and ar.check_in_at >= timezone('utc', now()) - interval '14 days'
              ) then 'low'
              when ms.payment_status = 'paid' then 'high'
              else 'medium'
            end
          ) as row_entry
          from public.member_subscriptions ms
          join public.members m on m.id = ms.member_id
          join public.subscription_plans sp on sp.id = ms.plan_id
          where ms.gym_id = p_gym_id
            and ms.status = 'active'
            and ms.end_date between current_date and current_date + 45
          order by ms.end_date asc
          limit 10
        ) t
      ), '[]'::json)
    ),
    'churn', json_build_object(
      'recent_churn_rate_percent', coalesce(churn_rate, 0),
      'projected_next_month_percent', coalesce(projected_churn, 0),
      'members_churned_last_30_days', (
        select count(*)::int
        from public.members m
        where m.gym_id = p_gym_id
          and m.status = 'inactive'
          and m.updated_at >= timezone('utc', now()) - interval '30 days'
      ),
      'at_risk_active_members', coalesce(at_risk_renewals, 0),
      'expired_not_renewed_90d', (
        select count(distinct e.member_id)::int
        from public.member_subscriptions e
        where e.gym_id = p_gym_id
          and e.end_date between current_date - 90 and current_date
          and not exists (
            select 1
            from public.member_subscriptions ms2
            where ms2.member_id = e.member_id
              and ms2.gym_id = p_gym_id
              and ms2.start_date > e.end_date
          )
      )
    ),
    'staffing_hints', json_build_object(
      'marketing_focus', case
        when coalesce(renewal_rate, 70) < 60 then 'renewal_campaign'
        when coalesce(at_risk_renewals, 0) >= 5 then 'retention_outreach'
        when coalesce(churn_rate, 0) > 8 then 'win_back'
        else 'growth'
      end,
      'priority', case
        when coalesce(at_risk_renewals, 0) >= 8 then 'high'
        when coalesce(at_risk_renewals, 0) >= 3 then 'medium'
        else 'normal'
      end
    ),
    'insights', '[]'::json
  )
  into result;

  select coalesce(
    (result->'monthly_forecast'->0->>'predicted_membership_revenue')::numeric,
    0
  ) into next_month_revenue;

  select (result->'renewals'->'next_30_days'->>'count')::int into renewal_30_count;

  summary_text := format(
    'Next month membership revenue forecast: ₹%s. %s renewals due in 30 days (%.0f%% historical renewal rate). Projected churn: %s%%. %s members need retention outreach.',
    trim(to_char(coalesce(next_month_revenue, 0), 'FM999,999,990')),
    coalesce(renewal_30_count, 0),
    coalesce(renewal_rate, 70),
    coalesce(projected_churn, 0),
    coalesce(at_risk_renewals, 0)
  );

  insights := json_build_array(
    format(
      'Historical renewal rate is %.1f%% — use this to expect ₹%s from subscriptions ending in the next 30 days.',
      coalesce(renewal_rate, 70),
      trim(to_char(
        coalesce((result->'renewals'->'next_30_days'->>'expected_revenue')::numeric, 0),
        'FM999,999,990'
      ))
    ),
    case when coalesce(renewal_30_count, 0) > 0
      then format('%s memberships expire within 30 days — assign staff for renewal calls this week.', renewal_30_count)
      else 'No memberships expiring in the next 30 days.' end,
    case when coalesce(at_risk_renewals, 0) > 0
      then format('%s active members show churn signals (fees due or low attendance) — prioritize personal outreach.', at_risk_renewals)
      else null end,
    case when coalesce(churn_rate, 0) > 5
      then format('Recent monthly churn is %.1f%% — consider win-back offers for inactive members.', churn_rate)
      else null end,
    case when (result->'staffing_hints'->>'marketing_focus') = 'renewal_campaign'
      then 'Marketing tip: run a renewal campaign with a limited-time discount before month-end.'
      when (result->'staffing_hints'->>'marketing_focus') = 'retention_outreach'
      then 'Staffing tip: dedicate front-desk time daily for at-risk member check-ins.'
      when (result->'staffing_hints'->>'marketing_focus') = 'win_back'
      then 'Marketing tip: target recently inactive members with a comeback offer.'
      else 'Growth mode: acquisition campaigns can scale while retention is stable.' end
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

grant execute on function public.get_gym_sales_forecast(uuid, int) to authenticated;
