import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/secure_storage_provider.dart';
import '../../../../core/services/biometric_provider.dart';
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
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.xl),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Sign in to continue managing your finances',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                  keyboardType: TextInputType.emailAddress,
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
                  obscureText: _obscurePassword,
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
                          : (value) => setState(() => _rememberMe = value ?? false),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(authNotifierProvider).errorMessage ??
                'Failed to sign in. Please try again.'),
              backgroundColor: AppColors.error,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication is not available on this device'),
              backgroundColor: AppColors.error,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved credentials found. Please login with "Remember me" enabled first.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Biometric authentication failed'),
              backgroundColor: AppColors.error,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reset link. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
