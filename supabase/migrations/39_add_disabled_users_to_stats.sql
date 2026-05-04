-- Migration 39: Add disabled_users count to get_system_stats
-- disabled_users = user_profiles WHERE is_active = false (admin-disabled accounts)
-- This is distinct from active_users which counts transaction activity in last 30 days.

DROP FUNCTION IF EXISTS get_system_stats();

CREATE FUNCTION get_system_stats()
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
  total_bill_groups INTEGER,
  disabled_users INTEGER
) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles) AS total_users,
    (SELECT COUNT(DISTINCT user_id)::INTEGER
     FROM public.transactions
     WHERE date >= CURRENT_DATE - INTERVAL '30 days') AS active_users,
    (SELECT COUNT(*)::INTEGER
     FROM public.user_profiles
     WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)) AS new_users_this_month,
    (SELECT COUNT(*)::INTEGER FROM public.transactions) AS total_transactions,
    (SELECT COALESCE(SUM(amount), 0)::DECIMAL
     FROM public.transactions WHERE type = 'income') AS total_income,
    (SELECT COALESCE(SUM(amount), 0)::DECIMAL
     FROM public.transactions WHERE type = 'expense') AS total_expense,
    (SELECT COALESCE(SUM(balance), 0)::DECIMAL FROM public.accounts) AS total_net_worth,
    (SELECT COUNT(*)::INTEGER FROM public.accounts) AS total_accounts,
    (SELECT COUNT(*)::INTEGER FROM public.budgets) AS total_budgets,
    (SELECT COUNT(*)::INTEGER FROM public.debts) AS total_bill_groups,
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles WHERE is_active = false) AS disabled_users;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
