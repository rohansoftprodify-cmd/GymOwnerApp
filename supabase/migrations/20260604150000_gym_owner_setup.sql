-- Track whether the gym owner finished in-app setup (hours, plans, etc.).
alter table public.gyms
  add column if not exists setup_completed_at timestamptz;

comment on column public.gyms.setup_completed_at is
  'Set when the gym owner completes the post-login setup wizard.';

-- Existing gyms with hours and at least one plan are treated as already set up.
update public.gyms g
set setup_completed_at = timezone('utc', now())
where g.setup_completed_at is null
  and exists (
    select 1 from public.gym_operating_hours h where h.gym_id = g.id
  )
  and exists (
    select 1
    from public.subscription_plans p
    where p.gym_id = g.id
      and p.is_active = true
  );
