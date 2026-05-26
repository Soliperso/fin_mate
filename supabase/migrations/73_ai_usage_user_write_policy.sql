-- ============================================================================
-- Migration 73: Allow users to upsert their own AI usage records
-- ============================================================================
-- The ai_usage_tracking table previously only allowed service-role writes.
-- Now that the iOS client tracks query counts locally (SharedPreferences),
-- we add user-level INSERT/UPDATE policies so the app can optionally mirror
-- lifetime query counts back to Supabase for admin analytics.
-- ============================================================================

-- Allow users to insert their own usage records
DROP POLICY IF EXISTS "Users can insert own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can insert own AI usage"
ON public.ai_usage_tracking FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own usage records
DROP POLICY IF EXISTS "Users can update own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can update own AI usage"
ON public.ai_usage_tracking FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Add a lifetime_query_count column for cross-install analytics
-- (populated optionally by the client; does not gate access — SharedPreferences does)
ALTER TABLE public.ai_usage_tracking
ADD COLUMN IF NOT EXISTS lifetime_query_count INTEGER DEFAULT 0;

COMMENT ON COLUMN public.ai_usage_tracking.lifetime_query_count IS
  'Total AI chat queries sent by this user since first install. '
  'Maintained by the client via SharedPreferences; mirrored here for admin analytics.';
