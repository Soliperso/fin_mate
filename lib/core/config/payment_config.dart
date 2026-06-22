/// Payment and subscription configuration
class PaymentConfig {
  // Pricing (displayed in UI, actual prices come from stores)
  static const double monthlyPriceUSD = 9.99;
  static const double annualPriceUSD = 49.99;

  // Free trial configuration
  static const int trialDurationDays = 7;

  // Feature limits
  static const int freemiumAIQueriesLifetime = 10;
  static const int freemiumHistoryMonths = 6; // 6 months of history

  // Premium features list
  static const List<String> premiumFeatures = [
    'Unlimited AI financial insights',
    'Receipt scanning with OCR',
    'Unlimited transaction history',
    'Advanced analytics & trends',
    'Savings goals with AI recommendations',
    'Tax document export',
    'Priority customer support',
    'Early access to new features',
  ];

  // Freemium features list
  static const List<String> freemiumFeatures = [
    'Unlimited transactions & budgets',
    'Multi-account tracking',
    'Basic charts & analytics',
    '10 free AI queries',
    '6 months transaction history',
    'CSV export (last 30 days)',
  ];

  // Offering identifiers (RevenueCat)
  static const String defaultOfferingId = 'default';

  // Annual discount percentage
  static double get annualDiscountPercentage {
    final monthlyYearlyCost = monthlyPriceUSD * 12;
    final discount =
        ((monthlyYearlyCost - annualPriceUSD) / monthlyYearlyCost) * 100;
    return discount;
  }

  // Price per month for annual plan
  static double get annualPricePerMonth {
    return annualPriceUSD / 12;
  }
}
