-- Track how attendance was recorded (staff desk, member GPS, member QR).

alter table public.attendance_records
  add column if not exists check_in_method text
    check (check_in_method is null or check_in_method in ('staff', 'member_gps', 'member_qr', 'legacy'));

comment on column public.attendance_records.check_in_method is
  'staff = owner desk, member_gps = member app GPS, member_qr = QR scan, legacy = historical rows';

create or replace function public.mark_attendance(p_member_id uuid, p_gym_id uuid, p_action text)
returns public.attendance_records
language plpgsql
security definer
set search_path = public
as $$
declare
  open_record public.attendance_records;
  created_record public.attendance_records;
begin
  if p_action not in ('check_in', 'check_out') then
    raise exception 'Invalid action. Use check_in or check_out.';
  end if;

  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  select *
  into open_record
  from public.attendance_records ar
  where ar.gym_id = p_gym_id
    and ar.member_id = p_member_id
    and ar.check_out_at is null
  order by ar.check_in_at desc
  limit 1;

  if p_action = 'check_in' then
    if open_record.id is not null then
      raise exception 'Member already checked in.';
    end if;

    insert into public.attendance_records (gym_id, member_id, check_in_at, marked_by, check_in_method)
    values (p_gym_id, p_member_id, timezone('utc', now()), auth.uid(), 'staff')
    returning * into created_record;

    return created_record;
  end if;

  if open_record.id is null then
    raise exception 'No open check-in found to check out.';
  end if;

  update public.attendance_records
  set check_out_at = timezone('utc', now())
  where id = open_record.id
  returning * into created_record;

  return created_record;
end;
$$;

drop function if exists public.member_mark_my_attendance(uuid, text, double precision, double precision);

create or replace function public.member_mark_my_attendance(
  p_gym_id uuid,
  p_action text,
  p_latitude double precision,
  p_longitude double precision,
  p_check_in_method text default 'member_gps'
)
returns public.attendance_records
language plpgsql
security definer
set search_path = public
as $$
declare
  linked_member_id uuid;
  open_record public.attendance_records;
  created_record public.attendance_records;
  method text;
begin
  if p_action not in ('check_in', 'check_out') then
    raise exception 'Invalid action. Use check_in or check_out.';
  end if;

  method := coalesce(nullif(trim(p_check_in_method), ''), 'member_gps');
  if method not in ('member_gps', 'member_qr') then
    raise exception 'Invalid check-in method for member self check-in.';
  end if;

  if not public.current_user_is_gym_app_user(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  perform public.assert_member_near_gym(p_gym_id, p_latitude, p_longitude);

  linked_member_id := public.current_user_linked_member_id(p_gym_id);
  if linked_member_id is null then
    raise exception 'No membership linked to this account.';
  end if;

  select *
  into open_record
  from public.attendance_records ar
  where ar.gym_id = p_gym_id
    and ar.member_id = linked_member_id
    and ar.check_out_at is null
  order by ar.check_in_at desc
  limit 1;

  if p_action = 'check_in' then
    if open_record.id is not null then
      raise exception 'You are already checked in.';
    end if;

    insert into public.attendance_records (
      gym_id, member_id, check_in_at, marked_by, check_in_method
    )
    values (
      p_gym_id, linked_member_id, timezone('utc', now()), auth.uid(), method
    )
    returning * into created_record;

    return created_record;
  end if;

  if open_record.id is null then
    raise exception 'No open check-in found to check out.';
  end if;

  update public.attendance_records
  set check_out_at = timezone('utc', now())
  where id = open_record.id
  returning * into created_record;

  return created_record;
end;
$$;

grant execute on function public.member_mark_my_attendance(uuid, text, double precision, double precision, text) to authenticated;

create or replace function public.member_mark_attendance_from_qr(
  p_raw text,
  p_action text,
  p_latitude double precision,
  p_longitude double precision
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

  att_row := public.member_mark_my_attendance(
    parsed_gym_id, p_action, p_latitude, p_longitude, 'member_qr'
  );

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

grant execute on function public.member_mark_attendance_from_qr(text, text, double precision, double precision) to authenticated;
