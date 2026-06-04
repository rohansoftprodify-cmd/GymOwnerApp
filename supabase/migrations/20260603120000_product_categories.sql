-- Product categories per gym + link products to a category.
create table if not exists public.product_categories (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  name text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, name)
);

alter table public.products
  add column if not exists category_id uuid references public.product_categories (id) on delete restrict;

create index if not exists idx_product_categories_gym_id on public.product_categories (gym_id);
create index if not exists idx_products_category_id on public.products (category_id);

create trigger product_categories_touch_updated_at
before update on public.product_categories
for each row execute function public.touch_updated_at();

alter table public.product_categories enable row level security;

create policy product_categories_gym_scope_select on public.product_categories
  for select using (public.current_user_is_gym_member(gym_id));

create policy product_categories_gym_scope_write on public.product_categories
  for all using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));
