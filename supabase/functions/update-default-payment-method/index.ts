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

    const { paymentMethodId, action } = await req.json()

    if (!paymentMethodId) {
      throw new Error('Payment method ID is required')
    }

    // Get user profile to get Stripe customer ID
    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single()

    if (!profile?.stripe_customer_id) {
      throw new Error('No Stripe customer found')
    }

    // Handle different actions
    if (action === 'set_default') {
      // Set as default payment method
      await stripe.customers.update(profile.stripe_customer_id, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      })

      return new Response(
        JSON.stringify({ success: true, message: 'Default payment method updated' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    } else if (action === 'detach') {
      // Detach (remove) payment method
      await stripe.paymentMethods.detach(paymentMethodId)

      return new Response(
        JSON.stringify({ success: true, message: 'Payment method removed' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    } else {
      throw new Error('Invalid action. Use "set_default" or "detach"')
    }
  } catch (error) {
    console.error('Error updating payment method:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
