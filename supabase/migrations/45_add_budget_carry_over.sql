-- Migration 45: Budget Carry-Over
-- Adds carry-over support so unspent/overspent budget rolls into the next period

ALTER TABLE budgets
    ADD COLUMN IF NOT EXISTS carry_over_enabled BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS last_carry_over_amount DECIMAL(15,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_period_end DATE;

-- Detects period rollovers and updates last_carry_over_amount for eligible budgets
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

        -- Only process if we haven't already handled this period
        IF v_budget.last_period_end IS NULL OR v_budget.last_period_end < v_period_start THEN
            -- Sum spending in prior period for this budget's category
            SELECT COALESCE(SUM(amount), 0) INTO v_spent
            FROM transactions
            WHERE user_id = v_budget.user_id
              AND category_id = v_budget.category_id
              AND type = 'expense'
              AND date >= v_prev_start
              AND date <= v_prev_end;

            -- carry = prior_budget - prior_spent (positive = surplus, negative = deficit)
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
