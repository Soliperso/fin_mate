import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';

class DataPrivacyPage extends ConsumerWidget {
  const DataPrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Data & Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Export Section
            _buildSectionTitle(context, 'Export Your Data'),
            const SizedBox(height: AppSizes.sm),
            _buildSectionDescription(
              context,
              'Download your financial data in various formats for backup or analysis.',
            ),
            const SizedBox(height: AppSizes.md),
            _buildExportButton(
              context,
              ref,
              icon: Icons.download_outlined,
              title: 'Export All Data',
              subtitle: 'Download complete profile as JSON',
              onPressed: () => _exportAllData(context, ref),
            ),
            const SizedBox(height: AppSizes.sm),
            _buildExportButton(
              context,
              ref,
              icon: Icons.table_chart_outlined,
              title: 'Export Transactions',
              subtitle: 'Download transactions as CSV',
              onPressed: () => _exportTransactions(context, ref),
            ),
            const SizedBox(height: AppSizes.sm),
            _buildExportButton(
              context,
              ref,
              icon: Icons.assessment_outlined,
              title: 'Export Budgets',
              subtitle: 'Download budgets as CSV',
              onPressed: () => _exportBudgets(context, ref),
            ),
            const SizedBox(height: AppSizes.lg),

            // Privacy Section
            _buildSectionTitle(context, 'Privacy Controls'),
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Text(
                      'Your data is encrypted and only accessible to you. We never share your financial information.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Danger Zone
            _buildSectionTitle(context, 'Danger Zone', isDanger: true),
            const SizedBox(height: AppSizes.sm),
            _buildSectionDescription(
              context,
              'These actions cannot be undone. Please proceed with caution.',
              isDanger: true,
            ),
            const SizedBox(height: AppSizes.md),
            _buildDangerButton(
              context,
              ref,
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              onPressed: () => _showDeleteAccountDialog(context, ref),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    bool isDanger = false,
  }) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDanger ? AppColors.error : AppColors.textSecondary,
          ),
    );
  }

  Widget _buildSectionDescription(
    BuildContext context,
    String description, {
    bool isDanger = false,
  }) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDanger ? AppColors.error.withValues(alpha: 0.7) : AppColors.textSecondary,
          ),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryTeal,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward,
          color: AppColors.textTertiary,
        ),
        onTap: onPressed,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      ),
    );
  }

  Widget _buildDangerButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            icon,
            color: AppColors.error,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.error.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: AppColors.error.withValues(alpha: 0.5),
        ),
        onTap: onPressed,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      ),
    );
  }

  void _exportAllData(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing export...')),
      );

      final jsonData = await ref
          .read(settingsOperationsProvider.notifier)
          .exportDataAsJson();

      // Share the data
      await Share.share(
        jsonData,
        subject: 'FinMate Data Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing CSV export...')),
      );

      final csvData = await ref
          .read(settingsOperationsProvider.notifier)
          .exportTransactionsAsCsv();

      // Share the data
      await Share.share(
        csvData,
        subject: 'FinMate Transactions Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _exportBudgets(BuildContext context, WidgetRef ref) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing CSV export...')),
      );

      final csvData = await ref
          .read(settingsOperationsProvider.notifier)
          .exportBudgetsAsCsv();

      // Share the data
      await Share.share(
        csvData,
        subject: 'FinMate Budgets Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: This action cannot be undone!',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'Deleting your account will:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSizes.xs),
            Text('• Permanently delete all your transactions'),
            Text('• Delete all budgets and goals'),
            Text('• Remove you from bill splitting groups'),
            Text('• Delete all uploaded documents'),
            SizedBox(height: AppSizes.md),
            Text(
              'This action cannot be reversed.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmationDialog(context, ref);
            },
            child: const Text(
              'Delete My Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordConfirmationDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your password to confirm account deletion:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSizes.lg),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performAccountDeletion(context, ref);
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(BuildContext context, WidgetRef ref) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleting account...')),
        );
      }

      // Delete account
      await ref.read(settingsOperationsProvider.notifier).deleteAccount();

      // Sign out
      if (context.mounted) {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
