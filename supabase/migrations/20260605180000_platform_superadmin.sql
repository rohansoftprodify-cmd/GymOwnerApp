-- Platform superadmin role for the React admin portal (RLS bypass via explicit policies).

create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  full_name text,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.platform_admins is
  'Users allowed to access the gym superadmin web portal.';

alter table public.platform_admins enable row level security;

create policy platform_admins_self_select on public.platform_admins
  for select using (user_id = auth.uid());

create or replace function public.current_user_is_superadmin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins where user_id = auth.uid()
  );
$$;

grant execute on function public.current_user_is_superadmin() to authenticated;

create policy platform_admins_superadmin_all on public.platform_admins
  for all using (public.current_user_is_superadmin())
  with check (public.current_user_is_superadmin());

-- Superadmin full access on tenant tables (additive policies; gym RLS still applies to others).
do $$
declare
  t text;
begin
  foreach t in array array[
    'gyms',
    'profiles',
    'gym_roles',
    'members',
    'attendance_records',
    'subscription_plans',
    'member_subscriptions',
    'products',
    'sales_orders',
    'sales_order_items',
    'promotions',
    'product_categories',
    'gym_operating_hours',
    'exercise_categories',
    'exercises',
    'diet_plan_categories',
    'diet_plans',
    'diet_meals',
    'diet_food_items',
    'user_active_sessions'
  ]
  loop
    execute format(
      'create policy %I on public.%I for all using (public.current_user_is_superadmin()) with check (public.current_user_is_superadmin())',
      t || '_superadmin_all',
      t
    );
  end loop;
end $$;

-- First superadmin: create auth user in Supabase Dashboard, then:
-- insert into public.platform_admins (user_id, email, full_name)
-- select id, email, raw_user_meta_data->>'full_name' from auth.users where email = 'admin@yourcompany.com';
