// ============================================================================
// Supabase Edge Function: Stripe Webhook Handler
// ============================================================================
// Handles Stripe webhook events for subscription lifecycle
// CRITICAL SECURITY: Webhook signature verification prevents fake events
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@14.11.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import {
  verifyStripeWebhook,
  jsonResponse,
  errorResponse,
  getEnv,
  logRequest,
  logError,
} from '../_shared/security.ts'

// ============================================================================
// Initialize Stripe and Supabase
// ============================================================================

const stripe = new Stripe(getEnv('STRIPE_SECRET_KEY'), {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabase = createClient(
  getEnv('SUPABASE_URL'),
  getEnv('SUPABASE_SERVICE_ROLE_KEY'), // Service role bypasses RLS
)

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Log subscription event to database for audit trail
 */
const logSubscriptionEvent = async (
  userId: string,
  eventType: string,
  subscriptionTier: string | null,
  metadata: Record<string, unknown> = {},
) => {
  await supabase.from('subscription_events').insert({
    user_id: userId,
    event_type: eventType,
    subscription_tier: subscriptionTier,
    metadata,
    created_at: new Date().toISOString(),
  })
}

/**
 * Update user subscription status in database
 */
const updateSubscriptionStatus = async (
  userId: string,
  updates: {
    subscription_tier?: string
    subscription_status?: string
    subscription_start_date?: string | null
    subscription_end_date?: string | null
    trial_end_date?: string | null
    external_subscription_id?: string | null
    payment_provider?: string
  },
) => {
  const { error } = await supabase
    .from('user_profiles')
    .update(updates)
    .eq('id', userId)

  if (error) {
    throw new Error(`Failed to update user profile: ${error.message}`)
  }
}

/**
 * Get user ID from Stripe subscription metadata
 */
const getUserIdFromSubscription = (subscription: Stripe.Subscription): string => {
  const userId = subscription.metadata?.supabase_user_id
  if (!userId) {
    throw new Error('Missing supabase_user_id in subscription metadata')
  }
  return userId
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * Handle customer.subscription.created
 * User started a subscription (may be in trial)
 */
const handleSubscriptionCreated = async (subscription: Stripe.Subscription) => {
  const userId = getUserIdFromSubscription(subscription)

  const isTrialing = subscription.status === 'trialing'
  const trialEnd = subscription.trial_end
    ? new Date(subscription.trial_end * 1000).toISOString()
    : null

  await updateSubscriptionStatus(userId, {
    subscription_tier: 'premium',
    subscription_status: isTrialing ? 'trialing' : 'active',
    subscription_start_date: new Date(subscription.created * 1000).toISOString(),
    subscription_end_date: new Date(subscription.current_period_end * 1000).toISOString(),
    trial_end_date: trialEnd,
    external_subscription_id: subscription.id,
    payment_provider: 'stripe',
  })

  await logSubscriptionEvent(userId, isTrialing ? 'trial_started' : 'subscribed', 'premium', {
    subscription_id: subscription.id,
    plan: subscription.items.data[0]?.price.id,
    trial_end: trialEnd,
  })

  logRequest('stripe-webhook', userId, 'subscription_created')
}

/**
 * Handle customer.subscription.updated
 * Subscription status changed (trial → active, plan changed, etc.)
 */
const handleSubscriptionUpdated = async (subscription: Stripe.Subscription) => {
  const userId = getUserIdFromSubscription(subscription)

  const status = subscription.status
  const tier = (status === 'active' || status === 'trialing') ? 'premium' : 'freemium'

  await updateSubscriptionStatus(userId, {
    subscription_tier: tier,
    subscription_status: status,
    subscription_end_date: new Date(subscription.current_period_end * 1000).toISOString(),
  })

  await logSubscriptionEvent(userId, 'renewed', tier, {
    subscription_id: subscription.id,
    status,
  })

  logRequest('stripe-webhook', userId, 'subscription_updated')
}

/**
 * Handle customer.subscription.deleted
 * Subscription was canceled and has ended
 */
const handleSubscriptionDeleted = async (subscription: Stripe.Subscription) => {
  const userId = getUserIdFromSubscription(subscription)

  await updateSubscriptionStatus(userId, {
    subscription_tier: 'freemium',
    subscription_status: 'expired',
    subscription_end_date: new Date().toISOString(),
    trial_end_date: null,
  })

  await logSubscriptionEvent(userId, 'expired', 'freemium', {
    subscription_id: subscription.id,
    reason: subscription.cancellation_details?.reason || 'unknown',
  })

  logRequest('stripe-webhook', userId, 'subscription_deleted')
}

/**
 * Handle invoice.payment_succeeded
 * Successful payment (subscription renewal)
 */
const handlePaymentSucceeded = async (invoice: Stripe.Invoice) => {
  const subscriptionId = invoice.subscription as string
  if (!subscriptionId) return

  const subscription = await stripe.subscriptions.retrieve(subscriptionId)
  const userId = getUserIdFromSubscription(subscription)

  await updateSubscriptionStatus(userId, {
    subscription_tier: 'premium',
    subscription_status: 'active',
    subscription_end_date: new Date(subscription.current_period_end * 1000).toISOString(),
  })

  await logSubscriptionEvent(userId, 'renewed', 'premium', {
    subscription_id: subscriptionId,
    invoice_id: invoice.id,
    amount_cents: invoice.amount_paid,
    currency: invoice.currency,
  })

  logRequest('stripe-webhook', userId, 'payment_succeeded')
}

/**
 * Handle invoice.payment_failed
 * Payment failed (credit card declined, etc.)
 */
const handlePaymentFailed = async (invoice: Stripe.Invoice) => {
  const subscriptionId = invoice.subscription as string
  if (!subscriptionId) return

  const subscription = await stripe.subscriptions.retrieve(subscriptionId)
  const userId = getUserIdFromSubscription(subscription)

  await updateSubscriptionStatus(userId, {
    subscription_status: 'past_due',
  })

  await logSubscriptionEvent(userId, 'payment_failed', 'premium', {
    subscription_id: subscriptionId,
    invoice_id: invoice.id,
    attempt_count: invoice.attempt_count,
  })

  logRequest('stripe-webhook', userId, 'payment_failed')
}

/**
 * Handle customer.subscription.trial_will_end
 * Trial will end in 3 days (optional notification)
 */
const handleTrialWillEnd = async (subscription: Stripe.Subscription) => {
  const userId = getUserIdFromSubscription(subscription)

  await logSubscriptionEvent(userId, 'trial_ending_soon', 'premium', {
    subscription_id: subscription.id,
    trial_end: subscription.trial_end
      ? new Date(subscription.trial_end * 1000).toISOString()
      : null,
  })

  logRequest('stripe-webhook', userId, 'trial_will_end')
}

// ============================================================================
// Main Webhook Handler
// ============================================================================

serve(async (req: Request) => {
  try {
    // ========================================================================
    // CRITICAL SECURITY: Verify Webhook Signature
    // This prevents attackers from sending fake webhook events
    // ========================================================================
    const event = await verifyStripeWebhook(req, stripe)

    logRequest('stripe-webhook', null, `event_${event.type}`)

    // ========================================================================
    // Route Event to Appropriate Handler
    // ========================================================================
    switch (event.type) {
      case 'customer.subscription.created':
        await handleSubscriptionCreated(event.data.object as Stripe.Subscription)
        break

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription)
        break

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription)
        break

      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object as Stripe.Invoice)
        break

      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.Invoice)
        break

      case 'customer.subscription.trial_will_end':
        await handleTrialWillEnd(event.data.object as Stripe.Subscription)
        break

      default:
        // Log unhandled events for monitoring
        console.log(`Unhandled event type: ${event.type}`)
    }

    // ========================================================================
    // Return Success Response
    // Stripe expects 200 OK to confirm webhook received
    // ========================================================================
    return jsonResponse({ received: true })

  } catch (error) {
    // ========================================================================
    // Error Handling
    // ========================================================================
    const err = error as Error
    logError('stripe-webhook', err)

    // Return 400 for signature verification failures
    if (err.message.includes('signature')) {
      return errorResponse('Webhook signature verification failed', 400)
    }

    // Return 500 for processing errors (Stripe will retry)
    return errorResponse(err.message, 500)
  }
})
