-- Migration: Create Analytics Events Table
-- Description: Track user events and app usage for analytics
-- Created: 2025-10-15

-- ============================================================================
-- Analytics Events Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  event_properties JSONB DEFAULT '{}'::jsonb,
  screen_name TEXT,
  session_id TEXT,
  platform TEXT, -- 'ios', 'android', 'web'
  app_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Index for querying by user
CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);

-- Index for querying by event name
CREATE INDEX idx_analytics_event_name ON analytics_events(event_name);

-- Index for querying by date (most common query)
CREATE INDEX idx_analytics_created_at ON analytics_events(created_at DESC);

-- Composite index for user + date queries
CREATE INDEX idx_analytics_user_date ON analytics_events(user_id, created_at DESC);

-- Index for screen analytics
CREATE INDEX idx_analytics_screen ON analytics_events(screen_name) WHERE screen_name IS NOT NULL;

-- GIN index for JSONB properties (for filtering by properties)
CREATE INDEX idx_analytics_properties ON analytics_events USING GIN (event_properties);

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Users can insert their own analytics events
CREATE POLICY analytics_insert_own
  ON analytics_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Only admins can view analytics data
CREATE POLICY analytics_select_admin
  ON analytics_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Admins can delete old analytics data
CREATE POLICY analytics_delete_admin
  ON analytics_events FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- ============================================================================
-- Analytics Query Functions
-- ============================================================================

-- Get event summary (count by event name)
CREATE OR REPLACE FUNCTION get_event_summary(
  start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  event_name TEXT,
  event_count BIGINT,
  unique_users BIGINT,
  first_occurrence TIMESTAMPTZ,
  last_occurrence TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ae.event_name,
    COUNT(*) as event_count,
    COUNT(DISTINCT ae.user_id) as unique_users,
    MIN(ae.created_at) as first_occurrence,
    MAX(ae.created_at) as last_occurrence
  FROM analytics_events ae
  WHERE ae.created_at BETWEEN start_date AND end_date
  GROUP BY ae.event_name
  ORDER BY event_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get daily active users (DAU)
CREATE OR REPLACE FUNCTION get_daily_active_users(
  start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  date DATE,
  active_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    DATE(ae.created_at) as date,
    COUNT(DISTINCT ae.user_id) as active_users
  FROM analytics_events ae
  WHERE DATE(ae.created_at) BETWEEN start_date AND end_date
  GROUP BY DATE(ae.created_at)
  ORDER BY date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get most popular screens
CREATE OR REPLACE FUNCTION get_popular_screens(
  start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  end_date TIMESTAMPTZ DEFAULT NOW(),
  limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
  screen_name TEXT,
  view_count BIGINT,
  unique_viewers BIGINT,
  avg_session_duration INTERVAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ae.screen_name,
    COUNT(*) as view_count,
    COUNT(DISTINCT ae.user_id) as unique_viewers,
    INTERVAL '0' as avg_session_duration -- Placeholder for now
  FROM analytics_events ae
  WHERE ae.screen_name IS NOT NULL
    AND ae.created_at BETWEEN start_date AND end_date
  GROUP BY ae.screen_name
  ORDER BY view_count DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user funnel (conversion rates)
CREATE OR REPLACE FUNCTION get_user_funnel(
  start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  step_name TEXT,
  user_count BIGINT,
  conversion_rate NUMERIC
) AS $$
DECLARE
  total_users BIGINT;
BEGIN
  -- Get total unique users in period
  SELECT COUNT(DISTINCT user_id) INTO total_users
  FROM analytics_events
  WHERE created_at BETWEEN start_date AND end_date;

  RETURN QUERY
  WITH funnel_steps AS (
    SELECT 'Signed Up' as step, COUNT(DISTINCT user_id) as users
    FROM analytics_events
    WHERE event_name = 'user_signed_up'
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Added Transaction', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name = 'transaction_created'
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Created Budget', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name = 'budget_created'
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Created Savings Goal', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name = 'goal_created'
      AND created_at BETWEEN start_date AND end_date
  )
  SELECT
    fs.step as step_name,
    fs.users as user_count,
    CASE
      WHEN total_users > 0 THEN ROUND((fs.users::NUMERIC / total_users) * 100, 2)
      ELSE 0
    END as conversion_rate
  FROM funnel_steps fs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get retention cohorts
CREATE OR REPLACE FUNCTION get_retention_cohort(
  cohort_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days'
)
RETURNS TABLE (
  days_since_signup INTEGER,
  retained_users BIGINT,
  retention_rate NUMERIC
) AS $$
DECLARE
  cohort_size BIGINT;
BEGIN
  -- Get cohort size (users who signed up on cohort_date)
  SELECT COUNT(DISTINCT user_id) INTO cohort_size
  FROM analytics_events
  WHERE event_name = 'user_signed_up'
    AND DATE(created_at) = cohort_date;

  RETURN QUERY
  WITH cohort_users AS (
    SELECT DISTINCT user_id
    FROM analytics_events
    WHERE event_name = 'user_signed_up'
      AND DATE(created_at) = cohort_date
  ),
  daily_activity AS (
    SELECT
      cu.user_id,
      DATE(ae.created_at) - cohort_date as days_since_signup
    FROM cohort_users cu
    INNER JOIN analytics_events ae ON cu.user_id = ae.user_id
    WHERE DATE(ae.created_at) >= cohort_date
  )
  SELECT
    da.days_since_signup::INTEGER,
    COUNT(DISTINCT da.user_id) as retained_users,
    CASE
      WHEN cohort_size > 0 THEN ROUND((COUNT(DISTINCT da.user_id)::NUMERIC / cohort_size) * 100, 2)
      ELSE 0
    END as retention_rate
  FROM daily_activity da
  GROUP BY da.days_since_signup
  ORDER BY da.days_since_signup;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get feature adoption rates
CREATE OR REPLACE FUNCTION get_feature_adoption(
  start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  feature_name TEXT,
  users_adopted BIGINT,
  total_users BIGINT,
  adoption_rate NUMERIC
) AS $$
DECLARE
  total_active_users BIGINT;
BEGIN
  -- Get total active users in period
  SELECT COUNT(DISTINCT user_id) INTO total_active_users
  FROM analytics_events
  WHERE created_at BETWEEN start_date AND end_date;

  RETURN QUERY
  WITH feature_usage AS (
    SELECT 'Transactions' as feature, COUNT(DISTINCT user_id) as users
    FROM analytics_events
    WHERE event_name IN ('transaction_created', 'transaction_updated')
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Budgets', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name IN ('budget_created', 'budget_updated')
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Bill Splitting', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name IN ('group_created', 'settlement_recorded')
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Savings Goals', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name IN ('goal_created', 'contribution_added')
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'AI Insights', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name = 'ai_query'
      AND created_at BETWEEN start_date AND end_date

    UNION ALL

    SELECT 'Documents', COUNT(DISTINCT user_id)
    FROM analytics_events
    WHERE event_name = 'document_uploaded'
      AND created_at BETWEEN start_date AND end_date
  )
  SELECT
    fu.feature as feature_name,
    fu.users as users_adopted,
    total_active_users as total_users,
    CASE
      WHEN total_active_users > 0 THEN ROUND((fu.users::NUMERIC / total_active_users) * 100, 2)
      ELSE 0
    END as adoption_rate
  FROM feature_usage fu
  ORDER BY adoption_rate DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Data Cleanup (Optional - keep data for 90 days)
-- ============================================================================

-- Create function to clean old analytics data
CREATE OR REPLACE FUNCTION cleanup_old_analytics()
RETURNS void AS $$
BEGIN
  DELETE FROM analytics_events
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Optional: Create a cron job to run cleanup weekly
-- (Requires pg_cron extension - enable in Supabase dashboard if needed)
-- SELECT cron.schedule(
--   'cleanup-analytics',
--   '0 0 * * 0', -- Every Sunday at midnight
--   'SELECT cleanup_old_analytics();'
-- );

-- ============================================================================
-- Grant Permissions
-- ============================================================================

-- Grant execute on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_event_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_active_users TO authenticated;
GRANT EXECUTE ON FUNCTION get_popular_screens TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_funnel TO authenticated;
GRANT EXECUTE ON FUNCTION get_retention_cohort TO authenticated;
GRANT EXECUTE ON FUNCTION get_feature_adoption TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_analytics TO authenticated;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE analytics_events IS 'Stores user analytics events for tracking app usage and behavior';
COMMENT ON COLUMN analytics_events.event_name IS 'Name of the event (e.g., transaction_created, user_signed_up)';
COMMENT ON COLUMN analytics_events.event_properties IS 'Additional data about the event in JSON format';
COMMENT ON COLUMN analytics_events.session_id IS 'Session identifier to group related events';
COMMENT ON COLUMN analytics_events.platform IS 'Platform where event occurred (ios, android, web)';

COMMENT ON FUNCTION get_event_summary IS 'Get summary of all events with counts and unique users';
COMMENT ON FUNCTION get_daily_active_users IS 'Get daily active user counts over a date range';
COMMENT ON FUNCTION get_popular_screens IS 'Get most viewed screens with visitor counts';
COMMENT ON FUNCTION get_user_funnel IS 'Get user conversion funnel showing drop-off at each step';
COMMENT ON FUNCTION get_retention_cohort IS 'Get retention rates for a signup cohort';
COMMENT ON FUNCTION get_feature_adoption IS 'Get adoption rates for each major feature';
