// ============================================================================
// Supabase Edge Function: RevenueCat Webhook Handler
// ============================================================================
// Handles RevenueCat webhook events for subscription lifecycle management.
// RevenueCat is the payment backend for iOS / Android in-app purchases.
//
// Security: RevenueCat sends a shared secret in the Authorization header.
// Set REVENUECAT_WEBHOOK_SECRET in Supabase Dashboard → Edge Functions → Secrets.
// Configure the webhook URL in RevenueCat Dashboard → Project Settings → Webhooks.
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import {
  getEnv,
  jsonResponse,
  errorResponse,
  logRequest,
  logError,
} from '../_shared/security.ts'

// ============================================================================
// Supabase client — service role bypasses RLS so we can update any user
// ============================================================================

const supabase = createClient(
  getEnv('SUPABASE_URL'),
  getEnv('SUPABASE_SERVICE_ROLE_KEY'),
)

// ============================================================================
// RevenueCat event types
// ============================================================================

type RCEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'PRODUCT_CHANGE'
  | 'CANCELLATION'
  | 'UNCANCELLATION'
  | 'EXPIRATION'
  | 'BILLING_ISSUE'
  | 'SUBSCRIBER_ALIAS'
  | 'TRANSFER'

interface RCEvent {
  type: RCEventType
  app_user_id: string
  original_app_user_id: string
  product_id: string
  entitlement_ids: string[] | null
  expiration_at_ms: number | null
  purchased_at_ms: number | null
  period_type: 'TRIAL' | 'NORMAL' | 'INTRO' | null
  store: 'APP_STORE' | 'PLAY_STORE' | 'STRIPE' | 'PROMOTIONAL'
  cancel_reason: string | null
  expiration_reason: string | null
}

interface RCPayload {
  event: RCEvent
  api_version: string
}

// ============================================================================
// Helpers
// ============================================================================

const msToIso = (ms: number | null): string | null =>
  ms ? new Date(ms).toISOString() : null

const updateUserProfile = async (
  userId: string,
  updates: Record<string, unknown>,
) => {
  const { error } = await supabase
    .from('user_profiles')
    .update(updates)
    .eq('id', userId)

  if (error) throw new Error(`Profile update failed: ${error.message}`)
}

const logEvent = async (
  userId: string,
  eventType: string,
  tier: string | null,
  metadata: Record<string, unknown>,
) => {
  // Non-fatal — log error but don't fail the webhook response
  const { error } = await supabase.from('subscription_events').insert({
    user_id: userId,
    event_type: eventType,
    subscription_tier: tier,
    metadata,
    created_at: new Date().toISOString(),
  })
  if (error) console.error('subscription_events insert failed:', error.message)
}

// ============================================================================
// Event handlers
// ============================================================================

const handleInitialPurchase = async (event: RCEvent) => {
  const isTrial = event.period_type === 'TRIAL'
  const endDate = msToIso(event.expiration_at_ms)
  const startDate = msToIso(event.purchased_at_ms)
  const store = event.store === 'APP_STORE' ? 'apple' : 'google'

  await updateUserProfile(event.app_user_id, {
    subscription_tier: 'premium',
    subscription_status: isTrial ? 'trialing' : 'active',
    payment_provider: store,
    subscription_start_date: startDate,
    subscription_end_date: endDate,
    trial_end_date: isTrial ? endDate : null,
  })

  await logEvent(event.app_user_id, 'initial_purchase', 'premium', {
    product_id: event.product_id,
    store: event.store,
    period_type: event.period_type,
  })
}

const handleRenewal = async (event: RCEvent) => {
  const endDate = msToIso(event.expiration_at_ms)

  await updateUserProfile(event.app_user_id, {
    subscription_tier: 'premium',
    subscription_status: 'active',
    subscription_end_date: endDate,
    trial_end_date: null, // trial is over once renewed
  })

  await logEvent(event.app_user_id, 'renewal', 'premium', {
    product_id: event.product_id,
    store: event.store,
  })
}

const handleCancellation = async (event: RCEvent) => {
  // Cancelled but still active until end date — keep tier as premium
  await updateUserProfile(event.app_user_id, {
    subscription_status: 'canceled',
  })

  await logEvent(event.app_user_id, 'cancellation', 'premium', {
    cancel_reason: event.cancel_reason,
    expiration_at_ms: event.expiration_at_ms,
  })
}

const handleUncancellation = async (event: RCEvent) => {
  await updateUserProfile(event.app_user_id, {
    subscription_status: 'active',
  })

  await logEvent(event.app_user_id, 'uncancellation', 'premium', {
    product_id: event.product_id,
  })
}

const handleExpiration = async (event: RCEvent) => {
  await updateUserProfile(event.app_user_id, {
    subscription_tier: 'freemium',
    subscription_status: 'expired',
    subscription_end_date: msToIso(event.expiration_at_ms),
  })

  await logEvent(event.app_user_id, 'expiration', 'freemium', {
    expiration_reason: event.expiration_reason,
    product_id: event.product_id,
  })
}

const handleBillingIssue = async (event: RCEvent) => {
  await updateUserProfile(event.app_user_id, {
    subscription_status: 'past_due',
  })

  await logEvent(event.app_user_id, 'billing_issue', 'premium', {
    product_id: event.product_id,
    store: event.store,
  })
}

const handleProductChange = async (event: RCEvent) => {
  const endDate = msToIso(event.expiration_at_ms)

  await updateUserProfile(event.app_user_id, {
    subscription_end_date: endDate,
  })

  await logEvent(event.app_user_id, 'product_change', 'premium', {
    new_product_id: event.product_id,
  })
}

// ============================================================================
// Main handler
// ============================================================================

serve(async (req: Request) => {
  const FUNCTION_NAME = 'revenuecat-webhook'

  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405)
  }

  // ── Auth: verify shared secret ─────────────────────────────────────────────
  let webhookSecret: string
  try {
    webhookSecret = getEnv('REVENUECAT_WEBHOOK_SECRET')
  } catch {
    logError(FUNCTION_NAME, new Error('REVENUECAT_WEBHOOK_SECRET not configured'))
    return errorResponse('Webhook secret not configured', 500)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader || authHeader !== webhookSecret) {
    return errorResponse('Unauthorized', 401)
  }

  // ── Parse body ─────────────────────────────────────────────────────────────
  let payload: RCPayload
  try {
    payload = await req.json() as RCPayload
  } catch {
    return errorResponse('Invalid JSON body', 400)
  }

  const event = payload?.event
  if (!event?.type || !event?.app_user_id) {
    return errorResponse('Missing event.type or event.app_user_id', 422)
  }

  logRequest(FUNCTION_NAME, event.app_user_id, event.type)

  // ── Route to handler ───────────────────────────────────────────────────────
  try {
    switch (event.type) {
      case 'INITIAL_PURCHASE':
        await handleInitialPurchase(event)
        break
      case 'RENEWAL':
        await handleRenewal(event)
        break
      case 'CANCELLATION':
        await handleCancellation(event)
        break
      case 'UNCANCELLATION':
        await handleUncancellation(event)
        break
      case 'EXPIRATION':
        await handleExpiration(event)
        break
      case 'BILLING_ISSUE':
        await handleBillingIssue(event)
        break
      case 'PRODUCT_CHANGE':
        await handleProductChange(event)
        break
      case 'SUBSCRIBER_ALIAS':
      case 'TRANSFER':
        // No Supabase action needed for alias/transfer events
        break
      default:
        // Unknown event — return 200 so RevenueCat doesn't retry endlessly
        console.warn('Unhandled RevenueCat event type:', event.type)
    }

    return jsonResponse({ received: true })
  } catch (err) {
    const error = err as Error
    logError(FUNCTION_NAME, error, { event_type: event.type, user_id: event.app_user_id })
    // Return 500 so RevenueCat retries (transient DB failures should be retried)
    return errorResponse(`Internal error: ${error.message}`, 500)
  }
})
