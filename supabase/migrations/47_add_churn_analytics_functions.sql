-- ============================================================================
-- Migration 47: Add churn and subscription analytics functions
-- ============================================================================

-- ============================================================================
-- Function: get_churn_metrics
-- Returns KPI-level churn and subscription metrics for a date range
-- ============================================================================

CREATE OR REPLACE FUNCTION get_churn_metrics(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  metric_key        TEXT,
  metric_label      TEXT,
  metric_value      NUMERIC,
  metric_change     NUMERIC,  -- absolute change vs previous period
  metric_unit       TEXT      -- 'count', 'percent', 'currency'
) AS $$
DECLARE
  period_days    INTEGER;
  prev_start     DATE;
  prev_end       DATE;
BEGIN
  period_days := (p_end_date - p_start_date);
  prev_start   := p_start_date - period_days;
  prev_end     := p_start_date - INTERVAL '1 day';

  -- ── 1. Active Subscribers ────────────────────────────────────────────────
  RETURN QUERY
  WITH curr AS (
    SELECT COUNT(*) AS val FROM public.user_profiles
    WHERE subscription_tier = 'premium'
      AND subscription_status IN ('active', 'trialing')
  ),
  prev AS (
    -- Approximate: premium users whose subscription started before prev_end
    SELECT COUNT(*) AS val FROM public.user_profiles
    WHERE subscription_tier = 'premium'
      AND subscription_status IN ('active', 'trialing')
      AND (subscription_start_date IS NULL OR subscription_start_date::DATE <= prev_end)
  )
  SELECT
    'active_subscribers'::TEXT,
    'Active Subscribers'::TEXT,
    curr.val::NUMERIC,
    (curr.val - prev.val)::NUMERIC,
    'count'::TEXT
  FROM curr, prev;

  -- ── 2. New Subscriptions (current period) ────────────────────────────────
  RETURN QUERY
  WITH curr AS (
    SELECT COUNT(*) AS val FROM public.subscription_events
    WHERE event_type = 'subscribed'
      AND created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  prev AS (
    SELECT COUNT(*) AS val FROM public.subscription_events
    WHERE event_type = 'subscribed'
      AND created_at::DATE BETWEEN prev_start AND prev_end
  )
  SELECT
    'new_subscriptions'::TEXT,
    'New Subscriptions'::TEXT,
    curr.val::NUMERIC,
    (curr.val - prev.val)::NUMERIC,
    'count'::TEXT
  FROM curr, prev;

  -- ── 3. Cancellations ─────────────────────────────────────────────────────
  RETURN QUERY
  WITH curr AS (
    SELECT COUNT(*) AS val FROM public.subscription_events
    WHERE event_type = 'canceled'
      AND created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  prev AS (
    SELECT COUNT(*) AS val FROM public.subscription_events
    WHERE event_type = 'canceled'
      AND created_at::DATE BETWEEN prev_start AND prev_end
  )
  SELECT
    'cancellations'::TEXT,
    'Cancellations'::TEXT,
    curr.val::NUMERIC,
    (curr.val - prev.val)::NUMERIC,
    'count'::TEXT
  FROM curr, prev;

  -- ── 4. Renewals ──────────────────────────────────────────────────────────
  RETURN QUERY
  WITH curr AS (
    SELECT COUNT(*) AS val FROM public.subscription_events
    WHERE event_type = 'renewed'
      AND created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  prev AS (
    SELECT COUNT(*) AS val FROM public.subscription_events
    WHERE event_type = 'renewed'
      AND created_at::DATE BETWEEN prev_start AND prev_end
  )
  SELECT
    'renewals'::TEXT,
    'Renewals'::TEXT,
    curr.val::NUMERIC,
    (curr.val - prev.val)::NUMERIC,
    'count'::TEXT
  FROM curr, prev;

  -- ── 5. Trial-to-Paid Conversion Rate ─────────────────────────────────────
  RETURN QUERY
  WITH trials AS (
    SELECT COUNT(*) AS started FROM public.subscription_events
    WHERE event_type = 'trial_started'
      AND created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  converted AS (
    SELECT COUNT(*) AS cnt FROM public.subscription_events
    WHERE event_type = 'trial_converted'
      AND created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  prev_trials AS (
    SELECT COUNT(*) AS started FROM public.subscription_events
    WHERE event_type = 'trial_started'
      AND created_at::DATE BETWEEN prev_start AND prev_end
  ),
  prev_converted AS (
    SELECT COUNT(*) AS cnt FROM public.subscription_events
    WHERE event_type = 'trial_converted'
      AND created_at::DATE BETWEEN prev_start AND prev_end
  )
  SELECT
    'trial_conversion_rate'::TEXT,
    'Trial Conversion Rate'::TEXT,
    CASE WHEN trials.started > 0
         THEN ROUND((converted.cnt::NUMERIC / trials.started) * 100, 1)
         ELSE 0 END,
    CASE WHEN trials.started > 0 AND prev_trials.started > 0
         THEN ROUND((converted.cnt::NUMERIC / trials.started) * 100, 1)
              - ROUND((prev_converted.cnt::NUMERIC / prev_trials.started) * 100, 1)
         ELSE 0 END,
    'percent'::TEXT
  FROM trials, converted, prev_trials, prev_converted;

  -- ── 6. Customer Churn Rate ────────────────────────────────────────────────
  RETURN QUERY
  WITH active_start AS (
    SELECT COUNT(*) AS cnt FROM public.user_profiles
    WHERE subscription_tier = 'premium'
      AND (subscription_start_date IS NULL OR subscription_start_date::DATE <= p_start_date)
  ),
  churned AS (
    SELECT COUNT(*) AS cnt FROM public.subscription_events
    WHERE event_type IN ('canceled', 'expired')
      AND created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  prev_active AS (
    SELECT COUNT(*) AS cnt FROM public.user_profiles
    WHERE subscription_tier = 'premium'
      AND (subscription_start_date IS NULL OR subscription_start_date::DATE <= prev_start)
  ),
  prev_churned AS (
    SELECT COUNT(*) AS cnt FROM public.subscription_events
    WHERE event_type IN ('canceled', 'expired')
      AND created_at::DATE BETWEEN prev_start AND prev_end
  )
  SELECT
    'churn_rate'::TEXT,
    'Customer Churn Rate'::TEXT,
    CASE WHEN active_start.cnt > 0
         THEN ROUND((churned.cnt::NUMERIC / active_start.cnt) * 100, 1)
         ELSE 0 END,
    CASE WHEN active_start.cnt > 0 AND prev_active.cnt > 0
         THEN ROUND((churned.cnt::NUMERIC / active_start.cnt) * 100, 1)
              - ROUND((prev_churned.cnt::NUMERIC / prev_active.cnt) * 100, 1)
         ELSE 0 END,
    'percent'::TEXT
  FROM active_start, churned, prev_active, prev_churned;

  -- ── 7. Revenue Churn Rate (same as customer churn since we lack $ amounts) ─
  RETURN QUERY
  WITH active_start AS (
    SELECT COUNT(*) AS cnt FROM public.user_profiles
    WHERE subscription_tier = 'premium'
      AND (subscription_start_date IS NULL OR subscription_start_date::DATE <= p_start_date)
  ),
  lost_revenue_units AS (
    SELECT COALESCE(SUM(se.amount_cents), 0)::NUMERIC AS total
    FROM public.subscription_events se
    WHERE se.event_type IN ('canceled', 'expired')
      AND se.created_at::DATE BETWEEN p_start_date AND p_end_date
  ),
  total_revenue_units AS (
    SELECT COALESCE(SUM(se.amount_cents), 0)::NUMERIC AS total
    FROM public.subscription_events se
    WHERE se.event_type IN ('subscribed', 'renewed')
      AND se.created_at::DATE <= p_end_date
      AND se.subscription_tier = 'premium'
  ),
  prev_lost AS (
    SELECT COALESCE(SUM(se.amount_cents), 0)::NUMERIC AS total
    FROM public.subscription_events se
    WHERE se.event_type IN ('canceled', 'expired')
      AND se.created_at::DATE BETWEEN prev_start AND prev_end
  ),
  prev_total AS (
    SELECT COALESCE(SUM(se.amount_cents), 0)::NUMERIC AS total
    FROM public.subscription_events se
    WHERE se.event_type IN ('subscribed', 'renewed')
      AND se.created_at::DATE <= prev_end
      AND se.subscription_tier = 'premium'
  )
  SELECT
    'revenue_churn_rate'::TEXT,
    'Revenue Churn Rate'::TEXT,
    CASE WHEN total_revenue_units.total > 0
         THEN ROUND((lost_revenue_units.total / total_revenue_units.total) * 100, 1)
         ELSE 0 END,
    CASE WHEN total_revenue_units.total > 0 AND prev_total.total > 0
         THEN ROUND((lost_revenue_units.total / total_revenue_units.total) * 100, 1)
              - ROUND((prev_lost.total / prev_total.total) * 100, 1)
         ELSE 0 END,
    'percent'::TEXT
  FROM lost_revenue_units, total_revenue_units, prev_lost, prev_total;

END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execution to authenticated users (admin guard enforced in app)
GRANT EXECUTE ON FUNCTION get_churn_metrics(DATE, DATE) TO authenticated;

-- ============================================================================
-- Function: get_subscription_cohorts
-- Returns cohort table: signup month × subscription conversion
-- ============================================================================

CREATE OR REPLACE FUNCTION get_subscription_cohorts()
RETURNS TABLE (
  cohort_month       TEXT,    -- e.g. 'Jan 2025'
  cohort_month_date  DATE,    -- for sorting
  total_signups      INTEGER,
  premium_count      INTEGER,
  conversion_rate    NUMERIC  -- percent
) AS $$
BEGIN
  RETURN QUERY
  WITH cohorts AS (
    SELECT
      DATE_TRUNC('month', up.created_at)::DATE AS month_date,
      COUNT(*) AS signups,
      COUNT(*) FILTER (WHERE up.subscription_tier = 'premium') AS premium
    FROM public.user_profiles up
    GROUP BY DATE_TRUNC('month', up.created_at)
    ORDER BY month_date DESC
    LIMIT 12
  )
  SELECT
    TO_CHAR(c.month_date, 'Mon YYYY')::TEXT,
    c.month_date,
    c.signups::INTEGER,
    c.premium::INTEGER,
    CASE WHEN c.signups > 0
         THEN ROUND((c.premium::NUMERIC / c.signups) * 100, 1)
         ELSE 0 END
  FROM cohorts c
  ORDER BY c.month_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION get_subscription_cohorts() TO authenticated;

-- ============================================================================
-- Function: get_subscription_timeline
-- Returns day-by-day subscription event counts for a date range
-- ============================================================================

CREATE OR REPLACE FUNCTION get_subscription_timeline(
  p_start_date DATE,
  p_end_date   DATE
)
RETURNS TABLE (
  period_date    DATE,
  new_subs       INTEGER,
  cancellations  INTEGER,
  renewals       INTEGER,
  trials         INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(p_start_date, p_end_date, '1 day'::INTERVAL)::DATE AS d
  ),
  events AS (
    SELECT
      created_at::DATE AS event_date,
      COUNT(*) FILTER (WHERE event_type = 'subscribed')       AS new_subs,
      COUNT(*) FILTER (WHERE event_type = 'canceled')         AS cancellations,
      COUNT(*) FILTER (WHERE event_type = 'renewed')          AS renewals,
      COUNT(*) FILTER (WHERE event_type = 'trial_started')    AS trials
    FROM public.subscription_events
    WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
    GROUP BY created_at::DATE
  )
  SELECT
    ds.d,
    COALESCE(e.new_subs, 0)::INTEGER,
    COALESCE(e.cancellations, 0)::INTEGER,
    COALESCE(e.renewals, 0)::INTEGER,
    COALESCE(e.trials, 0)::INTEGER
  FROM date_series ds
  LEFT JOIN events e ON e.event_date = ds.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION get_subscription_timeline(DATE, DATE) TO authenticated;
