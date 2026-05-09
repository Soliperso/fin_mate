import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  final String? email;

  const ForgotPasswordPage({super.key, this.email});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      color: _emailSent
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.brandTeal.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      _emailSent
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.lock_rotation,
                      size: 44,
                      color: _emailSent ? AppColors.success : AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  _emailSent
                      ? 'auth.forgotPassword.titleSent'.tr()
                      : 'auth.forgotPassword.title'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  _emailSent
                      ? 'auth.forgotPassword.subtitleSent'.tr()
                      : 'auth.forgotPassword.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xxl),
                if (!_emailSent) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'auth.forgotPassword.emailLabel'.tr(),
                      hintText: 'auth.forgotPassword.emailHint'.tr(),
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
                      if (value == null || value.isEmpty) return 'auth.forgotPassword.emailRequired'.tr();
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                        return 'auth.forgotPassword.emailInvalid'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('auth.forgotPassword.sendButton'.tr()),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.forgotPassword.rememberPassword'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'auth.forgotPassword.logIn'.tr(),
                          style: const TextStyle(color: AppColors.brandTeal),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.info_circle, color: AppColors.success),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                'auth.forgotPassword.didntReceive'.tr(),
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'auth.forgotPassword.checkSpam'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleResendEmail,
                    icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('auth.forgotPassword.resendEmail'.tr()),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('auth.forgotPassword.backToLogin'.tr()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        await ref.read(authNotifierProvider.notifier).resetPassword(email);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          final stateError = ref.read(authNotifierProvider).errorMessage;
          ErrorSnackbar.show(
            context,
            message: stateError ?? 'auth.forgotPassword.failedToSend'.tr(),
          );
        }
      }
    }
  }

  Future<void> _handleResendEmail() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await ref.read(authNotifierProvider.notifier).resetPassword(email);

      if (mounted) {
        setState(() => _isLoading = false);
        SuccessSnackbar.show(
          context,
          message: 'auth.forgotPassword.resentSuccess'.tr(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final stateError = ref.read(authNotifierProvider).errorMessage;
        ErrorSnackbar.show(
          context,
          message: stateError ?? 'auth.forgotPassword.failedToResend'.tr(),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
