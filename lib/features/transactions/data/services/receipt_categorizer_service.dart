/// Service for automatically categorizing receipts based on merchant and items
class ReceiptCategorizerService {
  /// Category keywords mapping
  static const Map<String, List<String>> _categoryKeywords = {
    'food': [
      'restaurant',
      'cafe',
      'coffee',
      'pizza',
      'burger',
      'diner',
      'bistro',
      'bar',
      'pub',
      'grill',
      'sushi',
      'grocery',
      'supermarket',
      'whole foods',
      'trader joes',
      'safeway',
      'kroger',
      'walmart',
      'costco',
      'food',
      'dining',
      'lunch',
      'breakfast',
      'dinner',
      'delivery',
      'ubereats',
      'doordash',
      'grubhub',
    ],
    'shopping': [
      'mall',
      'store',
      'boutique',
      'amazon',
      'target',
      'walmart',
      'macys',
      'nordstrom',
      'gap',
      'h&m',
      'zara',
      'uniqlo',
      'shop',
      'retail',
      'market',
    ],
    'entertainment': [
      'movie',
      'cinema',
      'theater',
      'theatre',
      'concert',
      'sports',
      'gym',
      'fitness',
      'entertainment',
      'ticket',
      'netflix',
      'spotify',
      'disney',
      'gaming',
      'arcade',
    ],
    'transportation': [
      'gas',
      'fuel',
      'petrol',
      'shell',
      'bp',
      'chevron',
      'uber',
      'lyft',
      'taxi',
      'parking',
      'parking garage',
      'tolls',
      'transit',
      'bus',
      'train',
      'metro',
      'airline',
      'flight',
      'hotel',
      'airbnb',
      'car rental',
    ],
    'utilities': [
      'electric',
      'gas bill',
      'water',
      'internet',
      'phone',
      'mobile',
      'telecom',
      'utility',
      'power',
      'verizon',
      'at&t',
      'comcast',
      'cable',
    ],
    'health': [
      'pharmacy',
      'doctor',
      'hospital',
      'clinic',
      'medical',
      'dental',
      'dentist',
      'cvs',
      'walgreens',
      'health',
      'wellness',
      'gym',
      'yoga',
      'healthcare',
    ],
  };

  /// Suggest a category based on merchant name and items
  static String suggestCategory(String merchant, List<String> items) {
    final searchText = '$merchant ${items.join(' ')}'.toLowerCase();

    // Check each category
    for (final entry in _categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;

      // Check if any keyword is found in the search text
      for (final keyword in keywords) {
        if (searchText.contains(keyword)) {
          return category; // Return capitalized category name
        }
      }
    }

    // Default category if no match found
    return 'other';
  }

  /// Get available categories
  static List<String> getAvailableCategories() {
    return _categoryKeywords.keys.toList();
  }
}
