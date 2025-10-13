import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/bill_splitting_providers.dart';

class CreateGroupBottomSheet extends ConsumerStatefulWidget {
  const CreateGroupBottomSheet({super.key});

  @override
  ConsumerState<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends ConsumerState<CreateGroupBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final group = await ref.read(groupOperationsProvider.notifier).createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      if (group != null && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      } else if (mounted) {
        // Check the error state
        final errorState = ref.read(groupOperationsProvider);
        final errorMessage = errorState.hasError
            ? errorState.error.toString()
            : 'Failed to create group';
        print('❌ Group creation error: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: ${errorState.hasError ? errorState.error : "Unknown error"}')),
        );
      }
    } catch (e) {
      print('❌ Exception during group creation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationsState = ref.watch(groupOperationsProvider);
    final isLoading = operationsState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Group',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Roommates, Weekend Trip',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
              enabled: !isLoading,
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add a description for this group',
              ),
              maxLines: 3,
              enabled: !isLoading,
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Cancel',
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: CustomButton(
                    label: 'Create',
                    onPressed: isLoading ? null : _createGroup,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
