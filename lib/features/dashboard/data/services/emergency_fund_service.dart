import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/emergency_fund_status.dart';

class EmergencyFundService {
  final SupabaseClient _supabase;

  EmergencyFundService(this._supabase);

  Future<EmergencyFundStatus> calculateEmergencyFundStatus(String userId) async {
    try {
      // 1. Calculate average monthly expenses (last 3 months)
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

      final expensesResponse = await _supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', threeMonthsAgo.toIso8601String())
          .order('date', ascending: false);

      double totalExpenses = 0;
      if (expensesResponse.isNotEmpty) {
        for (var expense in expensesResponse) {
          totalExpenses += (expense['amount'] as num).toDouble();
        }
      }

      // Calculate average monthly expenses (total / 3 months)
      final averageMonthlyExpenses = totalExpenses / 3;

      // 2. Get current emergency fund amount (from savings goals + liquid accounts)
      double emergencyFundFromGoals = 0;

      // Check for emergency fund savings goals
      final goalsResponse = await _supabase
          .from('savings_goals')
          .select('current_amount')
          .eq('user_id', userId)
          .eq('category', 'Emergency Fund')
          .eq('is_completed', false);

      if (goalsResponse.isNotEmpty) {
        for (var goal in goalsResponse) {
          emergencyFundFromGoals += (goal['current_amount'] as num).toDouble();
        }
      }

      // Get liquid cash from checking and savings accounts
      final accountsResponse = await _supabase
          .from('accounts')
          .select('balance, type')
          .eq('user_id', userId)
          .inFilter('type', ['checking', 'savings', 'cash']);

      double liquidCash = 0;
      if (accountsResponse.isNotEmpty) {
        for (var account in accountsResponse) {
          liquidCash += (account['balance'] as num).toDouble();
        }
      }

      // Current emergency fund = savings goals + 30% of liquid cash
      // (assuming not all liquid cash should be counted as emergency fund)
      final currentAmount = emergencyFundFromGoals + (liquidCash * 0.3);

      // 3. Calculate recommendations
      final minimumRecommended = averageMonthlyExpenses * 3; // 3 months
      final targetRecommended = averageMonthlyExpenses * 6; // 6 months

      // 4. Calculate metrics
      final double monthsCovered = averageMonthlyExpenses > 0
          ? currentAmount / averageMonthlyExpenses
          : 0.0;

      final double readinessScore = targetRecommended > 0
          ? ((currentAmount / targetRecommended) * 100).clamp(0.0, 100.0)
          : 0.0;

      // 5. Determine level
      final level = _determineLevel(monthsCovered);

      // 6. Generate recommendations
      final recommendations = _generateRecommendations(
        currentAmount: currentAmount,
        monthsCovered: monthsCovered,
        averageMonthlyExpenses: averageMonthlyExpenses,
        minimumRecommended: minimumRecommended,
        targetRecommended: targetRecommended,
        level: level,
      );

      return EmergencyFundStatus(
        currentAmount: currentAmount,
        minimumRecommended: minimumRecommended,
        targetRecommended: targetRecommended,
        averageMonthlyExpenses: averageMonthlyExpenses,
        readinessScore: readinessScore,
        monthsCovered: monthsCovered,
        level: level,
        recommendations: recommendations,
      );
    } catch (e) {
      // Return default status on error
      return const EmergencyFundStatus(
        currentAmount: 0,
        minimumRecommended: 0,
        targetRecommended: 0,
        averageMonthlyExpenses: 0,
        readinessScore: 0,
        monthsCovered: 0,
        level: EmergencyFundLevel.critical,
        recommendations: ['Unable to calculate emergency fund status'],
      );
    }
  }

  EmergencyFundLevel _determineLevel(double monthsCovered) {
    if (monthsCovered < 1) return EmergencyFundLevel.critical;
    if (monthsCovered < 2) return EmergencyFundLevel.low;
    if (monthsCovered < 4) return EmergencyFundLevel.moderate;
    if (monthsCovered < 6) return EmergencyFundLevel.good;
    return EmergencyFundLevel.excellent;
  }

  List<String> _generateRecommendations({
    required double currentAmount,
    required double monthsCovered,
    required double averageMonthlyExpenses,
    required double minimumRecommended,
    required double targetRecommended,
    required EmergencyFundLevel level,
  }) {
    final recommendations = <String>[];

    if (averageMonthlyExpenses == 0) {
      recommendations.add('Start tracking your expenses to calculate your emergency fund needs');
      return recommendations;
    }

    switch (level) {
      case EmergencyFundLevel.critical:
        recommendations.add('Start building your emergency fund today - aim for at least \$${(averageMonthlyExpenses).toStringAsFixed(0)} (1 month of expenses)');
        if (currentAmount == 0) {
          recommendations.add('Consider setting aside \$${(averageMonthlyExpenses * 0.1).toStringAsFixed(0)} per month to start');
        }
        recommendations.add('Prioritize this over other savings goals for financial security');
        break;

      case EmergencyFundLevel.low:
        final monthlyContribution = (minimumRecommended - currentAmount) / 6;
        recommendations.add('You\'re on the right track! Add \$${monthlyContribution.toStringAsFixed(0)}/month to reach 3 months in 6 months');
        recommendations.add('Aim for ${minimumRecommended.toStringAsFixed(0)} (3 months) as your first milestone');
        break;

      case EmergencyFundLevel.moderate:
        final monthlyContribution = (targetRecommended - currentAmount) / 12;
        recommendations.add('Great progress! Add \$${monthlyContribution.toStringAsFixed(0)}/month to reach 6 months in a year');
        recommendations.add('You\'re ${(monthsCovered.toStringAsFixed(1))} months covered - keep going!');
        break;

      case EmergencyFundLevel.good:
        recommendations.add('Excellent! You\'re ${(monthsCovered.toStringAsFixed(1))} months covered');
        if (currentAmount < targetRecommended) {
          final remaining = targetRecommended - currentAmount;
          recommendations.add('Just \$${remaining.toStringAsFixed(0)} more to reach the 6-month goal');
        }
        recommendations.add('Consider reviewing your fund quarterly as expenses change');
        break;

      case EmergencyFundLevel.excellent:
        recommendations.add('Outstanding! Your emergency fund is fully funded');
        recommendations.add('You can now focus on other financial goals with confidence');
        recommendations.add('Review your emergency fund annually to ensure it matches your expenses');
        break;
    }

    return recommendations;
  }
}
