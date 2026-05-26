-- User feedback: users submit bug reports / suggestions from Settings.
-- Admins read all; users can only insert (no read-back of others' feedback).
CREATE TABLE IF NOT EXISTS user_feedback (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  category    TEXT NOT NULL CHECK (category IN ('bug', 'suggestion', 'other')),
  message     TEXT NOT NULL,
  app_version TEXT,
  platform    TEXT,
  reviewed    BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;

-- Users can insert their own feedback
DROP POLICY IF EXISTS "Users can submit feedback" ON user_feedback;
CREATE POLICY "Users can submit feedback"
  ON user_feedback FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Admins can read and update all feedback
DROP POLICY IF EXISTS "Admins can manage feedback" ON user_feedback;
CREATE POLICY "Admins can manage feedback"
  ON user_feedback FOR ALL
  USING (EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Admin RPC: paginated list with optional category filter
CREATE OR REPLACE FUNCTION admin_get_feedback(
  p_category TEXT DEFAULT NULL,
  p_limit    INT  DEFAULT 50,
  p_offset   INT  DEFAULT 0
)
RETURNS TABLE (
  id          UUID,
  user_id     UUID,
  user_email  TEXT,
  category    TEXT,
  message     TEXT,
  app_version TEXT,
  platform    TEXT,
  reviewed    BOOLEAN,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  RETURN QUERY
    SELECT
      f.id, f.user_id,
      u.email AS user_email,
      f.category, f.message, f.app_version, f.platform,
      f.reviewed, f.created_at
    FROM user_feedback f
    LEFT JOIN auth.users u ON u.id = f.user_id
    WHERE (p_category IS NULL OR f.category = p_category)
    ORDER BY f.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;

-- Admin RPC: mark feedback as reviewed / unreviewed
CREATE OR REPLACE FUNCTION admin_set_feedback_reviewed(p_id UUID, p_reviewed BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  UPDATE user_feedback SET reviewed = p_reviewed WHERE id = p_id;
END; $$;
