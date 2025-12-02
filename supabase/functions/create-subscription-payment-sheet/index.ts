import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@14.21.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2024-11-20.acacia',
})

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      throw new Error('User not authenticated')
    }

    const { priceId } = await req.json()

    if (!priceId) {
      throw new Error('Price ID is required')
    }

    // Get user profile to check for existing Stripe customer
    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('stripe_customer_id, email, full_name')
      .eq('id', user.id)
      .single()

    let customerId = profile?.stripe_customer_id

    // Create customer if doesn't exist
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email || profile?.email,
        name: profile?.full_name,
        metadata: {
          supabase_user_id: user.id,
        },
      })
      customerId = customer.id

      // Save customer ID to profile
      await supabaseClient
        .from('user_profiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
    }

    // Create subscription with incomplete status (requires payment)
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: {
        payment_method_types: ['card'],
        save_default_payment_method: 'on_subscription',
      },
      expand: ['latest_invoice.payment_intent', 'pending_setup_intent'],
      trial_period_days: 7,
      metadata: {
        supabase_user_id: user.id,
      },
    })

    // Get the payment intent or setup intent client secret
    let clientSecret: string | null = null

    if (subscription.pending_setup_intent && typeof subscription.pending_setup_intent !== 'string') {
      clientSecret = subscription.pending_setup_intent.client_secret
    } else if (subscription.latest_invoice && typeof subscription.latest_invoice !== 'string') {
      const paymentIntent = subscription.latest_invoice.payment_intent
      if (paymentIntent && typeof paymentIntent !== 'string') {
        clientSecret = paymentIntent.client_secret
      }
    }

    if (!clientSecret) {
      throw new Error('No client secret available')
    }

    return new Response(
      JSON.stringify({
        subscriptionId: subscription.id,
        clientSecret: clientSecret,
        customerId: customerId,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error creating subscription:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
