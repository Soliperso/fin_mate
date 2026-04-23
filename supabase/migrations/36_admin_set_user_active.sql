-- Migration 36: Add is_active column to user_profiles and admin RPC to toggle it
-- Fixes Disable/Enable Account in the admin panel.
-- is_active = false means an admin has explicitly disabled the account.

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- ── RPC: admin_set_user_active ─────────────────────────────────────────────
-- SECURITY DEFINER so it bypasses RLS; guards itself with is_admin() check.
CREATE OR REPLACE FUNCTION admin_set_user_active(p_user_id UUID, p_active BOOLEAN)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  UPDATE public.user_profiles
  SET is_active = p_active
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION admin_set_user_active(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_set_user_active(UUID, BOOLEAN) TO authenticated;

-- ── Update get_all_users_with_stats to read is_active from the column ───────
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
    COALESCE(COUNT(t.id), 0)::BIGINT AS transaction_count,
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::DECIMAL AS total_income,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL AS total_expense,
    COALESCE(SUM(a.balance), 0)::DECIMAL AS net_worth,
    up.is_active
  FROM public.user_profiles up
  LEFT JOIN public.transactions t ON t.user_id = up.id
  LEFT JOIN public.accounts a ON a.user_id = up.id
  WHERE
    (p_search_query IS NULL OR (
      up.email ILIKE '%' || p_search_query || '%' OR
      up.full_name ILIKE '%' || p_search_query || '%'
    ))
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role, up.created_at, up.is_active
  ORDER BY up.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Update get_user_details_admin to read is_active from the column ──────────
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
    COALESCE(COUNT(t.id), 0)::BIGINT AS transaction_count,
    COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::DECIMAL AS total_income,
    COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::DECIMAL AS total_expense,
    COALESCE(SUM(a.balance), 0)::DECIMAL AS net_worth,
    up.is_active
  FROM public.user_profiles up
  LEFT JOIN public.transactions t ON t.user_id = up.id
  LEFT JOIN public.accounts a ON a.user_id = up.id
  WHERE up.id = p_user_id
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role, up.created_at, up.is_active;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
