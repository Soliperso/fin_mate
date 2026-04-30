import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/providers/ad_provider.dart';

/// Native ad widget using Google's NativeTemplateStyle.
/// The template renders its own complete UI including attribution and AdChoices.
/// Shows nothing for premium users or when the ad fails to load.
class FinmateNativeAdWidget extends ConsumerWidget {
  // compact is kept for call-site compatibility but the template self-sizes
  final bool compact;

  const FinmateNativeAdWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);
    final nativeAd = ref.watch(nativeAdProvider);

    return shouldShowAds.when(
      data: (show) {
        if (!show || nativeAd == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // 320px satisfies AdMob's 120pt MediaView minimum for video ads
          child: SizedBox(
            width: double.infinity,
            height: 320,
            child: AdWidget(ad: nativeAd),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
