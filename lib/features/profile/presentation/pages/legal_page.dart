import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../widgets/legal_document_view.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & Compliance'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.lg),

            // Documents group
            _sectionLabel(context, 'Documents'),
            const SizedBox(height: AppSizes.sm),
            _buildCard(context, isDark, children: [
              _buildTile(
                context,
                icon: CupertinoIcons.hand_raised,
                title: 'Privacy Policy',
                subtitle: 'How we collect, use, and protect your data',
                onTap: () => _showPrivacyPolicy(context),
              ),
              _buildDivider(context, isDark),
              _buildTile(
                context,
                icon: CupertinoIcons.doc_text,
                title: 'Terms of Service',
                subtitle: 'Our terms and conditions for using Finmate',
                onTap: () => _showTermsOfService(context),
              ),
              _buildDivider(context, isDark),
              _buildTile(
                context,
                icon: CupertinoIcons.lock_shield,
                title: 'App Privacy Details',
                subtitle: 'App Store privacy information and data practices',
                onTap: () => _showAppPrivacyDetails(context),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // Info group
            _sectionLabel(context, 'Information'),
            const SizedBox(height: AppSizes.sm),
            _buildCard(context, isDark, children: [
              _buildTile(
                context,
                icon: CupertinoIcons.info_circle,
                title: 'Last Updated',
                subtitle: 'April 1, 2026',
                onTap: () {},
              ),
              _buildDivider(context, isDark),
              _buildTile(
                context,
                icon: CupertinoIcons.envelope,
                title: 'Contact Us',
                subtitle: 'privacy@finmate.app',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isDark ? AppColors.labelDark : AppColors.label,
                  size: 17),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.secondaryLabel,
                        ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 16,
                color: isDark ? AppColors.tertiaryLabelDark : AppColors.systemGray3),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  Future<void> _showPrivacyPolicy(BuildContext context) async {
    try {
      final content =
          await rootBundle.loadString('assets/legal/privacy_policy.md');
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LegalDocumentView(
              title: 'Privacy Policy',
              content: content,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
            context, 'legal.failedToLoadPrivacy'.tr());
      }
    }
  }

  Future<void> _showTermsOfService(BuildContext context) async {
    try {
      final content =
          await rootBundle.loadString('assets/legal/terms_of_service.md');
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LegalDocumentView(
              title: 'Terms of Service',
              content: content,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
            context, 'legal.failedToLoadTerms'.tr());
      }
    }
  }

  Future<void> _showAppPrivacyDetails(BuildContext context) async {
    try {
      final content =
          await rootBundle.loadString('assets/legal/app_privacy_details.md');
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LegalDocumentView(
              title: 'App Privacy Details',
              content: content,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
            context, 'legal.failedToLoadDetails'.tr());
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('legal.errorTitle'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
