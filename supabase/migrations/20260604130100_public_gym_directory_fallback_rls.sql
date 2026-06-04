-- Allow directory fallback queries (when RPC JSON parsing path is unavailable).

create policy gyms_public_directory_select on public.gyms
  for select
  to anon, authenticated
  using (true);

create policy gym_operating_hours_public_directory_select on public.gym_operating_hours
  for select
  to anon, authenticated
  using (true);

create policy promotions_public_directory_select on public.promotions
  for select
  to anon, authenticated
  using (is_active = true);
