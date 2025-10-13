-- ============================================================================
-- ADVANCED ANALYTICS FUNCTIONS FOR ADMIN
-- ============================================================================
-- This migration adds enhanced analytics functions for the admin dashboard
-- including trends, cohorts, engagement metrics, and breakdowns
-- ============================================================================

-- ============================================================================
-- FUNCTION: Get user growth trends
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_growth_trends(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_granularity TEXT DEFAULT 'day' -- 'day', 'week', 'month'
)
RETURNS TABLE (
  period_start TIMESTAMPTZ,
  new_users INTEGER,
  cumulative_users INTEGER
) AS $$
DECLARE
  date_trunc_param TEXT;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  -- Validate granularity
  IF p_granularity NOT IN ('day', 'week', 'month') THEN
    RAISE EXCEPTION 'Invalid granularity. Must be day, week, or month.';
  END IF;

  date_trunc_param := p_granularity;

  RETURN QUERY
  WITH date_series AS (
    SELECT DATE_TRUNC(date_trunc_param, d)::TIMESTAMPTZ as period
    FROM GENERATE_SERIES(
      DATE_TRUNC(date_trunc_param, p_start_date::TIMESTAMP),
      DATE_TRUNC(date_trunc_param, p_end_date::TIMESTAMP),
      ('1 ' || date_trunc_param)::INTERVAL
    ) as d
  ),
  user_signups AS (
    SELECT
      DATE_TRUNC(date_trunc_param, created_at)::TIMESTAMPTZ as signup_period,
      COUNT(*)::INTEGER as new_count
    FROM public.user_profiles
    WHERE created_at >= p_start_date AND created_at <= p_end_date + INTERVAL '1 day'
    GROUP BY signup_period
  )
  SELECT
    ds.period as period_start,
    COALESCE(us.new_count, 0) as new_users,
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles WHERE created_at <= ds.period) as cumulative_users
  FROM date_series ds
  LEFT JOIN user_signups us ON ds.period = us.signup_period
  ORDER BY ds.period;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get financial trends over time
-- ============================================================================

CREATE OR REPLACE FUNCTION get_financial_trends(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_granularity TEXT DEFAULT 'day'
)
RETURNS TABLE (
  period_start TIMESTAMPTZ,
  total_income DECIMAL,
  total_expense DECIMAL,
  net_cashflow DECIMAL,
  transaction_count INTEGER,
  average_transaction_amount DECIMAL
) AS $$
DECLARE
  date_trunc_param TEXT;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  -- Validate granularity
  IF p_granularity NOT IN ('day', 'week', 'month') THEN
    RAISE EXCEPTION 'Invalid granularity. Must be day, week, or month.';
  END IF;

  date_trunc_param := p_granularity;

  RETURN QUERY
  WITH date_series AS (
    SELECT DATE_TRUNC(date_trunc_param, d)::TIMESTAMPTZ as period
    FROM GENERATE_SERIES(
      DATE_TRUNC(date_trunc_param, p_start_date::TIMESTAMP),
      DATE_TRUNC(date_trunc_param, p_end_date::TIMESTAMP),
      ('1 ' || date_trunc_param)::INTERVAL
    ) as d
  ),
  transaction_stats AS (
    SELECT
      DATE_TRUNC(date_trunc_param, date)::TIMESTAMPTZ as transaction_period,
      COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0)::DECIMAL as income,
      COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)::DECIMAL as expense,
      COUNT(*)::INTEGER as tx_count,
      COALESCE(AVG(amount), 0)::DECIMAL as avg_amount
    FROM public.transactions
    WHERE date >= p_start_date AND date <= p_end_date
    GROUP BY transaction_period
  )
  SELECT
    ds.period as period_start,
    COALESCE(ts.income, 0)::DECIMAL as total_income,
    COALESCE(ts.expense, 0)::DECIMAL as total_expense,
    COALESCE(ts.income - ts.expense, 0)::DECIMAL as net_cashflow,
    COALESCE(ts.tx_count, 0) as transaction_count,
    COALESCE(ts.avg_amount, 0)::DECIMAL as average_transaction_amount
  FROM date_series ds
  LEFT JOIN transaction_stats ts ON ds.period = ts.transaction_period
  ORDER BY ds.period;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get feature adoption statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_feature_adoption_stats()
RETURNS TABLE (
  feature_name TEXT,
  users_using_feature INTEGER,
  total_users INTEGER,
  adoption_percentage DECIMAL,
  total_items INTEGER
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  WITH total_user_count AS (
    SELECT COUNT(*)::INTEGER as total FROM public.user_profiles
  )
  SELECT
    'Budgets'::TEXT as feature_name,
    (SELECT COUNT(DISTINCT user_id)::INTEGER FROM public.budgets) as users_using_feature,
    (SELECT total FROM total_user_count) as total_users,
    ((SELECT COUNT(DISTINCT user_id)::DECIMAL FROM public.budgets) / NULLIF((SELECT total FROM total_user_count), 0) * 100)::DECIMAL as adoption_percentage,
    (SELECT COUNT(*)::INTEGER FROM public.budgets) as total_items

  UNION ALL

  SELECT
    'Bill Splitting'::TEXT,
    (SELECT COUNT(DISTINCT user_id)::INTEGER FROM public.group_members) as users_using_feature,
    (SELECT total FROM total_user_count),
    ((SELECT COUNT(DISTINCT user_id)::DECIMAL FROM public.group_members) / NULLIF((SELECT total FROM total_user_count), 0) * 100)::DECIMAL,
    (SELECT COUNT(*)::INTEGER FROM public.bill_groups) as total_items

  UNION ALL

  SELECT
    'Savings Goals'::TEXT,
    (SELECT COUNT(DISTINCT user_id)::INTEGER FROM public.savings_goals) as users_using_feature,
    (SELECT total FROM total_user_count),
    ((SELECT COUNT(DISTINCT user_id)::DECIMAL FROM public.savings_goals) / NULLIF((SELECT total FROM total_user_count), 0) * 100)::DECIMAL,
    (SELECT COUNT(*)::INTEGER FROM public.savings_goals) as total_items

  UNION ALL

  SELECT
    'Multiple Accounts'::TEXT,
    (SELECT COUNT(DISTINCT user_id)::INTEGER FROM (
      SELECT user_id FROM public.accounts GROUP BY user_id HAVING COUNT(*) > 1
    ) sub) as users_using_feature,
    (SELECT total FROM total_user_count),
    ((SELECT COUNT(DISTINCT user_id)::DECIMAL FROM (
      SELECT user_id FROM public.accounts GROUP BY user_id HAVING COUNT(*) > 1
    ) sub) / NULLIF((SELECT total FROM total_user_count), 0) * 100)::DECIMAL,
    (SELECT COUNT(*)::INTEGER FROM public.accounts) as total_items

  UNION ALL

  SELECT
    'MFA Enabled'::TEXT,
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles WHERE mfa_enabled = TRUE) as users_using_feature,
    (SELECT total FROM total_user_count),
    ((SELECT COUNT(*)::DECIMAL FROM public.user_profiles WHERE mfa_enabled = TRUE) / NULLIF((SELECT total FROM total_user_count), 0) * 100)::DECIMAL,
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles WHERE mfa_enabled = TRUE) as total_items;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get spending breakdown by category
-- ============================================================================

CREATE OR REPLACE FUNCTION get_category_breakdown(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  category_id UUID,
  category_name TEXT,
  category_type TEXT,
  total_amount DECIMAL,
  transaction_count INTEGER,
  percentage_of_total DECIMAL
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  WITH expense_totals AS (
    SELECT
      c.id as cat_id,
      c.name as cat_name,
      c.type as cat_type,
      COALESCE(SUM(t.amount), 0)::DECIMAL as amount,
      COUNT(t.id)::INTEGER as tx_count
    FROM public.categories c
    LEFT JOIN public.transactions t ON t.category_id = c.id
      AND t.type = 'expense'
      AND t.date >= p_start_date
      AND t.date <= p_end_date
    GROUP BY c.id, c.name, c.type
  ),
  grand_total AS (
    SELECT COALESCE(SUM(amount), 0)::DECIMAL as total FROM expense_totals WHERE amount > 0
  )
  SELECT
    et.cat_id,
    et.cat_name,
    et.cat_type,
    et.amount,
    et.tx_count,
    CASE
      WHEN (SELECT total FROM grand_total) > 0
      THEN (et.amount / (SELECT total FROM grand_total) * 100)::DECIMAL
      ELSE 0::DECIMAL
    END as percentage_of_total
  FROM expense_totals et
  WHERE et.amount > 0
  ORDER BY et.amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get user engagement metrics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_engagement_metrics(
  p_period_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  metric_name TEXT,
  metric_value DECIMAL,
  metric_description TEXT
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  SELECT
    'Daily Active Users (Avg)'::TEXT as metric_name,
    (
      SELECT COALESCE(AVG(daily_users), 0)::DECIMAL
      FROM (
        SELECT DATE(date) as day, COUNT(DISTINCT user_id) as daily_users
        FROM public.transactions
        WHERE date >= CURRENT_DATE - p_period_days
        GROUP BY DATE(date)
      ) daily_stats
    ) as metric_value,
    'Average number of unique users per day'::TEXT as metric_description

  UNION ALL

  SELECT
    'Transactions Per Active User'::TEXT,
    (
      SELECT CASE
        WHEN COUNT(DISTINCT user_id) > 0
        THEN (COUNT(*)::DECIMAL / COUNT(DISTINCT user_id))
        ELSE 0
      END
      FROM public.transactions
      WHERE date >= CURRENT_DATE - p_period_days
    ) as metric_value,
    'Average transactions per active user'::TEXT

  UNION ALL

  SELECT
    'Average Transaction Value'::TEXT,
    (
      SELECT COALESCE(AVG(amount), 0)::DECIMAL
      FROM public.transactions
      WHERE date >= CURRENT_DATE - p_period_days
    ),
    'Average amount per transaction'::TEXT

  UNION ALL

  SELECT
    'User Retention Rate'::TEXT,
    (
      SELECT CASE
        WHEN COUNT(DISTINCT t1.user_id) > 0
        THEN (COUNT(DISTINCT t2.user_id)::DECIMAL / COUNT(DISTINCT t1.user_id) * 100)
        ELSE 0
      END
      FROM (
        SELECT DISTINCT user_id FROM public.transactions
        WHERE date >= CURRENT_DATE - p_period_days AND date < CURRENT_DATE - (p_period_days / 2)
      ) t1
      LEFT JOIN (
        SELECT DISTINCT user_id FROM public.transactions
        WHERE date >= CURRENT_DATE - (p_period_days / 2)
      ) t2 ON t1.user_id = t2.user_id
    ),
    'Percentage of users from first half still active in second half'::TEXT

  UNION ALL

  SELECT
    'Bill Settlement Rate'::TEXT,
    (
      SELECT CASE
        WHEN COUNT(*) > 0
        THEN (COUNT(CASE WHEN is_settled THEN 1 END)::DECIMAL / COUNT(*) * 100)
        ELSE 0
      END
      FROM public.expense_splits
    ),
    'Percentage of expense splits that have been settled'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get net worth distribution percentiles
-- ============================================================================

CREATE OR REPLACE FUNCTION get_net_worth_percentiles()
RETURNS TABLE (
  percentile TEXT,
  net_worth_value DECIMAL,
  user_count INTEGER
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  WITH user_net_worth AS (
    SELECT
      up.id as user_id,
      COALESCE(SUM(a.balance), 0)::DECIMAL as net_worth
    FROM public.user_profiles up
    LEFT JOIN public.accounts a ON a.user_id = up.id
    GROUP BY up.id
  )
  SELECT
    'P10'::TEXT as percentile,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY net_worth)::DECIMAL as net_worth_value,
    COUNT(*)::INTEGER as user_count
  FROM user_net_worth

  UNION ALL

  SELECT
    'P25'::TEXT,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY net_worth)::DECIMAL,
    COUNT(*)::INTEGER
  FROM user_net_worth

  UNION ALL

  SELECT
    'P50 (Median)'::TEXT,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY net_worth)::DECIMAL,
    COUNT(*)::INTEGER
  FROM user_net_worth

  UNION ALL

  SELECT
    'P75'::TEXT,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY net_worth)::DECIMAL,
    COUNT(*)::INTEGER
  FROM user_net_worth

  UNION ALL

  SELECT
    'P90'::TEXT,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY net_worth)::DECIMAL,
    COUNT(*)::INTEGER
  FROM user_net_worth

  UNION ALL

  SELECT
    'Average'::TEXT,
    AVG(net_worth)::DECIMAL,
    COUNT(*)::INTEGER
  FROM user_net_worth;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- Advanced analytics functions are now available:
-- - get_user_growth_trends(start_date, end_date, granularity)
-- - get_financial_trends(start_date, end_date, granularity)
-- - get_feature_adoption_stats()
-- - get_category_breakdown(start_date, end_date)
-- - get_user_engagement_metrics(period_days)
-- - get_net_worth_percentiles()
-- ============================================================================
