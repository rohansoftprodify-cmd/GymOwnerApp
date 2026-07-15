-- AI Member Retention Prediction: leave probability, attendance/payment/engagement signals.

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
      m.email,
      m.user_id,
      (
        select max(ar.check_in_at)
        from public.attendance_records ar
        where ar.member_id = m.id
          and ar.gym_id = p_gym_id
      ) as last_check_in_at,
      (
        select count(*)::int
        from public.attendance_records ar
        where ar.member_id = m.id
          and ar.gym_id = p_gym_id
          and ar.check_in_at >= timezone('utc', now()) - interval '30 days'
      ) as check_ins_last_30d,
      (
        select count(*)::int
        from public.attendance_records ar
        where ar.member_id = m.id
          and ar.gym_id = p_gym_id
          and ar.check_in_at >= timezone('utc', now()) - interval '60 days'
          and ar.check_in_at < timezone('utc', now()) - interval '30 days'
      ) as check_ins_prior_30d,
      (
        select count(*)::int
        from public.attendance_records ar
        where ar.member_id = m.id
          and ar.gym_id = p_gym_id
          and ar.check_in_method in ('member_gps', 'member_qr')
          and ar.check_in_at >= timezone('utc', now()) - interval '30 days'
      ) as app_check_ins_last_30d,
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
      ) as subscription_end_date,
      (
        select uas.updated_at
        from public.user_active_sessions uas
        where uas.user_id = m.user_id
      ) as last_app_activity_at
    from public.members m
    where m.gym_id = p_gym_id
      and m.status = 'active'
  ),
  scored as (
    select
      ms.*,
      (
        case
          when ms.last_check_in_at is null then 35
          when ms.last_check_in_at < timezone('utc', now()) - interval '14 days' then 40
          when ms.last_check_in_at < timezone('utc', now()) - interval '7 days' then 25
          else 0
        end
        + case
            when ms.check_ins_prior_30d >= 3
              and ms.check_ins_last_30d < greatest(ms.check_ins_prior_30d * 0.5, 1)
              then 18
            when ms.check_ins_prior_30d >= 1
              and ms.check_ins_last_30d = 0
              then 15
            else 0
          end
      )::int as attendance_score,
      (
        case coalesce(ms.payment_status, 'paid')
          when 'due' then 30
          when 'partial' then 15
          else 0
        end
      )::int as payment_score,
      (
        case
          when ms.user_id is null then 0
          when ms.last_app_activity_at is null then 12
          when ms.last_app_activity_at < timezone('utc', now()) - interval '14 days' then 20
          when ms.last_app_activity_at < timezone('utc', now()) - interval '7 days' then 10
          when ms.app_check_ins_last_30d = 0
            and ms.last_check_in_at is not null
            and ms.last_check_in_at >= timezone('utc', now()) - interval '14 days'
            then 8
          else 0
        end
      )::int as engagement_score,
      (
        case
          when ms.subscription_end_date is not null
            and ms.subscription_end_date <= current_date + 7
            and (
              ms.last_check_in_at is null
              or ms.last_check_in_at < timezone('utc', now()) - interval '7 days'
            ) then 15
          when ms.subscription_end_date is not null
            and ms.subscription_end_date <= current_date + 15 then 8
          else 0
        end
      )::int as renewal_score
    from member_stats ms
  ),
  enriched as (
    select
      s.member_id,
      s.full_name,
      s.phone,
      s.email,
      s.user_id,
      s.last_check_in_at,
      s.check_ins_last_30d,
      s.check_ins_prior_30d,
      s.app_check_ins_last_30d,
      s.last_app_activity_at,
      s.payment_status,
      s.subscription_end_date,
      s.attendance_score,
      s.payment_score,
      s.engagement_score,
      s.renewal_score,
      least(
        greatest(
          s.attendance_score + s.payment_score + s.engagement_score + s.renewal_score,
          0
        ),
        95
      )::int as leave_probability_30d,
      least(
        greatest(
          s.attendance_score + s.payment_score + s.engagement_score + s.renewal_score,
          0
        ),
        100
      )::int as risk_score
    from scored s
  ),
  labeled as (
    select
      e.*,
      case
        when e.leave_probability_30d >= 75 then 'critical'
        when e.leave_probability_30d >= 55 then 'high'
        when e.leave_probability_30d >= 35 then 'medium'
        else 'low'
      end as risk_level,
      array_remove(
        array[
          case
            when e.last_check_in_at is null then 'Never checked in'
            when e.last_check_in_at < timezone('utc', now()) - interval '14 days'
              then 'No visit in 14+ days'
            when e.last_check_in_at < timezone('utc', now()) - interval '7 days'
              then 'No visit in 7+ days'
            else null
          end,
          case
            when e.check_ins_prior_30d >= 2
              and e.check_ins_last_30d < greatest(e.check_ins_prior_30d * 0.5, 1)
              then format(
                'Attendance dropped (%s → %s visits in 30d)',
                e.check_ins_prior_30d,
                e.check_ins_last_30d
              )
            else null
          end,
          case e.payment_status
            when 'due' then 'Missed payment / fee overdue'
            when 'partial' then 'Partial payment'
            else null
          end,
          case
            when e.last_app_activity_at is not null
              and e.last_app_activity_at < timezone('utc', now()) - interval '14 days'
              then 'Low app engagement (14+ days inactive)'
            when e.user_id is not null
              and e.app_check_ins_last_30d = 0
              and e.last_app_activity_at < timezone('utc', now()) - interval '7 days'
              then 'No member-app check-ins recently'
            when e.user_id is null then 'Member app not linked'
            else null
          end,
          case
            when e.subscription_end_date is not null
              and e.subscription_end_date <= current_date + 7
              then 'Membership ends within 7 days'
            when e.subscription_end_date is not null
              and e.subscription_end_date <= current_date + 15
              then 'Membership ends within 15 days'
            else null
          end
        ],
        null
      ) as reasons
    from enriched e
    where e.leave_probability_30d >= 35
  )
  select json_build_object(
    'generated_at', timezone('utc', now()),
    'summary', json_build_object(
      'critical',
      (select count(*) from labeled where risk_level = 'critical'),
      'high',
      (select count(*) from labeled where risk_level = 'high'),
      'medium',
      (select count(*) from labeled where risk_level = 'medium'),
      'low',
      (select count(*) from labeled where risk_level = 'low'),
      'total_at_risk',
      (select count(*) from labeled)
    ),
    'members',
    coalesce(
      (
        select json_agg(
          json_build_object(
            'member_id', l.member_id,
            'full_name', l.full_name,
            'phone', l.phone,
            'email', l.email,
            'risk_score', l.risk_score,
            'risk_level', l.risk_level,
            'leave_probability_30d', l.leave_probability_30d,
            'alert_message', format(
              '%s has %s%% probability of leaving within 30 days.',
              l.full_name,
              l.leave_probability_30d
            ),
            'reasons', l.reasons,
            'signals', json_build_object(
              'attendance', json_build_object(
                'score', l.attendance_score,
                'check_ins_last_30d', l.check_ins_last_30d,
                'check_ins_prior_30d', l.check_ins_prior_30d,
                'last_check_in_at', l.last_check_in_at
              ),
              'payment', json_build_object(
                'score', l.payment_score,
                'status', l.payment_status
              ),
              'engagement', json_build_object(
                'score', l.engagement_score,
                'app_check_ins_last_30d', l.app_check_ins_last_30d,
                'last_app_activity_at', l.last_app_activity_at
              ),
              'renewal', json_build_object(
                'score', l.renewal_score,
                'subscription_end_date', l.subscription_end_date
              )
            ),
            'last_check_in_at', l.last_check_in_at,
            'payment_status', l.payment_status,
            'subscription_end_date', l.subscription_end_date,
            'suggested_action',
              case l.risk_level
                when 'critical' then format(
                  'Urgent: call %s today — %s',
                  coalesce(nullif(l.phone, ''), l.full_name),
                  array_to_string(l.reasons, ', ')
                )
                when 'high' then format(
                  'Contact %s within 48 hours — %s',
                  l.full_name,
                  array_to_string(l.reasons, ', ')
                )
                when 'medium' then format(
                  'Follow up with %s this week — %s',
                  l.full_name,
                  array_to_string(l.reasons, ', ')
                )
                else format('Check in with %s — %s', l.full_name, array_to_string(l.reasons, ', '))
              end
          )
          order by l.leave_probability_30d desc, l.full_name
        )
        from labeled l
      ),
      '[]'::json
    )
  )
  into result;

  return result;
end;
$$;

grant execute on function public.get_gym_churn_risks(uuid) to authenticated;

-- Explicit alias for retention-focused clients.
create or replace function public.get_gym_member_retention_predictions(p_gym_id uuid)
returns json
language sql
security definer
set search_path = public
as $$
  select public.get_gym_churn_risks(p_gym_id);
$$;

grant execute on function public.get_gym_member_retention_predictions(uuid) to authenticated;
