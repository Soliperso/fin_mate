// ============================================================================
// Supabase Edge Function: Cancel Subscription
// ============================================================================
// Cancels a Stripe subscription
// User retains access until end of billing period
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@14.11.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import {
  verifyAuth,
  verifyUserOwnership,
  checkRateLimit,
  validateRequiredFields,
  validateUUID,
  jsonResponse,
  errorResponse,
  handleCors,
  getEnv,
  logRequest,
  logError,
} from '../_shared/security.ts'

// ============================================================================
// Initialize Stripe
// ============================================================================

const stripe = new Stripe(getEnv('STRIPE_SECRET_KEY'), {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

// ============================================================================
// Main Handler
// ============================================================================

serve(async (req: Request) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  try {
    // Verify authentication
    const authUser = await verifyAuth(req)
    logRequest('cancel-subscription', authUser.id, 'initiated')

    // Rate limiting (3 cancellations per hour to prevent abuse)
    checkRateLimit(authUser.id, 3, 3600000)

    // Parse request
    const body = await req.json()
    validateRequiredFields(body, ['userId'])

    const { userId, immediately } = body
    validateUUID(userId)

    // Verify user ownership
    verifyUserOwnership(authUser, userId)

    // Get user's subscription
    const supabase = createClient(
      getEnv('SUPABASE_URL'),
      getEnv('SUPABASE_SERVICE_ROLE_KEY'),
    )

    const { data: profile } = await supabase
      .from('user_profiles')
      .select('external_subscription_id, subscription_status, subscription_tier, role')
      .eq('id', userId)
      .single()

    // Check if user has premium tier
    if (profile?.subscription_tier !== 'premium') {
      return errorResponse('No premium subscription to cancel', 404)
    }

    // Handle admin users (who may have manual premium without Stripe)
    if (!profile?.external_subscription_id) {
      // Check if this is an admin with manual premium access
      if (profile.role === 'admin') {
        return errorResponse(
          'Admin users cannot cancel their subscription through this endpoint. Contact support.',
          403
        )
      }
      return errorResponse('No active subscription found', 404)
    }

    if (profile.subscription_status === 'canceled' ||
        profile.subscription_status === 'expired') {
      return errorResponse('Subscription is already canceled', 400)
    }

    // Cancel subscription in Stripe
    const subscription = await stripe.subscriptions.update(
      profile.external_subscription_id,
      {
        cancel_at_period_end: !immediately,
        // If immediately = true, subscription ends now
        // If immediately = false (default), user keeps access until period end
      },
    )

    // Update database status
    await supabase
      .from('user_profiles')
      .update({
        subscription_status: 'canceled',
      })
      .eq('id', userId)

    // Log cancellation event
    await supabase.from('subscription_events').insert({
      user_id: userId,
      event_type: 'canceled',
      subscription_tier: 'premium',
      metadata: {
        subscription_id: subscription.id,
        cancel_at_period_end: subscription.cancel_at_period_end,
        ends_at: subscription.current_period_end
          ? new Date(subscription.current_period_end * 1000).toISOString()
          : null,
      },
    })

    logRequest('cancel-subscription', authUser.id, 'success')

    return jsonResponse({
      success: true,
      message: immediately
        ? 'Subscription canceled immediately'
        : `Subscription canceled. Access until ${new Date(subscription.current_period_end * 1000).toLocaleDateString()}`,
      endsAt: subscription.current_period_end
        ? new Date(subscription.current_period_end * 1000).toISOString()
        : null,
    })

  } catch (error) {
    const err = error as Error
    logError('cancel-subscription', err)

    if (err.message.includes('Rate limit')) {
      return errorResponse(err.message, 429)
    }
    if (err.message.includes('Unauthorized') || err.message.includes('Invalid')) {
      return errorResponse(err.message, 401)
    }

    return errorResponse('Failed to cancel subscription', 500)
  }
})
