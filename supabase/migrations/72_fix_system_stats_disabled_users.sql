-- ============================================================================
-- FIX: get_system_stats() missing disabled_users and incorrect total_bill_groups
-- Migration 55 overwrote this function and dropped disabled_users
-- Rename total_bill_groups to total_debts (it counts debts, not bill groups)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE (
  total_users INTEGER,
  active_users INTEGER,
  new_users_this_month INTEGER,
  total_transactions INTEGER,
  total_income DECIMAL,
  total_expense DECIMAL,
  total_net_worth DECIMAL,
  total_accounts INTEGER,
  total_budgets INTEGER,
  total_debts INTEGER,
  disabled_users INTEGER
) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles) as total_users,
    (SELECT COUNT(DISTINCT user_id)::INTEGER
     FROM public.transactions
     WHERE date >= CURRENT_DATE - INTERVAL '30 days') as active_users,
    (SELECT COUNT(*)::INTEGER
     FROM public.user_profiles
     WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)) as new_users_this_month,
    (SELECT COUNT(*)::INTEGER FROM public.transactions) as total_transactions,
    (SELECT COALESCE(SUM(amount), 0)::DECIMAL
     FROM public.transactions
     WHERE type = 'income') as total_income,
    (SELECT COALESCE(SUM(amount), 0)::DECIMAL
     FROM public.transactions
     WHERE type = 'expense') as total_expense,
    (SELECT COALESCE(SUM(balance), 0)::DECIMAL FROM public.accounts) as total_net_worth,
    (SELECT COUNT(*)::INTEGER FROM public.accounts) as total_accounts,
    (SELECT COUNT(*)::INTEGER FROM public.budgets) as total_budgets,
    (SELECT COUNT(*)::INTEGER FROM public.debts) as total_debts,
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles WHERE is_active = false) as disabled_users;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
