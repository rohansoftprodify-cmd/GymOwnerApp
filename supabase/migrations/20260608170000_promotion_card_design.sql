-- Custom offer card visuals: colors, copy, and draggable text positions.

alter table public.promotions
  add column if not exists card_design jsonb;

comment on column public.promotions.card_design is
  'Offer card theme: template_id, colors, badge/button text, element positions (0-1 normalized).';
