import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fin_mate/shared/widgets/password_strength_indicator.dart';

void main() {
  group('PasswordStrengthIndicator Widget', () {
    testWidgets('should not display anything for empty password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: ''),
          ),
        ),
      );

      // Should be hidden
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('should display strength indicator for weak password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'abc'),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should display strength indicator for strong password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'Abc123!@#'),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should show requirement chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'Test123'),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsWidgets);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('should validate password requirements', (WidgetTester tester) async {
      // Test with password containing all requirements
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'StrongPass123!'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show requirement containers
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('should update when password changes', (WidgetTester tester) async {
      String password = '';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    PasswordStrengthIndicator(password: password),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => password = 'Abc123!@#');
                      },
                      child: const Text('Set Password'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
