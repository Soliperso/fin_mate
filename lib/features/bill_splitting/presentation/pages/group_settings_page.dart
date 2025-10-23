import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/bill_group_entity.dart';
import '../providers/bill_splitting_providers.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  final BillGroup group;
  final String groupId;

  const GroupSettingsPage({
    super.key,
    required this.group,
    required this.groupId,
  });

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group name cannot be empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref.read(groupOperationsProvider.notifier).updateGroup(
            groupId: widget.groupId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      if (success && mounted) {
        ref.invalidate(groupProvider(widget.groupId));
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        SuccessSnackbar.show(context, message: 'Group updated successfully');
      } else if (mounted) {
        setState(() => _isSaving = false);
        ErrorSnackbar.show(context, message: 'Failed to update group');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorSnackbar.show(context, message: 'Error: $e');
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Group'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this group?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: AppSizes.md),
              Text(
                'This action cannot be undone. All expenses, settlements, and member data will be permanently deleted.',
                style: TextStyle(color: AppColors.error),
              ),
              SizedBox(height: AppSizes.md),
              Text(
                'Please settle all outstanding balances before deleting the group.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await _deleteGroup();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      final success = await ref.read(groupOperationsProvider.notifier).deleteGroup(widget.groupId);

      if (success && mounted) {
        ref.invalidate(userGroupsProvider);
        Navigator.of(context).popUntil((route) => route.isFirst);
        SuccessSnackbar.show(context, message: 'Group deleted successfully');
      } else if (mounted) {
        ErrorSnackbar.show(context, message: 'Failed to delete group');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: 'Error: $e');
      }
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer see this group or receive updates about it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _leaveGroup();
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final success = await ref.read(memberOperationsProvider.notifier).removeMember(
            groupId: widget.groupId,
            userId: currentUserId,
          );

      if (success && mounted) {
        ref.invalidate(userGroupsProvider);
        Navigator.of(context).popUntil((route) => route.isFirst);
        SuccessSnackbar.show(context, message: 'You left the group');
      } else if (mounted) {
        ErrorSnackbar.show(context, message: 'Failed to leave group');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isCreator = widget.group.createdBy == currentUserId;
    final balancesAsync = ref.watch(groupBalancesProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Group Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Information Section
            _buildSectionHeader(context, 'Group Information'),
            const SizedBox(height: AppSizes.md),
            _buildGroupInfoCard(context, dateFormat),
            const SizedBox(height: AppSizes.xl),

            // Edit Group Section
            if (_isEditing) ...[
              _buildEditForm(context),
              const SizedBox(height: AppSizes.xl),
            ] else ...[
              _buildViewMode(context),
              const SizedBox(height: AppSizes.xl),
            ],

            // Balances Warning (if any)
            balancesAsync.when(
              data: (balances) {
                final hasUnsettledBalances = balances.any((b) => b.balance != 0);
                if (hasUnsettledBalances) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AppColors.warning, size: 20),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                'Unsettled balances exist. Please settle all balances before deleting the group.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.warning,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Danger Zone
            _buildSectionHeader(context, 'Danger Zone'),
            const SizedBox(height: AppSizes.md),
            _buildDangerZone(context, isCreator),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildGroupInfoCard(BuildContext context, DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Icons.group,
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
                        widget.group.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        'Created ${dateFormat.format(widget.group.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.group.description != null && widget.group.description!.isNotEmpty) ...[
              const Divider(height: AppSizes.lg),
              Text(
                'Description',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                widget.group.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isCreator = widget.group.createdBy == currentUserId;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          setState(() => _isEditing = true);
        },
        icon: const Icon(Icons.edit),
        label: Text(isCreator ? 'Edit Group' : 'View Details'),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Group Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() => _isEditing = false);
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, bool isCreator) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCreator) ...[
              Text(
                'Delete Group',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Permanently delete this group and all associated data. This action cannot be undone.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showDeleteConfirmation,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Group'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Leave Group',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Remove yourself from this group. You will no longer see group expenses or balances.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showLeaveConfirmation,
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave Group'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
