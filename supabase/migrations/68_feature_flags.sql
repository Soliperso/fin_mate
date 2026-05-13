CREATE TABLE IF NOT EXISTS feature_flags (
  key         TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  enabled     BOOLEAN NOT NULL DEFAULT true,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read feature flags" ON feature_flags;
CREATE POLICY "Admins can read feature flags"
  ON feature_flags FOR SELECT
  USING (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

INSERT INTO feature_flags (key, name, description, enabled) VALUES
  ('receipt_scanner',        'Receipt Scanner',        'ML Kit receipt scanning for transactions', true),
  ('csv_export',             'CSV Export / Import',    'Export and import transactions via CSV', true),
  ('savings_goals',          'Savings Goals',          'Savings goals and contribution tracking', true),
  ('debt_payoff',            'Debt Payoff',            'Avalanche/snowball debt payoff planning', true),
  ('recurring_transactions', 'Recurring Transactions', 'Scheduled and recurring income/expense tracking', true),
  ('ai_insights',            'AI Insights',            'AI-powered financial insights (coming soon)', false),
  ('ads',                    'Ads',                    'Show banner ads to free users', true)
ON CONFLICT (key) DO NOTHING;

DROP FUNCTION IF EXISTS admin_get_feature_flags();
CREATE OR REPLACE FUNCTION admin_get_feature_flags()
RETURNS TABLE (key TEXT, name TEXT, description TEXT, enabled BOOLEAN, updated_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  RETURN QUERY
    SELECT f.key, f.name, f.description, f.enabled, f.updated_at
    FROM feature_flags f ORDER BY f.name;
END; $$;

CREATE OR REPLACE FUNCTION admin_set_feature_flag(p_key TEXT, p_enabled BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  UPDATE feature_flags SET enabled = p_enabled, updated_at = NOW() WHERE key = p_key;
END; $$;
