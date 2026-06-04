-- Diet plans by goal: weight loss, muscle gain, healthy maintenance.
-- Structure: category (goal) -> plan -> meals -> food items.

create table if not exists public.diet_plan_categories (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  goal_key text not null check (goal_key in ('weight_loss', 'muscle_gain', 'healthy')),
  name text not null,
  description text,
  nutrition_tips text,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, goal_key)
);

create table if not exists public.diet_plans (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  category_id uuid not null references public.diet_plan_categories (id) on delete restrict,
  name text not null,
  description text,
  image_path text,
  target_calories int check (target_calories is null or target_calories > 0),
  target_protein_g numeric(8, 2) check (target_protein_g is null or target_protein_g >= 0),
  target_carbs_g numeric(8, 2) check (target_carbs_g is null or target_carbs_g >= 0),
  target_fat_g numeric(8, 2) check (target_fat_g is null or target_fat_g >= 0),
  hydration_liters numeric(4, 2) check (hydration_liters is null or hydration_liters > 0),
  duration_days int not null default 7 check (duration_days > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.diet_meals (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  diet_plan_id uuid not null references public.diet_plans (id) on delete cascade,
  meal_label text not null,
  meal_time text,
  guidance text,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.diet_food_items (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  diet_meal_id uuid not null references public.diet_meals (id) on delete cascade,
  food_name text not null,
  portion text,
  calories int check (calories is null or calories >= 0),
  protein_g numeric(8, 2) check (protein_g is null or protein_g >= 0),
  carbs_g numeric(8, 2) check (carbs_g is null or carbs_g >= 0),
  fat_g numeric(8, 2) check (fat_g is null or fat_g >= 0),
  notes text,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_diet_plan_categories_gym on public.diet_plan_categories (gym_id);
create index if not exists idx_diet_plans_gym on public.diet_plans (gym_id);
create index if not exists idx_diet_plans_category on public.diet_plans (category_id);
create index if not exists idx_diet_meals_plan on public.diet_meals (diet_plan_id);
create index if not exists idx_diet_food_items_meal on public.diet_food_items (diet_meal_id);

create trigger diet_plan_categories_touch_updated_at
before update on public.diet_plan_categories
for each row execute function public.touch_updated_at();

create trigger diet_plans_touch_updated_at
before update on public.diet_plans
for each row execute function public.touch_updated_at();

create trigger diet_meals_touch_updated_at
before update on public.diet_meals
for each row execute function public.touch_updated_at();

alter table public.diet_plan_categories enable row level security;
alter table public.diet_plans enable row level security;
alter table public.diet_meals enable row level security;
alter table public.diet_food_items enable row level security;

create policy diet_plan_categories_gym_scope_select on public.diet_plan_categories
  for select using (public.current_user_is_gym_member(gym_id));

create policy diet_plan_categories_gym_scope_write on public.diet_plan_categories
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy diet_plans_gym_scope_select on public.diet_plans
  for select using (public.current_user_is_gym_member(gym_id));

create policy diet_plans_gym_scope_write on public.diet_plans
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy diet_meals_gym_scope_select on public.diet_meals
  for select using (public.current_user_is_gym_member(gym_id));

create policy diet_meals_gym_scope_write on public.diet_meals
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

create policy diet_food_items_gym_scope_select on public.diet_food_items
  for select using (public.current_user_is_gym_member(gym_id));

create policy diet_food_items_gym_scope_write on public.diet_food_items
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'diet-images',
  'diet-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy diet_images_select on storage.objects
  for select using (bucket_id = 'diet-images');

create policy diet_images_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'diet-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy diet_images_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'diet-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy diet_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'diet-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );
