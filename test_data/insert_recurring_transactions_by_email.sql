-- ============================================================================
-- EASY TEST DATA: Sample Recurring Transactions for Upcoming Bills
-- ============================================================================
-- This script uses your email address to find your user ID and insert
-- sample recurring transactions for testing.
--
-- HOW TO USE:
-- 1. Replace 'your-email@example.com' below with your actual email
-- 2. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql/new
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
  v_user_email TEXT := 'chah762002@yahoo.fr';  -- ⚠️ Your email address
BEGIN
  -- Get the user's ID from their email
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = v_user_email;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No user found with email: %. Please check the email address.', v_user_email;
  END IF;

  RAISE NOTICE 'Found user_id: % for email: %', v_user_id, v_user_email;

  -- Get the user's first active account
  SELECT id INTO v_account_id
  FROM public.accounts
  WHERE user_id = v_user_id AND is_active = true
  LIMIT 1;

  IF v_account_id IS NULL THEN
    RAISE EXCEPTION 'No active account found for user %. Please create an account first in the app.', v_user_email;
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
  RAISE NOTICE '✓ Inserted: Netflix Subscription (due in 5 days)';

  -- 2. Rent payment - due in 10 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_housing, 'expense', 1200.00,
    'Monthly Rent', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '10 days', true
  );
  RAISE NOTICE '✓ Inserted: Monthly Rent (due in 10 days)';

  -- 3. Electric bill - due tomorrow
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_utilities, 'expense', 85.50,
    'Electric Bill', 'monthly', CURRENT_DATE - INTERVAL '1 month',
    CURRENT_DATE + INTERVAL '1 day', true
  );
  RAISE NOTICE '✓ Inserted: Electric Bill (due tomorrow)';

  -- 4. Internet bill - due in 15 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_utilities, 'expense', 60.00,
    'Internet Service', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '15 days', true
  );
  RAISE NOTICE '✓ Inserted: Internet Service (due in 15 days)';

  -- 5. Gym membership - due in 20 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_personal_care, 'expense', 45.00,
    'Gym Membership', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '20 days', true
  );
  RAISE NOTICE '✓ Inserted: Gym Membership (due in 20 days)';

  -- 6. Spotify subscription - due in 25 days
  INSERT INTO public.recurring_transactions (
    user_id, account_id, category_id, type, amount, description,
    frequency, start_date, next_occurrence, is_active
  ) VALUES (
    v_user_id, v_account_id, v_category_entertainment, 'expense', 9.99,
    'Spotify Premium', 'monthly', CURRENT_DATE,
    CURRENT_DATE + INTERVAL '25 days', true
  );
  RAISE NOTICE '✓ Inserted: Spotify Premium (due in 25 days)';

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✓ Successfully inserted 6 recurring transactions!';
  RAISE NOTICE 'Refresh your FinMate dashboard to see the upcoming bills.';
  RAISE NOTICE '========================================';

END $$;

-- Verify the inserted data
-- This query will show you all your upcoming bills:
-- Replace 'your-email@example.com' with your actual email
SELECT
  description,
  amount,
  next_occurrence,
  next_occurrence - CURRENT_DATE as days_until_due,
  frequency,
  is_active
FROM recurring_transactions
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'chah762002@yahoo.fr')
  AND is_active = true
  AND next_occurrence >= CURRENT_DATE
  AND next_occurrence <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY next_occurrence;
