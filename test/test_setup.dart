// Common test setup and utilities

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget for testing with necessary providers and builders
Widget testableWidget(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      body: widget,
    ),
  );
}

/// Creates a material app for testing with custom configuration
Widget createTestApp({
  required Widget home,
  ThemeData? theme,
  Locale? locale,
}) {
  return MaterialApp(
    home: home,
    theme: theme ?? ThemeData.light(),
    locale: locale,
  );
}

/// Common test helper extensions
extension WidgetTesterX on WidgetTester {
  /// Finds text and taps it
  Future<void> tapText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Enters text into a field
  Future<void> enterText(String value) async {
    await typeText(find.byType(TextField), value);
    await pumpAndSettle();
  }

  /// Gets the first matching widget
  T getWidget<T extends Widget>(Finder finder) {
    return widget<T>(finder);
  }

  /// Waits for widget to appear
  Future<void> waitForWidget(Finder finder) async {
    await pumpWidget(Container());
    int counter = 0;
    while (!finder.evaluate().isNotEmpty && counter < 100) {
      await pump(const Duration(milliseconds: 50));
      counter++;
    }
  }
}

/// Mock data for testing
class TestData {
  static final now = DateTime.now();

  static Map<String, dynamic> mockTransaction({
    String id = '1',
    String userId = 'user1',
    String type = 'expense',
    double amount = 50.0,
  }) {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': 'Test Transaction',
      'date': now,
      'createdAt': now,
    };
  }

  static Map<String, dynamic> mockAccount({
    String id = '1',
    String name = 'Test Account',
    double balance = 1000.0,
  }) {
    return {
      'id': id,
      'userId': 'user1',
      'name': name,
      'type': 'checking',
      'balance': balance,
      'currency': 'USD',
      'isActive': true,
      'createdAt': now,
    };
  }

  static Map<String, dynamic> mockUser({
    String id = 'user1',
    String email = 'test@example.com',
  }) {
    return {
      'id': id,
      'email': email,
      'createdAt': now,
    };
  }
}
