import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/profile_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCurrency = 'USD';
  String? _selectedAvatarPath;

  // Originals captured at load time for unsaved-changes detection
  String _originalFullName = '';
  String _originalPhone = '';
  String _originalCurrency = 'USD';

  bool get _hasUnsavedChanges =>
      _fullNameController.text != _originalFullName ||
      _phoneController.text != _originalPhone ||
      _selectedCurrency != _originalCurrency ||
      _selectedAvatarPath != null;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'MXN',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile = ref.read(currentUserProfileProvider).profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
      _selectedCurrency = profile.currency;

      _originalFullName = _fullNameController.text;
      _originalPhone = _phoneController.text;
      _originalCurrency = _selectedCurrency;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Section helpers (matching profile_page.dart style) ────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
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

  Widget _buildSectionCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

  Widget _iconBadge(IconData icon, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color ??
            (isDark
                ? AppColors.tertiarySystemBackgroundDark
                : AppColors.secondarySystemBackground),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 17,
        color: color != null
            ? AppColors.white
            : (isDark ? AppColors.labelDark : AppColors.label),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildEmailRow(String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      child: Row(
        children: [
          _iconBadge(CupertinoIcons.envelope),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'profile.cannotBeChanged'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required Widget prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        child: prefixIcon,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 64, minHeight: 32),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      filled: true,
      fillColor: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.systemBackground,
      contentPadding: const EdgeInsets.only(
        right: AppSizes.md,
        top: 12,
        bottom: 12,
      ),
    );
  }

  // ── Navigation guard ──────────────────────────────────────────────────────

  Future<void> _handleClose() async {
    if (!_hasUnsavedChanges) {
      if (mounted) context.pop();
      return;
    }

    final discard = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: Text('profile.unsavedChanges'.tr()),
        content: Text('profile.discardChangesMessage'.tr()),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text('profile.discard'.tr()),
          ),
        ],
      ),
    );

    if (discard == true && mounted) context.pop();
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Future<void> _showAvatarOptions() async {
    final profile = ref.read(currentUserProfileProvider).profile;
    final hasPersistedAvatar = (profile?.avatarUrl ?? '').isNotEmpty;
    final hasLocalPick = _selectedAvatarPath != null;
    GlassBottomSheet.show(
      context: context,
      child: SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.photo),
              title: Text('profile.chooseFromGallery'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.camera),
              title: Text('profile.takeAPhoto'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (hasPersistedAvatar || hasLocalPick) ...[
              Divider(
                height: 0,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.trash,
                    color: AppColors.systemRed),
                title: Text(
                  'profile.removePhoto'.tr(),
                  style: const TextStyle(color: AppColors.systemRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (hasLocalPick) {
                    setState(() => _selectedAvatarPath = null);
                  } else {
                    _handleDeleteAvatar();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _selectedAvatarPath = pickedFile.path);
    }
  }

  // ── Save / Delete ─────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_selectedAvatarPath != null) {
          await ref
              .read(currentUserProfileProvider.notifier)
              .uploadAndUpdateAvatar(_selectedAvatarPath!);
        }

        await ref.read(currentUserProfileProvider.notifier).updateProfile(
              fullName: _fullNameController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              currency: _selectedCurrency,
            );

        if (mounted) {
          SuccessSnackbar.show(
            context,
            message: 'profile.profileUpdated'.tr(),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: 'profile.failedToUpdateProfile'.tr(),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.removePhoto'.tr()),
        content: Text('profile.removePhotoConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'profile.removePhoto'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(currentUserProfileProvider.notifier).deleteAvatar();
        setState(() => _selectedAvatarPath = null);
        if (mounted) {
          SuccessSnackbar.show(
            context,
            message: 'profile.profileUpdated'.tr(),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: 'profile.failedToRemovePhoto'.tr(),
          );
        }
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = profileState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleClose();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('profile.editProfileTitle'.tr()),
          leading: Center(
            child: CircularIconButton(
              icon: CupertinoIcons.xmark,
              onTap: _handleClose,
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  profileState.isLoading || profileState.isUploadingAvatar
                      ? null
                      : _handleSave,
              child: profileState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.save'.tr()),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: AppSizes.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar ────────────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: profileState.isUploadingAvatar
                          ? null
                          : _showAvatarOptions,
                      child: Stack(
                        children: [
                          _buildAvatar(profile),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(AppSizes.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.white, width: 3),
                              ),
                              child: profileState.isUploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.white),
                                      ),
                                    )
                                  : const Icon(
                                      CupertinoIcons.camera,
                                      size: 20,
                                      color: AppColors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Center(
                    child: Text(
                      'profile.tapToChangePhoto'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // ── Personal Information ──────────────────────────────────
                  _sectionLabel('profile.personalInformation'.tr()),
                  const SizedBox(height: AppSizes.sm),
                  _buildSectionCard(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _fieldDecoration(
                          labelText: 'profile.fullName'.tr(),
                          prefixIcon: _iconBadge(CupertinoIcons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'profile.fullNameRequired'.tr();
                          }
                          return null;
                        },
                      ),
                      _buildDivider(),
                      TextFormField(
                        controller: _phoneController,
                        decoration: _fieldDecoration(
                          labelText: 'profile.phoneNumber'.tr(),
                          prefixIcon: _iconBadge(CupertinoIcons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ── Account ───────────────────────────────────────────────
                  _sectionLabel('profile.account'.tr()),
                  const SizedBox(height: AppSizes.sm),
                  _buildSectionCard(
                    children: [
                      _buildEmailRow(profile?.email ?? ''),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ── Preferences ───────────────────────────────────────────
                  _sectionLabel('profile.preferences'.tr()),
                  const SizedBox(height: AppSizes.sm),
                  _buildSectionCard(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCurrency,
                        decoration: _fieldDecoration(
                          labelText: 'profile.preferredCurrency'.tr(),
                          prefixIcon: _iconBadge(CupertinoIcons.money_dollar),
                        ),
                        dropdownColor: isDark
                            ? AppColors.secondarySystemBackgroundDark
                            : AppColors.systemBackground,
                        items: _currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCurrency = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic profile) {
    if (_selectedAvatarPath != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryTeal, width: 4),
          image: DecorationImage(
            image: FileImage(File(_selectedAvatarPath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryTeal, width: 4),
          image: DecorationImage(
            image: NetworkImage(profile.avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryTeal.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.primaryTeal, width: 4),
      ),
      child: Center(
        child: Text(
          profile?.initials ?? 'U',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
    );
  }
}
