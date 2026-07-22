-- Member self-checkout: place product orders only from the member's own gym.

create or replace function public.product_selling_price(
  p_offer_price numeric,
  p_actual_price numeric,
  p_price numeric
)
returns numeric
language sql
immutable
as $$
  select case
    when p_offer_price is not null
      and p_offer_price > 0
      and p_offer_price < coalesce(p_actual_price, p_price, 0)
      then p_offer_price
    else coalesce(p_actual_price, p_price, 0)
  end;
$$;

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

  insert into public.sales_orders (gym_id, member_id, sold_by, total_amount)
  values (v_gym_id, v_member_id, null, 0)
  returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items) as t(value)
  loop
    v_product_id := nullif(v_item->>'product_id', '')::uuid;
    v_qty := (v_item->>'qty')::int;

    select
      p.stock_qty,
      public.product_selling_price(p.offer_price, p.actual_price, p.price)
    into v_stock, v_unit_price
    from public.products p
    where p.id = v_product_id
      and p.gym_id = v_gym_id
      and p.is_active = true
    for update;

    if v_stock < v_qty then
      raise exception 'Not enough stock while placing order';
    end if;

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

    update public.products
    set stock_qty = v_stock - v_qty,
        updated_at = timezone('utc', now())
    where id = v_product_id;
  end loop;

  update public.sales_orders
  set total_amount = v_total
  where id = v_order_id;

  return jsonb_build_object(
    'order_id', v_order_id,
    'total_amount', v_total,
    'gym_id', v_gym_id
  );
end;
$$;

grant execute on function public.create_member_product_order(jsonb) to authenticated;

comment on function public.create_member_product_order(jsonb) is
  'Creates a sales order for the authenticated member; products must belong to the member gym.';
