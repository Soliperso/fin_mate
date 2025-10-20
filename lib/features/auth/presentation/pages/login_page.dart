import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
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
  final _logger = Logger();
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
  }

  Future<void> _loadSavedCredentials() async {
    final storageService = ref.read(secureStorageServiceProvider);
    final rememberMe = await storageService.isRememberMeEnabled();

    if (rememberMe) {
      final email = await storageService.getSavedEmail();
      final password = await storageService.getSavedPassword();

      if (email != null && password != null) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryTeal.withValues(alpha: 0.15),
                          AppColors.primaryTeal.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.lock_person_outlined,
                      size: 58,
                      color: AppColors.primaryTeal.withValues(alpha: 0.7),
                      weight: 210,
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
                        Icon(Icons.error_outline, color: AppColors.error),
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
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
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
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: authState.isLoading ? null : _handleForgotPassword,
                      child: const Text('Forgot Password?'),
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('Sign Up'),
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

                        // Check if credentials are saved
                        return FutureBuilder<bool>(
                          future: ref.read(secureStorageServiceProvider).isRememberMeEnabled(),
                          builder: (context, snapshot) {
                            // Only show if user has saved credentials
                            if (!snapshot.hasData || !snapshot.data!) {
                              return const SizedBox.shrink();
                            }

                            return OutlinedButton.icon(
                              onPressed: authState.isLoading ? null : _handleBiometricLogin,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Use Biometric Login'),
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
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
          await storageService.saveCredentials(
            email: email,
            password: password,
          );

          // Check if biometric is available and enable it
          final biometricService = ref.read(biometricServiceProvider);
          final isAvailable = await biometricService.isBiometricAvailable();
          if (isAvailable) {
            await storageService.setBiometricEnabled(true);
          }
        } else {
          await storageService.clearCredentials();
          await storageService.setBiometricEnabled(false);
        }

        await ref.read(authNotifierProvider.notifier).signInWithEmail(
              email: email,
              password: password,
            );
        // Router will automatically redirect to dashboard via redirect logic
      } catch (e) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: ref.read(authNotifierProvider).errorMessage ??
                'Failed to sign in. Please try again.',
          );
        }
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    _logger.d('Biometric login button pressed');

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final storageService = ref.read(secureStorageServiceProvider);

      _logger.d('Checking biometric availability...');
      final isAvailable = await biometricService.isBiometricAvailable();
      _logger.d('Biometric available: $isAvailable');

      if (!isAvailable) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: 'Biometric authentication is not available on this device',
          );
        }
        return;
      }

      _logger.d('Getting saved credentials...');
      final email = await storageService.getSavedEmail();
      final password = await storageService.getSavedPassword();
      _logger.d('Email found: ${email != null}, Password found: ${password != null}');

      if (email == null || password == null) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: 'No saved credentials found. Please login with "Remember me" enabled first.',
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }

      _logger.d('Starting biometric authentication...');
      // Authenticate with biometrics
      final result = await biometricService.authenticate(
        localizedReason: 'Authenticate to access FinMate',
      );

      _logger.d('Biometric result: ${result.success}');
      if (!result.success) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: result.errorMessage ?? 'Biometric authentication failed',
          );
        }
        return;
      }

      _logger.d('Biometric success, signing in...');
      // Sign in with saved credentials
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            email: email,
            password: password,
          );
      _logger.d('Sign in complete');
    } catch (e, stackTrace) {
      _logger.e('Biometric login error', error: e, stackTrace: stackTrace);

      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: 'Biometric login failed: ${e.toString()}',
        );
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
