import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class LegalDocumentView extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentView({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: _buildFormattedContent(context, content),
        ),
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context, String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppSizes.md));
      } else if (line.startsWith('# ')) {
        // H1
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Text(
              line.replaceFirst('# ', ''),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // H2
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Text(
              line.replaceFirst('## ', ''),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        // H3
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Text(
              line.replaceFirst('### ', ''),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        // Bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.md,
              bottom: AppSizes.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.md, top: 4),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.replaceFirst('- ', ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('**')) {
        // Bold text
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
            child: Text(
              line.replaceAll('**', ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      } else {
        // Regular paragraph
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
            child: Text(
              line,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}