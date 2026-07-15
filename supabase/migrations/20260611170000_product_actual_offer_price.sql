-- Product MRP (actual) and optional offer price; price column remains selling price for sales.

alter table public.products
  add column if not exists actual_price numeric(12, 2),
  add column if not exists offer_price numeric(12, 2);

update public.products
set actual_price = price
where actual_price is null;

alter table public.products
  alter column actual_price set not null;

alter table public.products
  drop constraint if exists products_offer_price_valid;

alter table public.products
  add constraint products_offer_price_valid check (
    offer_price is null
    or (offer_price >= 0 and offer_price <= actual_price)
  );

comment on column public.products.actual_price is 'Listed / MRP price shown to members.';
comment on column public.products.offer_price is 'Optional discounted selling price; when set, used at checkout.';
comment on column public.products.price is 'Effective selling price (offer_price or actual_price), kept for sales compatibility.';
