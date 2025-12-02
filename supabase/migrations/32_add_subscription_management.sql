-- ============================================================================
-- Migration 32: Add subscription lifecycle management
-- ============================================================================

-- Add subscription lifecycle columns to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'active'
CHECK (subscription_status IN ('active', 'trialing', 'canceled', 'expired', 'past_due'));

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS subscription_start_date TIMESTAMPTZ;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS subscription_end_date TIMESTAMPTZ;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS trial_end_date TIMESTAMPTZ;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS payment_provider TEXT DEFAULT 'stripe'
CHECK (payment_provider IN ('stripe', 'apple', 'google') OR payment_provider IS NULL);

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS external_subscription_id TEXT;

-- Create indexes for subscription queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_status ON public.user_profiles(subscription_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_end_date ON public.user_profiles(subscription_end_date);
CREATE INDEX IF NOT EXISTS idx_user_profiles_external_subscription_id ON public.user_profiles(external_subscription_id);

-- ============================================================================
-- Create subscription_events table for audit trail
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  -- Event types: 'trial_started', 'trial_converted', 'trial_expired',
  --              'subscribed', 'renewed', 'canceled', 'expired',
  --              'payment_failed', 'refunded', 'upgraded', 'downgraded'
  subscription_tier TEXT,
  previous_tier TEXT,
  payment_provider TEXT,
  amount_cents INTEGER,
  currency TEXT DEFAULT 'USD',
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_event_type CHECK (event_type IN (
    'trial_started', 'trial_converted', 'trial_expired',
    'subscribed', 'renewed', 'canceled', 'expired',
    'payment_failed', 'refunded', 'upgraded', 'downgraded'
  ))
);

-- Create indexes for event queries
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_id ON public.subscription_events(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_event_type ON public.subscription_events(event_type);
CREATE INDEX IF NOT EXISTS idx_subscription_events_created_at ON public.subscription_events(created_at DESC);

-- Enable RLS on subscription_events
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- Users can view their own subscription events
DROP POLICY IF EXISTS "Users can view own subscription events" ON public.subscription_events;
CREATE POLICY "Users can view own subscription events"
ON public.subscription_events FOR SELECT
USING (auth.uid() = user_id);

-- Service role can insert subscription events (for webhooks)
DROP POLICY IF EXISTS "Service role can insert subscription events" ON public.subscription_events;
CREATE POLICY "Service role can insert subscription events"
ON public.subscription_events FOR INSERT
WITH CHECK (true);

-- ============================================================================
-- Create AI usage tracking table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ai_usage_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month DATE NOT NULL, -- First day of the month
  query_count INTEGER DEFAULT 0,
  tokens_used INTEGER DEFAULT 0,
  cost_cents INTEGER DEFAULT 0, -- Track AI costs
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, month)
);

-- Create index for usage queries
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_month ON public.ai_usage_tracking(user_id, month DESC);

-- Enable RLS on ai_usage_tracking
ALTER TABLE public.ai_usage_tracking ENABLE ROW LEVEL SECURITY;

-- Users can view their own AI usage
DROP POLICY IF EXISTS "Users can view own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can view own AI usage"
ON public.ai_usage_tracking FOR SELECT
USING (auth.uid() = user_id);

-- Service role can manage AI usage (for tracking)
DROP POLICY IF EXISTS "Service role can manage AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Service role can manage AI usage"
ON public.ai_usage_tracking FOR ALL
USING (true)
WITH CHECK (true);

-- ============================================================================
-- Helper function to check if user has active subscription
-- ============================================================================

CREATE OR REPLACE FUNCTION is_subscription_active(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_record RECORD;
BEGIN
  SELECT subscription_tier, subscription_status, subscription_end_date, trial_end_date
  INTO user_record
  FROM public.user_profiles
  WHERE id = user_id;

  -- Premium tier with active or trialing status
  IF user_record.subscription_tier = 'premium' THEN
    -- Check if trial is still active
    IF user_record.subscription_status = 'trialing' THEN
      RETURN user_record.trial_end_date IS NULL OR user_record.trial_end_date > NOW();
    END IF;

    -- Check if subscription is active
    IF user_record.subscription_status = 'active' THEN
      RETURN user_record.subscription_end_date IS NULL OR user_record.subscription_end_date > NOW();
    END IF;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Helper function to get AI query count for current month
-- ============================================================================

CREATE OR REPLACE FUNCTION get_ai_query_count(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  current_month DATE;
  query_count INTEGER;
BEGIN
  current_month := DATE_TRUNC('month', NOW());

  SELECT COALESCE(ai_usage_tracking.query_count, 0)
  INTO query_count
  FROM public.ai_usage_tracking
  WHERE ai_usage_tracking.user_id = get_ai_query_count.user_id
    AND ai_usage_tracking.month = current_month;

  RETURN COALESCE(query_count, 0);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Helper function to increment AI usage
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_ai_usage(
  p_user_id UUID,
  p_tokens INTEGER DEFAULT 0,
  p_cost_cents INTEGER DEFAULT 0
)
RETURNS VOID AS $$
DECLARE
  current_month DATE;
BEGIN
  current_month := DATE_TRUNC('month', NOW());

  INSERT INTO public.ai_usage_tracking (user_id, month, query_count, tokens_used, cost_cents, updated_at)
  VALUES (p_user_id, current_month, 1, p_tokens, p_cost_cents, NOW())
  ON CONFLICT (user_id, month)
  DO UPDATE SET
    query_count = ai_usage_tracking.query_count + 1,
    tokens_used = ai_usage_tracking.tokens_used + p_tokens,
    cost_cents = ai_usage_tracking.cost_cents + p_cost_cents,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Migration notes
-- ============================================================================
-- This migration adds:
-- 1. Subscription lifecycle columns to user_profiles (status, dates, provider, external ID)
-- 2. subscription_events table for complete audit trail
-- 3. ai_usage_tracking table for monthly AI query limits
-- 4. Helper functions for subscription validation and AI usage tracking
-- 5. RLS policies for secure access control
--
-- Usage:
-- - Check if user is premium: SELECT is_user_premium(user_id)
-- - Check if subscription is active: SELECT is_subscription_active(user_id)
-- - Get AI query count: SELECT get_ai_query_count(user_id)
-- - Increment AI usage: SELECT increment_ai_usage(user_id, tokens, cost_cents)
