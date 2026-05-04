-- Migration 61: Restore last_sign_in_at in get_user_details_admin
-- Migration 36 (disable/enable account) overwrote get_user_details_admin and
-- dropped the auth.users join, causing Last Active to always show null.
-- This migration re-applies the correct version.

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
    COALESCE(COUNT(t.id), 0)::BIGINT AS transaction_count,
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::DECIMAL AS total_income,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL AS total_expense,
    COALESCE(SUM(a.balance), 0)::DECIMAL AS net_worth,
    up.is_active
  FROM public.user_profiles up
  LEFT JOIN auth.users au ON au.id = up.id
  LEFT JOIN public.transactions t ON t.user_id = up.id
  LEFT JOIN public.accounts a ON a.user_id = up.id
  WHERE up.id = p_user_id
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role,
           up.created_at, au.last_sign_in_at, up.is_active;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
