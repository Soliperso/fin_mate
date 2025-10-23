-- ============================================================================
-- FIX ACCOUNT BALANCE CALCULATION FROM TRANSACTIONS
-- ============================================================================
-- This migration adds a function to recalculate account balances from
-- transactions and ensures account balances are accurate.
-- ============================================================================

-- Function to recalculate account balance from all its transactions
CREATE OR REPLACE FUNCTION recalculate_account_balance(p_account_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  new_balance DECIMAL;
BEGIN
  -- Calculate balance from transactions
  -- Income adds to balance, expenses subtract
  SELECT COALESCE(SUM(
    CASE
      WHEN type = 'income' THEN amount
      WHEN type = 'expense' THEN -amount
      WHEN type = 'transfer' AND account_id = p_account_id THEN -amount
      WHEN type = 'transfer' AND to_account_id = p_account_id THEN amount
      ELSE 0
    END
  ), 0) INTO new_balance
  FROM transactions
  WHERE (account_id = p_account_id OR to_account_id = p_account_id)
    AND deleted_at IS NULL;

  -- Update the account with the calculated balance
  UPDATE accounts
  SET balance = new_balance
  WHERE id = p_account_id;

  RETURN new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to recalculate all account balances for a user
CREATE OR REPLACE FUNCTION recalculate_user_account_balances(p_user_id UUID)
RETURNS TABLE(account_id UUID, account_name TEXT, new_balance DECIMAL) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.name,
    recalculate_account_balance(a.id)
  FROM accounts a
  WHERE a.user_id = p_user_id
    AND a.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION recalculate_account_balance(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_user_account_balances(UUID) TO authenticated;

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
-- To use these functions:
--
-- 1. Recalculate a single account balance:
--    SELECT recalculate_account_balance('account-id-here');
--
-- 2. Recalculate all accounts for a user:
--    SELECT * FROM recalculate_user_account_balances('user-id-here');
--
-- This ensures account balances are calculated correctly from transactions:
-- - Income transactions ADD to balance
-- - Expense transactions SUBTRACT from balance
-- - Transfer transactions move money between accounts
-- ============================================================================
