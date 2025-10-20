-- ============================================================================
-- EASY TEST DATA: Sample Recurring Transactions for Upcoming Bills
-- ============================================================================
-- This script automatically uses the current authenticated user's ID
-- and their first active account to insert sample recurring transactions.
--
-- HOW TO USE:
-- 1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql/new
-- 2. Make sure you're logged in as the user you want to test with
-- 3. Copy and paste this entire script
-- 4. Click "RUN"
-- 5. Refresh your FinMate dashboard to see the upcoming bills
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_account_id UUID;
  v_category_entertainment UUID;
  v_category_housing UUID;
  v_category_utilities UUID;
  v_category_personal_care UUID;
BEGIN
  -- Get the current authenticated user's ID
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No authenticated user found. Please make sure you are logged in to Supabase dashboard.';
  END IF;

  RAISE NOTICE 'Using user_id: %', v_user_id;

  -- Get the user's first active account
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE user_id = v_user_id AND is_active = true
  LIMIT 1;

  IF v_account_id IS NULL THEN
    RAISE EXCEPTION 'No active account found for user. Please create an account first in the app.';
  END IF;

  RAISE NOTICE 'Using account_id: %', v_account_id;

  -- Get category IDs (these are default categories that should exist)
  SELECT id INTO v_category_entertainment FROM categories WHERE name = 'Entertainment' AND (user_id = v_user_id OR is_default = true) LIMIT 1;
  SELECT id INTO v_category_housing FROM categories WHERE name = 'Housing' AND (user_id = v_user_id OR is_default = true) LIMIT 1;
  SELECT id INTO v_category_utilities FROM categories WHERE name = 'Bills & Utilities' AND (user_id = v_user_id OR is_default = true) LIMIT 1;
  SELECT id INTO v_category_personal_care FROM categories WHERE name = 'Personal Care' AND (user_id = v_user_id OR is_default = true) LIMIT 1;

  -- Insert sample recurring transactions

  -- 1. Netflix subscription - due in 5 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_entertainment, 'expense', 15.99,
    'Netflix Subscription', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '5 days', true
  );
  RAISE NOTICE 'Inserted: Netflix Subscription (due in 5 days)';

  -- 2. Rent payment - due in 10 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_housing, 'expense', 1200.00,
    'Monthly Rent', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '10 days', true
  );
  RAISE NOTICE 'Inserted: Monthly Rent (due in 10 days)';

  -- 3. Electric bill - due tomorrow
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_utilities, 'expense', 85.50,
    'Electric Bill', 'monthly', CURRENT_DATE - INTERVAL '1 month',
    CURRENT_DATE + INTERVAL '1 day', true
  );
  RAISE NOTICE 'Inserted: Electric Bill (due tomorrow)';

  -- 4. Internet bill - due in 15 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_utilities, 'expense', 60.00,
    'Internet Service', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '15 days', true
  );
  RAISE NOTICE 'Inserted: Internet Service (due in 15 days)';

  -- 5. Gym membership - due in 20 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_personal_care, 'expense', 45.00,
    'Gym Membership', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '20 days', true
  );
  RAISE NOTICE 'Inserted: Gym Membership (due in 20 days)';

  -- 6. Spotify subscription - due in 25 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_entertainment, 'expense', 9.99,
    'Spotify Premium', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '25 days', true
  );
  RAISE NOTICE 'Inserted: Spotify Premium (due in 25 days)';

  RAISE NOTICE '✓ Successfully inserted 6 recurring transactions!';
  RAISE NOTICE 'Refresh your FinMate dashboard to see the upcoming bills.';

END $$;

-- Verify the inserted data
-- This query will show you all your upcoming bills:
SELECT
  description,
  amount,
  next_occurrence,
  next_occurrence - CURRENT_DATE as days_until_due,
  frequency,
  is_active
FROM recurring_transactions
WHERE user_id = auth.uid()
  AND is_active = true
  AND next_occurrence >= CURRENT_DATE
  AND next_occurrence <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY next_occurrence;
