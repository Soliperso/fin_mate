-- App version control: admin sets min supported version per platform.
-- The Flutter client checks on startup and blocks users on outdated builds.
CREATE TABLE IF NOT EXISTS app_versions (
  platform      TEXT PRIMARY KEY CHECK (platform IN ('ios', 'android')),
  min_version   TEXT NOT NULL DEFAULT '1.0.0',
  latest_version TEXT NOT NULL DEFAULT '1.0.0',
  release_notes TEXT,
  force_update  BOOLEAN NOT NULL DEFAULT false,
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_by    TEXT
);

ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Seed default rows so the table is never empty
INSERT INTO app_versions (platform, min_version, latest_version, force_update) VALUES
  ('ios',     '1.0.0', '1.0.0', false),
  ('android', '1.0.0', '1.0.0', false)
ON CONFLICT (platform) DO NOTHING;

-- Public read: any authenticated user can check version requirements
DROP POLICY IF EXISTS "Authenticated users can read app versions" ON app_versions;
CREATE POLICY "Authenticated users can read app versions"
  ON app_versions FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Admin write: only admins can update version settings
DROP POLICY IF EXISTS "Admins can update app versions" ON app_versions;
CREATE POLICY "Admins can update app versions"
  ON app_versions FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Admin RPC: update version settings for a platform
CREATE OR REPLACE FUNCTION admin_set_app_version(
  p_platform       TEXT,
  p_min_version    TEXT,
  p_latest_version TEXT,
  p_release_notes  TEXT,
  p_force_update   BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_email TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  IF p_platform NOT IN ('ios', 'android') THEN
    RAISE EXCEPTION 'platform must be ios or android';
  END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();
  UPDATE app_versions
     SET min_version    = p_min_version,
         latest_version = p_latest_version,
         release_notes  = p_release_notes,
         force_update   = p_force_update,
         updated_at     = NOW(),
         updated_by     = v_email
   WHERE platform = p_platform;
END; $$;
