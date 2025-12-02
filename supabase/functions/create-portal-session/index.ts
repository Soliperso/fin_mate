// ============================================================================
// Supabase Edge Function: Create Stripe Customer Portal Session
// ============================================================================
// Creates a session URL for Stripe Customer Portal where users can:
// - Update payment methods
// - View invoices
// - Cancel subscription
// - Update billing address
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
    logRequest('create-portal-session', authUser.id, 'initiated')

    // Rate limiting (5 requests per minute)
    checkRateLimit(authUser.id, 5, 60000)

    // Parse request
    const body = await req.json()
    validateRequiredFields(body, ['userId'])

    const { userId, returnUrl } = body
    validateUUID(userId)

    // Verify user ownership
    verifyUserOwnership(authUser, userId)

    // Get user's Stripe customer ID
    const supabase = createClient(
      getEnv('SUPABASE_URL'),
      getEnv('SUPABASE_SERVICE_ROLE_KEY'),
    )

    const { data: profile } = await supabase
      .from('user_profiles')
      .select('stripe_customer_id')
      .eq('id', userId)
      .single()

    if (!profile?.stripe_customer_id) {
      return errorResponse('No Stripe customer found. Subscribe first.', 404)
    }

    // Create portal session
    const session = await stripe.billingPortal.sessions.create({
      customer: profile.stripe_customer_id,
      return_url: returnUrl || `${getEnv('APP_URL')}/settings`,
    })

    logRequest('create-portal-session', authUser.id, 'success')

    return jsonResponse({ url: session.url })

  } catch (error) {
    const err = error as Error
    logError('create-portal-session', err)

    if (err.message.includes('Rate limit')) {
      return errorResponse(err.message, 429)
    }
    if (err.message.includes('Unauthorized') || err.message.includes('Invalid')) {
      return errorResponse(err.message, 401)
    }

    return errorResponse('Failed to create portal session', 500)
  }
})
