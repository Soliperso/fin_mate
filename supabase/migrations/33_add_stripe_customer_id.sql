-- ============================================================================
-- Migration 33: Add Stripe customer ID to user_profiles
-- ============================================================================
-- This column stores the Stripe Customer ID for each user, enabling:
-- - Faster Stripe API calls (no need to search by email)
-- - Multiple subscriptions per customer
-- - Customer portal access
-- - Proper webhook handling
-- ============================================================================

-- Add stripe_customer_id column
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

-- Add index for fast lookups (webhooks need to find users by Stripe customer ID)
CREATE INDEX IF NOT EXISTS idx_user_profiles_stripe_customer_id
ON public.user_profiles(stripe_customer_id)
WHERE stripe_customer_id IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.user_profiles.stripe_customer_id IS
'Stripe Customer ID (cus_xxx) for this user. Created when user first subscribes. Used for Stripe API calls and webhook handling.';

-- ============================================================================
-- Migration notes
-- ============================================================================
-- This column is populated automatically when a user:
-- 1. Creates their first checkout session (via create-checkout-session function)
-- 2. Or when a webhook event is received for a new customer
--
-- The stripe_customer_id is used to:
-- - Link Stripe customer data with Supabase user profiles
-- - Enable Stripe Customer Portal access
-- - Process webhook events correctly
-- - Manage subscriptions via Stripe API
-- ============================================================================
