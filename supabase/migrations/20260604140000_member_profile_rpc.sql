-- Full member profile payload for the member mobile app.

create or replace function public.get_my_member_profile()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  ctx json;
begin
  if auth.uid() is null then
    return null;
  end if;

  select json_build_object(
    'gym_id', r.gym_id,
    'member_id', m.id,
    'gym_name', g.name,
    'gym_address', g.address,
    'gym_phone', g.phone,
    'full_name', m.full_name,
    'email', m.email,
    'phone', m.phone,
    'member_status', m.status,
    'joined_on', m.joined_on,
    'date_of_birth', m.date_of_birth,
    'emergency_contact', m.emergency_contact,
    'notes', m.notes,
    'auth_email', u.email,
    'subscription', (
      select json_build_object(
        'id', ms.id,
        'plan_name', sp.name,
        'plan_description', sp.description,
        'duration_days', sp.duration_days,
        'start_date', ms.start_date,
        'end_date', ms.end_date,
        'payment_status', ms.payment_status,
        'amount_paid', ms.amount_paid,
        'plan_price', sp.price,
        'status', ms.status
      )
      from public.member_subscriptions ms
      join public.subscription_plans sp on sp.id = ms.plan_id
      where ms.member_id = m.id
        and ms.gym_id = r.gym_id
        and ms.status = 'active'
      order by ms.end_date desc
      limit 1
    ),
    'attendance_stats', (
      select json_build_object(
        'total_visits', count(*)::int,
        'last_check_in_at', max(ar.check_in_at),
        'is_checked_in', coalesce(bool_or(ar.check_out_at is null), false)
      )
      from public.attendance_records ar
      where ar.member_id = m.id
        and ar.gym_id = r.gym_id
    )
  )
  into ctx
  from public.gym_roles r
  join public.members m
    on m.gym_id = r.gym_id
   and m.user_id = r.user_id
  join public.gyms g on g.id = r.gym_id
  left join auth.users u on u.id = auth.uid()
  where r.user_id = auth.uid()
    and r.role = 'member'
  limit 1;

  return ctx;
end;
$$;

grant execute on function public.get_my_member_profile() to authenticated;
