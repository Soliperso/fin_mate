import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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
              _buildDivider(isDark),
              _buildTile(
                context,
                icon: CupertinoIcons.doc_text,
                title: 'Terms of Service',
                subtitle: 'Our terms and conditions for using FinMate',
                onTap: () => _showTermsOfService(context),
              ),
              _buildDivider(isDark),
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
                subtitle: 'October 21, 2025',
                onTap: () {},
              ),
              _buildDivider(isDark),
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
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
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
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.labelDark, size: 17),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9E9EA3),
                          inherit: true,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.systemGray3),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      color: isDark ? AppColors.separatorDark : AppColors.separator,
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
            context, 'Failed to load Privacy Policy: ${e.toString()}');
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
            context, 'Failed to load Terms of Service: ${e.toString()}');
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
            context, 'Failed to load App Privacy Details: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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
