import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/theme_provider.dart';
import '../providers/settings_providers.dart';

class DisplaySettingsPage extends ConsumerWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsOperationsProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Display Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (settings) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Section
                _buildSectionTitle(context, 'Theme'),
                const SizedBox(height: AppSizes.sm),
                _buildThemeTile(
                  context,
                  title: 'Light',
                  subtitle: 'Use light theme',
                  isSelected: currentThemeMode == ThemeMode.light,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateThemeMode('light');
                  },
                  icon: Icons.light_mode,
                ),
                const SizedBox(height: AppSizes.sm),
                _buildThemeTile(
                  context,
                  title: 'Dark',
                  subtitle: 'Use dark theme',
                  isSelected: currentThemeMode == ThemeMode.dark,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateThemeMode('dark');
                  },
                  icon: Icons.dark_mode,
                ),
                const SizedBox(height: AppSizes.sm),
                _buildThemeTile(
                  context,
                  title: 'System',
                  subtitle: 'Follow device settings',
                  isSelected: currentThemeMode == ThemeMode.system,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateThemeMode('system');
                  },
                  icon: Icons.settings_brightness,
                ),
                const SizedBox(height: AppSizes.lg),

                // Currency Section
                _buildSectionTitle(context, 'Currency & Format'),
                const SizedBox(height: AppSizes.sm),
                _buildDropdownSettingTile(
                  context,
                  title: 'Currency',
                  subtitle: 'Default currency for amounts',
                  value: settings?.notificationPreferences.budgetThreshold.toString() ?? 'USD',
                  items: const ['USD', 'EUR', 'GBP', 'JPY', 'INR'],
                  onChanged: (value) {
                    // Update currency in profile
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildDropdownSettingTile(
                  context,
                  title: 'Date Format',
                  subtitle: 'How dates are displayed',
                  value: 'MM/DD/YYYY',
                  items: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
                  onChanged: (value) {
                    // Update date format
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildDropdownSettingTile(
                  context,
                  title: 'Number Format',
                  subtitle: 'How numbers are formatted',
                  value: '1,234.56',
                  items: const ['1,234.56', '1.234,56', '1 234.56'],
                  onChanged: (value) {
                    // Update number format
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // Language Section
                _buildSectionTitle(context, 'Language'),
                const SizedBox(height: AppSizes.sm),
                _buildDropdownSettingTile(
                  context,
                  title: 'Language',
                  subtitle: 'App language',
                  value: 'English (US)',
                  items: const ['English (US)', 'Spanish', 'French', 'German'],
                  onChanged: (value) {
                    if (value != null) {
                      final lang = value.toLowerCase().contains('spanish')
                          ? 'es'
                          : value.toLowerCase().contains('french')
                              ? 'fr'
                              : value.toLowerCase().contains('german')
                                  ? 'de'
                                  : 'en';
                      ref
                          .read(settingsOperationsProvider.notifier)
                          .updateLanguage(lang);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
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
                size: 28,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryTeal,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
