-- Alter members status check constraint and add left/extra usage columns.

-- 1. Drop existing status check constraint if it exists.
alter table public.members drop constraint if exists members_status_check;

-- 2. Add columns if not exists.
alter table public.members
  add column if not exists left_at timestamptz,
  add column if not exists left_message text,
  add column if not exists extra_days integer not null default 0,
  add column if not exists extra_amount numeric(12, 2) not null default 0.00;

-- 3. Add back the check constraint to support active, inactive, and left statuses.
alter table public.members
  add constraint members_status_check check (status in ('active', 'inactive', 'left'));
