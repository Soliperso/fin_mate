// ============================================================================
// Supabase Edge Function: Create Stripe Checkout Session
// ============================================================================
// This function creates a Stripe Checkout session for subscription payments
// Security: JWT authentication, rate limiting, input validation
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
  validatePriceId,
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
    // ========================================================================
    // SECURITY STEP 1: Verify JWT Authentication
    // ========================================================================
    const authUser = await verifyAuth(req)
    logRequest('create-checkout-session', authUser.id, 'initiated')

    // ========================================================================
    // SECURITY STEP 2: Rate Limiting (10 requests per minute per user)
    // ========================================================================
    checkRateLimit(authUser.id, 10, 60000)

    // ========================================================================
    // SECURITY STEP 3: Parse and Validate Request Body
    // ========================================================================
    const body = await req.json()

    validateRequiredFields(body, ['priceId', 'userId'])

    const { priceId, userId, successUrl, cancelUrl } = body

    // Validate formats
    validateUUID(userId)
    validatePriceId(priceId)

    // ========================================================================
    // SECURITY STEP 4: Verify User Ownership
    // Ensure authenticated user matches requested userId
    // ========================================================================
    verifyUserOwnership(authUser, userId)

    // ========================================================================
    // SECURITY STEP 5: Verify User Doesn't Already Have Active Subscription
    // ========================================================================
    const supabase = createClient(
      getEnv('SUPABASE_URL'),
      getEnv('SUPABASE_SERVICE_ROLE_KEY'),
    )

    const { data: profile } = await supabase
      .from('user_profiles')
      .select('subscription_tier, subscription_status, external_subscription_id')
      .eq('id', userId)
      .single()

    if (profile?.subscription_tier === 'premium' &&
        profile?.subscription_status === 'active') {
      return errorResponse(
        'User already has an active premium subscription',
        400,
      )
    }

    // ========================================================================
    // Get or Create Stripe Customer
    // ========================================================================
    let customerId = profile?.stripe_customer_id

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: authUser.email,
        metadata: {
          supabase_user_id: userId,
        },
      })
      customerId = customer.id

      // Store customer ID in database
      await supabase
        .from('user_profiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', userId)
    }

    // ========================================================================
    // Create Checkout Session
    // ========================================================================
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: successUrl || `${getEnv('APP_URL')}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl || `${getEnv('APP_URL')}/subscription/cancel`,

      // Enable 7-day free trial
      subscription_data: {
        trial_period_days: 7,
        metadata: {
          supabase_user_id: userId,
        },
      },

      // Allow promotion codes
      allow_promotion_codes: true,

      // Store user ID in session metadata
      client_reference_id: userId,
      metadata: {
        supabase_user_id: userId,
      },

      // Billing settings
      billing_address_collection: 'required',

      // Automatic tax calculation (if enabled in Stripe)
      automatic_tax: {
        enabled: false, // Set to true if you enable Stripe Tax
      },
    })

    // ========================================================================
    // Log Success
    // ========================================================================
    logRequest('create-checkout-session', authUser.id, 'success')

    // Return checkout URL
    return jsonResponse({
      url: session.url,
      sessionId: session.id,
    })

  } catch (error) {
    // ========================================================================
    // Error Handling
    // ========================================================================
    const err = error as Error
    logError('create-checkout-session', err)

    // Return user-friendly error message
    if (err.message.includes('Rate limit')) {
      return errorResponse(err.message, 429)
    }
    if (err.message.includes('Unauthorized') || err.message.includes('Invalid')) {
      return errorResponse(err.message, 401)
    }
    if (err.message.includes('Missing')) {
      return errorResponse(err.message, 400)
    }

    return errorResponse('Failed to create checkout session', 500)
  }
})
