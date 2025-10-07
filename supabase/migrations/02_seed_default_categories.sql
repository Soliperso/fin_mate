-- ============================================================================
-- SEED DEFAULT CATEGORIES
-- ============================================================================

-- Default Income Categories
INSERT INTO public.categories (id, user_id, name, type, icon, color, is_default)
VALUES
  ('11111111-1111-1111-1111-111111111101'::UUID, NULL, 'Salary', 'income', '💼', '#2ECC71', TRUE),
  ('11111111-1111-1111-1111-111111111102'::UUID, NULL, 'Freelance', 'income', '💻', '#27AE60', TRUE),
  ('11111111-1111-1111-1111-111111111103'::UUID, NULL, 'Investment', 'income', '📈', '#16A085', TRUE),
  ('11111111-1111-1111-1111-111111111104'::UUID, NULL, 'Gift', 'income', '🎁', '#1ABC9C', TRUE),
  ('11111111-1111-1111-1111-111111111105'::UUID, NULL, 'Other Income', 'income', '💰', '#2ECC71', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Default Expense Categories
INSERT INTO public.categories (id, user_id, name, type, icon, color, is_default)
VALUES
  ('11111111-1111-1111-1111-111111111201'::UUID, NULL, 'Food & Dining', 'expense', '🍔', '#E74C3C', TRUE),
  ('11111111-1111-1111-1111-111111111202'::UUID, NULL, 'Transportation', 'expense', '🚗', '#E67E22', TRUE),
  ('11111111-1111-1111-1111-111111111203'::UUID, NULL, 'Shopping', 'expense', '🛍️', '#F39C12', TRUE),
  ('11111111-1111-1111-1111-111111111204'::UUID, NULL, 'Entertainment', 'expense', '🎬', '#9B59B6', TRUE),
  ('11111111-1111-1111-1111-111111111205'::UUID, NULL, 'Bills & Utilities', 'expense', '💡', '#3498DB', TRUE),
  ('11111111-1111-1111-1111-111111111206'::UUID, NULL, 'Healthcare', 'expense', '⚕️', '#1ABC9C', TRUE),
  ('11111111-1111-1111-1111-111111111207'::UUID, NULL, 'Education', 'expense', '📚', '#34495E', TRUE),
  ('11111111-1111-1111-1111-111111111208'::UUID, NULL, 'Housing', 'expense', '🏠', '#95A5A6', TRUE),
  ('11111111-1111-1111-1111-111111111209'::UUID, NULL, 'Personal Care', 'expense', '💅', '#E91E63', TRUE),
  ('11111111-1111-1111-1111-111111111210'::UUID, NULL, 'Other Expense', 'expense', '💸', '#C0392B', TRUE)
ON CONFLICT (id) DO NOTHING;
