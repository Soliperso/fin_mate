import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../widgets/legal_document_view.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & Compliance'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Legal Documents',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Review our policies and terms of service',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Privacy Policy Card
              _buildLegalCard(
                context,
                title: 'Privacy Policy',
                description: 'How we collect, use, and protect your data',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  _showPrivacyPolicy(context);
                },
              ),
              const SizedBox(height: AppSizes.md),

              // Terms of Service Card
              _buildLegalCard(
                context,
                title: 'Terms of Service',
                description: 'Our terms and conditions for using FinMate',
                icon: Icons.description_outlined,
                onTap: () {
                  _showTermsOfService(context);
                },
              ),
              const SizedBox(height: AppSizes.md),

              // App Privacy Details Card
              _buildLegalCard(
                context,
                title: 'App Privacy Details',
                description: 'App Store privacy information and data practices',
                icon: Icons.security_outlined,
                onTap: () {
                  _showAppPrivacyDetails(context);
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // Last Updated Section
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'Last Updated: October 21, 2025\n\n'
                      'By using FinMate, you agree to our Privacy Policy and Terms of Service. '
                      'We are committed to protecting your personal information and maintaining your trust.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Contact Section
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.lightGray.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questions?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'If you have any questions about our legal documents or privacy practices, '
                      'please contact us at:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'privacy@finmate.app',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.lightGray.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
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
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrivacyPolicy(BuildContext context) async {
    try {
      final content = await rootBundle.loadString('assets/legal/privacy_policy.md');
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
        _showErrorDialog(context, 'Failed to load Privacy Policy: ${e.toString()}');
      }
    }
  }

  Future<void> _showTermsOfService(BuildContext context) async {
    try {
      final content = await rootBundle.loadString('assets/legal/terms_of_service.md');
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
        _showErrorDialog(context, 'Failed to load Terms of Service: ${e.toString()}');
      }
    }
  }

  Future<void> _showAppPrivacyDetails(BuildContext context) async {
    try {
      final content = await rootBundle.loadString('assets/legal/app_privacy_details.md');
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
        _showErrorDialog(context, 'Failed to load App Privacy Details: ${e.toString()}');
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

