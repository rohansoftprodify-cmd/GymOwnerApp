-- Migration: Add image_path to members and create member-images storage bucket

-- 1. Add image_path column to members table
alter table public.members
  add column if not exists image_path text;

comment on column public.members.image_path is 'Storage path in member-images bucket: {gym_id}/{member_id}.ext';

-- 2. Create bucket for member images
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'member-images',
  'member-images',
  true,
  5242880, -- 5MB limit
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- 3. Set RLS policies for member-images bucket
create policy member_images_select on storage.objects
  for select
  using (bucket_id = 'member-images');

create policy member_images_insert on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'member-images'
    and (storage.foldername(name))[1] is not null
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy member_images_update on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'member-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy member_images_delete on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'member-images'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy member_images_member_select on storage.objects
  for select
  using (
    bucket_id = 'member-images'
    and public.current_user_is_gym_app_user(((storage.foldername(name))[1])::uuid)
  );
