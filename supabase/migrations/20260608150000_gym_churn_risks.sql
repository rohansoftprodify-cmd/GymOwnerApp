-- AI-ready churn risk scoring for gym owners (deterministic; no external API required).

create or replace function public.get_gym_churn_risks(p_gym_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  result json;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  with member_stats as (
    select
      m.id as member_id,
      m.full_name,
      m.phone,
      (
        select max(ar.check_in_at)
        from public.attendance_records ar
        where ar.member_id = m.id
          and ar.gym_id = p_gym_id
      ) as last_check_in_at,
      (
        select ms.payment_status
        from public.member_subscriptions ms
        where ms.member_id = m.id
          and ms.gym_id = p_gym_id
          and ms.status = 'active'
        order by ms.end_date desc
        limit 1
      ) as payment_status,
      (
        select ms.end_date
        from public.member_subscriptions ms
        where ms.member_id = m.id
          and ms.gym_id = p_gym_id
          and ms.status = 'active'
        order by ms.end_date desc
        limit 1
      ) as subscription_end_date
    from public.members m
    where m.gym_id = p_gym_id
      and m.status = 'active'
  ),
  scored as (
    select
      member_id,
      full_name,
      phone,
      last_check_in_at,
      payment_status,
      subscription_end_date,
      (
        case
          when last_check_in_at is null then 35
          when last_check_in_at < timezone('utc', now()) - interval '14 days' then 40
          when last_check_in_at < timezone('utc', now()) - interval '7 days' then 25
          else 0
        end
        + case coalesce(payment_status, 'paid')
            when 'due' then 30
            when 'partial' then 15
            else 0
          end
        + case
            when subscription_end_date is not null
              and subscription_end_date <= current_date + 7
              and (
                last_check_in_at is null
                or last_check_in_at < timezone('utc', now()) - interval '7 days'
              ) then 20
            when subscription_end_date is not null
              and subscription_end_date <= current_date + 15 then 10
            else 0
          end
      )::int as risk_score
    from member_stats
  ),
  enriched as (
    select
      member_id,
      full_name,
      phone,
      risk_score,
      case
        when risk_score >= 60 then 'high'
        when risk_score >= 35 then 'medium'
        else 'low'
      end as risk_level,
      last_check_in_at,
      payment_status,
      subscription_end_date,
      array_remove(
        array[
          case
            when last_check_in_at is null then 'Never checked in'
            when last_check_in_at < timezone('utc', now()) - interval '14 days'
              then 'No visit in 14+ days'
            when last_check_in_at < timezone('utc', now()) - interval '7 days'
              then 'No visit in 7+ days'
            else null
          end,
          case payment_status
            when 'due' then 'Fee overdue'
            when 'partial' then 'Partial payment'
            else null
          end,
          case
            when subscription_end_date is not null
              and subscription_end_date <= current_date + 7
              then 'Renewal within 7 days'
            when subscription_end_date is not null
              and subscription_end_date <= current_date + 15
              then 'Renewal within 15 days'
            else null
          end
        ],
        null
      ) as reasons
    from scored
    where risk_score >= 25
  )
  select json_build_object(
    'members',
    coalesce(
      (
        select json_agg(
          json_build_object(
            'member_id', e.member_id,
            'full_name', e.full_name,
            'phone', e.phone,
            'risk_score', e.risk_score,
            'risk_level', e.risk_level,
            'reasons', e.reasons,
            'last_check_in_at', e.last_check_in_at,
            'payment_status', e.payment_status,
            'subscription_end_date', e.subscription_end_date,
            'suggested_action',
              case e.risk_level
                when 'high' then format(
                  'Priority: contact %s today — %s',
                  e.full_name,
                  array_to_string(e.reasons, ', ')
                )
                when 'medium' then format(
                  'Follow up with %s this week — %s',
                  e.full_name,
                  array_to_string(e.reasons, ', ')
                )
                else format('Check in with %s — %s', e.full_name, array_to_string(e.reasons, ', '))
              end
          )
          order by e.risk_score desc, e.full_name
        )
        from enriched e
      ),
      '[]'::json
    ),
    'summary',
    json_build_object(
      'high',
      (select count(*) from enriched where risk_level = 'high'),
      'medium',
      (select count(*) from enriched where risk_level = 'medium'),
      'low',
      (select count(*) from enriched where risk_level = 'low'),
      'total_at_risk',
      (select count(*) from enriched)
    )
  )
  into result;

  return result;
end;
$$;

grant execute on function public.get_gym_churn_risks(uuid) to authenticated;
