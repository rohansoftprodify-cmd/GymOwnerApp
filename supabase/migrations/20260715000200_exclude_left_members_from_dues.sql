-- Exclude left members from dues calculations in report_dues_summary view.

create or replace view public.report_dues_summary as
select
  ms.gym_id,
  count(*) filter (where ms.payment_status = 'due' and m.status != 'left') as due_count,
  count(*) filter (where ms.payment_status = 'partial' and m.status != 'left') as partial_count,
  count(*) filter (where ms.payment_status = 'paid' and m.status != 'left') as paid_count,
  coalesce(sum(case when ms.payment_status in ('due', 'partial') and m.status != 'left' then greatest(sp.price - ms.amount_paid, 0) else 0 end), 0) as pending_amount
from public.member_subscriptions ms
join public.subscription_plans sp on sp.id = ms.plan_id
join public.members m on m.id = ms.member_id
group by ms.gym_id;
