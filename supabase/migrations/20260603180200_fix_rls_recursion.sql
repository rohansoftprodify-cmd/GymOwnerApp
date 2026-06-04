-- Fix "stack depth limit exceeded" on members select.
-- RLS helpers must not re-enter RLS when reading members / gym_roles.

create or replace function public.current_user_is_gym_member(target_gym_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role in ('owner', 'staff')
  );
$$;

create or replace function public.current_user_is_gym_app_user(target_gym_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role = 'member'
  );
$$;

create or replace function public.current_user_linked_member_id(target_gym_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select m.id
  from public.members m
  where m.gym_id = target_gym_id
    and m.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.current_user_is_gym_owner(target_gym_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.gym_roles r
    where r.gym_id = target_gym_id
      and r.user_id = auth.uid()
      and r.role = 'owner'
  );
$$;
