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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.labelDark : AppColors.label;
    final secondaryText =
        isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePadding,
          vertical: AppSizes.sm,
        ),
        child: _buildFormattedContent(context, content, primaryText, secondaryText),
      ),
    );
  }

  Widget _buildFormattedContent(
    BuildContext context,
    String content,
    Color primaryText,
    Color secondaryText,
  ) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppSizes.xs));
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.xs),
            child: Text(
              line.replaceFirst('# ', ''),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.xs),
            child: Text(
              line.replaceFirst('## ', ''),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.xs, bottom: 2),
            child: Text(
              line.replaceFirst('### ', ''),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.md, bottom: AppSizes.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm, top: 7),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.replaceFirst('- ', ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: secondaryText,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('**')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line.replaceAll('**', ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
            ),
          ),
        );
      } else {
        widgets.add(
          Text(
            line,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: secondaryText,
                  height: 1.55,
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
