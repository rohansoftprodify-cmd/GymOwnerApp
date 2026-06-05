-- Product images for gym shop (owner upload, member browse).

alter table public.products
  add column if not exists image_path text;

comment on column public.products.image_path is 'Storage path in product-images bucket: {gym_id}/{product_id}.ext';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy product_images_select on storage.objects
  for select
  using (bucket_id = 'product-images');

create policy product_images_insert on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] is not null
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy product_images_update on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'product-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy product_images_delete on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'product-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy product_images_member_select on storage.objects
  for select
  using (
    bucket_id = 'product-images'
    and public.current_user_is_gym_app_user(((storage.foldername(name))[1])::uuid)
  );
