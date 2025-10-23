-- ============================================================================
-- ENFORCE ROW LEVEL SECURITY STRICTLY ON ALL USER DATA TABLES
-- ============================================================================
-- This migration ensures that RLS is strictly enforced on all tables containing
-- user-specific data, preventing data leakage between users.
-- ============================================================================

-- TRANSACTIONS TABLE - STRICT RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
CREATE POLICY "Users can view own transactions" ON public.transactions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
CREATE POLICY "Users can insert own transactions" ON public.transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
CREATE POLICY "Users can update own transactions" ON public.transactions
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
CREATE POLICY "Users can delete own transactions" ON public.transactions
  FOR DELETE USING (auth.uid() = user_id);

-- ACCOUNTS TABLE - STRICT RLS
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own accounts" ON public.accounts;
CREATE POLICY "Users can view own accounts" ON public.accounts
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own accounts" ON public.accounts;
CREATE POLICY "Users can insert own accounts" ON public.accounts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own accounts" ON public.accounts;
CREATE POLICY "Users can update own accounts" ON public.accounts
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own accounts" ON public.accounts;
CREATE POLICY "Users can delete own accounts" ON public.accounts
  FOR DELETE USING (auth.uid() = user_id);

-- BUDGETS TABLE - STRICT RLS
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;
CREATE POLICY "Users can view own budgets" ON public.budgets
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own budgets" ON public.budgets;
CREATE POLICY "Users can insert own budgets" ON public.budgets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own budgets" ON public.budgets;
CREATE POLICY "Users can update own budgets" ON public.budgets
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own budgets" ON public.budgets;
CREATE POLICY "Users can delete own budgets" ON public.budgets
  FOR DELETE USING (auth.uid() = user_id);

-- RECURRING TRANSACTIONS TABLE - STRICT RLS
ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can view own recurring transactions" ON public.recurring_transactions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can insert own recurring transactions" ON public.recurring_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can update own recurring transactions" ON public.recurring_transactions
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can delete own recurring transactions" ON public.recurring_transactions
  FOR DELETE USING (auth.uid() = user_id);

-- SAVINGS GOALS TABLE - STRICT RLS
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own goals" ON public.savings_goals;
CREATE POLICY "Users can view own goals" ON public.savings_goals
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own goals" ON public.savings_goals;
CREATE POLICY "Users can create own goals" ON public.savings_goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own goals" ON public.savings_goals;
CREATE POLICY "Users can update own goals" ON public.savings_goals
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own goals" ON public.savings_goals;
CREATE POLICY "Users can delete own goals" ON public.savings_goals
  FOR DELETE USING (auth.uid() = user_id);

-- GOAL CONTRIBUTIONS TABLE - STRICT RLS
ALTER TABLE public.goal_contributions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own goal contributions" ON public.goal_contributions;
CREATE POLICY "Users can view own goal contributions" ON public.goal_contributions
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.savings_goals WHERE id = goal_contributions.goal_id
    )
  );

DROP POLICY IF EXISTS "Users can create goal contributions" ON public.goal_contributions;
CREATE POLICY "Users can create goal contributions" ON public.goal_contributions
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.savings_goals WHERE id = goal_contributions.goal_id
    )
  );

DROP POLICY IF EXISTS "Users can update own goal contributions" ON public.goal_contributions;
CREATE POLICY "Users can update own goal contributions" ON public.goal_contributions
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM public.savings_goals WHERE id = goal_contributions.goal_id
    )
  );

DROP POLICY IF EXISTS "Users can delete own goal contributions" ON public.goal_contributions;
CREATE POLICY "Users can delete own goal contributions" ON public.goal_contributions
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.savings_goals WHERE id = goal_contributions.goal_id
    )
  );

-- NOTIFICATIONS TABLE - STRICT RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications" ON public.notifications
  FOR INSERT WITH CHECK (true);

-- NET WORTH SNAPSHOTS TABLE - STRICT RLS
ALTER TABLE public.net_worth_snapshots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own snapshots" ON public.net_worth_snapshots;
CREATE POLICY "Users can view own snapshots" ON public.net_worth_snapshots
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own snapshots" ON public.net_worth_snapshots;
CREATE POLICY "Users can insert own snapshots" ON public.net_worth_snapshots
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- BILL SPLITTING TABLES - STRICT RLS WITH MEMBERSHIP VALIDATION
-- Bill Groups - only members can access
ALTER TABLE public.bill_groups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view groups" ON public.bill_groups;
CREATE POLICY "Members can view groups" ON public.bill_groups
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = bill_groups.id
    )
    OR auth.uid() = created_by
  );

DROP POLICY IF EXISTS "Users can create groups" ON public.bill_groups;
CREATE POLICY "Users can create groups" ON public.bill_groups
  FOR INSERT WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Creators can update groups" ON public.bill_groups;
CREATE POLICY "Creators can update groups" ON public.bill_groups
  FOR UPDATE USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Creators can delete groups" ON public.bill_groups;
CREATE POLICY "Creators can delete groups" ON public.bill_groups
  FOR DELETE USING (auth.uid() = created_by);

-- Group Members - only members and group creators can access
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view group members" ON public.group_members;
CREATE POLICY "Members can view group members" ON public.group_members
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = group_members.group_id
    )
    OR auth.uid() IN (
      SELECT created_by FROM public.bill_groups WHERE id = group_members.group_id
    )
  );

DROP POLICY IF EXISTS "Admins can manage members" ON public.group_members;
CREATE POLICY "Admins can manage members" ON public.group_members
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Group members can be updated by admins" ON public.group_members;
CREATE POLICY "Group members can be updated by admins" ON public.group_members
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can remove members" ON public.group_members;
CREATE POLICY "Admins can remove members" ON public.group_members
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
  );

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
-- This migration ensures that:
-- 1. All user data tables have RLS ENABLED
-- 2. All data access is controlled by user_id or group membership
-- 3. Users cannot access other users' data at the database level
-- 4. This is the final layer of protection (before application-level checks)
--
-- IMPORTANT: After running this migration, verify that:
-- - You can log in with Account A and see ONLY Account A's data
-- - You can log in with Account B and see ONLY Account B's data
-- - You CANNOT see Account A's data when logged in as Account B
-- ============================================================================
