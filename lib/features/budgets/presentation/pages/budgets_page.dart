import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../shared/utils/category_icon_utils.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_hero_card.dart';
import '../widgets/create_budget_bottom_sheet.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('budgets.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/dashboard'),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.add,
              onTap: () => _showCreateBudgetBottomSheet(context),
            ),
          ),
        ],
      ),
      body: budgetsState.when(
        data: (budgets) {
          final filtered = _searchQuery.isEmpty
              ? budgets
              : budgets
                  .where((b) =>
                      (b.categoryName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          if (budgets.isEmpty) return _buildEmptyState(context);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
                child: Builder(builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'budgets.searchHint'.tr(),
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () => setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              }),
                              child: const Icon(CupertinoIcons.xmark_circle_fill,
                                  size: 18, color: AppColors.systemGray3),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.secondarySystemBackgroundDark
                          : AppColors.systemGray6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: 10),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  );
                }),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(budgetNotifierProvider.notifier).refresh();
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSizes.md),
                          children: [
                            EmptyStateCard(
                              icon: CupertinoIcons.search,
                              title: 'budgets.noSearchResults'.tr(),
                              message: 'budgets.noSearchResultsMessage'.tr(),
                              backgroundColor: AppColors.brandTeal,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSizes.md),
                          itemCount: filtered.length + 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSizes.md),
                                child: BudgetHeroCard(budgets: budgets),
                              );
                            }
                            if (index == 1) {
                              return _buildSectionHeader(context);
                            }
                            return _buildBudgetCard(context, filtered[index - 2]);
                          },
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: const [
            SkeletonCard(),
            SizedBox(height: AppSizes.md),
            SkeletonCard(),
            SizedBox(height: AppSizes.md),
            SkeletonCard(),
          ],
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'budgets.failedToLoad'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(budgetNotifierProvider.notifier).loadBudgets();
                  },
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                  label: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmptyStateCard(
                    icon: CupertinoIcons.money_dollar,
                    title: 'budgets.noBudgets'.tr(),
                    message: 'budgets.noBudgetsMessage'.tr(),
                    backgroundColor: AppColors.brandTeal,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    height: AppSizes.buttonHeightMd,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateBudgetBottomSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                      icon: const Icon(CupertinoIcons.add, size: 20),
                      label: Text(
                        'budgets.newBudget'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        'budgets.byCategory'.tr(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetEntity budget) {
    final fmt = ref.watch(currencyFormat2Provider);
    final convFactor = ref.watch(conversionFactorProvider);
    final spent = budget.spent ?? 0.0;
    final remaining = budget.remaining ?? budget.effectiveAmount;
    final percentage = budget.spentPercentage.clamp(0.0, 100.0) / 100;
    final isOverBudget = budget.isExceeded;
    final isNearLimit = budget.isNearLimit;

    final categoryColor =
        _parseColor(budget.categoryColor) ?? AppColors.brandTeal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final progressColor = isOverBudget
        ? AppColors.systemRed
        : isNearLimit
            ? AppColors.systemOrange
            : AppColors.brandTeal;

    final remainingColor = isOverBudget ? AppColors.systemRed : AppColors.brandTeal;
    final remainingSign = isOverBudget ? '+' : '';
    final remainingLabel = isOverBudget ? 'over' : 'left';

    return GestureDetector(
      onTap: () => _showBudgetOptions(context, budget),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      _getIconForCategory(budget.categoryIcon,
                          categoryName: budget.categoryName),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.categoryName ?? 'Uncategorized',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${fmt.format(spent * convFactor)} of ${fmt.format(budget.effectiveAmount * convFactor)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            if (budget.carryOverEnabled &&
                                budget.lastCarryOverAmount != 0) ...[
                              const SizedBox(width: AppSizes.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (budget.lastCarryOverAmount > 0
                                          ? AppColors.systemGreen
                                          : AppColors.systemRed)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull),
                                ),
                                child: Text(
                                  budget.lastCarryOverAmount > 0
                                      ? '+${fmt.format(budget.lastCarryOverAmount.abs() * convFactor)}'
                                      : '-${fmt.format(budget.lastCarryOverAmount.abs() * convFactor)}',
                                  style: TextStyle(
                                    color: budget.lastCarryOverAmount > 0
                                        ? AppColors.systemGreen
                                        : AppColors.systemRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$remainingSign${fmt.format(remaining.abs() * convFactor)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: remainingColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        remainingLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.sm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percentage),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? AppColors.tertiarySystemBackgroundDark
                        : AppColors.systemGray5,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),
            if (isOverBudget)
              Container(
                width: double.infinity,
                color: AppColors.systemRed.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: 10),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle,
                        color: AppColors.systemRed, size: 14),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      'budgets.exceeded'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.systemRed,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateBudgetBottomSheet(BuildContext context,
      {BudgetEntity? budget}) {
    GlassBottomSheet.show(
      context: context,
      child: CreateBudgetBottomSheet(budget: budget),
    );
  }

  void _showBudgetOptions(BuildContext context, BudgetEntity budget) {
    final fmt = ref.watch(currencyFormat2Provider);
    final convFactor = ref.watch(conversionFactorProvider);
    final spent = budget.spent ?? 0.0;
    final remaining = budget.remaining ?? budget.amount;
    final percentage = (budget.spentPercentage.clamp(0.0, 100.0) / 100);
    final isOverBudget = budget.isExceeded;
    final isNearLimit = budget.isNearLimit;
    final categoryColor =
        _parseColor(budget.categoryColor) ?? AppColors.brandTeal;
    final progressColor = isOverBudget
        ? AppColors.systemRed
        : isNearLimit
            ? AppColors.systemOrange
            : AppColors.brandTeal;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    GlassBottomSheet.show(
      context: context,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Budget summary
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.md,
                AppSizes.lg,
                AppSizes.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Icon(
                          _getIconForCategory(budget.categoryIcon, categoryName: budget.categoryName),
                          color: categoryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.categoryName ?? 'Uncategorized',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              budget.period.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.tertiarySystemBackgroundDark
                          : AppColors.systemGray5,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'budgets.spent'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            fmt.format(spent * convFactor),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          if (ref.watch(usdEquivalentProvider(spent)) != null)
                            Text(
                              ref.watch(usdEquivalentProvider(spent))!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOverBudget
                                ? 'budgets.overBy'.tr()
                                : 'budgets.remaining'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            fmt.format(remaining.abs() * convFactor),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isOverBudget
                                      ? AppColors.systemRed
                                      : AppColors.systemGreen,
                                ),
                          ),
                          if (ref.watch(
                                  usdEquivalentProvider(remaining.abs())) !=
                              null)
                            Text(
                              ref.watch(
                                  usdEquivalentProvider(remaining.abs()))!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(
                height: 1,
                thickness: 0.5,
                color: isDark ? AppColors.separatorDark : AppColors.separator),

            // Edit action
            _buildActionRow(
              context: context,
              icon: CupertinoIcons.pencil,
              iconColor: AppColors.brandTeal,
              label: 'budgets.editBudget'.tr(),
              onTap: () {
                Navigator.pop(context);
                _showCreateBudgetBottomSheet(context, budget: budget);
              },
            ),

            Divider(
                height: 1,
                thickness: 0.5,
                indent: AppSizes.lg + 36 + 12,
                color: isDark ? AppColors.separatorDark : AppColors.separator),

            // View Transactions action
            _buildActionRow(
              context: context,
              icon: CupertinoIcons.list_bullet,
              iconColor: AppColors.brandTeal,
              label: 'budgets.viewTransactions'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.push('/transactions');
              },
            ),

            Divider(
                height: 1,
                thickness: 0.5,
                indent: AppSizes.lg + 36 + 12,
                color: isDark ? AppColors.separatorDark : AppColors.separator),

            // Delete action
            _buildActionRow(
              context: context,
              icon: CupertinoIcons.trash,
              iconColor: AppColors.systemRed,
              label: 'budgets.deleteBudget'.tr(),
              labelColor: AppColors.systemRed,
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('budgets.deleteTitle'.tr()),
                    content: Text('budgets.deleteMessage'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text('common.cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text('budgets.delete'.tr(),
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  try {
                    await ref
                        .read(budgetNotifierProvider.notifier)
                        .deleteBudget(budget.id);
                    if (context.mounted) {
                      SuccessDialog.show(
                        context,
                        title: 'budgets.deleted'.tr(),
                        message: 'budgets.deletedMessage'.tr(),
                        autoDismissDuration: const Duration(milliseconds: 800),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showErrorDialog(context, 'Failed to delete budget: $e');
                    }
                  }
                }
              },
            ),

            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.systemGray3,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? iconKey, {String? categoryName}) {
    return getCategoryIcon(categoryName, iconKey: iconKey);
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

    try {
      // Remove # if present
      final hexColor = colorString.replaceAll('#', '');

      // Add FF for alpha if not present
      final colorValue = hexColor.length == 6 ? 'FF$hexColor' : hexColor;

      return Color(int.parse(colorValue, radix: 16));
    } catch (e) {
      return null;
    }
  }
}
