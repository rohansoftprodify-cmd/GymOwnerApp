-- Pre-login check: does this member account already have an active app session elsewhere?

create or replace function public.member_email_has_active_session(p_email text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  if p_email is null or trim(p_email) = '' then
    return false;
  end if;

  select u.id into v_user_id
  from auth.users u
  where lower(trim(u.email)) = lower(trim(p_email))
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

grant execute on function public.member_email_has_active_session(text) to anon;
grant execute on function public.member_email_has_active_session(text) to authenticated;
