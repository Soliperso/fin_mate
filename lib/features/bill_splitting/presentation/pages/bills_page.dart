import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../providers/bill_splitting_providers.dart';
import '../widgets/create_group_bottom_sheet.dart';

class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Bill Splitting'),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userGroupsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupCardWithBalance(
                  context,
                  ref,
                  group,
                  currentUserId,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateGroupBottomSheet(),
    ).then((created) {
      if (created == true) {
        ref.invalidate(userGroupsProvider);
      }
    });
  }

  Widget _buildGroupCardWithBalance(
    BuildContext context,
    WidgetRef ref,
    dynamic group,
    String currentUserId,
  ) {
    // Fetch members and balances separately
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final balancesAsync = ref.watch(groupBalancesProvider(group.id));

    return membersAsync.when(
      data: (members) {
        final memberCount = members.length;

        // Now handle balances
        return balancesAsync.when(
          data: (balances) {
            // Find current user's balance or default to 0
            double userBalance = 0.0;
            if (balances.isNotEmpty) {
              try {
                final userBalanceObj = balances.firstWhere(
                  (b) => b.userId == currentUserId,
                );
                userBalance = userBalanceObj.balance;
              } catch (e) {
                // User not found in balances, use the first balance or 0
                userBalance = balances.isNotEmpty ? balances.first.balance : 0.0;
              }
            }

            return _buildGroupCard(
              context,
              group,
              memberCount,
              userBalance,
            );
          },
          loading: () => _buildGroupCard(context, group, memberCount, 0.0, isLoading: true),
          error: (error, stack) {
            // If balance fetch fails, still show member count but indicate balance error
            return _buildGroupCard(
              context,
              group,
              memberCount,
              0.0,
              hasBalanceError: true,
            );
          },
        );
      },
      loading: () => _buildGroupCard(context, group, 0, 0.0, isLoading: true),
      error: (error, stack) {
        // If member fetch fails, show error
        return _buildGroupCard(
          context,
          group,
          0,
          0.0,
          hasMemberError: true,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final errorMessage = error.toString();

    final isMigrationError = errorMessage.contains('does not exist') ||
        (errorMessage.contains('relation') && errorMessage.contains('does not exist'));
    final isRecursionError = errorMessage.contains('infinite recursion');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSizes.lg),
            Text(
              isMigrationError
                  ? 'Database Setup Required'
                  : isRecursionError
                      ? 'Database Policy Error'
                      : 'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              isMigrationError
                  ? 'The bill splitting tables need to be created in your database. Please run the migration script.'
                  : isRecursionError
                      ? 'There is an infinite recursion in the database policies. Please run the RLS fix migration.'
                      : 'Unable to load bill splitting groups.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            if (isMigrationError || isRecursionError)
              Text(
                isMigrationError
                    ? 'Migration file: supabase/migrations/09_create_bill_splitting_and_savings_goals.sql'
                    : 'Fix file: supabase/migrations/13_fix_rls_infinite_recursion.sql',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontFamily: 'monospace',
                    ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(userGroupsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: EmptyStateCard(
          icon: Icons.groups_outlined,
          title: 'No Groups Yet',
          message: 'Create a group to start splitting expenses and settling payments with friends.',
          backgroundColor: AppColors.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    dynamic group,
    int memberCount,
    double balance, {
    bool isLoading = false,
    bool hasMemberError = false,
    bool hasBalanceError = false,
  }) {
    final isOwed = balance > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: InkWell(
        onTap: () {
          context.go('/bills/group/${group.id}');
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.slateBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: AppColors.slateBlue,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        if (isLoading)
                          Text(
                            'Loading...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          )
                        else if (hasMemberError)
                          Text(
                            'Unable to load members',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                ),
                          )
                        else
                          Text(
                            '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: hasBalanceError
                      ? AppColors.lightGray
                      : balance == 0
                          ? AppColors.lightGray
                          : isOwed
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (hasBalanceError)
                      const Icon(
                        Icons.error_outline,
                        size: AppSizes.iconSm,
                        color: AppColors.textTertiary,
                      )
                    else if (balance != 0)
                      Icon(
                        isOwed ? Icons.arrow_downward : Icons.arrow_upward,
                        size: AppSizes.iconSm,
                        color: isOwed ? AppColors.success : AppColors.error,
                      ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      hasBalanceError
                          ? 'Unable to calculate balance'
                          : isLoading
                              ? 'Loading balance...'
                              : balance == 0
                                  ? 'Settled up'
                                  : isOwed
                                      ? 'You are owed \$${balance.abs().toStringAsFixed(2)}'
                                      : 'You owe \$${balance.abs().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: hasBalanceError
                                ? AppColors.textTertiary
                                : isLoading
                                    ? AppColors.textTertiary
                                    : balance == 0
                                        ? AppColors.textSecondary
                                        : isOwed
                                            ? AppColors.success
                                            : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
