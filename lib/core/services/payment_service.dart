import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

/// Service for handling payments and subscriptions via Stripe
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _logger = Logger();
  bool _isInitialized = false;

  /// Your Supabase Edge Function URL for creating payment intents/subscriptions
  /// Example: https://your-project.supabase.co/functions/v1/create-subscription
  String get _functionsUrl {
    // Get Supabase URL from environment config
    final supabaseUrl = EnvConfig.supabaseUrl;
    return '$supabaseUrl/functions/v1';
  }

  /// Initialize Stripe SDK
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.i('Stripe already initialized');
      return;
    }

    try {
      Stripe.publishableKey = EnvConfig.stripePublishableKey;

      // Merchant identifier removed - Apple Pay disabled for beta testing
      // When enabling Apple Pay, set: Stripe.merchantIdentifier = 'merchant.com.finmate.app';

      await Stripe.instance.applySettings();

      _isInitialized = true;
      _logger.i('Stripe initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Stripe: $e');
      rethrow;
    }
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
      _logger.i('Creating checkout session for price: $priceId');

      final response = await http.post(
        Uri.parse('$_functionsUrl/create-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
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
        _logger.i('Checkout session created successfully');
        return sessionUrl;
      } else {
        _logger.e('Failed to create checkout session: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating checkout session: $e');
      return null;
    }
  }

  /// Create a payment intent for one-time payments (if needed)
  Future<String?> createPaymentIntent({
    required int amountCents,
    required String currency,
  }) async {
    try {
      _logger.i('Creating payment intent for amount: $amountCents $currency');

      final response = await http.post(
        Uri.parse('$_functionsUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'amount': amountCents,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['clientSecret'] as String?;
        _logger.i('Payment intent created successfully');
        return clientSecret;
      } else {
        _logger.e('Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating payment intent: $e');
      return null;
    }
  }

  /// Process a payment with the payment sheet
  Future<bool> presentPaymentSheet(String clientSecret) async {
    try {
      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'FinMate',
          style: ThemeMode.system,
          // Optional: Enable Apple Pay / Google Pay
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            testEnv: kDebugMode,
          ),
          // Apple Pay disabled for beta testing (requires Apple Developer merchant ID)
          // applePay: const PaymentSheetApplePay(
          //   merchantCountryCode: 'US',
          // ),
        ),
      );

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      _logger.i('Payment completed successfully');
      return true;
    } catch (e) {
      if (e is StripeException) {
        _logger.e('Stripe error: ${e.error.localizedMessage}');
      } else {
        _logger.e('Payment failed: $e');
      }
      return false;
    }
  }

  /// Get subscription status from Supabase
  /// This queries your database which is kept in sync via Stripe webhooks
  Future<Map<String, dynamic>?> getSubscriptionStatus(String userId) async {
    try {
      _logger.i('🔍 Fetching subscription status for user: $userId');
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('''
            subscription_tier,
            subscription_status,
            subscription_start_date,
            subscription_end_date,
            trial_end_date,
            external_subscription_id
          ''')
          .eq('id', userId)
          .maybeSingle();

      _logger.i('✅ Subscription status fetched: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e('❌ Error fetching subscription status: $e');
      _logger.e('Stack trace: $stackTrace');
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
      _logger.e('Error checking premium status: $e');
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
      _logger.e('Error checking trial status: $e');
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
      _logger.e('Error getting trial days: $e');
      return null;
    }
  }

  /// Cancel subscription (calls Supabase Edge Function)
  /// Returns a Map with 'success' (bool) and 'message' (String)
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    try {
      _logger.i('Canceling subscription for user: $userId');

      final response = await http.post(
        Uri.parse('$_functionsUrl/cancel-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        _logger.i('Subscription canceled successfully');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Subscription canceled successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to cancel subscription';

        _logger.e('Failed to cancel subscription: $errorMessage');

        // Return structured error with helpful message
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logger.e('Error canceling subscription: $e');
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
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
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
        _logger.e('Failed to create portal session: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating portal session: $e');
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
      _logger.e('Error fetching billing history: $e');
      return [];
    }
  }

  /// Create a SetupIntent for adding payment methods
  /// Returns client secret for Payment Sheet
  Future<Map<String, dynamic>?> createSetupIntent() async {
    try {
      _logger.i('Creating setup intent for adding payment method');

      final response = await http.post(
        Uri.parse('$_functionsUrl/create-setup-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Setup intent created successfully');
        return data;
      } else {
        _logger.e('Failed to create setup intent: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating setup intent: $e');
      return null;
    }
  }

  /// Present Payment Sheet for adding a payment method
  Future<bool> presentPaymentMethodSheet() async {
    try {
      // Create setup intent
      final setupData = await createSetupIntent();
      if (setupData == null || setupData['clientSecret'] == null) {
        _logger.e('Failed to get setup intent');
        return false;
      }

      // Initialize the payment sheet for setup
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: setupData['clientSecret'],
          merchantDisplayName: 'FinMate',
          style: ThemeMode.system,
          customerId: setupData['customerId'],
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
          ),
          // Apple Pay disabled for beta testing (requires Apple Developer merchant ID)
          // applePay: const PaymentSheetApplePay(
          //   merchantCountryCode: 'US',
          // ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            testEnv: kDebugMode,
          ),
        ),
      );

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      _logger.i('Payment method added successfully');
      return true;
    } catch (e) {
      if (e is StripeException) {
        _logger.e('Stripe error: ${e.error.localizedMessage}');
      } else {
        _logger.e('Failed to add payment method: $e');
      }
      return false;
    }
  }

  /// Get all payment methods for the user
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      _logger.i('Fetching payment methods');

      final response = await http.get(
        Uri.parse('$_functionsUrl/get-payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final methods = data['paymentMethods'] as List<dynamic>;
        _logger.i('Fetched ${methods.length} payment methods');
        return List<Map<String, dynamic>>.from(methods);
      } else {
        _logger.e('Failed to fetch payment methods: ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching payment methods: $e');
      return [];
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      _logger.i('Setting default payment method: $paymentMethodId');

      final response = await http.post(
        Uri.parse('$_functionsUrl/update-default-payment-method'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'paymentMethodId': paymentMethodId,
          'action': 'set_default',
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('Default payment method updated successfully');
        return true;
      } else {
        _logger.e('Failed to update default payment method: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating default payment method: $e');
      return false;
    }
  }

  /// Remove a payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      _logger.i('Removing payment method: $paymentMethodId');

      final response = await http.post(
        Uri.parse('$_functionsUrl/update-default-payment-method'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'paymentMethodId': paymentMethodId,
          'action': 'detach',
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('Payment method removed successfully');
        return true;
      } else {
        _logger.e('Failed to remove payment method: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error removing payment method: $e');
      return false;
    }
  }

  /// Get invoices from Stripe
  Future<List<Map<String, dynamic>>> getInvoices() async {
    try {
      _logger.i('Fetching invoices');

      final response = await http.get(
        Uri.parse('$_functionsUrl/get-invoices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final invoices = data['invoices'] as List<dynamic>;
        _logger.i('Fetched ${invoices.length} invoices');
        return List<Map<String, dynamic>>.from(invoices);
      } else {
        _logger.e('Failed to fetch invoices: ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching invoices: $e');
      return [];
    }
  }

  /// Create subscription and present Payment Sheet (in-app purchase)
  /// Returns true if subscription was created successfully
  Future<bool> createSubscriptionWithPaymentSheet({
    required String priceId,
  }) async {
    try {
      _logger.i('Creating subscription with Payment Sheet for price: $priceId');

      // Create subscription via Edge Function
      final response = await http.post(
        Uri.parse('$_functionsUrl/create-subscription-payment-sheet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'priceId': priceId,
        }),
      );

      if (response.statusCode != 200) {
        _logger.e('Failed to create subscription: ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'] as String?;
      final customerId = data['customerId'] as String?;

      if (clientSecret == null) {
        _logger.e('No client secret returned');
        return false;
      }

      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'FinMate',
          style: ThemeMode.system,
          customerId: customerId,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
          ),
          // Apple Pay disabled for beta testing (requires Apple Developer merchant ID)
          // applePay: const PaymentSheetApplePay(
          //   merchantCountryCode: 'US',
          // ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            testEnv: kDebugMode,
          ),
        ),
      );

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      _logger.i('Subscription created successfully');
      return true;
    } catch (e) {
      if (e is StripeException) {
        _logger.e('Stripe error: ${e.error.localizedMessage}');
      } else {
        _logger.e('Error creating subscription: $e');
      }
      return false;
    }
  }
}
