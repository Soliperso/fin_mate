import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
// import 'package:supabase_flutter/supabase_flutter.dart' show Session; // [Biometric]
// import '../../../../core/config/supabase_client.dart'; // [Biometric]
import '../../../../core/services/secure_storage_provider.dart';
// import '../../../../core/services/biometric_provider.dart'; // [Biometric]
// import '../../../../shared/widgets/success_animation.dart'; // [Biometric]
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
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    // Clear errors when user types (addListener fires on programmatic clear() too,
    // which would wipe the error set by a failed login before the UI renders it —
    // onChanged fires only on actual user input, so the error survives the
    // programmatic password clear that happens after a failed attempt).
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
      // Email is already filled — jump straight to the password field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _passwordFocusNode.requestFocus();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocusNode.requestFocus();
      });
    }
  }

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
                      CupertinoIcons.lock_shield_fill,
                      size: 44,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'auth.login.title'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'auth.login.subtitle'.tr(),
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
                  label: 'Email address field',
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearError(),
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'auth.login.emailLabel'.tr(),
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
                      if (value == null || value.isEmpty) return 'auth.login.emailRequired'.tr();
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                        return 'auth.login.emailInvalid'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Semantics(
                  label: 'Password field',
                  child: TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _clearError(),
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'auth.login.passwordLabel'.tr(),
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
                        return 'auth.login.passwordRequired'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: authState.isLoading
                          ? null
                          : (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                    ),
                    Text(
                      'auth.login.rememberMe'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: authState.isLoading ? null : _handleForgotPassword,
                      child: Text(
                        'auth.login.forgotPassword'.tr(),
                        style: const TextStyle(color: AppColors.brandTeal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                // [Biometric: commented out — login button with biometric icon]
                // Consumer(
                //   builder: (context, ref, child) {
                //     final isBiometricAvailable = ref.watch(isBiometricAvailableProvider);
                //     final showBiometric = isBiometricAvailable.maybeWhen(
                //       data: (v) => v,
                //       orElse: () => false,
                //     );
                //     if (!showBiometric) { return ElevatedButton(...); }
                //     return FutureBuilder<String?>( // token check + biometric button
                //       ...
                //     );
                //   },
                // ),
                Semantics(
                  label: 'Log in button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('auth.login.loginButton'.tr()),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.login.noAccount'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text(
                        'auth.login.signUp'.tr(),
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

  Future<void> _handleLogin() async {
    // Enforce client-side lockout
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      ref.read(authNotifierProvider.notifier).setError(
            'auth.login.tooManyAttempts'.tr(args: [remaining.toString()]),
          );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final storageService = ref.read(secureStorageServiceProvider);

        await storageService.saveEmail(email);

        await ref.read(authNotifierProvider.notifier).signInWithEmail(
              email: email,
              password: password,
            );

        // Success — reset failure counter and clear password from memory
        _failedAttempts = 0;
        _lockoutUntil = null;
        _passwordController.clear();

        // [Biometric: commented out — refresh token storage for biometric re-auth]
        // final biometricService = ref.read(biometricServiceProvider);
        // final isAvailable = await biometricService.isBiometricAvailable();
        // final refreshToken = supabase.auth.currentSession?.refreshToken;
        // if (refreshToken != null) { await storageService.saveRefreshToken(refreshToken); }
        // if (isAvailable) { await storageService.setBiometricEnabled(true); }

        // Router will automatically redirect to dashboard via redirect logic
      } catch (e) {
        // Clear password on failure too — never leave it in memory after an attempt
        _passwordController.clear();

        _failedAttempts++;
        if (_failedAttempts >= AppConfig.maxLoginAttempts) {
          setState(() {
            _lockoutUntil = DateTime.now().add(const Duration(minutes: 15));
          });
        }
        // Error message shown via the inline error box (authState.errorMessage)
      }
    }
  }

  // [Biometric: commented out]
  // Future<void> _handleBiometricLogin() async {
  //   try {
  //     final biometricService = ref.read(biometricServiceProvider);
  //     final isAvailable = await biometricService.isBiometricAvailable();
  //     if (!isAvailable) {
  //       if (mounted) showErrorDialog(context, 'auth.login.biometricNotAvailable'.tr());
  //       return;
  //     }
  //     final result = await biometricService.authenticate(
  //       localizedReason: 'auth.login.biometricReason'.tr(),
  //     );
  //     if (!result.success) {
  //       if (mounted) {
  //         showErrorDialog(context, result.errorMessage ?? 'auth.login.biometricFailed'.tr());
  //       }
  //       return;
  //     }
  //     final storageService = ref.read(secureStorageServiceProvider);
  //     final refreshToken = await storageService.getRefreshToken();
  //     if (refreshToken == null || refreshToken.isEmpty) {
  //       if (mounted) showErrorDialog(context, 'auth.login.biometricNoCredentials'.tr());
  //       return;
  //     }
  //     Session? session;
  //     try {
  //       final response = await supabase.auth.refreshSession(refreshToken);
  //       session = response.session;
  //     } catch (_) {}
  //     if (session == null) {
  //       await storageService.clearRefreshToken();
  //       if (mounted) {
  //         setState(() {});
  //         showErrorDialog(context,
  //           'Your session has expired. Log in once with your password — Face ID will work for all future logins.');
  //       }
  //       return;
  //     }
  //     await storageService.saveRefreshToken(session.refreshToken!);
  //     await ref.read(authNotifierProvider.notifier).refreshCurrentUser();
  //   } catch (e) {
  //     if (mounted) showErrorDialog(context, 'auth.login.biometricFailed'.tr());
  //   }
  // }

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
