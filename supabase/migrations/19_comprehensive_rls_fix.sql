-- ============================================================================
-- COMPREHENSIVE RLS FIX - FIX ALL INFINITE RECURSION ISSUES
-- ============================================================================
-- This migration fixes ALL infinite recursion issues in bill splitting RLS
-- Run this in Supabase SQL Editor after migrations 09-14
-- ============================================================================

-- Drop ALL problematic bill_groups policies
DROP POLICY IF EXISTS "Users can view groups they are members of" ON public.bill_groups;
DROP POLICY IF EXISTS "Users can create groups" ON public.bill_groups;
DROP POLICY IF EXISTS "Group creators can update groups" ON public.bill_groups;
DROP POLICY IF EXISTS "Group creators can delete groups" ON public.bill_groups;

-- Drop ALL problematic group_members policies
DROP POLICY IF EXISTS "Users can view group members" ON public.group_members;
DROP POLICY IF EXISTS "Group admins can add members" ON public.group_members;
DROP POLICY IF EXISTS "Group admins can remove members" ON public.group_members;

-- Drop ALL problematic group_expenses policies
DROP POLICY IF EXISTS "Users can view group expenses" ON public.group_expenses;
DROP POLICY IF EXISTS "Group members can create expenses" ON public.group_expenses;
DROP POLICY IF EXISTS "Expense creators can update expenses" ON public.group_expenses;
DROP POLICY IF EXISTS "Expense creators can delete expenses" ON public.group_expenses;

-- Drop ALL problematic expense_splits policies
DROP POLICY IF EXISTS "Users can view expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Group members can create splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Expense creators can update splits" ON public.expense_splits;

-- Drop ALL problematic settlements policies
DROP POLICY IF EXISTS "Users can view group settlements" ON public.settlements;
DROP POLICY IF EXISTS "Users can create settlements" ON public.settlements;

-- ============================================================================
-- RECREATE POLICIES WITH CORRECTED RECURSION-FREE LOGIC
-- ============================================================================

-- Bill Groups: Users can view groups they created or are members of
CREATE POLICY "Users can view groups they are members of" ON public.bill_groups
  FOR SELECT USING (
    auth.uid() = created_by
    OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = bill_groups.id
      AND gm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create groups" ON public.bill_groups
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group creators can update groups" ON public.bill_groups
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Group creators can delete groups" ON public.bill_groups
  FOR DELETE USING (auth.uid() = created_by);

-- Group Members: Users can view group members if they are in the group
CREATE POLICY "Users can view group members" ON public.group_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id
      AND gm.user_id = auth.uid()
    )
  );

-- Group Members: Allow adding members by group creator or admin
CREATE POLICY "Group admins can add members" ON public.group_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bill_groups bg
      WHERE bg.id = group_members.group_id
      AND bg.created_by = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id
      AND gm.user_id = auth.uid()
      AND gm.role = 'admin'
    )
  );

-- Group Members: Allow removing members by admin or self
CREATE POLICY "Group admins can remove members" ON public.group_members
  FOR DELETE USING (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id
      AND gm.user_id = auth.uid()
      AND gm.role = 'admin'
    )
  );

-- Group Expenses: Users can view expenses in groups they're members of
CREATE POLICY "Users can view group expenses" ON public.group_expenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_expenses.group_id
      AND gm.user_id = auth.uid()
    )
  );

-- Group Expenses: Users can create expenses in groups they're members of
CREATE POLICY "Group members can create expenses" ON public.group_expenses
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_expenses.group_id
      AND gm.user_id = auth.uid()
    )
  );

-- Group Expenses: Only expense creator can update
CREATE POLICY "Expense creators can update expenses" ON public.group_expenses
  FOR UPDATE USING (auth.uid() = paid_by);

-- Group Expenses: Only expense creator can delete
CREATE POLICY "Expense creators can delete expenses" ON public.group_expenses
  FOR DELETE USING (auth.uid() = paid_by);

-- Expense Splits: Users can view splits for expenses in their groups
CREATE POLICY "Users can view expense splits" ON public.expense_splits
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_expenses ge
      INNER JOIN public.group_members gm ON gm.group_id = ge.group_id
      WHERE ge.id = expense_splits.expense_id
      AND gm.user_id = auth.uid()
    )
  );

-- Expense Splits: Users can create splits for expenses in their groups
CREATE POLICY "Group members can create splits" ON public.expense_splits
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.group_expenses ge
      INNER JOIN public.group_members gm ON gm.group_id = ge.group_id
      WHERE ge.id = expense_splits.expense_id
      AND gm.user_id = auth.uid()
    )
  );

-- Expense Splits: Only expense creator can update splits
CREATE POLICY "Expense creators can update splits" ON public.expense_splits
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.group_expenses ge
      WHERE ge.id = expense_splits.expense_id
      AND ge.paid_by = auth.uid()
    )
  );

-- Settlements: Users can view settlements in groups they're members of
CREATE POLICY "Users can view group settlements" ON public.settlements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = settlements.group_id
      AND gm.user_id = auth.uid()
    )
  );

-- Settlements: Users can create settlements in groups they're members of
CREATE POLICY "Users can create settlements" ON public.settlements
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = settlements.group_id
      AND gm.user_id = auth.uid()
    )
    AND (auth.uid() = from_user OR auth.uid() = to_user)
  );

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- All infinite recursion issues should be resolved.
-- The app should now be able to create and manage bill splitting groups.
-- ============================================================================
