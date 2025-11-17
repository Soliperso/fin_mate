-- ============================================================================
-- MIGRATION: Link existing Emergency Fund transactions to Savings Goals
-- ============================================================================
-- This migration fixes the disconnect between EmergencyFundPage contributions
-- and the SavingsGoals feature. It:
-- 1. Creates Emergency Fund savings goals for users who don't have one
-- 2. Links existing Emergency Fund Contribution transactions to the goal
-- ============================================================================

-- Step 1: Create Emergency Fund savings goals for users who have contributed
--         but don't have a goal yet
INSERT INTO public.savings_goals (
  user_id,
  name,
  description,
  target_amount,
  current_amount,
  category,
  is_completed,
  created_at,
  updated_at
)
SELECT DISTINCT
  t.user_id,
  'Emergency Fund',
  'Emergency fund for unexpected expenses',
  6000.00, -- Default 6-month target
  0.00, -- Will be updated by trigger
  'Emergency Fund',
  FALSE,
  NOW(),
  NOW()
FROM public.transactions t
WHERE t.description = 'Emergency Fund Contribution'
  AND t.user_id NOT IN (
    SELECT user_id FROM public.savings_goals
    WHERE category = 'Emergency Fund'
  )
ON CONFLICT DO NOTHING;

-- Step 2: Create goal contributions for each Emergency Fund Contribution transaction
-- that doesn't already have a corresponding goal_contribution
INSERT INTO public.goal_contributions (
  goal_id,
  transaction_id,
  amount,
  notes,
  contributed_at,
  created_at
)
SELECT
  sg.id,
  t.id,
  t.amount,
  'Migrated from transaction history',
  t.date::DATE,
  NOW()
FROM public.transactions t
INNER JOIN public.savings_goals sg ON (
  t.user_id = sg.user_id
  AND sg.category = 'Emergency Fund'
)
WHERE t.description = 'Emergency Fund Contribution'
  AND t.type = 'income'
  AND NOT EXISTS (
    SELECT 1 FROM public.goal_contributions gc
    WHERE gc.transaction_id = t.id
  )
ON CONFLICT DO NOTHING;

-- Step 3: Refresh the current_amount for Emergency Fund goals
-- This is handled by the trigger, but we can manually update to be safe
UPDATE public.savings_goals sg
SET current_amount = (
  SELECT COALESCE(SUM(gc.amount), 0)
  FROM public.goal_contributions gc
  WHERE gc.goal_id = sg.id
)
WHERE sg.category = 'Emergency Fund';

-- ============================================================================
-- MIGRATION COMPLETE
-- All Emergency Fund Contribution transactions are now linked to savings goals
-- ============================================================================
