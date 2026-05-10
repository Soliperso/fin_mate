import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

/// Service for handling payments and subscriptions via Stripe
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// Your Supabase Edge Function URL for creating payment intents/subscriptions
  /// Example: https://your-project.supabase.co/functions/v1/create-subscription
  String get _functionsUrl {
    // Get Supabase URL from environment config
    final supabaseUrl = EnvConfig.supabaseUrl;
    return '$supabaseUrl/functions/v1';
  }

  /// Initialize Stripe SDK
  Future<void> initialize() async {
    // No-op — Stripe SDK disabled until post-MVP
  }

  /// Create a subscription checkout session
  /// This calls your Supabase Edge Function which creates a Stripe Checkout Session
  Future<String?> createCheckoutSession({
    required String priceId,
    required String userId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/create-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'priceId': priceId,
          'userId': userId,
          'successUrl': successUrl ?? 'https://finmate.app/success',
          'cancelUrl': cancelUrl ?? 'https://finmate.app/cancel',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionUrl = data['url'] as String?;
        return sessionUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Create a payment intent for one-time payments (if needed)
  Future<String?> createPaymentIntent({
    required int amountCents,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'amount': amountCents,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['clientSecret'] as String?;
        return clientSecret;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Stubbed — requires flutter_stripe SDK (post-MVP).
  Future<bool> presentPaymentSheet(String clientSecret) async => false;

  /// Get subscription status from Supabase
  /// This queries your database which is kept in sync via Stripe webhooks
  Future<Map<String, dynamic>?> getSubscriptionStatus(String userId) async {
    try {
      final response =
          await Supabase.instance.client.from('user_profiles').select('''
            subscription_tier,
            subscription_status,
            subscription_start_date,
            subscription_end_date,
            trial_end_date,
            external_subscription_id
          ''').eq('id', userId).maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has active premium subscription
  Future<bool> isPremiumActive(String userId) async {
    try {
      final status = await getSubscriptionStatus(userId);
      if (status == null) return false;

      final tier = status['subscription_tier'] as String?;
      final subscriptionStatus = status['subscription_status'] as String?;
      final endDate = status['subscription_end_date'] as String?;

      // Check if premium and active
      if (tier != 'premium') return false;
      if (subscriptionStatus == 'canceled' || subscriptionStatus == 'expired') {
        return false;
      }

      // Check expiration date
      if (endDate != null) {
        final expirationDate = DateTime.parse(endDate);
        if (expirationDate.isBefore(DateTime.now())) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is in trial period
  Future<bool> isInTrial(String userId) async {
    try {
      final status = await getSubscriptionStatus(userId);
      if (status == null) return false;

      final subscriptionStatus = status['subscription_status'] as String?;
      final trialEndDate = status['trial_end_date'] as String?;

      if (subscriptionStatus != 'trialing') return false;
      if (trialEndDate == null) return false;

      final expirationDate = DateTime.parse(trialEndDate);
      return expirationDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Get days remaining in trial
  Future<int?> getTrialDaysRemaining(String userId) async {
    try {
      final isTrialing = await isInTrial(userId);
      if (!isTrialing) return null;

      final status = await getSubscriptionStatus(userId);
      final trialEndDate = status?['trial_end_date'] as String?;
      if (trialEndDate == null) return null;

      final expirationDate = DateTime.parse(trialEndDate);
      final daysRemaining = expirationDate.difference(DateTime.now()).inDays;
      return daysRemaining > 0 ? daysRemaining : 0;
    } catch (e) {
      return null;
    }
  }

  /// Cancel subscription (calls Supabase Edge Function)
  /// Returns a Map with 'success' (bool) and 'message' (String)
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/cancel-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Subscription canceled successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error'] ?? 'Failed to cancel subscription';

        // Return structured error with helpful message
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  /// Get customer portal URL for managing subscription
  /// Stripe Customer Portal allows users to manage their subscription, payment methods, invoices, etc.
  Future<String?> getCustomerPortalUrl(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/create-portal-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'userId': userId,
          'returnUrl': 'https://finmate.app/settings',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get subscription billing history
  Future<List<Map<String, dynamic>>> getBillingHistory(String userId) async {
    try {
      final events = await Supabase.instance.client
          .from('subscription_events')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(events);
    } catch (e) {
      return [];
    }
  }

  /// Create a SetupIntent for adding payment methods
  /// Returns client secret for Payment Sheet
  Future<Map<String, dynamic>?> createSetupIntent() async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/create-setup-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Present Payment Sheet for adding a payment method
  /// Stubbed — requires flutter_stripe SDK (post-MVP).
  Future<bool> presentPaymentMethodSheet() async => false;

  /// Get all payment methods for the user
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$_functionsUrl/get-payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final methods = data['paymentMethods'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(methods);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/update-default-payment-method'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'paymentMethodId': paymentMethodId,
          'action': 'set_default',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Remove a payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/update-default-payment-method'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'paymentMethodId': paymentMethodId,
          'action': 'detach',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get invoices from Stripe
  Future<List<Map<String, dynamic>>> getInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('$_functionsUrl/get-invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final invoices = data['invoices'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(invoices);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Create subscription and present Payment Sheet (in-app purchase)
  /// Returns true if subscription was created successfully
  /// Stubbed — requires flutter_stripe SDK (post-MVP).
  Future<bool> createSubscriptionWithPaymentSheet(
          {required String priceId}) async =>
      false;
}
