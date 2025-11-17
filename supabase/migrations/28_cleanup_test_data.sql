-- ============================================================================
-- MIGRATION: Clean up test data and fix orphaned contributions
-- ============================================================================
-- This migration:
-- 1. Adds a trigger to auto-delete orphaned goal contributions
-- 2. Can optionally clean up all your test data
--
-- To apply: supabase db push
-- ============================================================================

-- ============================================================================
-- STEP 1: Add cleanup trigger for orphaned contributions
-- ============================================================================
-- This prevents the $500 emergency fund bug in the future

CREATE OR REPLACE FUNCTION cleanup_orphaned_contributions()
RETURNS TRIGGER AS $$
BEGIN
  -- When a transaction is deleted, also delete its associated goal contributions
  DELETE FROM public.goal_contributions
  WHERE transaction_id = OLD.id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_transaction_deleted ON public.transactions;
CREATE TRIGGER on_transaction_deleted
  BEFORE DELETE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION cleanup_orphaned_contributions();

-- ============================================================================
-- STEP 2: Clean up all test data for current user (optional)
-- ============================================================================
-- Uncomment the code below if you want to reset all data to zero
-- Then run: supabase db push
--
-- DO $$
-- DECLARE
--   user_id UUID;
-- BEGIN
--   -- Get the current authenticated user
--   user_id := auth.uid();
--
--   IF user_id IS NULL THEN
--     RAISE EXCEPTION 'No authenticated user found. Please ensure you are logged in.';
--   END IF;
--
--   -- Delete all goal contributions (cascades and updates goal amounts)
--   DELETE FROM public.goal_contributions
--   WHERE goal_id IN (
--     SELECT id FROM public.savings_goals WHERE user_id = user_id
--   );
--
--   -- Delete all savings goals
--   DELETE FROM public.savings_goals WHERE user_id = user_id;
--
--   -- Delete all transactions (automatically updates account balances via trigger)
--   DELETE FROM public.transactions WHERE user_id = user_id;
--
--   -- Delete all recurring transactions
--   DELETE FROM public.recurring_transactions WHERE user_id = user_id;
--
--   -- Delete all budgets
--   DELETE FROM public.budgets WHERE user_id = user_id;
--
--   -- Delete all accounts except the default Cash account
--   DELETE FROM public.accounts WHERE user_id = user_id AND type != 'cash';
--
--   -- Reset cash account balance to 0
--   UPDATE public.accounts
--   SET balance = 0
--   WHERE user_id = user_id AND type = 'cash';
--
--   RAISE NOTICE 'Data cleanup complete for user: %', user_id;
-- END $$;
