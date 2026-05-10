-- Add a default "Savings" expense category used when linking a transaction to a savings goal.
INSERT INTO public.categories (id, user_id, name, type, icon, color, is_default)
VALUES (
  '11111111-1111-1111-1111-111111111106'::UUID,
  NULL,
  'Savings',
  'expense',
  '🏦',
  '#20808D',
  TRUE
)
ON CONFLICT (id) DO UPDATE SET type = 'expense';
