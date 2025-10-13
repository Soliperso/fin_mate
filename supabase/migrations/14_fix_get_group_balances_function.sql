-- ============================================================================
-- FIX get_group_balances FUNCTION - Ambiguous Column Reference
-- ============================================================================
-- This fixes the "column reference user_id is ambiguous" error
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql
-- ============================================================================

-- Drop and recreate the function with fully qualified column names
CREATE OR REPLACE FUNCTION get_group_balances(p_group_id UUID)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  email TEXT,
  balance DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  WITH member_expenses AS (
    SELECT
      gm.user_id,
      COALESCE(SUM(CASE WHEN ge.paid_by = gm.user_id THEN ge.amount ELSE 0 END), 0) as paid,
      COALESCE(SUM(es.amount), 0) as owed
    FROM public.group_members gm
    LEFT JOIN public.group_expenses ge ON ge.group_id = gm.group_id
    LEFT JOIN public.expense_splits es ON es.expense_id = ge.id AND es.user_id = gm.user_id
    WHERE gm.group_id = p_group_id
    GROUP BY gm.user_id
  ),
  settlements_net AS (
    SELECT
      gm.user_id,
      COALESCE(SUM(CASE WHEN s.from_user = gm.user_id THEN -s.amount ELSE 0 END), 0) +
      COALESCE(SUM(CASE WHEN s.to_user = gm.user_id THEN s.amount ELSE 0 END), 0) as settlement_amount
    FROM public.group_members gm
    LEFT JOIN public.settlements s ON s.group_id = gm.group_id AND (s.from_user = gm.user_id OR s.to_user = gm.user_id)
    WHERE gm.group_id = p_group_id
    GROUP BY gm.user_id
  )
  SELECT
    me.user_id,
    up.full_name,
    up.email,
    (me.paid - me.owed + COALESCE(sn.settlement_amount, 0))::DECIMAL as balance
  FROM member_expenses me
  LEFT JOIN settlements_net sn ON sn.user_id = me.user_id
  LEFT JOIN public.user_profiles up ON up.id = me.user_id
  ORDER BY balance DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- The get_group_balances function should now work without ambiguous errors.
-- ============================================================================
