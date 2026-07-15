-- Gym check-in QR: one static QR per gym (payload: gym_checkin:{gym_id}).

create or replace function public.gym_check_in_qr_payload(p_gym_id uuid)
returns text
language sql
immutable
as $$
  select 'gym_checkin:' || p_gym_id::text;
$$;

create or replace function public.parse_gym_check_in_qr_raw(p_raw text)
returns uuid
language plpgsql
immutable
as $$
declare
  trimmed text;
  prefix constant text := 'gym_checkin:';
  parsed uuid;
begin
  trimmed := trim(p_raw);
  if trimmed is null or trimmed = '' then
    return null;
  end if;

  if not starts_with(trimmed, prefix) then
    return null;
  end if;

  begin
    parsed := trim(substring(trimmed from length(prefix) + 1))::uuid;
    return parsed;
  exception
    when others then
      return null;
  end;
end;
$$;

create or replace function public.get_gym_check_in_qr(p_gym_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  gym_row public.gyms;
begin
  -- Owner/staff (current_user_is_gym_member), not member-app role (gym_app_user).
  if not public.current_user_is_gym_member(p_gym_id)
     and not public.current_user_is_superadmin() then
    raise exception 'Unauthorized for this gym.';
  end if;

  select * into gym_row from public.gyms where id = p_gym_id;
  if not found then
    raise exception 'Gym not found.';
  end if;

  return json_build_object(
    'gym_id', gym_row.id,
    'gym_name', gym_row.name,
    'qr_payload', public.gym_check_in_qr_payload(gym_row.id),
    'deep_link', 'gymmember://checkin?gymId=' || gym_row.id::text
  );
end;
$$;

grant execute on function public.get_gym_check_in_qr(uuid) to authenticated;

create or replace function public.validate_gym_check_in_qr(p_raw text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  parsed_gym_id uuid;
  gym_row public.gyms;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  parsed_gym_id := public.parse_gym_check_in_qr_raw(p_raw);
  if parsed_gym_id is null then
    return json_build_object('valid', false, 'error', 'Invalid QR code format.');
  end if;

  select * into gym_row from public.gyms where id = parsed_gym_id;
  if not found then
    return json_build_object('valid', false, 'error', 'Gym not found.');
  end if;

  return json_build_object(
    'valid', true,
    'gym_id', gym_row.id,
    'gym_name', gym_row.name
  );
end;
$$;

grant execute on function public.validate_gym_check_in_qr(text) to authenticated;

create or replace function public.member_mark_attendance_from_qr(
  p_raw text,
  p_action text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  parsed_gym_id uuid;
  att_row public.attendance_records;
  member_name text;
begin
  if p_action not in ('check_in', 'check_out') then
    raise exception 'Invalid action. Use check_in or check_out.';
  end if;

  parsed_gym_id := public.parse_gym_check_in_qr_raw(p_raw);
  if parsed_gym_id is null then
    raise exception 'Invalid gym QR code.';
  end if;

  select m.full_name
  into member_name
  from public.members m
  where m.gym_id = parsed_gym_id
    and m.user_id = auth.uid();

  att_row := public.member_mark_my_attendance(parsed_gym_id, p_action);

  return json_build_object(
    'success', true,
    'action', p_action,
    'gym_id', parsed_gym_id,
    'member_name', coalesce(member_name, 'Member'),
    'attendance_id', att_row.id,
    'check_in_at', att_row.check_in_at,
    'check_out_at', att_row.check_out_at
  );
end;
$$;

grant execute on function public.member_mark_attendance_from_qr(text, text) to authenticated;
