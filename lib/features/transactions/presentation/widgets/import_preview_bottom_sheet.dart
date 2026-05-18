import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/services/csv_import_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';

class ImportPreviewBottomSheet extends ConsumerStatefulWidget {
  final CsvImportResult importResult;

  const ImportPreviewBottomSheet({super.key, required this.importResult});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    CsvImportResult result,
  ) {
    return GlassBottomSheet.show(
      context: context,
      isDismissible: true,
      child: ImportPreviewBottomSheet(importResult: result),
    );
  }

  @override
  ConsumerState<ImportPreviewBottomSheet> createState() =>
      _ImportPreviewBottomSheetState();
}

class _ImportPreviewBottomSheetState
    extends ConsumerState<ImportPreviewBottomSheet> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.importResult;
    final count = result.transactions.length;
    final skipped = result.errors.length;
    final preview = result.transactions.take(3).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.lg,
        AppSizes.pagePadding,
        AppSizes.pagePadding + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(CupertinoIcons.arrow_down_to_line,
                    color: AppColors.brandTeal, size: 18),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? 'transactions.import.headerSingular'.tr()
                          : 'transactions.import.headerPlural'
                              .tr(namedArgs: {'count': count.toString()}),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (skipped > 0)
                      Text(
                        skipped == 1
                            ? 'transactions.import.skippedSingular'.tr()
                            : 'transactions.import.skippedPlural'
                                .tr(namedArgs: {'count': skipped.toString()}),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.systemOrange,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Preview table ─────────────────────────────────────────
          if (preview.isNotEmpty) ...[
            Text(
              'Preview',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.secondarySystemBackgroundDark
                    : AppColors.systemBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                children: List.generate(preview.length, (i) {
                  final tx = preview[i];
                  return Column(
                    children: [
                      _PreviewRow(tx: tx),
                      if (i < preview.length - 1)
                        Divider(
                          height: 0,
                          thickness: 0.5,
                          indent: AppSizes.md,
                          endIndent: AppSizes.md,
                          color: Theme.of(context).dividerColor,
                        ),
                    ],
                  );
                }),
              ),
            ),
            if (count > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.sm, left: 4),
                child: Text(
                  '+ ${count - 3} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                ),
              ),
            const SizedBox(height: AppSizes.lg),
          ],

          // ── Skipped errors (collapsed summary) ────────────────────
          if (skipped > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.systemOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle,
                      color: AppColors.systemOrange, size: 16),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      '$skipped row${skipped == 1 ? '' : 's'} will be skipped '
                      '(unrecognised account or invalid data).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.systemOrange,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
          ],

          // ── Buttons ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _importing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: FilledButton(
                  onPressed: count == 0 || _importing ? null : _runImport,
                  child: _importing
                      ? const LoadingIndicator(size: 18, color: Colors.white)
                      : Text('Import $count'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runImport() async {
    setState(() => _importing = true);
    final repo = ref.read(transactionRepositoryProvider);
    int imported = 0;

    for (final tx in widget.importResult.transactions) {
      try {
        await repo.createTransaction(tx);
        imported++;
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ref.invalidate(transactionListProvider);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(budgetsWithSpendingProvider);

    final skipped = widget.importResult.transactions.length - imported;
    final msg = skipped > 0
        ? '$imported imported, $skipped skipped'
        : '$imported transaction${imported == 1 ? '' : 's'} imported';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final TransactionEntity tx;
  const _PreviewRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TransactionType.expense;
    final color = isExpense ? AppColors.systemRed : AppColors.systemGreen;
    final sign = isExpense ? '−' : '+';
    final amountStr = '$sign\$${NumberFormat('#,##0.00').format(tx.amount)}';

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? tx.categoryName ?? tx.type.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tx.accountName ?? ''} · ${DateFormat(AppDateFormats.shortDate).format(tx.date)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                ),
              ],
            ),
          ),
          Text(
            amountStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
