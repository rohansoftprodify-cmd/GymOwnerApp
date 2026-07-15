-- Member avatars for gym members (owner upload, member view).

alter table public.members
  add column if not exists avatar_url text;

comment on column public.members.avatar_url is 'Storage path in member-avatars bucket: {gym_id}/{member_id}.jpg';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'member-avatars',
  'member-avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy member_avatars_select on storage.objects
  for select
  using (bucket_id = 'member-avatars');

create policy member_avatars_insert on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'member-avatars'
    and (storage.foldername(name))[1] is not null
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy member_avatars_update on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'member-avatars'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );

create policy member_avatars_delete on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'member-avatars'
    and public.current_user_is_gym_member(((storage.foldername(name))[1])::uuid)
  );
