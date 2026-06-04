-- Weekly operating hours per gym (local time in gyms.timezone).

create table if not exists public.gym_operating_hours (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  day_of_week int not null check (day_of_week between 1 and 7),
  is_closed boolean not null default false,
  open_time time,
  close_time time,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, day_of_week),
  constraint gym_operating_hours_times_valid check (
    is_closed
    or (
      open_time is not null
      and close_time is not null
      and close_time > open_time
    )
  )
);

create index if not exists idx_gym_operating_hours_gym_id
  on public.gym_operating_hours (gym_id);

create trigger gym_operating_hours_touch_updated_at
before update on public.gym_operating_hours
for each row execute function public.touch_updated_at();

alter table public.gym_operating_hours enable row level security;

create policy gym_operating_hours_gym_scope_select on public.gym_operating_hours
  for select using (public.current_user_is_gym_member(gym_id));

create policy gym_operating_hours_gym_scope_write on public.gym_operating_hours
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));
