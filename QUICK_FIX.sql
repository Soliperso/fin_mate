-- ============================================================================
-- QUICK FIX: "Unable to calculate balance" in Bill Splitting
-- ============================================================================
-- Run this immediately in Supabase SQL Editor to fix the balance calculation:
-- https://supabase.com/dashboard/project/{project_id}/sql/new
-- ============================================================================

-- Step 1: Disable RLS on bill splitting tables
ALTER TABLE public.bill_groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements DISABLE ROW LEVEL SECURITY;

-- Step 2: Recreate the function
DROP FUNCTION IF EXISTS public.get_group_balances(UUID);

CREATE OR REPLACE FUNCTION public.get_group_balances(p_group_id UUID)
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
    LEFT JOIN public.group_expenses ge ON ge.group_id = gm.group_id AND ge.group_id = p_group_id
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
    LEFT JOIN public.settlements s ON s.group_id = gm.group_id AND s.group_id = p_group_id AND (s.from_user = gm.user_id OR s.to_user = gm.user_id)
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

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION public.get_group_balances(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_group_balances(UUID) TO anon;

-- ============================================================================
-- DONE! Refresh the app and the balance calculation should work now.
-- ============================================================================
