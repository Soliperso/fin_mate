-- Migration 92: Expose subscription data to admin RPCs.
-- 1. Add subscription_tier / subscription_status to get_all_users_with_stats
--    and get_user_details_admin so the admin UI can render tier badges/filters.
-- 2. Add get_subscription_overview() returning active subs, trial users,
--    monthly/annual counts and estimated MRR for the admin dashboard.
-- Plan is inferred from (subscription_end_date - subscription_start_date) since
-- the active code does not yet persist plan_id on user_profiles.

-- ── get_user_details_admin ──────────────────────────────────────────────────

DROP FUNCTION IF EXISTS get_user_details_admin(UUID);

CREATE OR REPLACE FUNCTION get_user_details_admin(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  created_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  transaction_count BIGINT,
  total_income DECIMAL,
  total_expense DECIMAL,
  net_worth DECIMAL,
  is_active BOOLEAN,
  subscription_tier TEXT,
  subscription_status TEXT,
  subscription_end_date TIMESTAMPTZ
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
    au.last_sign_in_at,
    COALESCE(tx.transaction_count, 0)::BIGINT  AS transaction_count,
    COALESCE(tx.total_income,      0)::DECIMAL AS total_income,
    COALESCE(tx.total_expense,     0)::DECIMAL AS total_expense,
    COALESCE(acc.net_worth,        0)::DECIMAL AS net_worth,
    up.is_active,
    up.subscription_tier,
    up.subscription_status,
    up.subscription_end_date
  FROM public.user_profiles up
  LEFT JOIN auth.users au ON au.id = up.id
  LEFT JOIN (
    SELECT
      t2.user_id,
      COUNT(t2.id)                                                             AS transaction_count,
      SUM(CASE WHEN t2.type = 'income'  THEN t2.amount ELSE 0 END)            AS total_income,
      SUM(CASE WHEN t2.type = 'expense' THEN t2.amount ELSE 0 END)            AS total_expense
    FROM public.transactions t2
    WHERE t2.user_id = p_user_id
    GROUP BY t2.user_id
  ) tx ON tx.user_id = up.id
  LEFT JOIN (
    SELECT a2.user_id, SUM(a2.balance) AS net_worth
    FROM public.accounts a2
    WHERE a2.user_id = p_user_id
    GROUP BY a2.user_id
  ) acc ON acc.user_id = up.id
  WHERE up.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── get_all_users_with_stats ────────────────────────────────────────────────

DROP FUNCTION IF EXISTS get_all_users_with_stats(INTEGER, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION get_all_users_with_stats(
  p_limit        INTEGER DEFAULT 50,
  p_offset       INTEGER DEFAULT 0,
  p_search_query TEXT    DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  created_at TIMESTAMPTZ,
  transaction_count BIGINT,
  total_income DECIMAL,
  total_expense DECIMAL,
  net_worth DECIMAL,
  is_active BOOLEAN,
  subscription_tier TEXT,
  subscription_status TEXT,
  subscription_end_date TIMESTAMPTZ
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
    COALESCE(tx.transaction_count, 0)::BIGINT  AS transaction_count,
    COALESCE(tx.total_income,      0)::DECIMAL AS total_income,
    COALESCE(tx.total_expense,     0)::DECIMAL AS total_expense,
    COALESCE(acc.net_worth,        0)::DECIMAL AS net_worth,
    up.is_active,
    up.subscription_tier,
    up.subscription_status,
    up.subscription_end_date
  FROM public.user_profiles up
  LEFT JOIN (
    SELECT
      t2.user_id,
      COUNT(t2.id)                                                             AS transaction_count,
      SUM(CASE WHEN t2.type = 'income'  THEN t2.amount ELSE 0 END)            AS total_income,
      SUM(CASE WHEN t2.type = 'expense' THEN t2.amount ELSE 0 END)            AS total_expense
    FROM public.transactions t2
    GROUP BY t2.user_id
  ) tx ON tx.user_id = up.id
  LEFT JOIN (
    SELECT a2.user_id, SUM(a2.balance) AS net_worth
    FROM public.accounts a2
    GROUP BY a2.user_id
  ) acc ON acc.user_id = up.id
  WHERE
    (p_search_query IS NULL OR (
      up.email     ILIKE '%' || p_search_query || '%' OR
      up.full_name ILIKE '%' || p_search_query || '%'
    ))
  ORDER BY up.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── get_subscription_overview ──────────────────────────────────────────────
-- Admin dashboard widget data. Plan is inferred from the active subscription's
-- duration (end - start). Monthly = ~$9.99, Annual = $49.99/12 for MRR.

CREATE OR REPLACE FUNCTION get_subscription_overview()
RETURNS TABLE (
  active_subscribers   INTEGER,
  trial_users          INTEGER,
  annual_subscribers   INTEGER,
  monthly_subscribers  INTEGER,
  estimated_mrr_cents  INTEGER
) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  RETURN QUERY
  WITH active AS (
    SELECT
      up.subscription_status,
      CASE
        WHEN up.subscription_start_date IS NOT NULL
         AND up.subscription_end_date  IS NOT NULL
         AND (up.subscription_end_date - up.subscription_start_date) > INTERVAL '60 days'
        THEN 'annual'
        ELSE 'monthly'
      END AS plan
    FROM public.user_profiles up
    WHERE up.subscription_tier = 'premium'
      AND up.subscription_status IN ('active', 'trialing')
  )
  SELECT
    (SELECT COUNT(*)::INTEGER FROM active WHERE subscription_status = 'active') AS active_subscribers,
    (SELECT COUNT(*)::INTEGER FROM active WHERE subscription_status = 'trialing') AS trial_users,
    (SELECT COUNT(*)::INTEGER FROM active WHERE plan = 'annual'  AND subscription_status = 'active') AS annual_subscribers,
    (SELECT COUNT(*)::INTEGER FROM active WHERE plan = 'monthly' AND subscription_status = 'active') AS monthly_subscribers,
    -- 9.99 / mo for monthly, 49.99 / 12 for annual ≈ $4.16 / mo
    (
      (SELECT COUNT(*) FROM active WHERE plan = 'monthly' AND subscription_status = 'active') * 999
      + (SELECT COUNT(*) FROM active WHERE plan = 'annual'  AND subscription_status = 'active') * 416
    )::INTEGER AS estimated_mrr_cents;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_subscription_overview() TO authenticated;
