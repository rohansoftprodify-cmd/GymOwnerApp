-- Phone-based member login support (phone compulsory for auth; email optional contact).

create or replace function public.normalize_member_phone(p_phone text)
returns text
language plpgsql
immutable
as $$
declare
  digits text;
begin
  if p_phone is null then
    return null;
  end if;

  digits := regexp_replace(p_phone, '\D', '', 'g');
  if digits = '' then
    return null;
  end if;

  -- India: 10-digit local -> +91XXXXXXXXXX
  if length(digits) = 10 then
    return '+91' || digits;
  end if;

  -- Already includes country code without +
  if length(digits) = 12 and left(digits, 2) = '91' then
    return '+' || digits;
  end if;

  -- Already E.164-ish digits with leading country code
  if length(digits) >= 11 and length(digits) <= 15 then
    return '+' || digits;
  end if;

  return null;
end;
$$;

comment on function public.normalize_member_phone(text) is
  'Normalize member phone to E.164 (+91…) for Auth login matching.';

create or replace function public.link_auth_user_to_member_by_phone()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_phone text;
  v_member_id uuid;
begin
  if v_user_id is null then
    return null;
  end if;

  select public.normalize_member_phone(u.phone) into v_phone
  from auth.users u
  where u.id = v_user_id;

  if v_phone is null or v_phone = '' then
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
    and m.phone is not null
    and public.normalize_member_phone(m.phone) = v_phone
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

  v_member_id := public.link_auth_user_to_member_by_email();
  if v_member_id is not null then
    return v_member_id;
  end if;

  return public.link_auth_user_to_member_by_phone();
end;
$$;

create or replace function public.member_phone_has_active_session(p_phone text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_phone text;
begin
  v_phone := public.normalize_member_phone(p_phone);
  if v_phone is null then
    return false;
  end if;

  select u.id into v_user_id
  from auth.users u
  where public.normalize_member_phone(u.phone) = v_phone
  limit 1;

  if v_user_id is null then
    return false;
  end if;

  return exists (
    select 1
    from public.user_active_sessions uas
    where uas.user_id = v_user_id
  );
end;
$$;

grant execute on function public.normalize_member_phone(text) to anon, authenticated;
grant execute on function public.link_auth_user_to_member_by_phone() to authenticated;
grant execute on function public.member_phone_has_active_session(text) to anon, authenticated;
