-- Auto check-out open attendance at end of each gym's local day (23:59).
-- Requires pg_cron (enable in Supabase Dashboard: Database → Extensions → pg_cron).

create or replace function public.attendance_end_of_local_day(
  p_timezone text,
  p_check_in_at timestamptz
)
returns timestamptz
language sql
stable
as $$
  select (
    (timezone(p_timezone, p_check_in_at)::date::timestamp + time '23:59:59')
    at time zone p_timezone
  );
$$;

create or replace function public.auto_checkout_open_attendance()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  with gym_context as (
    select
      g.id as gym_id,
      g.timezone as tz,
      timezone(g.timezone, now()) as local_now
    from public.gyms g
    where
      (
        extract(hour from timezone(g.timezone, now())) = 23
        and extract(minute from timezone(g.timezone, now())) >= 55
      )
      or (
        extract(hour from timezone(g.timezone, now())) = 0
        and extract(minute from timezone(g.timezone, now())) <= 10
      )
  ),
  closing as (
    select
      ar.id,
      greatest(
        public.attendance_end_of_local_day(gc.tz, ar.check_in_at),
        ar.check_in_at + interval '1 second'
      ) as checkout_at
    from public.attendance_records ar
    inner join gym_context gc on gc.gym_id = ar.gym_id
    where ar.check_out_at is null
      and timezone(gc.tz, ar.check_in_at)::date <= gc.local_now::date
  )
  update public.attendance_records ar
  set check_out_at = closing.checkout_at
  from closing
  where ar.id = closing.id
    and ar.check_out_at is null;

  get diagnostics updated_count = row_count;
  return coalesce(updated_count, 0);
end;
$$;

comment on function public.auto_checkout_open_attendance() is
  'Closes open attendance at 23:59 local time (per gym.timezone). Invoked by pg_cron near end of day.';

grant execute on function public.auto_checkout_open_attendance() to service_role;

create index if not exists idx_attendance_open_sessions
  on public.attendance_records (gym_id)
  where check_out_at is null;

create extension if not exists pg_cron;

do $schedule_auto_checkout$
declare
  existing_job_id bigint;
begin
  select jobid
  into existing_job_id
  from cron.job
  where jobname = 'auto-checkout-open-attendance';

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end if;

  perform cron.schedule(
    'auto-checkout-open-attendance',
    '*/5 * * * *',
    'select public.auto_checkout_open_attendance();'
  );
end;
$schedule_auto_checkout$;
