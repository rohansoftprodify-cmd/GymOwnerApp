-- Gym payment QR codes and UPI IDs (owner upload, visible in member app).

create table if not exists public.gym_payment_options (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  label text,
  upi_id text,
  qr_image_path text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint gym_payment_options_upi_format check (
    upi_id is null or upi_id ~* '^[\w.\-]+@[\w.\-]+$'
  ),
  constraint gym_payment_options_has_content check (
    coalesce(nullif(trim(upi_id), ''), null) is not null
    or coalesce(nullif(trim(qr_image_path), ''), null) is not null
  )
);

create index if not exists idx_gym_payment_options_gym_id
  on public.gym_payment_options (gym_id, sort_order);

create trigger gym_payment_options_touch_updated_at
before update on public.gym_payment_options
for each row execute function public.touch_updated_at();

create or replace function public.enforce_gym_payment_options_limit()
returns trigger
language plpgsql
as $$
declare
  option_count int;
begin
  select count(*)::int
  into option_count
  from public.gym_payment_options
  where gym_id = new.gym_id
    and is_active = true
    and (tg_op = 'INSERT' or id <> new.id);

  if option_count >= 5 then
    raise exception 'A gym can have at most 5 active payment options';
  end if;

  return new;
end;
$$;

drop trigger if exists gym_payment_options_limit on public.gym_payment_options;

create trigger gym_payment_options_limit
before insert or update of is_active on public.gym_payment_options
for each row
when (new.is_active)
execute function public.enforce_gym_payment_options_limit();

alter table public.gym_payment_options enable row level security;

drop policy if exists gym_payment_options_gym_scope_select on public.gym_payment_options;
drop policy if exists gym_payment_options_gym_scope_write on public.gym_payment_options;
drop policy if exists gym_payment_options_member_select on public.gym_payment_options;

create policy gym_payment_options_gym_scope_select on public.gym_payment_options
  for select using (public.current_user_is_gym_member(gym_id));

create policy gym_payment_options_gym_scope_write on public.gym_payment_options
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy gym_payment_options_member_select on public.gym_payment_options
  for select using (
    public.current_user_is_gym_app_user(gym_id) and is_active = true
  );

-- Public bucket: {gym_id}/{payment_option_id}.jpg
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'gym-payment-qr',
  'gym-payment-qr',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists gym_payment_qr_select on storage.objects;
drop policy if exists gym_payment_qr_insert on storage.objects;
drop policy if exists gym_payment_qr_update on storage.objects;
drop policy if exists gym_payment_qr_delete on storage.objects;
drop policy if exists gym_payment_qr_member_select on storage.objects;

create policy gym_payment_qr_select on storage.objects
  for select
  using (bucket_id = 'gym-payment-qr');

create policy gym_payment_qr_insert on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'gym-payment-qr'
    and (storage.foldername(name))[1] is not null
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy gym_payment_qr_update on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'gym-payment-qr'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy gym_payment_qr_delete on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'gym-payment-qr'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy gym_payment_qr_member_select on storage.objects
  for select
  using (
    bucket_id = 'gym-payment-qr'
    and public.current_user_is_gym_app_user(((storage.foldername(name))[1])::uuid)
  );

-- Include payment options in public gym directory detail.
create or replace function public.get_directory_gym_detail(p_gym_id uuid)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result json;
begin
  select json_build_object(
    'gym', (
      select json_build_object(
        'id', g.id,
        'name', g.name,
        'address', g.address,
        'phone', g.phone,
        'email', g.email,
        'timezone', g.timezone,
        'latitude', g.latitude,
        'longitude', g.longitude,
        'check_in_radius_meters', g.check_in_radius_meters,
        'amenities', to_json(public.sanitize_gym_amenities(g.amenities))
      )
      from public.gyms g
      where g.id = p_gym_id
    ),
    'hours', coalesce((
      select json_agg(
        json_build_object(
          'day_of_week', h.day_of_week,
          'is_closed', h.is_closed,
          'open_time', h.open_time,
          'close_time', h.close_time
        )
        order by h.day_of_week
      )
      from public.gym_operating_hours h
      where h.gym_id = p_gym_id
    ), '[]'::json),
    'promotions', coalesce((
      select json_agg(
        json_build_object(
          'id', p.id,
          'title', p.title,
          'description', p.description,
          'start_at', p.start_at,
          'end_at', p.end_at,
          'card_design', p.card_design
        )
        order by p.end_at
      )
      from public.promotions p
      where p.gym_id = p_gym_id
        and p.is_active = true
        and p.start_at <= timezone('utc', now())
        and p.end_at >= timezone('utc', now())
    ), '[]'::json),
    'payment_options', coalesce((
      select json_agg(
        json_build_object(
          'id', po.id,
          'label', po.label,
          'upi_id', po.upi_id,
          'qr_image_path', po.qr_image_path,
          'sort_order', po.sort_order
        )
        order by po.sort_order, po.created_at
      )
      from public.gym_payment_options po
      where po.gym_id = p_gym_id
        and po.is_active = true
        and (
          coalesce(nullif(trim(po.upi_id), ''), null) is not null
          or coalesce(nullif(trim(po.qr_image_path), ''), null) is not null
        )
    ), '[]'::json)
  )
  into result;

  if result is null or result->'gym' is null or json_typeof(result->'gym') = 'null' then
    return null;
  end if;

  return result;
end;
$$;

grant execute on function public.get_directory_gym_detail(uuid) to anon, authenticated;
