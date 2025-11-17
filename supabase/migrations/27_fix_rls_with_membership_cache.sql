-- ============================================================================
-- MIGRATION 21: Fix RLS Infinite Recursion with Membership Cache
-- ============================================================================
-- This migration fixes the circular dependency issue in RLS policies
-- by creating a denormalized membership cache table.
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE MEMBERSHIP CACHE TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.group_membership_cache (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES public.bill_groups(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_group_membership_cache_user_id ON public.group_membership_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_group_membership_cache_group_id ON public.group_membership_cache(group_id);

-- ============================================================================
-- STEP 2: POPULATE CACHE FROM EXISTING DATA
-- ============================================================================

INSERT INTO public.group_membership_cache (user_id, group_id, role, created_at, updated_at)
SELECT user_id, group_id, role, joined_at, NOW()
FROM public.group_members
ON CONFLICT (user_id, group_id) DO UPDATE SET
  role = EXCLUDED.role,
  updated_at = NOW();

-- ============================================================================
-- STEP 3: CREATE SIMPLIFIED RLS POLICIES (RE-ENABLE RLS FIRST)
-- ============================================================================

-- First, ensure RLS is enabled on all bill splitting tables
ALTER TABLE public.bill_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

-- Enable RLS on the new cache table
ALTER TABLE public.group_membership_cache ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Drop old policies that cause recursion
-- ============================================================================

DROP POLICY IF EXISTS "Users can view groups they are members of" ON public.bill_groups;
DROP POLICY IF EXISTS "Users can create groups" ON public.bill_groups;
DROP POLICY IF EXISTS "Group creators can update groups" ON public.bill_groups;
DROP POLICY IF EXISTS "Group creators can delete groups" ON public.bill_groups;

DROP POLICY IF EXISTS "Users can view group members" ON public.group_members;
DROP POLICY IF EXISTS "Group admins can add members" ON public.group_members;
DROP POLICY IF EXISTS "Group admins can remove members" ON public.group_members;

DROP POLICY IF EXISTS "Users can view group expenses" ON public.group_expenses;
DROP POLICY IF EXISTS "Group members can create expenses" ON public.group_expenses;
DROP POLICY IF EXISTS "Expense creators can update expenses" ON public.group_expenses;
DROP POLICY IF EXISTS "Expense creators can delete expenses" ON public.group_expenses;

DROP POLICY IF EXISTS "Users can view expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Group members can create splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Expense creators can update splits" ON public.expense_splits;

DROP POLICY IF EXISTS "Users can view group settlements" ON public.settlements;
DROP POLICY IF EXISTS "Users can create settlements" ON public.settlements;

-- ============================================================================
-- STEP 4: CREATE NEW SIMPLIFIED RLS POLICIES USING CACHE
-- ============================================================================

-- Bill Groups Policies - Use cache for membership checks
CREATE POLICY "Users can view groups they are members of" ON public.bill_groups
  FOR SELECT USING (
    id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create groups" ON public.bill_groups
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group creators can update groups" ON public.bill_groups
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Group creators can delete groups" ON public.bill_groups
  FOR DELETE USING (auth.uid() = created_by);

-- Group Members Policies - Check cache for membership
CREATE POLICY "Users can view group members they have access to" ON public.group_members
  FOR SELECT USING (
    group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
  );

CREATE POLICY "Group admins can add members" ON public.group_members
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.group_membership_cache
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
    OR
    auth.uid() IN (
      SELECT created_by FROM public.bill_groups WHERE id = group_members.group_id
    )
  );

CREATE POLICY "Group admins can remove members" ON public.group_members
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_membership_cache
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
    OR user_id = auth.uid()
  );

-- Group Expenses Policies - Use cache for membership
CREATE POLICY "Users can view group expenses" ON public.group_expenses
  FOR SELECT USING (
    group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
  );

CREATE POLICY "Group members can create expenses" ON public.group_expenses
  FOR INSERT WITH CHECK (
    group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
  );

CREATE POLICY "Expense creators can update expenses" ON public.group_expenses
  FOR UPDATE USING (auth.uid() = paid_by);

CREATE POLICY "Expense creators can delete expenses" ON public.group_expenses
  FOR DELETE USING (auth.uid() = paid_by);

-- Expense Splits Policies - Use cache for membership
CREATE POLICY "Users can view expense splits" ON public.expense_splits
  FOR SELECT USING (
    expense_id IN (
      SELECT id FROM public.group_expenses
      WHERE group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Group members can create splits" ON public.expense_splits
  FOR INSERT WITH CHECK (
    expense_id IN (
      SELECT id FROM public.group_expenses
      WHERE group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Expense creators can update splits" ON public.expense_splits
  FOR UPDATE USING (
    expense_id IN (
      SELECT id FROM public.group_expenses WHERE paid_by = auth.uid()
    )
  );

-- Settlements Policies - Use cache for membership
CREATE POLICY "Users can view group settlements" ON public.settlements
  FOR SELECT USING (
    group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create settlements" ON public.settlements
  FOR INSERT WITH CHECK (
    group_id IN (SELECT group_id FROM public.group_membership_cache WHERE user_id = auth.uid())
    AND (auth.uid() = from_user OR auth.uid() = to_user)
  );

-- Membership Cache Policies - Allow users to see their own memberships
CREATE POLICY "Users can view their own memberships" ON public.group_membership_cache
  FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- STEP 5: CREATE TRIGGER TO SYNC CACHE WITH GROUP_MEMBERS
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_group_membership_cache()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.group_membership_cache (user_id, group_id, role, created_at, updated_at)
    VALUES (NEW.user_id, NEW.group_id, NEW.role, NEW.joined_at, NOW())
    ON CONFLICT (user_id, group_id) DO UPDATE SET
      role = NEW.role,
      updated_at = NOW();

  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.group_membership_cache
    SET role = NEW.role, updated_at = NOW()
    WHERE user_id = NEW.user_id AND group_id = NEW.group_id;

  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.group_membership_cache
    WHERE user_id = OLD.user_id AND group_id = OLD.group_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS sync_group_membership_cache ON public.group_members;
CREATE TRIGGER sync_group_membership_cache
  AFTER INSERT OR UPDATE OR DELETE ON public.group_members
  FOR EACH ROW EXECUTE FUNCTION sync_group_membership_cache();

-- ============================================================================
-- STEP 6: VERIFY THE FIX
-- ============================================================================

-- After applying this migration, verify that:
-- 1. The group_membership_cache table is created
-- 2. All group members are in the cache
-- 3. RLS is enabled on all tables
-- 4. The get_group_balances() function works without errors

-- Test query (run as authenticated user):
-- SELECT * FROM public.bill_groups;
-- This should only return groups the user is a member of

-- Test the balance calculation:
-- SELECT * FROM public.get_group_balances('your-group-id');
-- This should work without "Unable to calculate balance" error

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Bill splitting RLS is now fixed with proper membership cache!
-- The circular dependency has been eliminated.
-- ============================================================================
