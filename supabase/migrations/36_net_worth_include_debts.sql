-- ============================================================================
-- UPDATE NET WORTH TO INCLUDE DEBT TRACKER BALANCES
-- ============================================================================
-- Updates calculate_true_net_worth to subtract balances from the debts table
-- (in addition to existing credit card accounts), so that debt payoff entries
-- are automatically reflected as liabilities in the net worth tracker.
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_true_net_worth(p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_assets       DECIMAL;
  credit_card_debt   DECIMAL;
  tracked_debt       DECIMAL;
BEGIN
  -- Assets: all non-credit-card accounts
  SELECT COALESCE(SUM(balance), 0) INTO total_assets
  FROM accounts
  WHERE user_id = p_user_id
    AND is_active = TRUE
    AND type NOT IN ('credit_card');

  -- Credit card accounts (legacy path)
  SELECT COALESCE(SUM(balance), 0) INTO credit_card_debt
  FROM accounts
  WHERE user_id = p_user_id
    AND is_active = TRUE
    AND type = 'credit_card';

  -- Debts from the debt tracker (credit cards already tracked in accounts
  -- are intentionally NOT deduplicated here — users should not double-enter.
  -- Debts table represents manually-tracked liabilities separate from accounts.)
  SELECT COALESCE(SUM(balance), 0) INTO tracked_debt
  FROM debts
  WHERE user_id = p_user_id
    AND is_active = TRUE;

  -- Net Worth = Assets - Credit Card Accounts - Tracked Debts
  RETURN total_assets - credit_card_debt - tracked_debt;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION calculate_true_net_worth(UUID) TO authenticated;
