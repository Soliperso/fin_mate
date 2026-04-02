import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/secure_storage_provider.dart';
import '../../../../core/services/biometric_provider.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    // Auto-focus email field when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocusNode.requestFocus();
    });

    // Clear errors when user types
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    final authState = ref.read(authNotifierProvider);
    if (authState.errorMessage != null) {
      ref.read(authNotifierProvider.notifier).clearError();
    }
  }

  Future<void> _loadSavedCredentials() async {
    final storageService = ref.read(secureStorageServiceProvider);
    final email = await storageService.getSavedEmail();

    if (email != null) {
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

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
                      CupertinoIcons.lock_shield_fill,
                      size: 44,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Sign in to continue managing your finances',
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
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Icon(CupertinoIcons.mail, size: 17, color: Colors.white),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Icon(CupertinoIcons.lock, size: 17, color: Colors.white),
                      ),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Icon(
                            _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: authState.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                                // Clear fields when remember me is unchecked
                                if (!_rememberMe) {
                                  _emailController.clear();
                                  _passwordController.clear();
                                }
                              });
                            },
                    ),
                    Text(
                      'Remember me',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: authState.isLoading ? null : _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppColors.brandTeal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: AppColors.brandTeal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                Consumer(
                  builder: (context, ref, child) {
                    final isBiometricAvailable = ref.watch(isBiometricAvailableProvider);

                    return isBiometricAvailable.when(
                      data: (isAvailable) {
                        if (!isAvailable) return const SizedBox.shrink();

                        // Check if email is saved
                        return FutureBuilder<String?>(
                          future: ref.read(secureStorageServiceProvider).getSavedEmail(),
                          builder: (context, snapshot) {
                            // Only show if user has saved email
                            if (!snapshot.hasData || snapshot.data == null) {
                              return const SizedBox.shrink();
                            }

                            return OutlinedButton.icon(
                              onPressed: authState.isLoading ? null : _handleBiometricLogin,
                              icon: const Icon(CupertinoIcons.lock_circle),
                              label: const Text('Use Biometric Login'),
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final storageService = ref.read(secureStorageServiceProvider);

        // Save or clear credentials based on remember me
        if (_rememberMe) {
          await storageService.saveEmail(email);

          // Check if biometric is available and enable it
          final biometricService = ref.read(biometricServiceProvider);
          final isAvailable = await biometricService.isBiometricAvailable();
          if (isAvailable) {
            await storageService.setBiometricEnabled(true);
          }
        } else {
          await storageService.clearEmail();
          await storageService.setBiometricEnabled(false);
        }

        await ref.read(authNotifierProvider.notifier).signInWithEmail(
              email: email,
              password: password,
            );
        // Router will automatically redirect to dashboard via redirect logic
      } catch (e) {
        // Error is shown via the inline error box (authState.errorMessage)
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);
      final storageService = ref.read(secureStorageServiceProvider);

      final isAvailable = await biometricService.isBiometricAvailable();

      if (!isAvailable) {
        if (mounted) {
          showErrorDialog(
            context,
            'Biometric authentication is not available on this device',
          );
        }
        return;
      }

      final email = await storageService.getSavedEmail();

      if (email == null) {
        if (mounted) {
          showErrorDialog(
            context,
            'No saved email found. Please log in first.',
          );
        }
        return;
      }

      // Authenticate with biometrics first
      final result = await biometricService.authenticate(
        localizedReason: 'Authenticate to access Finmate',
      );

      if (!result.success) {
        if (mounted) {
          showErrorDialog(
            context,
            result.errorMessage ?? 'Biometric authentication failed',
          );
        }
        return;
      }

      // Pre-fill email and focus password field
      _emailController.text = email;
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Biometric authentication failed');
      }
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.go('/forgot-password?email=${Uri.encodeComponent(email)}');
    } else {
      context.go('/forgot-password');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
