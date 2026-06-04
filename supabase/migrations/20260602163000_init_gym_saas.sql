-- Multi-tenant schema for gym owner attendance SaaS.
create extension if not exists pgcrypto;

create table if not exists public.gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  address text,
  timezone text not null default 'UTC',
  currency_code text not null default 'USD',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

do $$
begin
  if not exists (select 1 from pg_type where typname = 'gym_role') then
    create type public.gym_role as enum ('owner', 'staff');
  end if;
end $$;

create table if not exists public.gym_roles (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.gym_role not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (gym_id, user_id)
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  full_name text not null,
  email text,
  phone text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  joined_on date not null default current_date,
  date_of_birth date,
  emergency_contact text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  check_in_at timestamptz not null,
  check_out_at timestamptz,
  marked_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint attendance_record_time_valid check (check_out_at is null or check_out_at > check_in_at)
);

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  name text not null,
  description text,
  duration_days int not null check (duration_days > 0),
  price numeric(12, 2) not null check (price >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.member_subscriptions (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  plan_id uuid not null references public.subscription_plans (id) on delete restrict,
  start_date date not null,
  end_date date not null,
  amount_paid numeric(12, 2) not null default 0 check (amount_paid >= 0),
  status text not null default 'active' check (status in ('active', 'expired', 'cancelled')),
  payment_status text not null default 'due' check (payment_status in ('paid', 'partial', 'due')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint member_subscription_dates check (end_date >= start_date)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  name text not null,
  description text,
  sku text,
  price numeric(12, 2) not null check (price >= 0),
  stock_qty int not null default 0 check (stock_qty >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sales_orders (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  member_id uuid references public.members (id) on delete set null,
  sold_by uuid references public.profiles (id) on delete set null,
  total_amount numeric(12, 2) not null default 0 check (total_amount >= 0),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sales_order_items (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  order_id uuid not null references public.sales_orders (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete restrict,
  qty int not null check (qty > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  line_total numeric(12, 2) not null check (line_total >= 0),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  title text not null,
  description text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint promotion_dates check (end_at > start_at)
);

create index if not exists idx_gym_roles_user_id on public.gym_roles (user_id);
create index if not exists idx_members_gym_id on public.members (gym_id);
create index if not exists idx_attendance_gym_member on public.attendance_records (gym_id, member_id, check_in_at desc);
create index if not exists idx_subscriptions_gym_member on public.member_subscriptions (gym_id, member_id);
create index if not exists idx_products_gym_id on public.products (gym_id);
create index if not exists idx_sales_orders_gym_id on public.sales_orders (gym_id, created_at desc);
create index if not exists idx_promotions_gym_id on public.promotions (gym_id);

create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$ language plpgsql;

create or replace function public.current_user_is_gym_member(target_gym_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
  );
$$;

create or replace function public.current_user_is_gym_owner(target_gym_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role = 'owner'
  );
$$;

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

    insert into public.attendance_records (gym_id, member_id, check_in_at, marked_by)
    values (p_gym_id, p_member_id, timezone('utc', now()), auth.uid())
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

create or replace function public.create_member_with_subscription(
  p_gym_id uuid,
  p_full_name text,
  p_phone text,
  p_email text,
  p_plan_id uuid,
  p_start_date date
)
returns public.members
language plpgsql
security definer
set search_path = public
as $$
declare
  plan_record public.subscription_plans;
  new_member public.members;
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  select *
  into plan_record
  from public.subscription_plans
  where id = p_plan_id and gym_id = p_gym_id and is_active = true;

  if plan_record.id is null then
    raise exception 'Invalid plan for gym.';
  end if;

  insert into public.members (gym_id, full_name, phone, email)
  values (p_gym_id, p_full_name, p_phone, p_email)
  returning * into new_member;

  insert into public.member_subscriptions (
    gym_id, member_id, plan_id, start_date, end_date, payment_status, amount_paid
  )
  values (
    p_gym_id,
    new_member.id,
    p_plan_id,
    p_start_date,
    p_start_date + (plan_record.duration_days || ' days')::interval,
    'due',
    0
  );

  return new_member;
end;
$$;

create or replace view public.report_attendance_daily as
select
  gym_id,
  date_trunc('day', check_in_at)::date as attendance_date,
  count(*) as total_checkins,
  count(*) filter (where check_out_at is not null) as total_checkouts
from public.attendance_records
group by gym_id, date_trunc('day', check_in_at)::date;

create or replace view public.report_dues_summary as
select
  ms.gym_id,
  count(*) filter (where ms.payment_status = 'due') as due_count,
  count(*) filter (where ms.payment_status = 'partial') as partial_count,
  count(*) filter (where ms.payment_status = 'paid') as paid_count,
  coalesce(sum(case when ms.payment_status in ('due', 'partial') then greatest(sp.price - ms.amount_paid, 0) else 0 end), 0) as pending_amount
from public.member_subscriptions ms
join public.subscription_plans sp on sp.id = ms.plan_id
group by ms.gym_id;

create or replace view public.report_sales_daily as
select
  gym_id,
  date_trunc('day', created_at)::date as sales_date,
  count(*) as order_count,
  coalesce(sum(total_amount), 0) as total_sales
from public.sales_orders
group by gym_id, date_trunc('day', created_at)::date;

create trigger gyms_touch_updated_at
before update on public.gyms
for each row execute function public.touch_updated_at();
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();
create trigger members_touch_updated_at
before update on public.members
for each row execute function public.touch_updated_at();
create trigger plans_touch_updated_at
before update on public.subscription_plans
for each row execute function public.touch_updated_at();
create trigger member_subscriptions_touch_updated_at
before update on public.member_subscriptions
for each row execute function public.touch_updated_at();
create trigger products_touch_updated_at
before update on public.products
for each row execute function public.touch_updated_at();
create trigger promotions_touch_updated_at
before update on public.promotions
for each row execute function public.touch_updated_at();

alter table public.gyms enable row level security;
alter table public.profiles enable row level security;
alter table public.gym_roles enable row level security;
alter table public.members enable row level security;
alter table public.attendance_records enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.member_subscriptions enable row level security;
alter table public.products enable row level security;
alter table public.sales_orders enable row level security;
alter table public.sales_order_items enable row level security;
alter table public.promotions enable row level security;

create policy gyms_select on public.gyms for select using (public.current_user_is_gym_member(id));
create policy gyms_update_owner on public.gyms for update using (public.current_user_is_gym_owner(id));

create policy profiles_self on public.profiles for select using (id = auth.uid());
create policy profiles_self_upsert on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());

create policy gym_roles_select on public.gym_roles for select using (user_id = auth.uid() or public.current_user_is_gym_owner(gym_id));
create policy gym_roles_owner_write on public.gym_roles for all using (public.current_user_is_gym_owner(gym_id)) with check (public.current_user_is_gym_owner(gym_id));

create policy members_gym_scope_select on public.members for select using (public.current_user_is_gym_member(gym_id));
create policy members_gym_scope_write on public.members for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy attendance_gym_scope_select on public.attendance_records for select using (public.current_user_is_gym_member(gym_id));
create policy attendance_gym_scope_write on public.attendance_records for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy plans_gym_scope_select on public.subscription_plans for select using (public.current_user_is_gym_member(gym_id));
create policy plans_gym_scope_write on public.subscription_plans for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy subscriptions_gym_scope_select on public.member_subscriptions for select using (public.current_user_is_gym_member(gym_id));
create policy subscriptions_gym_scope_write on public.member_subscriptions for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy products_gym_scope_select on public.products for select using (public.current_user_is_gym_member(gym_id));
create policy products_gym_scope_write on public.products for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy sales_orders_gym_scope_select on public.sales_orders for select using (public.current_user_is_gym_member(gym_id));
create policy sales_orders_gym_scope_write on public.sales_orders for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy sales_items_gym_scope_select on public.sales_order_items for select using (public.current_user_is_gym_member(gym_id));
create policy sales_items_gym_scope_write on public.sales_order_items for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

create policy promotions_gym_scope_select on public.promotions for select using (public.current_user_is_gym_member(gym_id));
create policy promotions_gym_scope_write on public.promotions for all using (public.current_user_is_gym_member(gym_id)) with check (public.current_user_is_gym_member(gym_id));

grant execute on function public.mark_attendance(uuid, uuid, text) to authenticated;
grant execute on function public.create_member_with_subscription(uuid, text, text, text, uuid, date) to authenticated;
