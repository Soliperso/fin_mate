import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../providers/admin_providers.dart';

final _announcementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRemoteDataSourceProvider).getAnnouncements();
});

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final announcementsAsync = ref.watch(_announcementsProvider);

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
        title: const Text('Announcement Banners'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.add,
              onTap: () => _openSheet(context, ref, isDark, null),
            ),
          ),
        ],
      ),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load announcements'),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(_announcementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.bell_slash,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'No announcements yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextButton(
                    onPressed: () => _openSheet(context, ref, isDark, null),
                    child: const Text('Create one'),
                  ),
                ],
              ),
            );
          }

          final cardColor = isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) => _AnnouncementCard(
              data: items[i],
              cardColor: cardColor,
              onEdit: () => _openSheet(context, ref, isDark, items[i]),
              onDelete: () => _confirmDelete(context, ref, items[i]['id'] as String),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Map<String, dynamic>? existing,
  ) async {
    final titleCtrl =
        TextEditingController(text: existing?['title'] as String? ?? '');
    final msgCtrl =
        TextEditingController(text: existing?['message'] as String? ?? '');
    final ctaLabelCtrl = TextEditingController(
        text: existing?['cta_label'] as String? ?? '');
    final ctaUrlCtrl =
        TextEditingController(text: existing?['cta_url'] as String? ?? '');

    bool active = existing?['active'] as bool? ?? true;
    DateTime startsAt = existing?['starts_at'] != null
        ? DateTime.parse(existing!['starts_at'] as String).toLocal()
        : DateTime.now();
    DateTime? endsAt = existing?['ends_at'] != null
        ? DateTime.parse(existing!['ends_at'] as String).toLocal()
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: AppSizes.pagePadding,
            right: AppSizes.pagePadding,
            top: AppSizes.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  existing == null
                      ? 'New Announcement'
                      : 'Edit Announcement',
                  style:
                      Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: AppSizes.md),
                _Field(label: 'Title', controller: titleCtrl),
                const SizedBox(height: AppSizes.sm),
                _Field(
                    label: 'Message',
                    controller: msgCtrl,
                    maxLines: 3),
                const SizedBox(height: AppSizes.sm),
                _Field(
                    label: 'CTA Button Label (optional)',
                    controller: ctaLabelCtrl),
                const SizedBox(height: AppSizes.sm),
                _Field(
                    label: 'CTA URL (optional)',
                    controller: ctaUrlCtrl),
                const SizedBox(height: AppSizes.sm),
                // Date pickers
                _DateRow(
                  label: 'Starts',
                  value: startsAt,
                  onPick: (d) => setModal(() => startsAt = d),
                ),
                const SizedBox(height: 6),
                _DateRow(
                  label: 'Ends (optional)',
                  value: endsAt,
                  onPick: (d) => setModal(() => endsAt = d),
                  onClear:
                      endsAt != null ? () => setModal(() => endsAt = null) : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  activeThumbColor: AppColors.brandTeal,
                  activeTrackColor:
                      AppColors.brandTeal.withValues(alpha: 0.5),
                  onChanged: (v) => setModal(() => active = v),
                ),
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty ||
                          msgCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Title and message are required.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        final ds =
                            ref.read(adminRemoteDataSourceProvider);
                        if (existing == null) {
                          await ds.createAnnouncement(
                            title: titleCtrl.text.trim(),
                            message: msgCtrl.text.trim(),
                            ctaLabel: ctaLabelCtrl.text.trim(),
                            ctaUrl: ctaUrlCtrl.text.trim(),
                            active: active,
                            startsAt: startsAt,
                            endsAt: endsAt,
                          );
                        } else {
                          await ds.updateAnnouncement(
                            id: existing['id'] as String,
                            title: titleCtrl.text.trim(),
                            message: msgCtrl.text.trim(),
                            ctaLabel: ctaLabelCtrl.text.trim(),
                            ctaUrl: ctaUrlCtrl.text.trim(),
                            active: active,
                            startsAt: startsAt,
                            endsAt: endsAt,
                          );
                        }
                        ref.invalidate(_announcementsProvider);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Failed to save. Please try again.')),
                          );
                        }
                      }
                    },
                    child: Text(
                      existing == null ? 'Create' : 'Save',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text(
            'This will immediately hide the banner from all users.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRemoteDataSourceProvider).deleteAnnouncement(id);
      ref.invalidate(_announcementsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete. Please try again.')),
        );
      }
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color cardColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.data,
    required this.cardColor,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmt(dynamic val) {
    if (val == null) return '—';
    try {
      return DateFormat('MMM d, y').format(
          DateTime.parse(val as String).toLocal());
    } catch (_) {
      return '—';
    }
  }

  bool get _isLive {
    final active = data['active'] as bool? ?? false;
    if (!active) return false;
    final now = DateTime.now().toUtc();
    final starts = data['starts_at'] != null
        ? DateTime.parse(data['starts_at'] as String)
        : now;
    final ends = data['ends_at'] != null
        ? DateTime.parse(data['ends_at'] as String)
        : null;
    return starts.isBefore(now) && (ends == null || ends.isAfter(now));
  }

  @override
  Widget build(BuildContext context) {
    final live = _isLive;
    final active = data['active'] as bool? ?? false;

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
                Expanded(
                  child: Text(
                    data['title'] as String,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ),
                if (live)
                  _StatusChip(label: 'LIVE', color: AppColors.brandTeal)
                else if (active)
                  _StatusChip(label: 'Scheduled', color: AppColors.systemBlue)
                else
                  _StatusChip(
                      label: 'Inactive', color: AppColors.textSecondary),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(CupertinoIcons.pencil, size: 18),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onDelete,
                  child:
                      const Icon(CupertinoIcons.trash, size: 18, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data['message'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${_fmt(data['starts_at'])} → ${data['ends_at'] != null ? _fmt(data['ends_at']) : 'No end date'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;

  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = value != null
        ? DateFormat('MMM d, y').format(value!)
        : 'Not set';

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(dateStr),
        ),
        if (onClear != null)
          GestureDetector(
            onTap: onClear,
            child: Icon(CupertinoIcons.xmark_circle,
                size: 16, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}
