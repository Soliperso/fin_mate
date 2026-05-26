import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

/// Shown when the admin has set a minimum version higher than the installed build.
/// Non-dismissible — users must update before continuing.
class ForceUpdatePage extends ConsumerWidget {
  const ForceUpdatePage({super.key});

  // Replace these with your actual App Store / Play Store URLs.
  static const _appStoreUrl =
      'https://apps.apple.com/app/finmate/id0000000000';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.finmate.app';

  Future<void> _openStore() async {
    final url =
        Uri.parse(Platform.isIOS ? _appStoreUrl : _playStoreUrl);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 48,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Update Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'A newer version of Finmate is required to continue. '
                  'Please update from the ${Platform.isIOS ? 'App Store' : 'Play Store'}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openStore,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      Platform.isIOS
                          ? 'Open App Store'
                          : 'Open Play Store',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  child: Text(
                    'Sign out',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
