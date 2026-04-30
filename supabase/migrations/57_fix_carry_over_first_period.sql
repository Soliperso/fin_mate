-- Migration 57: Fix carry-over phantom rollover on first period
--
-- Bug: apply_budget_carry_overs() treated last_period_end IS NULL as a valid
-- rollover trigger, computing carry = budget.amount - 0 (no prior spending)
-- even when the budget was brand-new with no previous period at all.
-- This wrote a phantom last_carry_over_amount equal to the full budget amount.
--
-- Fix: when last_period_end IS NULL, just initialise the record (carry = 0).
-- Only calculate an actual carry-over when a real prior period exists.

CREATE OR REPLACE FUNCTION apply_budget_carry_overs()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_budget      RECORD;
    v_period_start DATE;
    v_prev_start   DATE;
    v_prev_end     DATE;
    v_spent        DECIMAL(15,2);
    v_count        INT := 0;
BEGIN
    FOR v_budget IN
        SELECT * FROM budgets
        WHERE is_active = TRUE AND carry_over_enabled = TRUE
    LOOP
        CASE v_budget.period
            WHEN 'weekly' THEN
                v_period_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
                v_prev_start   := v_period_start - INTERVAL '7 days';
                v_prev_end     := v_period_start - INTERVAL '1 day';
            WHEN 'monthly' THEN
                v_period_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
                v_prev_start   := (v_period_start - INTERVAL '1 month')::DATE;
                v_prev_end     := (v_period_start - INTERVAL '1 day')::DATE;
            WHEN 'yearly' THEN
                v_period_start := DATE_TRUNC('year', CURRENT_DATE)::DATE;
                v_prev_start   := (v_period_start - INTERVAL '1 year')::DATE;
                v_prev_end     := (v_period_start - INTERVAL '1 day')::DATE;
            ELSE
                CONTINUE;
        END CASE;

        IF v_budget.last_period_end IS NULL THEN
            -- Brand-new budget: no prior period ever existed.
            -- Just mark the current period as initialised; carry-over is zero.
            UPDATE budgets
               SET last_carry_over_amount = 0,
                   last_period_end        = v_period_start,
                   updated_at             = NOW()
             WHERE id = v_budget.id;

            v_count := v_count + 1;

        ELSIF v_budget.last_period_end < v_period_start THEN
            -- A real prior period exists and has ended — compute actual carry-over.
            SELECT COALESCE(SUM(amount), 0) INTO v_spent
            FROM transactions
            WHERE user_id    = v_budget.user_id
              AND category_id = v_budget.category_id
              AND type        = 'expense'
              AND date        >= v_prev_start
              AND date        <= v_prev_end;

            UPDATE budgets
               SET last_carry_over_amount = v_budget.amount - v_spent,
                   last_period_end        = v_period_start,
                   updated_at             = NOW()
             WHERE id = v_budget.id;

            v_count := v_count + 1;
        END IF;
    END LOOP;
    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION apply_budget_carry_overs() TO authenticated;

-- Clean up phantom carry-overs already written to the DB.
-- A phantom carry-over is one where:
--   • the budget was created in the current period (never had a prior period), AND
--   • last_period_end was set to the current period start (written by the old buggy code).
-- Reset these to zero so the next load shows the correct base amount.
UPDATE budgets
   SET last_carry_over_amount = 0,
       last_period_end        = NULL,
       updated_at             = NOW()
 WHERE carry_over_enabled = TRUE
   AND last_carry_over_amount != 0
   AND last_period_end = DATE_TRUNC('month', CURRENT_DATE)::DATE
   AND created_at      >= DATE_TRUNC('month', CURRENT_DATE);
