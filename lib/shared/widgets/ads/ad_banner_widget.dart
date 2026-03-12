import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/providers/ad_provider.dart';

/// A smart banner ad widget that automatically handles premium status checks
///
/// This widget:
/// - Shows ads ONLY for freemium users
/// - Hides completely for premium users
/// - Gracefully handles ad loading failures (shows nothing)
/// - Manages ad lifecycle automatically
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     // Your content here
///     AdBannerWidget(),
///   ],
/// )
/// ```
class AdBannerWidget extends ConsumerStatefulWidget {
  /// The size of the banner ad (default: standard banner)
  final AdSize adSize;

  /// Padding around the ad
  final EdgeInsets padding;

  const AdBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load ad after first frame to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we should show ads for this user
      final shouldShowAds = await ref.read(shouldShowAdsProvider.future);

      if (!shouldShowAds) {
        // User is premium, don't load ads
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // User is freemium, load the ad
      final adService = ref.read(adServiceProvider);
      final ad = await adService.loadBannerAd(
        size: widget.adSize,
        onAdFailedToLoad: (ad, error) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isLoading = false;
            });
          }
        },
      );

      if (ad != null && mounted) {
        setState(() {
          _bannerAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Silently fail - don't disrupt UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the premium status to rebuild if it changes
    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    return shouldShowAds.when(
      data: (show) {
        if (!show) {
          // User is premium - show nothing
          return const SizedBox.shrink();
        }

        if (!_isAdLoaded || _bannerAd == null) {
          // Ad not loaded yet - show nothing (no loading indicator to avoid UI jank)
          return const SizedBox.shrink();
        }

        // Ad loaded - show it
        return Padding(
          padding: widget.padding,
          child: SizedBox(
            width: double.infinity,
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
