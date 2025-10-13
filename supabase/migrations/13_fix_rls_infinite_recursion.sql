-- Fix infinite recursion in RLS policies
-- The issue is that bill_groups policy checks group_members, and group_members policy checks bill_groups
-- This creates a circular dependency causing PostgrestException: infinite recursion detected

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view groups they are members of" ON public.bill_groups;
DROP POLICY IF EXISTS "Group admins can add members" ON public.group_members;
DROP POLICY IF EXISTS "Users can view group settlements" ON public.settlements;
DROP POLICY IF EXISTS "Users can create settlements" ON public.settlements;

-- Recreate bill_groups SELECT policy (using EXISTS to avoid recursion)
CREATE POLICY "Users can view groups they are members of" ON public.bill_groups
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_members.group_id = bill_groups.id
      AND group_members.user_id = auth.uid()
    )
  );

-- Recreate group_members INSERT policy (using EXISTS to avoid recursion)
CREATE POLICY "Group admins can add members" ON public.group_members
  FOR INSERT WITH CHECK (
    -- Either you're an admin in this group
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id
      AND gm.user_id = auth.uid()
      AND gm.role = 'admin'
    )
    OR
    -- Or you're the creator of the group (first member being added)
    EXISTS (
      SELECT 1 FROM public.bill_groups bg
      WHERE bg.id = group_members.group_id
      AND bg.created_by = auth.uid()
    )
  );

-- Fix settlements policies
CREATE POLICY "Users can view group settlements" ON public.settlements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = settlements.group_id
      AND gm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create settlements" ON public.settlements
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = settlements.group_id
      AND gm.user_id = auth.uid()
    )
    AND (auth.uid() = from_user OR auth.uid() = to_user)
  );
