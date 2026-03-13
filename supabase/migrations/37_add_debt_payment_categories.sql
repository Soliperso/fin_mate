-- Add default expense categories matching each debt type in the Debt Payoff feature
INSERT INTO public.categories (id, user_id, name, type, icon, color, is_default)
VALUES
  ('11111111-1111-1111-1111-111111111212'::UUID, NULL, 'Credit Card Payment', 'expense', '💳', '#E74C3C', TRUE),
  ('11111111-1111-1111-1111-111111111213'::UUID, NULL, 'Personal Loan Payment', 'expense', '🏦', '#E67E22', TRUE),
  ('11111111-1111-1111-1111-111111111214'::UUID, NULL, 'Student Loan Payment', 'expense', '🎓', '#34495E', TRUE),
  ('11111111-1111-1111-1111-111111111215'::UUID, NULL, 'Auto Loan Payment',    'expense', '🚗', '#E67E22', TRUE),
  ('11111111-1111-1111-1111-111111111216'::UUID, NULL, 'Mortgage Payment',     'expense', '🏡', '#95A5A6', TRUE),
  ('11111111-1111-1111-1111-111111111217'::UUID, NULL, 'Medical Debt Payment', 'expense', '🏥', '#1ABC9C', TRUE)
ON CONFLICT (id) DO NOTHING;
