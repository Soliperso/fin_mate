# FinMate Testing Guide

## Overview
FinMate includes comprehensive unit, widget, and integration tests to ensure code quality and functionality.

## Test Structure

```
test/
├── unit/                    # Unit tests
│   ├── entities/           # Entity tests
│   │   ├── transaction_entity_test.dart
│   │   └── account_entity_test.dart
│   └── utils/              # Utility function tests
│       └── currency_formatter_test.dart
├── widget/                  # Widget/UI tests
│   ├── widgets/            # Widget component tests
│   │   └── password_strength_indicator_test.dart
│   └── pages/              # Page/screen tests
│       └── splash_page_test.dart
├── integration/            # Integration tests
│   ├── auth_flow_test.dart
│   ├── transaction_flow_test.dart
│   └── ...
├── test_setup.dart        # Common test utilities and mocks
└── golden_test.dart       # Golden/screenshot tests configuration
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

Generate coverage report (requires `lcov`):
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Specific Test File
```bash
flutter test test/unit/entities/transaction_entity_test.dart
```

### Run Tests Matching Pattern
```bash
flutter test --name="TransactionEntity"
```

### Run Tests in Watch Mode
```bash
flutter test --watch
```

### Run Widget Tests Only
```bash
flutter test test/widget/
```

### Run Unit Tests Only
```bash
flutter test test/unit/
```

### Run Integration Tests Only
```bash
flutter test test/integration/
```

## Test Categories

### 1. Unit Tests (`test/unit/`)
Test individual functions, methods, and classes in isolation.

**Examples:**
- Entity creation and copying
- Formatting functions
- Business logic calculations

**Benefits:**
- Fast execution
- Easy to debug
- High coverage possible

### 2. Widget Tests (`test/widget/`)
Test UI components and user interactions.

**Examples:**
- Password strength indicator display
- Form validation
- Button interactions
- Navigation

**Benefits:**
- Test UI behavior without device
- Verify widget rendering
- Test user interactions

### 3. Integration Tests (`test/integration/`)
Test complete user workflows and feature flows.

**Examples:**
- Authentication flow (email → password → OTP)
- Transaction creation flow
- Data filtering and sorting

**Benefits:**
- Test realistic user scenarios
- Verify feature completeness
- Catch integration issues

## Test Examples

### Unit Test Example
```dart
test('should create a transaction entity', () {
  final transaction = TransactionEntity(
    id: '1',
    userId: 'user1',
    type: TransactionType.expense,
    amount: 50.0,
    description: 'Coffee',
    // ...
  );

  expect(transaction.id, '1');
  expect(transaction.amount, 50.0);
});
```

### Widget Test Example
```dart
testWidgets('should display strength indicator for password', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PasswordStrengthIndicator(password: 'Test123'),
      ),
    ),
  );

  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

### Integration Test Example
```dart
test('should validate email format', () {
  expect(isValidEmail('user@example.com'), true);
  expect(isValidEmail('invalid'), false);
});
```

## Writing New Tests

### 1. Create Test File
Place tests in appropriate directory:
- Unit tests: `test/unit/`
- Widget tests: `test/widget/`
- Integration tests: `test/integration/`

### 2. Import Required Packages
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fin_mate/...'; // Your classes
```

### 3. Use Test Setup Helpers
```dart
import 'package:fin_mate/test/test_setup.dart';

// Use TestData for mocks
final mockTransaction = TestData.mockTransaction();

// Use testableWidget for widget tests
await tester.pumpWidget(testableWidget(MyWidget()));
```

### 4. Follow Test Structure
```dart
void main() {
  group('Feature Name', () {
    setUp(() {
      // Setup before each test
    });

    tearDown(() {
      // Cleanup after each test
    });

    test('should do something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = function(input);

      // Assert
      expect(result, 'expected');
    });
  });
}
```

## Mocking and Test Doubles

Use `mocktail` for mocking:
```dart
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements TransactionRepository {}

test('should fetch transactions', () {
  final mock = MockRepository();
  when(() => mock.getTransactions()).thenAnswer((_) async => []);

  // Test code
});
```

## Coverage Targets

Aim for these coverage minimums:
- **Overall:** 70%+
- **Business Logic:** 85%+
- **Entities/Models:** 90%+
- **UI Components:** 60%+

## Continuous Integration

Tests should pass before:
- Creating pull requests
- Merging to main branch
- Preparing for release

Add pre-commit hook:
```bash
# .git/hooks/pre-commit
#!/bin/bash
flutter test || exit 1
```

## Debugging Tests

### Print Debug Information
```dart
test('should do something', () {
  debugPrint('Debug info');
  expect(value, true);
});
```

### Run Single Test with Verbose Output
```bash
flutter test test/unit/entities/transaction_entity_test.dart -v
```

### Use Debugger
```dart
test('should do something', () {
  debugger(); // Pauses execution in IDE
  expect(value, true);
});
```

## Best Practices

1. **Test Names**: Use descriptive names
   - ✅ `should_validate_email_format`
   - ❌ `test1`

2. **Arrange-Act-Assert**: Follow AAA pattern
   ```dart
   // Arrange
   final input = 'test';

   // Act
   final result = function(input);

   // Assert
   expect(result, 'expected');
   ```

3. **One Assertion Per Test**: When possible
   - Makes failures clear
   - Easier to debug

4. **Use Descriptive Matchers**
   - ✅ `expect(list, isEmpty)`
   - ❌ `expect(list.length, 0)`

5. **Mock External Dependencies**
   - Isolate code under test
   - Make tests deterministic

6. **Test Edge Cases**
   - Empty inputs
   - Null values
   - Boundary values
   - Large datasets

## Troubleshooting

### Tests Fail Locally but Pass in CI
- Clear pubspec.lock and get packages again
- Check Dart SDK version matches
- Verify test environment setup

### Widget Tests Timeout
- Increase timeout: `expect(..., timeout: Duration(seconds: 30))`
- Check for infinite loops in widget
- Ensure proper pump/settle calls

### Coverage Not Generated
- Install lcov: `brew install lcov`
- Run: `flutter test --coverage`
- Check coverage directory exists

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito/Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Dart Testing Best Practices](https://dart.dev/guides/testing)

## Next Steps

1. Run existing tests: `flutter test`
2. Expand test coverage for critical features
3. Add integration tests for user workflows
4. Set up CI/CD pipeline to run tests automatically
5. Aim for 70%+ code coverage
