// ============================================================================
// Shared Security Utilities for Supabase Edge Functions
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// ============================================================================
// Environment Variables
// ============================================================================

export const getEnv = (key: string): string => {
  const value = Deno.env.get(key)
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`)
  }
  return value
}

// ============================================================================
// JWT Authentication
// ============================================================================

export interface AuthUser {
  id: string
  email: string
  role: string
}

/**
 * Verify JWT token and extract user information
 * Throws error if token is invalid or missing
 */
export const verifyAuth = async (req: Request): Promise<AuthUser> => {
  // Get authorization header
  const authHeader = req.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header')
  }

  const token = authHeader.replace('Bearer ', '')

  // Create Supabase client with service role for verification
  const supabase = createClient(
    getEnv('SUPABASE_URL'),
    getEnv('SUPABASE_ANON_KEY'),
  )

  // Verify token and get user
  const { data: { user }, error } = await supabase.auth.getUser(token)

  if (error || !user) {
    throw new Error('Invalid or expired token')
  }

  return {
    id: user.id,
    email: user.email || '',
    role: user.role || 'authenticated',
  }
}

/**
 * Verify that the authenticated user matches the requested userId
 * Prevents users from performing actions on behalf of other users
 */
export const verifyUserOwnership = (authUser: AuthUser, requestedUserId: string): void => {
  if (authUser.id !== requestedUserId) {
    throw new Error('Unauthorized: Cannot perform action for another user')
  }
}

// ============================================================================
// Webhook Signature Verification (Stripe)
// ============================================================================

import Stripe from 'https://esm.sh/stripe@14.11.0'

/**
 * Verify Stripe webhook signature to prevent fake webhook attacks
 * This is CRITICAL security - never skip this step!
 */
export const verifyStripeWebhook = async (
  req: Request,
  stripe: Stripe,
): Promise<Stripe.Event> => {
  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    throw new Error('Missing stripe-signature header')
  }

  const webhookSecret = getEnv('STRIPE_WEBHOOK_SECRET')
  const body = await req.text()

  try {
    // Verify signature and construct event
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      webhookSecret,
    )
    return event
  } catch (err) {
    const error = err as Error
    throw new Error(`Webhook signature verification failed: ${error.message}`)
  }
}

// ============================================================================
// Rate Limiting
// ============================================================================

interface RateLimitEntry {
  count: number
  resetAt: number
}

// In-memory rate limit store (resets when function cold-starts)
const rateLimitStore = new Map<string, RateLimitEntry>()

/**
 * Simple rate limiter based on user ID
 * @param userId - User identifier
 * @param maxRequests - Maximum requests allowed in window
 * @param windowMs - Time window in milliseconds
 */
export const checkRateLimit = (
  userId: string,
  maxRequests: number = 10,
  windowMs: number = 60000, // 1 minute default
): void => {
  const now = Date.now()
  const entry = rateLimitStore.get(userId)

  // If no entry or window expired, create new entry
  if (!entry || now > entry.resetAt) {
    rateLimitStore.set(userId, {
      count: 1,
      resetAt: now + windowMs,
    })
    return
  }

  // Increment counter
  entry.count++

  // Check if limit exceeded
  if (entry.count > maxRequests) {
    const resetInSeconds = Math.ceil((entry.resetAt - now) / 1000)
    throw new Error(
      `Rate limit exceeded. Try again in ${resetInSeconds} seconds.`,
    )
  }
}

// ============================================================================
// Input Validation
// ============================================================================

/**
 * Validate that required fields exist in request body
 */
export const validateRequiredFields = (
  body: Record<string, unknown>,
  requiredFields: string[],
): void => {
  const missing = requiredFields.filter((field) => !body[field])
  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`)
  }
}

/**
 * Validate UUID format
 */
export const validateUUID = (uuid: string): void => {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(uuid)) {
    throw new Error(`Invalid UUID format: ${uuid}`)
  }
}

/**
 * Validate Stripe Price ID format
 */
export const validatePriceId = (priceId: string): void => {
  if (!priceId.startsWith('price_')) {
    throw new Error(`Invalid Stripe price ID: ${priceId}`)
  }
}

// ============================================================================
// Secure Response Helpers
// ============================================================================

/**
 * Create standardized JSON response
 */
export const jsonResponse = (
  data: unknown,
  status: number = 200,
): Response => {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      // Security headers
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    },
  })
}

/**
 * Create error response
 */
export const errorResponse = (
  message: string,
  status: number = 400,
): Response => {
  return jsonResponse({ error: message }, status)
}

// ============================================================================
// CORS Headers
// ============================================================================

// CORS headers removed for mobile app - using JWT authentication instead
// Mobile apps don't need CORS headers, only web apps do
export const corsHeaders = {
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

/**
 * Handle CORS preflight requests
 */
export const handleCors = (req: Request): Response | null => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  return null
}

// ============================================================================
// Logging (Secure - no sensitive data)
// ============================================================================

/**
 * Log request information (redact sensitive data)
 */
export const logRequest = (
  functionName: string,
  userId: string | null,
  action: string,
) => {
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      function: functionName,
      userId: userId || 'anonymous',
      action,
    }),
  )
}

/**
 * Log error (redact sensitive data)
 */
export const logError = (
  functionName: string,
  error: Error,
  context?: Record<string, unknown>,
) => {
  console.error(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      function: functionName,
      error: error.message,
      stack: error.stack,
      context: context || {},
    }),
  )
}
