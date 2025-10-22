import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/emergency_fund_status.dart';
import '../../data/services/emergency_fund_service.dart';
import '../providers/emergency_fund_provider.dart';

class EmergencyFundPage extends ConsumerStatefulWidget {
  const EmergencyFundPage({super.key});

  @override
  ConsumerState<EmergencyFundPage> createState() => _EmergencyFundPageState();
}

class _EmergencyFundPageState extends ConsumerState<EmergencyFundPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addContribution() async {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: 'Please enter a valid amount',
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get the first account for the user (default account for contribution)
      final accountResponse = await supabase
          .from('accounts')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if (accountResponse.isEmpty) {
        throw Exception('No accounts found. Please create an account first.');
      }

      final accountId = accountResponse[0]['id'];

      // Get the Savings category (or create a default one)
      final categoryResponse = await supabase
          .from('categories')
          .select('id')
          .eq('user_id', userId)
          .ilike('name', '%savings%')
          .limit(1);

      String? categoryId;
      if (categoryResponse.isNotEmpty) {
        categoryId = categoryResponse[0]['id'];
      }

      // Create a transaction to add funds to emergency fund account
      await supabase.from('transactions').insert({
        'user_id': userId,
        'type': 'income',
        'amount': amount,
        'description': _descriptionController.text.isEmpty
            ? 'Emergency Fund Contribution'
            : _descriptionController.text,
        'category_id': categoryId,
        'account_id': accountId,
        'date': DateTime.now().toIso8601String(),
        'is_recurring': false,
      });

      // Refresh the emergency fund status
      ref.invalidate(emergencyFundStatusProvider);

      if (mounted) {
        _amountController.clear();
        _descriptionController.clear();

        SuccessSnackbar.show(
          context,
          message: 'Emergency fund contribution added!',
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: 'Failed to add contribution: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyFundAsync = ref.watch(emergencyFundStatusProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Emergency Fund'),
        centerTitle: true,
      ),
      body: emergencyFundAsync.when(
        data: (status) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Amount',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(status.currentAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTeal,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Target (6 months)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat
                                    .format(status.targetRecommended),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                        child: LinearProgressIndicator(
                          value: (status.readinessScore / 100)
                              .clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${status.readinessScore.toStringAsFixed(0)}% Ready',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                ),
                          ),
                          Text(
                            'Need: ${currencyFormat.format(
                              status.targetRecommended - status.currentAmount,
                            )}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Add Contribution Form
              Text(
                'Add Contribution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.md),

              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  filled: true,
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Description Input (optional)
              TextField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  filled: true,
                  hintText:
                      'e.g., Monthly savings, Bonus, etc.',
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addContribution,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    _isLoading
                        ? 'Adding...'
                        : 'Add Contribution',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Info Box
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.tealLight.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: AppColors.tealLight.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.tealLight,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            'Emergency Fund Tips',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...[
                      'Aim for 3-6 months of living expenses',
                      'Start with small regular contributions',
                      'Keep funds easily accessible',
                      'Only use for true emergencies',
                    ].map(
                      (tip) => Padding(
                        padding:
                            const EdgeInsets.only(
                              bottom: AppSizes.sm,
                            ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.deepNavy,
                                  ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.deepNavy,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Failed to load emergency fund',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Please try again later',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(emergencyFundStatusProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}