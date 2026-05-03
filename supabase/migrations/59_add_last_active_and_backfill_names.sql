-- Migration 59: Add last_sign_in_at to get_user_details_admin + backfill full_name
-- 1. Updates the admin RPC to expose auth.users.last_sign_in_at
-- 2. Backfills user_profiles.full_name from auth metadata for existing users

-- ============================================================================
-- 1. Backfill full_name from auth.users.raw_user_meta_data
-- ============================================================================
-- Runs for users where full_name is null or empty string.
-- Tries 'full_name' key first, then 'name' key as fallback.

UPDATE public.user_profiles up
SET full_name = COALESCE(
  NULLIF(au.raw_user_meta_data->>'full_name', ''),
  NULLIF(au.raw_user_meta_data->>'name', ''),
  NULL
)
FROM auth.users au
WHERE au.id = up.id
  AND (up.full_name IS NULL OR up.full_name = '');

-- ============================================================================
-- 2. Update get_user_details_admin to include last_sign_in_at
-- ============================================================================

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
  LEFT JOIN auth.users au ON au.id = up.id
  LEFT JOIN public.transactions t ON t.user_id = up.id
  LEFT JOIN public.accounts a ON a.user_id = up.id
  WHERE up.id = p_user_id
  GROUP BY up.id, up.email, up.full_name, up.avatar_url, up.role,
           up.created_at, au.last_sign_in_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
