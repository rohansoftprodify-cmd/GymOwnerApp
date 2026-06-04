-- Member app: self check-in/out, gym geo for location attendance, product read for Buy tab.

alter table public.gyms
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists check_in_radius_meters int not null default 150
    check (check_in_radius_meters > 0 and check_in_radius_meters <= 5000);

create or replace function public.member_mark_my_attendance(
  p_gym_id uuid,
  p_action text
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
begin
  if p_action not in ('check_in', 'check_out') then
    raise exception 'Invalid action. Use check_in or check_out.';
  end if;

  if not public.current_user_is_gym_app_user(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

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

    insert into public.attendance_records (gym_id, member_id, check_in_at, marked_by)
    values (p_gym_id, linked_member_id, timezone('utc', now()), auth.uid())
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

grant execute on function public.member_mark_my_attendance(uuid, text) to authenticated;

create policy products_member_select on public.products
  for select
  using (
    public.current_user_is_gym_app_user(gym_id)
    and is_active = true
  );

create policy product_categories_member_select on public.product_categories
  for select
  using (public.current_user_is_gym_app_user(gym_id));
