-- Add updated_by (audit trail) and rollout_percentage (gradual rollout) to feature_flags.
ALTER TABLE feature_flags
  ADD COLUMN IF NOT EXISTS updated_by        TEXT,
  ADD COLUMN IF NOT EXISTS rollout_percentage INT NOT NULL DEFAULT 100
    CONSTRAINT rollout_pct_range CHECK (rollout_percentage BETWEEN 0 AND 100);

-- Insert missing flags for features already in the app.
-- maintenance_mode is off by default and pinned to the top of the admin list.
INSERT INTO feature_flags (key, name, description, enabled, is_beta) VALUES
  ('maintenance_mode',   'Maintenance Mode',     'Take the app offline for all non-admin users',    false, false),
  ('net_worth_tracking', 'Net Worth Tracking',   'Dashboard net worth card and periodic snapshots',  true,  false),
  ('budget_alerts',      'Budget Alerts',        'Notify users when approaching budget limits',       true,  false),
  ('biometric_login',    'Biometric Login',      'Face ID / Touch ID / fingerprint login',            true,  false),
  ('data_export_json',   'JSON Data Export',     'Export all user data as a JSON archive',            true,  false),
  ('emergency_fund',     'Emergency Fund',       'Emergency fund tracker on the dashboard',           true,  false),
  ('in_app_review',      'In-App Review Prompt', 'App Store / Play Store in-app review prompt',       true,  false)
ON CONFLICT (key) DO NOTHING;

-- Rebuild admin_get_feature_flags to return new columns.
-- maintenance_mode is always sorted first so it is easy to find.
DROP FUNCTION IF EXISTS admin_get_feature_flags();
CREATE FUNCTION admin_get_feature_flags()
RETURNS TABLE (
  key                TEXT,
  name               TEXT,
  description        TEXT,
  enabled            BOOLEAN,
  is_beta            BOOLEAN,
  updated_at         TIMESTAMPTZ,
  updated_by         TEXT,
  rollout_percentage INT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  RETURN QUERY
    SELECT f.key, f.name, f.description, f.enabled, f.is_beta,
           f.updated_at, f.updated_by, f.rollout_percentage
    FROM feature_flags f
    ORDER BY
      CASE WHEN f.key = 'maintenance_mode' THEN 0 ELSE 1 END,
      f.name;
END; $$;

-- admin_set_feature_flag now records which admin made the change.
CREATE OR REPLACE FUNCTION admin_set_feature_flag(p_key TEXT, p_enabled BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_email TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
  UPDATE feature_flags
     SET enabled    = p_enabled,
         updated_at = NOW(),
         updated_by = v_email
   WHERE key = p_key;
END; $$;

-- New: adjust the rollout percentage for a flag (0 = nobody, 100 = everyone).
CREATE OR REPLACE FUNCTION admin_set_rollout_percentage(p_key TEXT, p_pct INT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_email TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  IF p_pct < 0 OR p_pct > 100 THEN
    RAISE EXCEPTION 'rollout_percentage must be 0–100';
  END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
  UPDATE feature_flags
     SET rollout_percentage = p_pct,
         updated_at         = NOW(),
         updated_by         = v_email
   WHERE key = p_key;
END; $$;

-- Public RPC: extend to return rollout_percentage so the client can apply
-- deterministic bucket logic without an extra round-trip.
CREATE OR REPLACE FUNCTION get_feature_flags()
RETURNS TABLE (key TEXT, enabled BOOLEAN, rollout_percentage INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
    SELECT f.key, f.enabled, f.rollout_percentage FROM feature_flags f;
END; $$;
