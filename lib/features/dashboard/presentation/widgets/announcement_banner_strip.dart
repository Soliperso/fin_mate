import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/announcement_provider.dart';

/// Tracks which announcement IDs have been dismissed this session.
final _dismissedIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Dismissible announcement banners shown at the top of the dashboard.
/// Dismissed banners stay hidden for the current session.
class AnnouncementBannerStrip extends ConsumerWidget {
  const AnnouncementBannerStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(activeAnnouncementsProvider);
    final dismissed = ref.watch(_dismissedIdsProvider);

    return announcementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        final visible =
            banners.where((b) => !dismissed.contains(b['id'])).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Column(
          children: visible.map((b) => _Banner(data: b)).toList(),
        );
      },
    );
  }
}

class _Banner extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _Banner({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id'] as String;
    final title = data['title'] as String;
    final message = data['message'] as String;
    final ctaLabel = data['cta_label'] as String?;
    final ctaUrl = data['cta_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: AppColors.brandTeal.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                CupertinoIcons.info_circle_fill,
                color: AppColors.brandTeal,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandTeal,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.brandTeal.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                  ),
                  if (ctaLabel != null &&
                      ctaLabel.isNotEmpty &&
                      ctaUrl != null &&
                      ctaUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(ctaUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          ctaLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.brandTeal,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref
                  .read(_dismissedIdsProvider.notifier)
                  .update((s) => {...s, id}),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 14,
                  color: AppColors.brandTeal.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
