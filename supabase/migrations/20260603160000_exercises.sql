-- Exercise library per gym (categories, exercises, image storage).

create table if not exists public.exercise_categories (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  name text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, name)
);

create table if not exists public.exercises (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  category_id uuid not null references public.exercise_categories (id) on delete restrict,
  name text not null,
  image_path text,
  benefits text,
  precautions text,
  default_sets int not null default 3 check (default_sets > 0),
  default_reps int not null default 10 check (default_reps > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_exercise_categories_gym_id on public.exercise_categories (gym_id);
create index if not exists idx_exercises_gym_id on public.exercises (gym_id);
create index if not exists idx_exercises_category_id on public.exercises (category_id);

create trigger exercise_categories_touch_updated_at
before update on public.exercise_categories
for each row execute function public.touch_updated_at();

create trigger exercises_touch_updated_at
before update on public.exercises
for each row execute function public.touch_updated_at();

alter table public.exercise_categories enable row level security;
alter table public.exercises enable row level security;

create policy exercise_categories_gym_scope_select on public.exercise_categories
  for select using (public.current_user_is_gym_member(gym_id));

create policy exercise_categories_gym_scope_write on public.exercise_categories
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy exercises_gym_scope_select on public.exercises
  for select using (public.current_user_is_gym_member(gym_id));

create policy exercises_gym_scope_write on public.exercises
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

-- Public bucket for exercise demonstration images: {gym_id}/{exercise_id}.jpg
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'exercise-images',
  'exercise-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy exercise_images_select on storage.objects
  for select
  using (bucket_id = 'exercise-images');

create policy exercise_images_insert on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'exercise-images'
    and (storage.foldername(name))[1] is not null
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy exercise_images_update on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'exercise-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy exercise_images_delete on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'exercise-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );
