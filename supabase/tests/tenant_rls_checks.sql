-- Validate tenant isolation and RLS.
-- Run in Supabase SQL editor with test users in place.

-- 1) As gym A user, reading gym B members should return 0 rows.
-- select * from public.members where gym_id = '22222222-2222-2222-2222-222222222222';

-- 2) As gym A user, writing gym B member should fail by policy.
-- insert into public.members (gym_id, full_name, phone) values ('22222222-2222-2222-2222-222222222222', 'Blocked', '+919999999999');

-- 3) As gym owner, role assignment should pass only for same gym.
-- insert into public.gym_roles (gym_id, user_id, role) values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'staff');
