-- 1. Create trigger function to sync member status based on subscription presence
create or replace function public.fn_sync_member_status_with_subscriptions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member_id uuid;
  v_has_active boolean;
  v_current_status text;
begin
  if TG_OP = 'DELETE' then
    v_member_id := OLD.member_id;
  else
    v_member_id := NEW.member_id;
  end if;

  -- Get current status of the member
  select status into v_current_status
  from public.members
  where id = v_member_id;

  if v_current_status is null then
    return null;
  end if;

  -- Check if they have any active, non-expired subscriptions
  select exists (
    select 1
    from public.member_subscriptions ms
    join public.gyms g on g.id = ms.gym_id
    where ms.member_id = v_member_id
      and ms.status = 'active'
      and ms.end_date >= timezone(g.timezone, now())::date
  ) into v_has_active;

  if v_has_active then
    -- Reactivate member if they were not active (e.g. inactive or left)
    if v_current_status <> 'active' then
      update public.members
      set status = 'active', updated_at = timezone('utc', now())
      where id = v_member_id;
    end if;
  else
    -- Deactivate member if they were active but no longer have active subscriptions
    if v_current_status = 'active' then
      update public.members
      set status = 'inactive', updated_at = timezone('utc', now())
      where id = v_member_id;
    end if;
  end if;

  if TG_OP = 'DELETE' then
    return OLD;
  else
    return NEW;
  end if;
end;
$$;

-- 2. Bind the trigger to member_subscriptions table
drop trigger if exists member_subscriptions_status_sync on public.member_subscriptions;
create trigger member_subscriptions_status_sync
after insert or update or delete on public.member_subscriptions
for each row
execute function public.fn_sync_member_status_with_subscriptions();

-- 3. Create function to automatically transition past subscriptions to 'expired'
create or replace function public.auto_expire_subscriptions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.member_subscriptions ms
  set status = 'expired', updated_at = timezone('utc', now())
  from public.gyms g
  where ms.gym_id = g.id
    and ms.status = 'active'
    and ms.end_date < timezone(g.timezone, now())::date;

  get diagnostics updated_count = row_count;
  return coalesce(updated_count, 0);
end;
$$;

grant execute on function public.auto_expire_subscriptions() to service_role;

-- 4. Schedule the auto-expire job to run hourly using pg_cron
create extension if not exists pg_cron;

do $schedule_auto_expire$
declare
  existing_job_id bigint;
begin
  select jobid
  into existing_job_id
  from cron.job
  where jobname = 'auto-expire-subscriptions';

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end if;

  perform cron.schedule(
    'auto-expire-subscriptions',
    '0 * * * *', -- run at the start of every hour
    'select public.auto_expire_subscriptions();'
  );
end;
$schedule_auto_expire$;

-- 5. Backfill existing records to ensure data consistency immediately
-- Update existing active subscriptions that have already passed their end_date
update public.member_subscriptions ms
set status = 'expired', updated_at = timezone('utc', now())
from public.gyms g
where ms.gym_id = g.id
  and ms.status = 'active'
  and ms.end_date < timezone(g.timezone, now())::date;

-- Update members who are currently marked 'active' but have no active subscriptions to 'inactive'
update public.members m
set status = 'inactive', updated_at = timezone('utc', now())
where m.status = 'active'
  and not exists (
    select 1
    from public.member_subscriptions ms
    join public.gyms g on g.id = ms.gym_id
    where ms.member_id = m.id
      and ms.status = 'active'
      and ms.end_date >= timezone(g.timezone, now())::date
  );

