import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/auth_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.tertiarySystemBackgroundDark : AppColors.brandTeal.withValues(alpha: 0.12);
    final iconColor = isDark ? Colors.white : AppColors.brandTeal;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.xl),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandTeal.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_crop_circle_badge_plus,
                      size: 44,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'auth.signup.title'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'auth.signup.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xxl),
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.error),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                ],
                Semantics(
                  label: 'Full name field',
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'auth.signup.fullNameLabel'.tr(),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Icon(CupertinoIcons.person, size: 17, color: iconColor),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'auth.signup.nameRequired'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'auth.signup.emailLabel'.tr(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Icon(CupertinoIcons.mail, size: 17, color: iconColor),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'auth.signup.emailRequired'.tr();
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                      return 'auth.signup.emailInvalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                  onChanged: (value) => setState(() {}), // Trigger rebuild for strength indicator
                  decoration: InputDecoration(
                    labelText: 'auth.signup.passwordLabel'.tr(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Icon(CupertinoIcons.lock, size: 17, color: iconColor),
                      ),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Container(
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Icon(
                            _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            size: 17,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.signup.passwordRequired'.tr();
                    }
                    if (value.length < 8) {
                      return 'auth.signup.passwordTooShort'.tr();
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'auth.signup.passwordNeedsUppercase'.tr();
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'auth.signup.passwordNeedsNumber'.tr();
                    }
                    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]').hasMatch(value)) {
                      return 'auth.signup.passwordNeedsSpecial'.tr();
                    }
                    return null;
                  },
                ),
                PasswordStrengthIndicator(password: _passwordController.text),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_acceptedTerms) _handleSignup();
                  },
                  decoration: InputDecoration(
                    labelText: 'auth.signup.confirmPasswordLabel'.tr(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Icon(CupertinoIcons.lock, size: 17, color: iconColor),
                      ),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        child: Container(
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Icon(
                            _obscureConfirmPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            size: 17,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'auth.signup.passwordMismatch'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Wrap(
                    children: [
                      Text(
                        'auth.signup.acceptTerms'.tr(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile/legal'),
                        child: Text(
                          'auth.signup.termsOfService'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brandTeal,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Text(
                        'auth.signup.and'.tr(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile/legal'),
                        child: Text(
                          'auth.signup.privacyPolicy'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brandTeal,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Semantics(
                  label: 'Create account button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: (authState.isLoading || !_acceptedTerms) ? null : _handleSignup,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('auth.signup.createButton'.tr()),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.signup.haveAccount'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'auth.signup.signIn'.tr(),
                        style: const TextStyle(color: AppColors.brandTeal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_acceptedTerms) {
      ErrorSnackbar.show(context, message: 'auth.signup.mustAcceptTerms'.tr());
      return;
    }
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authNotifierProvider.notifier).signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
            );
        if (mounted) {
          // Navigate to email verification page
          context.go('/verify-email', extra: _emailController.text.trim());
        }
      } catch (e) {
        // Error is already handled in the provider
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: ref.read(authNotifierProvider).errorMessage ??
                'auth.signup.failedToCreate'.tr(),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }
}
