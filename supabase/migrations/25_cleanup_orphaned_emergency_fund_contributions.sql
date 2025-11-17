-- ============================================================================
-- MIGRATION: Clean up orphaned Emergency Fund contributions
-- ============================================================================
-- This migration removes goal_contributions entries where the linked
-- transaction has been deleted, and resets the goal's current_amount
-- ============================================================================

-- Step 1: Delete orphaned goal contributions (transaction_id points to deleted records)
DELETE FROM public.goal_contributions gc
WHERE gc.goal_id IN (
  SELECT id FROM public.savings_goals
  WHERE category = 'Emergency Fund'
)
AND gc.transaction_id IS NOT NULL
AND gc.transaction_id NOT IN (
  SELECT id FROM public.transactions
);

-- Step 2: Recalculate current_amount for all Emergency Fund goals
UPDATE public.savings_goals sg
SET current_amount = (
  SELECT COALESCE(SUM(gc.amount), 0)
  FROM public.goal_contributions gc
  WHERE gc.goal_id = sg.id
),
updated_at = NOW()
WHERE sg.category = 'Emergency Fund';

-- Step 3: Reset completion status if current_amount is below target
UPDATE public.savings_goals
SET is_completed = FALSE,
    completed_at = NULL,
    updated_at = NOW()
WHERE category = 'Emergency Fund'
AND current_amount < target_amount
AND is_completed = TRUE;

-- ============================================================================
-- MIGRATION COMPLETE
-- Orphaned contributions removed and balances recalculated
-- ============================================================================
