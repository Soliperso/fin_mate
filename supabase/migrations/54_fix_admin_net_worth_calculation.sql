-- ============================================================================
-- FIX ADMIN NET WORTH CALCULATIONS
-- ============================================================================
-- get_system_stats and the per-user admin functions were computing net worth
-- as a simple SUM of all account balances, ignoring credit card debt and
-- debt-tracker liabilities. This aligns them with calculate_true_net_worth:
--
--   Net Worth = SUM(non-credit-card active accounts)
--             - SUM(credit_card active accounts)
--             - SUM(active debts)
-- ============================================================================

-- ── get_system_stats ────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE (
  total_users           INTEGER,
  active_users          INTEGER,
  new_users_this_month  INTEGER,
  total_transactions    INTEGER,
  total_income          DECIMAL,
  total_expense         DECIMAL,
  total_net_worth       DECIMAL,
  total_accounts        INTEGER,
  total_budgets         INTEGER,
  total_bill_groups     INTEGER
) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INTEGER FROM public.user_profiles),
    (SELECT COUNT(DISTINCT user_id)::INTEGER
     FROM public.transactions
     WHERE date >= CURRENT_DATE - INTERVAL '30 days'),
    (SELECT COUNT(*)::INTEGER
     FROM public.user_profiles
     WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)),
    (SELECT COUNT(*)::INTEGER FROM public.transactions),
    (SELECT COALESCE(SUM(amount), 0)::DECIMAL
     FROM public.transactions WHERE type = 'income'),
    (SELECT COALESCE(SUM(amount), 0)::DECIMAL
     FROM public.transactions WHERE type = 'expense'),
    (
      (SELECT COALESCE(SUM(balance), 0) FROM public.accounts
       WHERE is_active = TRUE AND type != 'credit_card')
      - (SELECT COALESCE(SUM(balance), 0) FROM public.accounts
         WHERE is_active = TRUE AND type = 'credit_card')
      - (SELECT COALESCE(SUM(balance), 0) FROM public.debts
         WHERE is_active = TRUE)
    )::DECIMAL,
    (SELECT COUNT(*)::INTEGER FROM public.accounts),
    (SELECT COUNT(*)::INTEGER FROM public.budgets),
    (SELECT COUNT(*)::INTEGER FROM public.bill_groups);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── get_all_users_with_stats ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_all_users_with_stats(
  p_limit        INTEGER DEFAULT 50,
  p_offset       INTEGER DEFAULT 0,
  p_search_query TEXT    DEFAULT NULL
)
RETURNS TABLE (
  id                UUID,
  email             TEXT,
  full_name         TEXT,
  avatar_url        TEXT,
  role              TEXT,
  created_at        TIMESTAMPTZ,
  transaction_count BIGINT,
  total_income      DECIMAL,
  total_expense     DECIMAL,
  net_worth         DECIMAL,
  is_active         BOOLEAN
) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  SELECT
    up.id,
    up.email,
    up.full_name,
    up.avatar_url,
    up.role,
    up.created_at,
    COALESCE(COUNT(t.id), 0)::BIGINT,
    COALESCE(SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END), 0)::DECIMAL,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL,
    calculate_true_net_worth(up.id)::DECIMAL,
    (EXISTS (
      SELECT 1 FROM public.transactions
      WHERE user_id = up.id
        AND date >= CURRENT_DATE - INTERVAL '30 days'
      LIMIT 1
    ))
  FROM public.user_profiles up
  LEFT JOIN public.transactions t ON t.user_id = up.id
  WHERE
    p_search_query IS NULL OR (
      up.email     ILIKE '%' || p_search_query || '%' OR
      up.full_name ILIKE '%' || p_search_query || '%'
    )
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role, up.created_at
  ORDER BY up.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── get_user_details_admin ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_user_details_admin(p_user_id UUID)
RETURNS TABLE (
  id                UUID,
  email             TEXT,
  full_name         TEXT,
  avatar_url        TEXT,
  role              TEXT,
  created_at        TIMESTAMPTZ,
  transaction_count BIGINT,
  total_income      DECIMAL,
  total_expense     DECIMAL,
  net_worth         DECIMAL,
  is_active         BOOLEAN
) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  SELECT
    up.id,
    up.email,
    up.full_name,
    up.avatar_url,
    up.role,
    up.created_at,
    COALESCE(COUNT(t.id), 0)::BIGINT,
    COALESCE(SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END), 0)::DECIMAL,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL,
    calculate_true_net_worth(up.id)::DECIMAL,
    (EXISTS (
      SELECT 1 FROM public.transactions
      WHERE user_id = up.id
        AND date >= CURRENT_DATE - INTERVAL '30 days'
      LIMIT 1
    ))
  FROM public.user_profiles up
  LEFT JOIN public.transactions t ON t.user_id = up.id
  WHERE up.id = p_user_id
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role, up.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
