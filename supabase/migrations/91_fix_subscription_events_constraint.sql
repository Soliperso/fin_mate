-- Migration 91: Fix subscription_events event_type constraint.
-- Migration 32 defined event types matching a Stripe-style naming convention
-- ('trial_started', 'subscribed', 'renewed', etc.). The RevenueCat webhook
-- (supabase/functions/revenuecat-webhook/index.ts) uses RevenueCat's native
-- event names ('initial_purchase', 'renewal', 'cancellation', etc.).
-- This mismatch causes every webhook INSERT to fail the CHECK constraint.

ALTER TABLE public.subscription_events
  DROP CONSTRAINT IF EXISTS valid_event_type;

ALTER TABLE public.subscription_events
  ADD CONSTRAINT valid_event_type CHECK (event_type IN (
    'initial_purchase',
    'renewal',
    'cancellation',
    'uncancellation',
    'expiration',
    'billing_issue',
    'product_change'
  ));