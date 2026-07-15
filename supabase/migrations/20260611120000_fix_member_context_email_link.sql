-- Auto-link members.user_id when auth email matches member email (fixes login with unlinked rows).

create or replace function public.link_auth_user_to_member_by_email()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_member_id uuid;
begin
  if v_user_id is null then
    return null;
  end if;

  select lower(trim(u.email)) into v_email
  from auth.users u
  where u.id = v_user_id;

  if v_email is null or v_email = '' then
    return null;
  end if;

  select m.id into v_member_id
  from public.members m
  where m.user_id = v_user_id
  limit 1;

  if v_member_id is not null then
    return v_member_id;
  end if;

  select m.id into v_member_id
  from public.members m
  where m.user_id is null
    and m.email is not null
    and lower(trim(m.email)) = v_email
    and not exists (
      select 1 from public.members m2 where m2.user_id = v_user_id
    )
  order by m.updated_at desc nulls last, m.created_at desc
  limit 1
  for update of m;

  if v_member_id is null then
    return null;
  end if;

  update public.members
  set user_id = v_user_id, updated_at = timezone('utc', now())
  where id = v_member_id;

  return v_member_id;
end;
$$;

create or replace function public.current_auth_member_id()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_member_id uuid;
begin
  select m.id into v_member_id
  from public.members m
  where m.user_id = auth.uid()
  limit 1;

  if v_member_id is not null then
    return v_member_id;
  end if;

  return public.link_auth_user_to_member_by_email();
end;
$$;

create or replace function public.get_my_member_context()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  ctx json;
  v_member_id uuid;
begin
  if auth.uid() is null then
    return null;
  end if;

  v_member_id := public.current_auth_member_id();
  if v_member_id is null then
    return null;
  end if;

  select json_build_object(
    'gym_id', m.gym_id,
    'member_id', m.id,
    'gym_name', g.name,
    'full_name', m.full_name,
    'email', m.email,
    'phone', m.phone,
    'member_status', m.status,
    'subscription', (
      select json_build_object(
        'id', ms.id,
        'plan_name', sp.name,
        'start_date', ms.start_date,
        'end_date', ms.end_date,
        'payment_status', ms.payment_status,
        'amount_paid', ms.amount_paid,
        'plan_price', sp.price
      )
      from public.member_subscriptions ms
      join public.subscription_plans sp on sp.id = ms.plan_id
      where ms.member_id = m.id
        and ms.gym_id = m.gym_id
        and ms.status = 'active'
      order by ms.end_date desc
      limit 1
    )
  )
  into ctx
  from public.members m
  join public.gyms g on g.id = m.gym_id
  where m.id = v_member_id;

  return ctx;
end;
$$;

grant execute on function public.link_auth_user_to_member_by_email() to authenticated;
grant execute on function public.get_my_member_context() to authenticated;
