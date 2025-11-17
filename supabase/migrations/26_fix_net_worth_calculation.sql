-- ============================================================================
-- FIX NET WORTH CALCULATION
-- ============================================================================
-- This migration adds a proper net worth calculation function that:
-- 1. Sums all account balances (assets)
-- 2. Subtracts credit card balances (liabilities)
-- 3. Returns true net worth = Assets - Liabilities
-- ============================================================================

-- Function to calculate true net worth for a user
-- Net Worth = Sum of all assets (cash, checking, savings, investment) - credit card debt
CREATE OR REPLACE FUNCTION calculate_true_net_worth(p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_assets DECIMAL;
  credit_card_debt DECIMAL;
BEGIN
  -- Calculate total assets (exclude credit cards)
  SELECT COALESCE(SUM(balance), 0) INTO total_assets
  FROM accounts
  WHERE user_id = p_user_id
    AND is_active = TRUE
    AND type NOT IN ('credit_card');

  -- Calculate credit card debt (positive balance on credit card is debt)
  SELECT COALESCE(SUM(balance), 0) INTO credit_card_debt
  FROM accounts
  WHERE user_id = p_user_id
    AND is_active = TRUE
    AND type = 'credit_card';

  -- Net Worth = Assets - Credit Card Debt
  RETURN total_assets - credit_card_debt;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION calculate_true_net_worth(UUID) TO authenticated;

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
-- This replaces the previous incorrect calculation:
--   OLD: Net Worth = This Month's Income - This Month's Expenses (cash flow)
--   NEW: Net Worth = Sum of Assets - Credit Card Debt (actual worth)
--
-- To use:
--   SELECT calculate_true_net_worth('user-id-here');
--
-- Account types treated as assets: cash, checking, savings, investment, other
-- Account types treated as liabilities: credit_card
-- ============================================================================
