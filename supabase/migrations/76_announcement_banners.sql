-- Announcement banners: admin can push dismissible strips to users' dashboards.
CREATE TABLE IF NOT EXISTS announcements (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title          TEXT NOT NULL,
  message        TEXT NOT NULL,
  cta_label      TEXT,
  cta_url        TEXT,
  active         BOOLEAN NOT NULL DEFAULT true,
  starts_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  created_by     TEXT,
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read active announcements (needed for dashboard).
DROP POLICY IF EXISTS "Authenticated users can read announcements" ON announcements;
CREATE POLICY "Authenticated users can read announcements"
  ON announcements FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only admins can insert / update / delete.
DROP POLICY IF EXISTS "Admins can manage announcements" ON announcements;
CREATE POLICY "Admins can manage announcements"
  ON announcements FOR ALL
  USING (EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Public RPC: returns banners that are currently active and within their time window.
CREATE OR REPLACE FUNCTION get_active_announcements()
RETURNS TABLE (id UUID, title TEXT, message TEXT, cta_label TEXT, cta_url TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
    SELECT a.id, a.title, a.message, a.cta_label, a.cta_url
    FROM announcements a
    WHERE a.active = true
      AND a.starts_at <= NOW()
      AND (a.ends_at IS NULL OR a.ends_at > NOW())
    ORDER BY a.created_at DESC;
END; $$;
