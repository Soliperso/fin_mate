import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../core/services/theme_provider.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/settings_providers.dart';

class DisplaySettingsPage extends ConsumerStatefulWidget {
  final String? section;

  const DisplaySettingsPage({super.key, this.section});

  @override
  ConsumerState<DisplaySettingsPage> createState() =>
      _DisplaySettingsPageState();
}

class _DisplaySettingsPageState extends ConsumerState<DisplaySettingsPage> {
  final _themeKey = GlobalKey();
  final _currencyKey = GlobalKey();
  final _scrollController = ScrollController();

  static const _langCodes = ['en', 'es', 'fr' /*, 'ar'*/];

  String _langCodeToLabel(String code) {
    switch (code) {
      case 'es':
        return 'display.langEs'.tr();
      case 'fr':
        return 'display.langFr'.tr();
      // case 'ar':
      //   return 'display.langAr'.tr();
      default:
        return 'display.langEn'.tr();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
    }
  }

  void _scrollToSection() {
    GlobalKey? key;
    switch (widget.section) {
      case 'theme':
        key = _themeKey;
        break;
      case 'currency':
      case 'dateformat':
        key = _currencyKey;
        break;
    }
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsOperationsProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final displayFmt = ref.watch(displayFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('display.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: settingsState.when(
        loading: () => const SkeletonList(itemCount: 6, itemHeight: 56),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (_) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Theme ────────────────────────────────────────────────
              _sectionLabel(context, 'display.themeSection'.tr(),
                  key: _themeKey),
              const SizedBox(height: AppSizes.sm),
              _buildCard(context, isDark, children: [
                _buildThemeTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.sun_max,
                  title: 'display.light'.tr(),
                  subtitle: 'display.lightSub'.tr(),
                  isSelected: currentThemeMode == ThemeMode.light,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateThemeMode('light');
                  },
                ),
                _buildDivider(isDark),
                _buildThemeTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.moon,
                  title: 'display.dark'.tr(),
                  subtitle: 'display.darkSub'.tr(),
                  isSelected: currentThemeMode == ThemeMode.dark,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateThemeMode('dark');
                  },
                ),
                _buildDivider(isDark),
                _buildThemeTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.device_phone_portrait,
                  title: 'display.system'.tr(),
                  subtitle: 'display.systemSub'.tr(),
                  isSelected: currentThemeMode == ThemeMode.system,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateThemeMode('system');
                  },
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Currency & Format ─────────────────────────────────────
              _sectionLabel(context, 'display.currencyFormat'.tr(),
                  key: _currencyKey),
              const SizedBox(height: AppSizes.sm),
              _buildCard(context, isDark, children: [
                _buildOptionTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.money_dollar,
                  title: 'display.currency'.tr(),
                  subtitle: 'display.currencySub'.tr(),
                  value: displayFmt.currencyCode,
                  options: const ['USD', 'EUR', 'GBP', 'JPY', 'INR'],
                  onSelected: (v) =>
                      ref.read(displayFormatProvider.notifier).setCurrency(v),
                ),
                _buildDivider(isDark),
                _buildOptionTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.calendar,
                  title: 'display.dateFormat'.tr(),
                  subtitle: 'display.dateFormatSub'.tr(),
                  value: displayFmt.dateFormat,
                  options: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
                  onSelected: (v) =>
                      ref.read(displayFormatProvider.notifier).setDateFormat(v),
                ),
                _buildDivider(isDark),
                _buildOptionTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.number,
                  title: 'display.numberFormat'.tr(),
                  subtitle: 'display.numberFormatSub'.tr(),
                  value: displayFmt.numberFormat,
                  options: const ['1,234.56', '1.234,56', '1 234.56'],
                  onSelected: (v) => ref
                      .read(displayFormatProvider.notifier)
                      .setNumberFormat(v),
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Language ──────────────────────────────────────────────
              _sectionLabel(context, 'display.language'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildCard(context, isDark, children: [
                _buildOptionTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.globe,
                  title: 'display.language'.tr(),
                  subtitle: 'display.languageSub'.tr(),
                  value: _langCodeToLabel(
                    settingsState.valueOrNull?.language ?? 'en',
                  ),
                  options: _langCodes.map(_langCodeToLabel).toList(),
                  onSelected: (v) async {
                    final idx =
                        _langCodes.map(_langCodeToLabel).toList().indexOf(v);
                    if (idx < 0) return;
                    final code = _langCodes[idx];
                    await context.setLocale(Locale(code));
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('saved_locale', code);
                    ref
                        .read(settingsOperationsProvider.notifier)
                        .updateLanguage(code);
                    if (context.mounted) {
                      SuccessSnackbar.show(
                        context,
                        message: 'display.languageChanged'
                            .tr(namedArgs: {'lang': v}),
                      );
                    }
                  },
                ),
              ]),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text, {Key? key}) {
    return Padding(
      key: key,
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

  Widget _buildThemeTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.labelDark : AppColors.secondaryLabel,
                size: 17,
              ),
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark,
                  size: 16, color: AppColors.primaryTeal)
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return InkWell(
      onTap: () =>
          _showPickerDialog(context, title, value, options, onSelected),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.labelDark : AppColors.secondaryLabel,
                size: 17,
              ),
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
            ),
            const SizedBox(width: AppSizes.xs),
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
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  void _showPickerDialog(
    BuildContext context,
    String title,
    String current,
    List<String> options,
    ValueChanged<String> onSelected,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String selected = current;
        return StatefulBuilder(
          builder: (_, setState) => SimpleDialog(
            title: Text(title),
            children: options
                .map(
                  (option) => SimpleDialogOption(
                    onPressed: () async {
                      setState(() => selected = option);
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      onSelected(option);
                    },
                    child: Row(
                      children: [
                        Expanded(child: Text(option)),
                        if (option == selected)
                          const Icon(CupertinoIcons.checkmark,
                              size: 16, color: AppColors.primaryTeal),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
