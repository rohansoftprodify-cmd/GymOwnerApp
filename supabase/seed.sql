-- Demo seed data for local development.
-- Replace UUIDs/emails before production.
insert into public.gyms (id, name, email, phone, timezone, currency_code)
values
  ('11111111-1111-1111-1111-111111111111', 'Iron Hub Downtown', 'owner@ironhub.test', '+10000000001', 'Asia/Kolkata', 'INR'),
  ('22222222-2222-2222-2222-222222222222', 'PowerFit North', 'owner@powerfit.test', '+10000000002', 'Asia/Kolkata', 'INR')
on conflict (id) do nothing;

-- Profiles must reference existing auth.users IDs.
-- This maps profiles from auth user emails, so no hardcoded auth UUIDs are required.
insert into public.profiles (id, full_name, phone)
select
  u.id,
  m.full_name,
  m.phone
from (
  values
    ('owner@ironhub.test', 'Iron Hub Owner', '+919999000001'),
    ('owner@powerfit.test', 'PowerFit Owner', '+919999000002'),
    ('owner@guptafittnessclub.test', 'Gupta Fitness Owner', '+919100000004')
) as m(email, full_name, phone)
join auth.users u on lower(u.email) = lower(m.email)
on conflict (id) do update
set
  full_name = excluded.full_name,
  phone = excluded.phone;

insert into public.gym_roles (gym_id, user_id, role)
select
  m.gym_id::uuid,
  u.id,
  'owner'::public.gym_role
from (
  values
    ('11111111-1111-1111-1111-111111111111', 'owner@ironhub.test'),
    ('22222222-2222-2222-2222-222222222222', 'owner@powerfit.test')
) as m(gym_id, email)
join auth.users u on lower(u.email) = lower(m.email)
on conflict (gym_id, user_id) do nothing;

insert into public.subscription_plans (gym_id, name, description, duration_days, price)
values
  ('11111111-1111-1111-1111-111111111111', 'Monthly Standard', 'Full gym access', 30, 2500),
  ('11111111-1111-1111-1111-111111111111', 'Quarterly Pro', 'Discounted 3 month plan', 90, 6500),
  ('22222222-2222-2222-2222-222222222222', 'Monthly Standard', 'Full gym access', 30, 3000)
on conflict do nothing;

-- Full linked dummy dataset for one gym: guptafittnessclub
-- NOTE: profile id must exist in auth.users, or profile insert will fail.
insert into public.gyms (id, name, email, phone, address, timezone, currency_code)
values (
  '33333333-3333-3333-3333-333333333333',
  'guptafittnessclub',
  'owner@guptafittnessclub.test',
  '+919100000003',
  'Main Road, Jaipur',
  'Asia/Kolkata',
  'INR'
)
on conflict (id) do nothing;

insert into public.gym_roles (gym_id, user_id, role)
select
  '33333333-3333-3333-3333-333333333333'::uuid,
  u.id,
  'owner'::public.gym_role
from auth.users u
where lower(u.email) = 'owner@guptafittnessclub.test'
on conflict (gym_id, user_id) do nothing;

insert into public.members (id, gym_id, full_name, email, phone, status, joined_on, emergency_contact, notes)
values
  (
    '44444444-4444-4444-4444-444444444444',
    '33333333-3333-3333-3333-333333333333',
    'Rahul Sharma',
    'rahul.sharma@example.test',
    '+919100000101',
    'active',
    current_date - 20,
    'Ramesh Sharma +919100009901',
    'Prefers evening batches'
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    '33333333-3333-3333-3333-333333333333',
    'Neha Gupta',
    'neha.gupta@example.test',
    '+919100000102',
    'active',
    current_date - 12,
    'Suman Gupta +919100009902',
    'Strength training focus'
  )
on conflict (id) do nothing;

insert into public.subscription_plans (id, gym_id, name, description, duration_days, price, is_active)
values
  (
    '66666666-6666-6666-6666-666666666666',
    '33333333-3333-3333-3333-333333333333',
    'Monthly Basic',
    'General gym floor access',
    30,
    1800,
    true
  ),
  (
    '77777777-7777-7777-7777-777777777777',
    '33333333-3333-3333-3333-333333333333',
    'Quarterly Plus',
    'Access + group classes',
    90,
    4800,
    true
  )
on conflict (id) do nothing;

insert into public.member_subscriptions (
  id, gym_id, member_id, plan_id, start_date, end_date, amount_paid, status, payment_status
)
values
  (
    '88888888-8888-8888-8888-888888888888',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    '66666666-6666-6666-6666-666666666666',
    current_date - 20,
    current_date + 10,
    1800,
    'active',
    'paid'
  ),
  (
    '99999999-9999-9999-9999-999999999999',
    '33333333-3333-3333-3333-333333333333',
    '55555555-5555-5555-5555-555555555555',
    '77777777-7777-7777-7777-777777777777',
    current_date - 12,
    current_date + 78,
    2500,
    'active',
    'partial'
  )
on conflict (id) do nothing;

insert into public.attendance_records (
  id, gym_id, member_id, check_in_at, check_out_at, marked_by
)
values
  (
    'aaaaaaaa-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    timezone('utc', now()) - interval '1 day' - interval '2 hours',
    timezone('utc', now()) - interval '1 day' - interval '1 hour',
    (select id from auth.users where lower(email) = 'owner@guptafittnessclub.test' limit 1)
  ),
  (
    'bbbbbbbb-1111-1111-1111-111111111111',
    '33333333-3333-3333-3333-333333333333',
    '55555555-5555-5555-5555-555555555555',
    timezone('utc', now()) - interval '3 hours',
    null,
    (select id from auth.users where lower(email) = 'owner@guptafittnessclub.test' limit 1)
  )
on conflict (id) do nothing;

insert into public.product_categories (id, gym_id, name, sort_order)
values
  (
    '18181818-1818-1818-1818-181818181818',
    '33333333-3333-3333-3333-333333333333',
    'Supplements',
    1
  ),
  (
    '19191919-1919-1919-1919-191919191919',
    '33333333-3333-3333-3333-333333333333',
    'Apparel',
    2
  ),
  (
    '1a1a1a1a-1a1a-1a1a-1a1a-1a1a1a1a1a1a',
    '33333333-3333-3333-3333-333333333333',
    'Accessories',
    3
  )
on conflict (id) do nothing;

insert into public.products (
  id, gym_id, category_id, name, description, sku, price, stock_qty, is_active
)
values
  (
    '12121212-1212-1212-1212-121212121212',
    '33333333-3333-3333-3333-333333333333',
    '18181818-1818-1818-1818-181818181818',
    'Whey Protein 1kg',
    'Chocolate flavor',
    'GFC-WHEY-1KG',
    2499,
    30,
    true
  ),
  (
    '13131313-1313-1313-1313-131313131313',
    '33333333-3333-3333-3333-333333333333',
    '19191919-1919-1919-1919-191919191919',
    'Gym T-Shirt',
    'Dry-fit tee',
    'GFC-TSHIRT-M',
    699,
    50,
    true
  )
on conflict (id) do nothing;

insert into public.sales_orders (id, gym_id, member_id, sold_by, total_amount, created_at)
values
  (
    '14141414-1414-1414-1414-141414141414',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    (select id from auth.users where lower(email) = 'owner@guptafittnessclub.test' limit 1),
    3198,
    timezone('utc', now()) - interval '4 hours'
  )
on conflict (id) do nothing;

insert into public.sales_order_items (
  id, gym_id, order_id, product_id, qty, unit_price, line_total
)
values
  (
    '15151515-1515-1515-1515-151515151515',
    '33333333-3333-3333-3333-333333333333',
    '14141414-1414-1414-1414-141414141414',
    '12121212-1212-1212-1212-121212121212',
    1,
    2499,
    2499
  ),
  (
    '16161616-1616-1616-1616-161616161616',
    '33333333-3333-3333-3333-333333333333',
    '14141414-1414-1414-1414-141414141414',
    '13131313-1313-1313-1313-131313131313',
    1,
    699,
    699
  )
on conflict (id) do nothing;

insert into public.promotions (
  id, gym_id, title, description, start_at, end_at, is_active
)
values
  (
    '17171717-1717-1717-1717-171717171717',
    '33333333-3333-3333-3333-333333333333',
    'Monsoon Offer',
    'Flat 10% off on quarterly membership',
    timezone('utc', now()) - interval '2 days',
    timezone('utc', now()) + interval '10 days',
    true
  )
on conflict (id) do nothing;

-- Default weekly hours for guptafittnessclub (local time in Asia/Kolkata).
insert into public.gym_operating_hours (gym_id, day_of_week, is_closed, open_time, close_time)
values
  ('33333333-3333-3333-3333-333333333333', 1, false, '06:00:00', '22:00:00'),
  ('33333333-3333-3333-3333-333333333333', 2, false, '06:00:00', '22:00:00'),
  ('33333333-3333-3333-3333-333333333333', 3, false, '06:00:00', '22:00:00'),
  ('33333333-3333-3333-3333-333333333333', 4, false, '06:00:00', '22:00:00'),
  ('33333333-3333-3333-3333-333333333333', 5, false, '06:00:00', '22:00:00'),
  ('33333333-3333-3333-3333-333333333333', 6, false, '08:00:00', '20:00:00'),
  ('33333333-3333-3333-3333-333333333333', 7, false, '08:00:00', '20:00:00')
on conflict (gym_id, day_of_week) do update
set
  is_closed = excluded.is_closed,
  open_time = excluded.open_time,
  close_time = excluded.close_time;

-- Exercise categories & sample exercises for guptafittnessclub
insert into public.exercise_categories (gym_id, name, sort_order)
values
  ('33333333-3333-3333-3333-333333333333', 'Chest', 1),
  ('33333333-3333-3333-3333-333333333333', 'Biceps', 2),
  ('33333333-3333-3333-3333-333333333333', 'Triceps', 3),
  ('33333333-3333-3333-3333-333333333333', 'Back', 4),
  ('33333333-3333-3333-3333-333333333333', 'Legs', 5),
  ('33333333-3333-3333-3333-333333333333', 'Shoulders', 6),
  ('33333333-3333-3333-3333-333333333333', 'Abs', 7)
on conflict (gym_id, name) do nothing;

insert into public.exercises (
  gym_id,
  category_id,
  name,
  benefits,
  precautions,
  default_sets,
  default_reps
)
select
  '33333333-3333-3333-3333-333333333333'::uuid,
  c.id,
  e.name,
  e.benefits,
  e.precautions,
  e.default_sets,
  e.default_reps
from (
  values
    ('Chest', 'Bench Press', 'Builds chest strength and pressing power.', 'Keep shoulder blades retracted; use a spotter for heavy sets.', 4, 8),
    ('Biceps', 'Barbell Curl', 'Targets biceps peak and arm thickness.', 'Avoid swinging; control the negative.', 3, 12)
) as e(category_name, name, benefits, precautions, default_sets, default_reps)
join public.exercise_categories c
  on c.gym_id = '33333333-3333-3333-3333-333333333333'::uuid
 and c.name = e.category_name;

-- Diet plan categories (lose / gain / healthy) for guptafittnessclub
insert into public.diet_plan_categories (
  id, gym_id, goal_key, name, description, nutrition_tips, sort_order
)
values
  (
    '18181818-1818-1818-1818-181818181818',
    '33333333-3333-3333-3333-333333333333',
    'weight_loss',
    'Weight Loss',
    'Fat loss with muscle preservation — moderate deficit and high protein.',
    'Aim ~300–500 kcal below maintenance; protein ~1.6–2.2 g/kg.',
    1
  ),
  (
    '19191919-1919-1919-1919-191919191919',
    '33333333-3333-3333-3333-333333333333',
    'muscle_gain',
    'Muscle Gain',
    'Lean mass focus — controlled surplus with training-aligned carbs.',
    'Aim ~250–500 kcal above maintenance; protein ~1.8–2.4 g/kg.',
    2
  ),
  (
    '1a1a1a1a-1a1a-1a1a-1a1a-1a1a1a1a1a1a',
    '33333333-3333-3333-3333-333333333333',
    'healthy',
    'Healthy Lifestyle',
    'Balanced maintenance nutrition for energy and long-term health.',
    'Eat near maintenance; protein ~1.2–1.6 g/kg; whole foods first.',
    3
  )
on conflict (gym_id, goal_key) do update
set
  name = excluded.name,
  description = excluded.description,
  nutrition_tips = excluded.nutrition_tips,
  sort_order = excluded.sort_order;

insert into public.diet_plans (
  id,
  gym_id,
  category_id,
  name,
  description,
  target_calories,
  target_protein_g,
  target_carbs_g,
  target_fat_g,
  hydration_liters,
  duration_days,
  is_active
)
values
  (
    '1b1b1b1b-1b1b-1b1b-1b1b-1b1b1b1b1b1b',
    '33333333-3333-3333-3333-333333333333',
    '18181818-1818-1818-1818-181818181818',
    '7-Day Lean Cut',
    'Sample weight-loss plan for active members.',
    1800,
    140,
    160,
    55,
    3,
    7,
    true
  ),
  (
    '1c1c1c1c-1c1c-1c1c-1c1c-1c1c1c1c1c1c',
    '33333333-3333-3333-3333-333333333333',
    '19191919-1919-1919-1919-191919191919',
    '14-Day Muscle Builder',
    'Sample muscle-gain plan with higher carbs around training.',
    2800,
    180,
    320,
    80,
    3.5,
    14,
    true
  )
on conflict (id) do nothing;

insert into public.diet_meals (id, gym_id, diet_plan_id, meal_label, meal_time, guidance, sort_order)
values
  (
    '1d1d1d1d-1d1d-1d1d-1d1d-1d1d1d1d1d1d',
    '33333333-3333-3333-3333-333333333333',
    '1b1b1b1b-1b1b-1b1b-1b1b-1b1b1b1b1b1b',
    'Breakfast',
    '08:00',
    'High protein, moderate carbs; avoid sugary drinks.',
    0
  ),
  (
    '1e1e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    '33333333-3333-3333-3333-333333333333',
    '1b1b1b1b-1b1b-1b1b-1b1b-1b1b1b1b1b1b',
    'Lunch',
    '13:00',
    'Lean protein + vegetables; control rice/roti portion.',
    1
  ),
  (
    '1f1f1f1f-1f1f-1f1f-1f1f-1f1f1f1f1f1f',
    '33333333-3333-3333-3333-333333333333',
    '1c1c1c1c-1c1c-1c1c-1c1c-1c1c1c1c1c1c',
    'Breakfast',
    '07:30',
    'Calorie-dense start; include protein and complex carbs.',
    0
  )
on conflict (id) do nothing;

insert into public.diet_food_items (
  gym_id, diet_meal_id, food_name, portion, calories, protein_g, carbs_g, fat_g, sort_order
)
values
  (
    '33333333-3333-3333-3333-333333333333',
    '1d1d1d1d-1d1d-1d1d-1d1d-1d1d1d1d1d1d',
    'Oats with milk',
    '1 bowl',
    350,
    18,
    45,
    8,
    0
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    '1d1d1d1d-1d1d-1d1d-1d1d-1d1d1d1d1d1d',
    'Boiled eggs',
    '2 whole',
    140,
    12,
    1,
    10,
    1
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    '1e1e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    'Grilled chicken salad',
    '1 plate',
    420,
    40,
    15,
    18,
    0
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    '1f1f1f1f-1f1f-1f1f-1f1f-1f1f1f1f1f1f',
    'Paneer paratha + curd',
    '2 paratha',
    550,
    22,
    65,
    22,
    0
  );
