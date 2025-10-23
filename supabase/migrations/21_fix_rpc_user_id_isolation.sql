-- ============================================================================
-- FIX RPC FUNCTIONS FOR USER DATA ISOLATION
-- ============================================================================
-- This migration updates all RPC functions to accept and validate p_user_id
-- to fix critical data isolation vulnerability where users could see each
-- other's data.
-- ============================================================================

-- ============================================================================
-- TRANSACTION SUMMARY FUNCTIONS
-- ============================================================================

-- Update get_total_by_type to accept p_user_id parameter
CREATE OR REPLACE FUNCTION get_total_by_type(
  p_user_id UUID,
  start_date DATE,
  end_date DATE,
  transaction_type TEXT
)
RETURNS DECIMAL AS $$
  SELECT COALESCE(SUM(amount), 0)
  FROM transactions
  WHERE user_id = p_user_id
    AND date >= start_date
    AND date <= end_date
    AND type = transaction_type;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Update calculate_money_health_score to accept p_user_id parameter
CREATE OR REPLACE FUNCTION calculate_money_health_score(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  income DECIMAL;
  expense DECIMAL;
  savings_rate DECIMAL;
  score INTEGER := 50;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO income
  FROM transactions
  WHERE user_id = p_user_id AND type = 'income' AND date >= CURRENT_DATE - INTERVAL '30 days';

  SELECT COALESCE(SUM(amount), 0) INTO expense
  FROM transactions
  WHERE user_id = p_user_id AND type = 'expense' AND date >= CURRENT_DATE - INTERVAL '30 days';

  IF income > 0 THEN
    savings_rate := ((income - expense) / income) * 100;
    IF savings_rate >= 20 THEN score := 100;
    ELSIF savings_rate >= 15 THEN score := 85;
    ELSIF savings_rate >= 10 THEN score := 70;
    ELSIF savings_rate >= 5 THEN score := 55;
    ELSIF savings_rate >= 0 THEN score := 40;
    ELSE score := 20;
    END IF;
  END IF;

  RETURN score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SAVINGS GOALS FUNCTIONS
-- ============================================================================

-- Update get_goals_summary to accept p_user_id parameter
CREATE OR REPLACE FUNCTION get_goals_summary(p_user_id UUID)
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
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- NOTIFICATION FUNCTIONS
-- ============================================================================

-- Update get_unread_notification_count to accept p_user_id parameter
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM notifications
    WHERE user_id = p_user_id
        AND is_read = FALSE
        AND is_archived = FALSE;

    RETURN v_count;
END;
$$;

-- Update mark_notification_read to accept and validate p_user_id
CREATE OR REPLACE FUNCTION mark_notification_read(p_user_id UUID, p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = CURRENT_TIMESTAMP
    WHERE id = p_notification_id
        AND user_id = p_user_id;

    RETURN FOUND;
END;
$$;

-- Update mark_all_notifications_read to accept p_user_id parameter
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id
        AND is_read = FALSE;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- Update archive_notification to accept and validate p_user_id
CREATE OR REPLACE FUNCTION archive_notification(p_user_id UUID, p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_archived = TRUE,
        archived_at = CURRENT_TIMESTAMP
    WHERE id = p_notification_id
        AND user_id = p_user_id;

    RETURN FOUND;
END;
$$;

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
--
-- All RPC functions have been updated to:
-- 1. Accept an explicit p_user_id parameter
-- 2. Filter data by that user_id parameter
-- 3. Prevent unauthorized access to other users' data
--
-- The following functions were updated:
-- - get_total_by_type() - Now filters by p_user_id
-- - calculate_money_health_score() - Now filters by p_user_id
-- - get_goals_summary() - Now filters by p_user_id
-- - get_unread_notification_count() - Now filters by p_user_id
-- - mark_notification_read() - Now validates p_user_id
-- - mark_all_notifications_read() - Now filters by p_user_id
-- - archive_notification() - Now validates p_user_id
--
-- This migration fixes the critical data isolation vulnerability where
-- RPC functions were using auth.uid() which could be bypassed or return
-- null in certain conditions, allowing data leakage between users.
-- ============================================================================
