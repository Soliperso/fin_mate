-- ============================================================================
-- FIXED MIGRATION - RUN THIS IN SUPABASE SQL EDITOR
-- Dashboard URL: https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql
-- ============================================================================
-- This creates tables first, then adds policies to avoid circular dependencies
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: CREATE ALL TABLES (NO POLICIES YET)
-- ============================================================================

-- BILL GROUPS TABLE
CREATE TABLE IF NOT EXISTS public.bill_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bill_groups_created_by ON public.bill_groups(created_by);

-- GROUP MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES public.bill_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);

-- GROUP EXPENSES TABLE
CREATE TABLE IF NOT EXISTS public.group_expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES public.bill_groups(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  paid_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  category TEXT,
  notes TEXT,
  split_type TEXT NOT NULL CHECK (split_type IN ('equal', 'custom', 'percentage')) DEFAULT 'equal',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_expenses_group_id ON public.group_expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_group_expenses_paid_by ON public.group_expenses(paid_by);
CREATE INDEX IF NOT EXISTS idx_group_expenses_date ON public.group_expenses(date);

-- EXPENSE SPLITS TABLE
CREATE TABLE IF NOT EXISTS public.expense_splits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  expense_id UUID NOT NULL REFERENCES public.group_expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL CHECK (amount >= 0),
  is_settled BOOLEAN DEFAULT FALSE,
  settled_at TIMESTAMPTZ,
  UNIQUE(expense_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON public.expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user_id ON public.expense_splits(user_id);

-- SETTLEMENTS TABLE
CREATE TABLE IF NOT EXISTS public.settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES public.bill_groups(id) ON DELETE CASCADE,
  from_user UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  to_user UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  notes TEXT,
  evidence_url TEXT,
  settled_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settlements_group_id ON public.settlements(group_id);
CREATE INDEX IF NOT EXISTS idx_settlements_from_user ON public.settlements(from_user);
CREATE INDEX IF NOT EXISTS idx_settlements_to_user ON public.settlements(to_user);

-- SAVINGS GOALS TABLE
CREATE TABLE IF NOT EXISTS public.savings_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  target_amount DECIMAL(15,2) NOT NULL CHECK (target_amount > 0),
  current_amount DECIMAL(15,2) DEFAULT 0 CHECK (current_amount >= 0),
  deadline DATE,
  category TEXT,
  icon TEXT,
  color TEXT,
  is_shared BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON public.savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_deadline ON public.savings_goals(deadline);
CREATE INDEX IF NOT EXISTS idx_savings_goals_is_completed ON public.savings_goals(is_completed);

-- GOAL CONTRIBUTIONS TABLE
CREATE TABLE IF NOT EXISTS public.goal_contributions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id UUID NOT NULL REFERENCES public.savings_goals(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  notes TEXT,
  contributed_at DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id ON public.goal_contributions(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_contributions_transaction_id ON public.goal_contributions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_goal_contributions_date ON public.goal_contributions(contributed_at);

-- ============================================================================
-- STEP 2: ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE public.bill_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_contributions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 3: CREATE RLS POLICIES (NOW THAT ALL TABLES EXIST)
-- ============================================================================

-- Bill Groups Policies
DROP POLICY IF EXISTS "Users can view groups they are members of" ON public.bill_groups;
CREATE POLICY "Users can view groups they are members of" ON public.bill_groups
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = id
    )
  );

DROP POLICY IF EXISTS "Users can create groups" ON public.bill_groups;
CREATE POLICY "Users can create groups" ON public.bill_groups
  FOR INSERT WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Group creators can update groups" ON public.bill_groups;
CREATE POLICY "Group creators can update groups" ON public.bill_groups
  FOR UPDATE USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Group creators can delete groups" ON public.bill_groups;
CREATE POLICY "Group creators can delete groups" ON public.bill_groups
  FOR DELETE USING (auth.uid() = created_by);

-- Group Members Policies
DROP POLICY IF EXISTS "Users can view group members" ON public.group_members;
CREATE POLICY "Users can view group members" ON public.group_members
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = group_members.group_id
    )
  );

DROP POLICY IF EXISTS "Group admins can add members" ON public.group_members;
CREATE POLICY "Group admins can add members" ON public.group_members
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
    OR
    auth.uid() IN (
      SELECT created_by FROM public.bill_groups WHERE id = group_members.group_id
    )
  );

DROP POLICY IF EXISTS "Group admins can remove members" ON public.group_members;
CREATE POLICY "Group admins can remove members" ON public.group_members
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = group_members.group_id AND role = 'admin'
    )
    OR user_id = auth.uid()
  );

-- Group Expenses Policies
DROP POLICY IF EXISTS "Users can view group expenses" ON public.group_expenses;
CREATE POLICY "Users can view group expenses" ON public.group_expenses
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = group_expenses.group_id
    )
  );

DROP POLICY IF EXISTS "Group members can create expenses" ON public.group_expenses;
CREATE POLICY "Group members can create expenses" ON public.group_expenses
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = group_expenses.group_id
    )
  );

DROP POLICY IF EXISTS "Expense creators can update expenses" ON public.group_expenses;
CREATE POLICY "Expense creators can update expenses" ON public.group_expenses
  FOR UPDATE USING (auth.uid() = paid_by);

DROP POLICY IF EXISTS "Expense creators can delete expenses" ON public.group_expenses;
CREATE POLICY "Expense creators can delete expenses" ON public.group_expenses
  FOR DELETE USING (auth.uid() = paid_by);

-- Expense Splits Policies
DROP POLICY IF EXISTS "Users can view expense splits" ON public.expense_splits;
CREATE POLICY "Users can view expense splits" ON public.expense_splits
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = (SELECT group_id FROM public.group_expenses WHERE id = expense_splits.expense_id)
    )
  );

DROP POLICY IF EXISTS "Group members can create splits" ON public.expense_splits;
CREATE POLICY "Group members can create splits" ON public.expense_splits
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.group_members
      WHERE group_id = (SELECT group_id FROM public.group_expenses WHERE id = expense_splits.expense_id)
    )
  );

DROP POLICY IF EXISTS "Expense creators can update splits" ON public.expense_splits;
CREATE POLICY "Expense creators can update splits" ON public.expense_splits
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT paid_by FROM public.group_expenses WHERE id = expense_splits.expense_id
    )
  );

-- Settlements Policies
DROP POLICY IF EXISTS "Users can view group settlements" ON public.settlements;
CREATE POLICY "Users can view group settlements" ON public.settlements
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = settlements.group_id
    )
  );

DROP POLICY IF EXISTS "Users can create settlements" ON public.settlements;
CREATE POLICY "Users can create settlements" ON public.settlements
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.group_members WHERE group_id = settlements.group_id
    )
    AND (auth.uid() = from_user OR auth.uid() = to_user)
  );

-- Savings Goals Policies
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

-- Goal Contributions Policies
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

-- ============================================================================
-- STEP 4: CREATE FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add creator as admin when group is created
CREATE OR REPLACE FUNCTION add_creator_as_admin()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_group_created ON public.bill_groups;
CREATE TRIGGER on_group_created
  AFTER INSERT ON public.bill_groups
  FOR EACH ROW EXECUTE FUNCTION add_creator_as_admin();

-- Create equal splits automatically
CREATE OR REPLACE FUNCTION create_equal_splits()
RETURNS TRIGGER AS $$
DECLARE
  member_count INTEGER;
  split_amount DECIMAL;
  member_record RECORD;
BEGIN
  IF NEW.split_type = 'equal' THEN
    SELECT COUNT(*) INTO member_count
    FROM public.group_members
    WHERE group_id = NEW.group_id;

    IF member_count > 0 THEN
      split_amount := NEW.amount / member_count;

      FOR member_record IN
        SELECT user_id FROM public.group_members WHERE group_id = NEW.group_id
      LOOP
        INSERT INTO public.expense_splits (expense_id, user_id, amount)
        VALUES (NEW.id, member_record.user_id, split_amount);
      END LOOP;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_expense_created ON public.group_expenses;
CREATE TRIGGER on_expense_created
  AFTER INSERT ON public.group_expenses
  FOR EACH ROW EXECUTE FUNCTION create_equal_splits();

-- Get group balances
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
      user_id,
      COALESCE(SUM(CASE WHEN s.from_user = user_id THEN -s.amount ELSE 0 END), 0) +
      COALESCE(SUM(CASE WHEN s.to_user = user_id THEN s.amount ELSE 0 END), 0) as settlement_amount
    FROM public.group_members gm
    LEFT JOIN public.settlements s ON s.group_id = gm.group_id AND (s.from_user = gm.user_id OR s.to_user = gm.user_id)
    WHERE gm.group_id = p_group_id
    GROUP BY user_id
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

-- Update goal amount when contribution changes
CREATE OR REPLACE FUNCTION update_goal_amount_on_contribution()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.savings_goals
    SET current_amount = current_amount + NEW.amount,
        updated_at = NOW()
    WHERE id = NEW.goal_id;

    UPDATE public.savings_goals
    SET is_completed = TRUE,
        completed_at = NOW()
    WHERE id = NEW.goal_id
      AND current_amount >= target_amount
      AND is_completed = FALSE;

  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.savings_goals
    SET current_amount = current_amount - OLD.amount + NEW.amount,
        updated_at = NOW()
    WHERE id = NEW.goal_id;

    UPDATE public.savings_goals
    SET is_completed = (current_amount >= target_amount),
        completed_at = CASE
          WHEN current_amount >= target_amount THEN COALESCE(completed_at, NOW())
          ELSE NULL
        END
    WHERE id = NEW.goal_id;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.savings_goals
    SET current_amount = GREATEST(current_amount - OLD.amount, 0),
        updated_at = NOW(),
        is_completed = CASE
          WHEN (current_amount - OLD.amount) >= target_amount THEN TRUE
          ELSE FALSE
        END,
        completed_at = CASE
          WHEN (current_amount - OLD.amount) >= target_amount THEN completed_at
          ELSE NULL
        END
    WHERE id = OLD.goal_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_contribution_change ON public.goal_contributions;
CREATE TRIGGER on_contribution_change
  AFTER INSERT OR UPDATE OR DELETE ON public.goal_contributions
  FOR EACH ROW EXECUTE FUNCTION update_goal_amount_on_contribution();

-- Get goal progress percentage
CREATE OR REPLACE FUNCTION get_goal_progress(p_goal_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_progress DECIMAL;
BEGIN
  SELECT
    CASE
      WHEN target_amount > 0 THEN (current_amount / target_amount * 100)
      ELSE 0
    END INTO v_progress
  FROM public.savings_goals
  WHERE id = p_goal_id;

  RETURN COALESCE(v_progress, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get goals summary
CREATE OR REPLACE FUNCTION get_goals_summary()
RETURNS TABLE (
  total_goals INTEGER,
  completed_goals INTEGER,
  active_goals INTEGER,
  total_target DECIMAL,
  total_saved DECIMAL,
  overall_progress DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::INTEGER as total_goals,
    COUNT(*) FILTER (WHERE is_completed = TRUE)::INTEGER as completed_goals,
    COUNT(*) FILTER (WHERE is_completed = FALSE)::INTEGER as active_goals,
    COALESCE(SUM(target_amount), 0)::DECIMAL as total_target,
    COALESCE(SUM(current_amount), 0)::DECIMAL as total_saved,
    CASE
      WHEN COALESCE(SUM(target_amount), 0) > 0
      THEN (COALESCE(SUM(current_amount), 0) / COALESCE(SUM(target_amount), 1) * 100)::DECIMAL
      ELSE 0::DECIMAL
    END as overall_progress
  FROM public.savings_goals
  WHERE user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Updated_at triggers
DROP TRIGGER IF EXISTS update_bill_groups_updated_at ON public.bill_groups;
CREATE TRIGGER update_bill_groups_updated_at
  BEFORE UPDATE ON public.bill_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_group_expenses_updated_at ON public.group_expenses;
CREATE TRIGGER update_group_expenses_updated_at
  BEFORE UPDATE ON public.group_expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_savings_goals_updated_at ON public.savings_goals;
CREATE TRIGGER update_savings_goals_updated_at
  BEFORE UPDATE ON public.savings_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- All tables, policies, functions, and triggers have been created.
-- Bill Splitting and Savings Goals are ready to use!
-- ============================================================================
