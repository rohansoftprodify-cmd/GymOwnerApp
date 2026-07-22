-- Member Support Bot: owner-managed Q&A shown to members in the member app.

create table if not exists public.gym_support_faqs (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms (id) on delete cascade,
  category text not null check (
    category in (
      'gym_timings',
      'membership_plans',
      'trainer_availability',
      'diet_queries',
      'general'
    )
  ),
  question text not null,
  answer text not null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_gym_support_faqs_gym
  on public.gym_support_faqs (gym_id, category, sort_order);

drop trigger if exists gym_support_faqs_touch_updated_at on public.gym_support_faqs;
create trigger gym_support_faqs_touch_updated_at
before update on public.gym_support_faqs
for each row execute function public.touch_updated_at();

alter table public.gym_support_faqs enable row level security;

drop policy if exists gym_support_faqs_gym_scope_select on public.gym_support_faqs;
create policy gym_support_faqs_gym_scope_select on public.gym_support_faqs
  for select using (public.current_user_is_gym_member(gym_id));

drop policy if exists gym_support_faqs_gym_scope_write on public.gym_support_faqs;
create policy gym_support_faqs_gym_scope_write on public.gym_support_faqs
  for all
  using (public.current_user_is_gym_member(gym_id))
  with check (public.current_user_is_gym_member(gym_id));

drop policy if exists gym_support_faqs_member_select on public.gym_support_faqs;
create policy gym_support_faqs_member_select on public.gym_support_faqs
  for select
  using (
    public.current_user_is_gym_app_user(gym_id)
    and is_active = true
  );

create or replace function public.ensure_default_gym_support_faqs(p_gym_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.current_user_is_gym_member(p_gym_id) then
    raise exception 'Unauthorized for this gym.';
  end if;

  if exists (select 1 from public.gym_support_faqs where gym_id = p_gym_id) then
    return;
  end if;

  insert into public.gym_support_faqs (gym_id, category, question, answer, sort_order)
  values
    (
      p_gym_id,
      'gym_timings',
      'What are the gym opening hours?',
      'Please check the gym profile or ask at the front desk for today''s hours. Hours may vary on holidays.',
      0
    ),
    (
      p_gym_id,
      'gym_timings',
      'Is the gym open on Sundays?',
      'Sunday hours may differ from weekdays. Contact the gym or check the notice board at reception.',
      1
    ),
    (
      p_gym_id,
      'membership_plans',
      'What membership plans do you offer?',
      'We offer monthly, quarterly, and annual plans. Visit the front desk or check your gym app for current pricing.',
      0
    ),
    (
      p_gym_id,
      'membership_plans',
      'How do I renew my membership?',
      'Renew at the front desk before your end date, or ask staff to extend your plan in the system.',
      1
    ),
    (
      p_gym_id,
      'trainer_availability',
      'Are personal trainers available?',
      'Yes — ask at reception for trainer schedules and PT session packages.',
      0
    ),
    (
      p_gym_id,
      'trainer_availability',
      'How do I book a trainer session?',
      'Speak with front desk staff or your assigned trainer to book a slot.',
      1
    ),
    (
      p_gym_id,
      'diet_queries',
      'Do you provide diet plans?',
      'Diet plans may be included with select memberships. Open the Diet section in your member app or ask staff.',
      0
    ),
    (
      p_gym_id,
      'diet_queries',
      'Can I get a vegetarian diet plan?',
      'Yes. Tell staff your preference (veg, non-veg, or eggetarian) when requesting a diet plan.',
      1
    ),
    (
      p_gym_id,
      'general',
      'How do I check in?',
      'Use QR scan at the entrance, GPS check-in in the member app, or ask staff to check you in at the desk.',
      0
    );
end;
$$;

grant execute on function public.ensure_default_gym_support_faqs(uuid) to authenticated;

create or replace function public.get_member_support_faqs()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_gym_id uuid;
  result json;
begin
  if auth.uid() is null then
    return '[]'::json;
  end if;

  select r.gym_id into v_gym_id
  from public.gym_roles r
  where r.user_id = auth.uid()
    and r.role = 'member'
  limit 1;

  if v_gym_id is null then
    return '[]'::json;
  end if;

  select coalesce(json_agg(cat_entry order by cat_entry->>'sort_order'), '[]'::json)
  into result
  from (
    select json_build_object(
      'category', f.category,
      'category_label', case f.category
        when 'gym_timings' then 'Gym timings'
        when 'membership_plans' then 'Membership plans'
        when 'trainer_availability' then 'Trainer availability'
        when 'diet_queries' then 'Diet queries'
        else 'General'
      end,
      'sort_order', min(f.sort_order),
      'items', json_agg(
        json_build_object(
          'id', f.id,
          'question', f.question,
          'answer', f.answer,
          'sort_order', f.sort_order
        )
        order by f.sort_order, f.question
      )
    ) as cat_entry
    from public.gym_support_faqs f
    where f.gym_id = v_gym_id
      and f.is_active = true
    group by f.category
  ) grouped;

  return result;
end;
$$;

grant execute on function public.get_member_support_faqs() to authenticated;

drop policy if exists gym_support_faqs_superadmin_all on public.gym_support_faqs;
create policy gym_support_faqs_superadmin_all on public.gym_support_faqs
  for all
  using (public.current_user_is_superadmin())
  with check (public.current_user_is_superadmin());
