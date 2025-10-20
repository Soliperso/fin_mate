import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/group_member_entity.dart';
import '../providers/bill_splitting_providers.dart';

class AddMemberBottomSheet extends ConsumerStatefulWidget {
  final String groupId;

  const AddMemberBottomSheet({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends ConsumerState<AddMemberBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  MemberRole _selectedRole = MemberRole.member;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(memberOperationsProvider.notifier).addMember(
            groupId: widget.groupId,
            userEmail: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(groupMembersProvider(widget.groupId));
        ref.invalidate(groupBalancesProvider(widget.groupId));

        Navigator.of(context).pop(true);
        SuccessSnackbar.show(context, message: 'Member added successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = 'Failed to add member';
        final errorString = e.toString();

        if (errorString.contains('User not found')) {
          errorMessage = 'No user found with email "${_emailController.text.trim()}". Please check the email and try again.';
        } else if (errorString.contains('Already a member')) {
          errorMessage = 'This user is already a member of the group';
        } else if (errorString.contains('permission') || errorString.contains('denied')) {
          errorMessage = 'You don\'t have permission to add members';
        } else {
          errorMessage = 'Failed to add member. Please try again.';
        }

        ErrorSnackbar.show(context, message: errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.md,
          right: AppSizes.md,
          top: AppSizes.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
        ),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Member',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Info Card
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryTeal,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Enter the email address of the person you want to add. They must have a FinMate account.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryTeal,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofocus: true,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address';
                  }
                  // Basic email validation
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _addMember(),
              ),
              const SizedBox(height: AppSizes.md),

              // Role Selection
              Text(
                'Role',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() => _selectedRole = MemberRole.member);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sm,
                            horizontal: AppSizes.md,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRole == MemberRole.member
                                ? AppColors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person,
                                color: _selectedRole == MemberRole.member
                                    ? AppColors.primaryTeal
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Member',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _selectedRole == MemberRole.member
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedRole == MemberRole.member
                                      ? AppColors.slateBlue
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Can view expenses',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _selectedRole == MemberRole.member
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() => _selectedRole = MemberRole.admin);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sm,
                            horizontal: AppSizes.md,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRole == MemberRole.admin
                                ? AppColors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: _selectedRole == MemberRole.admin
                                    ? AppColors.primaryTeal
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Admin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _selectedRole == MemberRole.admin
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedRole == MemberRole.admin
                                      ? AppColors.slateBlue
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Can manage group',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _selectedRole == MemberRole.admin
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Cancel',
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: CustomButton(
                      label: 'Add Member',
                      onPressed: _isLoading ? null : _addMember,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
