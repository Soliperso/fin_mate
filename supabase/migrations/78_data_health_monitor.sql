-- Data health RPC: surfaces integrity issues across user data.
-- Returns one row per check with a count of affected records.
CREATE OR REPLACE FUNCTION admin_get_data_health()
RETURNS TABLE (
  check_name   TEXT,
  description  TEXT,
  issue_count  BIGINT,
  severity     TEXT  -- 'ok' | 'warn' | 'error'
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY

  -- Accounts with no transactions in the last 90 days
  SELECT
    'orphaned_accounts'::TEXT,
    'Accounts with no transactions in 90+ days'::TEXT,
    COUNT(*)::BIGINT,
    CASE WHEN COUNT(*) > 50 THEN 'warn' ELSE 'ok' END::TEXT
  FROM accounts a
  WHERE NOT EXISTS (
    SELECT 1 FROM transactions t
    WHERE t.account_id = a.id
      AND t.date >= NOW() - INTERVAL '90 days'
  )

  UNION ALL

  -- Transactions whose category was deleted (category_id is NULL but type is set)
  SELECT
    'uncategorised_transactions'::TEXT,
    'Transactions with no category assigned'::TEXT,
    COUNT(*)::BIGINT,
    CASE WHEN COUNT(*) > 100 THEN 'warn' ELSE 'ok' END::TEXT
  FROM transactions
  WHERE category_id IS NULL

  UNION ALL

  -- Savings goals with zero contributions
  SELECT
    'goals_no_contributions'::TEXT,
    'Savings goals with no contributions ever'::TEXT,
    COUNT(*)::BIGINT,
    CASE WHEN COUNT(*) > 20 THEN 'warn' ELSE 'ok' END::TEXT
  FROM savings_goals sg
  WHERE NOT EXISTS (
    SELECT 1 FROM goal_contributions gc WHERE gc.goal_id = sg.id
  )

  UNION ALL

  -- Budgets where the limit is exceeded by more than 2x (possible data issue)
  SELECT
    'severely_exceeded_budgets'::TEXT,
    'Budgets exceeded by more than 2× their limit'::TEXT,
    COUNT(*)::BIGINT,
    CASE WHEN COUNT(*) > 10 THEN 'warn' ELSE 'ok' END::TEXT
  FROM budgets b
  WHERE b.amount > 0
    AND (
      SELECT COALESCE(SUM(t.amount), 0)
      FROM transactions t
      WHERE t.category_id = b.category_id
        AND t.user_id = b.user_id
        AND t.type = 'expense'
        AND DATE_TRUNC('month', t.date) = DATE_TRUNC('month', NOW())
    ) > b.amount * 2

  UNION ALL

  -- User profiles missing full_name (indicates incomplete onboarding)
  SELECT
    'incomplete_profiles'::TEXT,
    'User profiles missing a display name'::TEXT,
    COUNT(*)::BIGINT,
    CASE WHEN COUNT(*) > 30 THEN 'warn' ELSE 'ok' END::TEXT
  FROM user_profiles
  WHERE full_name IS NULL OR full_name = ''

  UNION ALL

  -- Debts with no payments logged and created > 30 days ago
  SELECT
    'stale_debts'::TEXT,
    'Debts older than 30 days with no payments recorded'::TEXT,
    COUNT(*)::BIGINT,
    CASE WHEN COUNT(*) > 20 THEN 'warn' ELSE 'ok' END::TEXT
  FROM debts d
  WHERE d.created_at < NOW() - INTERVAL '30 days'
    AND NOT EXISTS (
      SELECT 1 FROM debt_payments dp WHERE dp.debt_id = d.id
    );
END; $$;
