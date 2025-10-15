import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/group_balance_entity.dart';
import '../providers/bill_splitting_providers.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import '../widgets/settle_up_bottom_sheet.dart';
import '../widgets/members_section.dart';
import '../widgets/settlement_history_section.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return groupAsync.when(
      data: (group) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // TODO: Group settings
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupProvider(groupId));
              ref.invalidate(groupMembersProvider(groupId));
              ref.invalidate(groupExpensesProvider(groupId));
              ref.invalidate(groupBalancesProvider(groupId));
              ref.invalidate(groupSettlementsProvider(groupId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balances Section
                  balancesAsync.when(
                    data: (balances) => _buildBalancesSection(context, ref, balances, currentUserId),
                    loading: () => _buildLoadingBalances(context),
                    error: (error, stack) => _buildBalancesError(context),
                  ),

                  // Members Section
                  membersAsync.when(
                    data: (members) => MembersSection(
                      groupId: groupId,
                      members: members,
                      currentUserId: currentUserId,
                      onAddMember: () {
                        // TODO: Show add member bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add member feature coming soon')),
                        );
                      },
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Text(
                        'Failed to load members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ),

                  // Settlement History Section
                  settlementsAsync.when(
                    data: (settlements) => SettlementHistorySection(
                      groupId: groupId,
                      settlements: settlements,
                      currentUserId: currentUserId,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),

                  // Expenses Section
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Expenses',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton.icon(
                              onPressed: () => _showAddExpenseSheet(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        expensesAsync.when(
                          data: (expenses) {
                            if (expenses.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSizes.xl),
                                  child: Text(
                                    'No expenses yet',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                final expense = expenses[index];
                                return _buildExpenseItem(context, ref, expense, currentUserId);
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSizes.xl),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.xl),
                              child: Text(
                                'Failed to load expenses',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.error,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: balancesAsync.maybeWhen(
            data: (balances) => FloatingActionButton.extended(
              onPressed: () => _showSettleUpSheet(context, balances),
              icon: const Icon(Icons.done_all),
              label: const Text('Settle Up'),
            ),
            orElse: () => null,
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Failed to load group',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Unable to fetch group details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(groupProvider(groupId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddExpenseBottomSheet(groupId: groupId),
    ).then((result) {
      if (result == true) {
        // Data will be refreshed automatically via provider invalidation
      }
    });
  }

  void _showSettleUpSheet(BuildContext context, List<dynamic> balances) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SettleUpBottomSheet(
        groupId: groupId,
        balances: balances.cast<GroupBalance>(),
        currentUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
      ),
    ).then((result) {
      if (result == true) {
        // Data will be refreshed automatically via provider invalidation
      }
    });
  }

  Widget _buildBalancesSection(BuildContext context, WidgetRef ref, List<dynamic> balances, String currentUserId) {
    if (balances.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.slateBlue, AppColors.tealBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Balances',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No balances to show',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slateBlue, AppColors.tealBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Balances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppSizes.md),
          ...balances.map((balance) {
            final amount = balance.balance;
            final isCurrentUser = balance.userId == currentUserId;
            final displayName = isCurrentUser ? 'You' : balance.fullName;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                  Text(
                    amount >= 0 ? '+\$${amount.toStringAsFixed(2)}' : '-\$${amount.abs().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingBalances(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slateBlue, AppColors.tealBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Balances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppSizes.md),
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesError(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.slateBlue, AppColors.tealBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Balances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Unable to calculate balances',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, WidgetRef ref, dynamic expense, String currentUserId) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isCurrentUser = expense.paidBy == currentUserId;
    final paidByName = isCurrentUser ? 'You' : expense.paidByName;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: const Icon(
            Icons.receipt,
            color: AppColors.primaryTeal,
          ),
        ),
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.xs),
            Text(
              'Paid by $paidByName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              dateFormat.format(expense.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(expense.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              expense.splitType.value.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
