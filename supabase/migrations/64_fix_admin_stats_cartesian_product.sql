-- Migration 64: Fix Cartesian product bug in admin financial stats RPCs
-- Both get_user_details_admin and get_all_users_with_stats joined transactions
-- and accounts without linking them, creating a transactions × accounts
-- cross-product that inflated net_worth by N_transactions and
-- total_income/expense by N_accounts. Rewrite using subquery aggregations.
-- Note: table aliases are required inside subqueries to avoid the PL/pgSQL
-- ambiguity error (code 42702) caused by RETURNS TABLE columns sharing names
-- like "id", "type", "amount" with the queried tables.

-- ── get_user_details_admin ───────────────────────────────────────────────────

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
  is_active BOOLEAN
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
    up.is_active
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

-- ── get_all_users_with_stats ─────────────────────────────────────────────────

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
  is_active BOOLEAN
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
    up.is_active
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
