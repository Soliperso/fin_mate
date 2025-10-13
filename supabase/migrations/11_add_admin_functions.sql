-- ============================================================================
-- ADMIN FUNCTIONS AND RLS POLICIES
-- ============================================================================
-- This migration adds admin-only functions for user management and analytics
-- ============================================================================

-- ============================================================================
-- ADMIN RLS POLICY: Allow admins to view all user profiles
-- ============================================================================

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
CREATE POLICY "Admins can view all profiles" ON public.user_profiles
  FOR SELECT USING (
    is_admin() = TRUE
    OR auth.uid() = id
  );

-- ============================================================================
-- FUNCTION: Get all users with statistics (admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_users_with_stats(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_search_query TEXT DEFAULT NULL
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
  -- Check if user is admin
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
    COALESCE(COUNT(t.id), 0)::BIGINT as transaction_count,
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::DECIMAL as total_income,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL as total_expense,
    COALESCE(SUM(a.balance), 0)::DECIMAL as net_worth,
    (EXISTS (
      SELECT 1 FROM public.transactions
      WHERE user_id = up.id
        AND date >= CURRENT_DATE - INTERVAL '30 days'
      LIMIT 1
    )) as is_active
  FROM public.user_profiles up
  LEFT JOIN public.transactions t ON t.user_id = up.id
  LEFT JOIN public.accounts a ON a.user_id = up.id
  WHERE
    (p_search_query IS NULL OR (
      up.email ILIKE '%' || p_search_query || '%' OR
      up.full_name ILIKE '%' || p_search_query || '%'
    ))
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role, up.created_at
  ORDER BY up.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get system-wide statistics (admin only)
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
  total_bill_groups INTEGER
) AS $$
BEGIN
  -- Check if user is admin
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
    (SELECT COUNT(*)::INTEGER FROM public.bill_groups) as total_bill_groups;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get user details by ID (admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_details_admin(p_user_id UUID)
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
  -- Check if user is admin
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
    COALESCE(COUNT(t.id), 0)::BIGINT as transaction_count,
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::DECIMAL as total_income,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL as total_expense,
    COALESCE(SUM(a.balance), 0)::DECIMAL as net_worth,
    (EXISTS (
      SELECT 1 FROM public.transactions
      WHERE user_id = up.id
        AND date >= CURRENT_DATE - INTERVAL '30 days'
      LIMIT 1
    )) as is_active
  FROM public.user_profiles up
  LEFT JOIN public.transactions t ON t.user_id = up.id
  LEFT JOIN public.accounts a ON a.user_id = up.id
  WHERE up.id = p_user_id
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role, up.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- Admin functions are now available:
-- - get_all_users_with_stats(limit, offset, search_query)
-- - get_system_stats()
-- - get_user_details_admin(user_id)
-- ============================================================================
