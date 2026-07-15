-- Member store orders await gym owner payment confirmation before stock is deducted.

alter table public.sales_orders
  add column if not exists payment_status text not null default 'confirmed'
    check (payment_status in ('pending', 'confirmed', 'rejected')),
  add column if not exists confirmed_at timestamptz,
  add column if not exists confirmed_by uuid references public.profiles (id) on delete set null;

update public.sales_orders
set payment_status = 'confirmed'
where payment_status is distinct from 'confirmed';

create index if not exists idx_sales_orders_pending
  on public.sales_orders (gym_id, created_at desc)
  where payment_status = 'pending';

create or replace function public.create_member_product_order(p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member_id uuid;
  v_gym_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_unit_price numeric;
  v_stock int;
  v_line_total numeric;
  v_order_id uuid;
  v_total numeric := 0;
  v_product_gym_id uuid;
  v_product_name text;
begin
  v_member_id := public.current_auth_member_id();
  if v_member_id is null then
    raise exception 'Not linked to a gym membership';
  end if;

  select m.gym_id into v_gym_id
  from public.members m
  where m.id = v_member_id;

  if v_gym_id is null then
    raise exception 'Member gym not found';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Cart is empty';
  end if;

  for v_item in select value from jsonb_array_elements(p_items) as t(value)
  loop
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_qty := (v_item->>'qty')::int;

    if v_product_id is null then
      raise exception 'Invalid product';
    end if;
    if v_qty is null or v_qty < 1 then
      raise exception 'Invalid quantity';
    end if;

    select
      p.gym_id,
      p.stock_qty,
      p.name,
      public.product_selling_price(p.offer_price, p.actual_price, p.price)
    into v_product_gym_id, v_stock, v_product_name, v_unit_price
    from public.products p
    where p.id = v_product_id
      and p.is_active = true
    for update;

    if v_product_gym_id is null then
      raise exception 'Product not found or unavailable';
    end if;

    if v_product_gym_id <> v_gym_id then
      raise exception 'You can only buy products from your own gym';
    end if;

    if v_stock < v_qty then
      raise exception 'Not enough stock for "%"', coalesce(v_product_name, 'product');
    end if;
  end loop;

  insert into public.sales_orders (
    gym_id,
    member_id,
    sold_by,
    total_amount,
    payment_status
  )
  values (v_gym_id, v_member_id, null, 0, 'pending')
  returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items) as t(value)
  loop
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_qty := (v_item->>'qty')::int;

    select
      public.product_selling_price(p.offer_price, p.actual_price, p.price)
    into v_unit_price
    from public.products p
    where p.id = v_product_id
      and p.gym_id = v_gym_id
      and p.is_active = true;

    v_line_total := v_unit_price * v_qty;
    v_total := v_total + v_line_total;

    insert into public.sales_order_items (
      gym_id,
      order_id,
      product_id,
      qty,
      unit_price,
      line_total
    )
    values (
      v_gym_id,
      v_order_id,
      v_product_id,
      v_qty,
      v_unit_price,
      v_line_total
    );
  end loop;

  update public.sales_orders
  set total_amount = v_total
  where id = v_order_id;

  return jsonb_build_object(
    'order_id', v_order_id,
    'total_amount', v_total,
    'gym_id', v_gym_id,
    'payment_status', 'pending'
  );
end;
$$;

create or replace function public.confirm_sales_order(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.sales_orders%rowtype;
  v_item record;
  v_stock int;
begin
  select * into v_order
  from public.sales_orders
  where id = p_order_id
  for update;

  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  if not public.current_user_is_gym_member(v_order.gym_id) then
    raise exception 'Not authorized';
  end if;

  if v_order.payment_status <> 'pending' then
    raise exception 'Order is not pending confirmation';
  end if;

  for v_item in
    select soi.product_id, soi.qty
    from public.sales_order_items soi
    where soi.order_id = v_order.id
  loop
    select p.stock_qty into v_stock
    from public.products p
    where p.id = v_item.product_id
      and p.gym_id = v_order.gym_id
      and p.is_active = true
    for update;

    if v_stock is null then
      raise exception 'Product no longer available';
    end if;

    if v_stock < v_item.qty then
      raise exception 'Not enough stock to confirm this order';
    end if;

    update public.products
    set stock_qty = v_stock - v_item.qty,
        updated_at = timezone('utc', now())
    where id = v_item.product_id;
  end loop;

  update public.sales_orders
  set payment_status = 'confirmed',
      confirmed_at = timezone('utc', now()),
      confirmed_by = auth.uid()
  where id = v_order.id;

  return jsonb_build_object(
    'order_id', v_order.id,
    'payment_status', 'confirmed'
  );
end;
$$;

create or replace function public.reject_sales_order(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.sales_orders%rowtype;
begin
  select * into v_order
  from public.sales_orders
  where id = p_order_id
  for update;

  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  if not public.current_user_is_gym_member(v_order.gym_id) then
    raise exception 'Not authorized';
  end if;

  if v_order.payment_status <> 'pending' then
    raise exception 'Order is not pending confirmation';
  end if;

  update public.sales_orders
  set payment_status = 'rejected',
      confirmed_at = timezone('utc', now()),
      confirmed_by = auth.uid()
  where id = v_order.id;

  return jsonb_build_object(
    'order_id', v_order.id,
    'payment_status', 'rejected'
  );
end;
$$;

grant execute on function public.confirm_sales_order(uuid) to authenticated;
grant execute on function public.reject_sales_order(uuid) to authenticated;

create or replace view public.report_sales_daily as
select
  gym_id,
  date_trunc('day', created_at)::date as sales_date,
  count(*) as order_count,
  coalesce(sum(total_amount), 0) as total_sales
from public.sales_orders
where payment_status = 'confirmed'
group by gym_id, date_trunc('day', created_at)::date;

comment on column public.sales_orders.payment_status is
  'pending = member UPI order awaiting gym confirmation; confirmed = completed sale; rejected = declined';
