-- ============================================================================
-- TEST DATA: Sample Recurring Transactions for Upcoming Bills
-- ============================================================================
-- This script inserts sample recurring transactions to test the "Upcoming Bills"
-- section in the dashboard. Replace 'YOUR_USER_ID' with your actual user ID
-- and 'YOUR_ACCOUNT_ID' with one of your account IDs.
--
-- To get your user ID and account ID, run these queries in Supabase SQL Editor:
-- 1. SELECT id FROM auth.users WHERE email = 'your-email@example.com';
-- 2. SELECT id FROM accounts WHERE user_id = 'YOUR_USER_ID' LIMIT 1;
-- ============================================================================

-- IMPORTANT: Replace these values before running!
-- Get your user_id: SELECT id FROM auth.users WHERE email = 'your-email@example.com';
-- Get your account_id: SELECT id FROM accounts WHERE user_id = 'YOUR_USER_ID' LIMIT 1;

-- Example bills to test upcoming bills display
-- NOTE: Replace the UUIDs below with your actual user_id and account_id

-- Example 1: Netflix subscription - due in 5 days
INSERT INTO public.recurring_transactions (
  user_id,
  account_id,
  category_id,
  type,
  amount,
  description,
  frequency,
  start_date,
  next_occurrence,
  is_active
) VALUES (
  'YOUR_USER_ID',  -- Replace with your user ID
  'YOUR_ACCOUNT_ID',  -- Replace with your account ID
  (SELECT id FROM categories WHERE name = 'Entertainment' AND user_id = 'YOUR_USER_ID' LIMIT 1),
  'expense',
  15.99,
  'Netflix Subscription',
  'monthly',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '5 days',
  true
);

-- Example 2: Rent payment - due in 10 days
INSERT INTO public.recurring_transactions (
  user_id,
  account_id,
  category_id,
  type,
  amount,
  description,
  frequency,
  start_date,
  next_occurrence,
  is_active
) VALUES (
  'YOUR_USER_ID',  -- Replace with your user ID
  'YOUR_ACCOUNT_ID',  -- Replace with your account ID
  (SELECT id FROM categories WHERE name = 'Housing' AND user_id = 'YOUR_USER_ID' LIMIT 1),
  'expense',
  1200.00,
  'Monthly Rent',
  'monthly',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '10 days',
  true
);

-- Example 3: Electric bill - due tomorrow
INSERT INTO public.recurring_transactions (
  user_id,
  account_id,
  category_id,
  type,
  amount,
  description,
  frequency,
  start_date,
  next_occurrence,
  is_active
) VALUES (
  'YOUR_USER_ID',  -- Replace with your user ID
  'YOUR_ACCOUNT_ID',  -- Replace with your account ID
  (SELECT id FROM categories WHERE name = 'Bills & Utilities' AND user_id = 'YOUR_USER_ID' LIMIT 1),
  'expense',
  85.50,
  'Electric Bill',
  'monthly',
  CURRENT_DATE - INTERVAL '1 month',
  CURRENT_DATE + INTERVAL '1 day',
  true
);

-- Example 4: Internet bill - due in 15 days
INSERT INTO public.recurring_transactions (
  user_id,
  account_id,
  category_id,
  type,
  amount,
  description,
  frequency,
  start_date,
  next_occurrence,
  is_active
) VALUES (
  'YOUR_USER_ID',  -- Replace with your user ID
  'YOUR_ACCOUNT_ID',  -- Replace with your account ID
  (SELECT id FROM categories WHERE name = 'Bills & Utilities' AND user_id = 'YOUR_USER_ID' LIMIT 1),
  'expense',
  60.00,
  'Internet Service',
  'monthly',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '15 days',
  true
);

-- Example 5: Gym membership - due in 20 days
INSERT INTO public.recurring_transactions (
  user_id,
  account_id,
  category_id,
  type,
  amount,
  description,
  frequency,
  start_date,
  next_occurrence,
  is_active
) VALUES (
  'YOUR_USER_ID',  -- Replace with your user ID
  'YOUR_ACCOUNT_ID',  -- Replace with your account ID
  (SELECT id FROM categories WHERE name = 'Personal Care' AND user_id = 'YOUR_USER_ID' LIMIT 1),
  'expense',
  45.00,
  'Gym Membership',
  'monthly',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '20 days',
  true
);

-- Verify the inserted data
-- Run this query to see your upcoming bills:
-- SELECT
--   id,
--   description,
--   amount,
--   next_occurrence,
--   frequency,
--   is_active
-- FROM recurring_transactions
-- WHERE user_id = 'YOUR_USER_ID'
--   AND is_active = true
--   AND next_occurrence >= CURRENT_DATE
--   AND next_occurrence <= CURRENT_DATE + INTERVAL '30 days'
-- ORDER BY next_occurrence;
