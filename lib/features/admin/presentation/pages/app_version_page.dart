import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../providers/admin_providers.dart';

final _appVersionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRemoteDataSourceProvider).getAppVersions();
});

class AppVersionPage extends ConsumerStatefulWidget {
  const AppVersionPage({super.key});

  @override
  ConsumerState<AppVersionPage> createState() => _AppVersionPageState();
}

class _AppVersionPageState extends ConsumerState<AppVersionPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final versionsAsync = ref.watch(_appVersionsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        title: const Text('App Version Manager'),
      ),
      body: versionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load version settings'),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(_appVersionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (versions) => ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            _InfoBanner(isDark: isDark),
            const SizedBox(height: AppSizes.md),
            ...versions.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _PlatformCard(
                  data: v,
                  isDark: isDark,
                  onSaved: () => ref.invalidate(_appVersionsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isDark;
  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: AppColors.brandTeal.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.info_circle, color: AppColors.brandTeal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enable "Force Update" to block users below the minimum version. '
              'Users on or above the minimum are unaffected.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandTeal,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final VoidCallback onSaved;

  const _PlatformCard({
    required this.data,
    required this.isDark,
    required this.onSaved,
  });

  @override
  ConsumerState<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends ConsumerState<_PlatformCard> {
  bool _saving = false;

  String get platform => widget.data['platform'] as String;

  IconData get platformIcon =>
      platform == 'ios' ? CupertinoIcons.device_phone_portrait : CupertinoIcons.device_phone_portrait;

  String get platformLabel => platform == 'ios' ? 'iOS' : 'Android';

  String _formatDate(dynamic val) {
    if (val == null) return '—';
    try {
      return DateFormat('MMM d, y').format(DateTime.parse(val as String).toLocal());
    } catch (_) {
      return '—';
    }
  }

  Future<void> _openEditSheet() async {
    final minCtrl = TextEditingController(
        text: widget.data['min_version'] as String? ?? '1.0.0');
    final latestCtrl = TextEditingController(
        text: widget.data['latest_version'] as String? ?? '1.0.0');
    final notesCtrl = TextEditingController(
        text: widget.data['release_notes'] as String? ?? '');
    bool forceUpdate =
        widget.data['force_update'] as bool? ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSizes.pagePadding,
                right: AppSizes.pagePadding,
                top: AppSizes.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Edit $platformLabel Version',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  _VersionField(
                    label: 'Minimum Version',
                    hint: '1.0.0',
                    controller: minCtrl,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _VersionField(
                    label: 'Latest Version',
                    hint: '1.2.0',
                    controller: latestCtrl,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Release Notes (optional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Force Update'),
                    subtitle: Text(
                      'Block users below the minimum version',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    value: forceUpdate,
                    activeThumbColor: Colors.red,
                    activeTrackColor: Colors.red.withValues(alpha: 0.5),
                    onChanged: (v) => setModal(() => forceUpdate = v),
                  ),
                  const SizedBox(height: AppSizes.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(adminRemoteDataSourceProvider)
                              .setAppVersion(
                                platform: platform,
                                minVersion: minCtrl.text.trim(),
                                latestVersion: latestCtrl.text.trim(),
                                releaseNotes: notesCtrl.text.trim(),
                                forceUpdate: forceUpdate,
                              );
                          widget.onSaved();
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save. Please try again.'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    final forceUpdate = widget.data['force_update'] as bool? ?? false;
    final updatedBy = widget.data['updated_by'] as String?;
    final dateStr = _formatDate(widget.data['updated_at']);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    platform == 'ios'
                        ? CupertinoIcons.device_phone_portrait
                        : CupertinoIcons.device_phone_portrait,
                    size: 18,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  platformLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (forceUpdate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'FORCE UPDATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _openEditSheet,
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.sm),
            _Row(
              label: 'Minimum Version',
              value: widget.data['min_version'] as String? ?? '—',
            ),
            const SizedBox(height: 4),
            _Row(
              label: 'Latest Version',
              value: widget.data['latest_version'] as String? ?? '—',
            ),
            if ((widget.data['release_notes'] as String?)?.isNotEmpty ==
                true) ...[
              const SizedBox(height: 4),
              _Row(
                label: 'Release Notes',
                value: widget.data['release_notes'] as String,
              ),
            ],
            const SizedBox(height: 4),
            _Row(
              label: 'Last Changed',
              value: updatedBy != null
                  ? '$updatedBy · $dateStr'
                  : (dateStr != '—' ? dateStr : 'Never'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _VersionField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
