-- Migration 58: Cleanup phantom carry-overs (corrected)
--
-- Migration 57's cleanup used created_at >= current month start, which missed
-- budgets created just before the month boundary.
--
-- This migration uses a safer approach: reset any budget whose current
-- carry-over amount equals the full budget amount AND has no actual expense
-- transactions in the previous period for that category. That combination
-- is the fingerprint of a phantom carry-over (prior period had $0 spending
-- only because no real data existed, not because the user genuinely spent $0).

UPDATE budgets b
   SET last_carry_over_amount = 0,
       last_period_end        = NULL,
       updated_at             = NOW()
 WHERE b.carry_over_enabled   = TRUE
   AND b.last_carry_over_amount != 0
   AND b.last_period_end = DATE_TRUNC('month', CURRENT_DATE)::DATE
   AND NOT EXISTS (
       SELECT 1
         FROM transactions t
        WHERE t.user_id     = b.user_id
          AND t.category_id = b.category_id
          AND t.type        = 'expense'
          AND t.date        >= (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE
          AND t.date        <  DATE_TRUNC('month', CURRENT_DATE)::DATE
   );
