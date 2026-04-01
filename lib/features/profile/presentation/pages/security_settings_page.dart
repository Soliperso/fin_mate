import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/biometric_provider.dart';
import '../../../../core/services/secure_storage_provider.dart';
import '../../../../core/services/mfa_provider.dart';
import '../../../../core/services/mfa_service.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _isLoadingBiometric = false;
  bool _isLoadingMfa = false;

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(secureStorageServiceProvider);
    final isBiometricAvailableAsync = ref.watch(isBiometricAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Security Settings'),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Methods',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            // Biometric Authentication
            isBiometricAvailableAsync.when(
              data: (isAvailable) {
                if (!isAvailable) return const SizedBox.shrink();

                return FutureBuilder<bool>(
                  future: storage.isBiometricEnabled(),
                  builder: (context, snapshot) {
                    final isEnabled = snapshot.data ?? false;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.fingerprint), // keep as-is (platform-specific)
                        title: Text(
                          'Biometric Login',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        subtitle: FutureBuilder<String?>(
                          future: ref.read(biometricServiceProvider).getPrimaryBiometricType(),
                          builder: (context, typeSnapshot) {
                            final type = typeSnapshot.data ?? 'Biometric';
                            return Text(
                              'Use $type to sign in quickly',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                            );
                          },
                        ),
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.primaryTeal,
                            onChanged: _isLoadingBiometric
                                ? null
                                : (value) => _handleBiometricToggle(value),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSizes.md),

            // Multi-Factor Authentication
            FutureBuilder<bool>(
              future: storage.isMfaEnabled(),
              builder: (context, snapshot) {
                final isMfaEnabled = snapshot.data ?? false;

                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(CupertinoIcons.shield),
                        title: Text(
                          'Multi-Factor Authentication',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        subtitle: Text(
                          isMfaEnabled
                              ? 'MFA is enabled for extra security'
                              : 'Add an extra layer of security',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                          value: isMfaEnabled,
                          thumbColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? Colors.white : null,
                          ),
                          trackColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? AppColors.primaryTeal : null,
                          ),
                          onChanged: _isLoadingMfa
                              ? null
                              : (value) {
                                  if (value) {
                                    _showMfaSetupOptions();
                                  } else {
                                    _handleDisableMfa();
                                  }
                                },
                          ),
                        ),
                      ),
                      if (isMfaEnabled) ...[
                        const Divider(height: 1),
                        FutureBuilder<String?>(
                          future: storage.getMfaMethod(),
                          builder: (context, methodSnapshot) {
                            final method = methodSnapshot.data;
                            final mfaMethodEnum = MfaMethodExtension.fromString(method);

                            return ListTile(
                              leading: Icon(
                                method == 'email' ? CupertinoIcons.envelope : CupertinoIcons.qrcode,
                                size: 20,
                              ),
                              title: Text(
                                mfaMethodEnum?.displayName ?? 'Unknown Method',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                                    ),
                              ),
                              trailing: TextButton(
                                onPressed: _showMfaSetupOptions,
                                child: const Text('Change'),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.lg),

            Text(
              'Password',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            Card(
              child: ListTile(
                leading: const Icon(CupertinoIcons.lock),
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                subtitle: Text(
                  'Update your account password',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Coming Soon'),
                      content: const Text('Password change feature coming soon.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    setState(() => _isLoadingBiometric = true);

    try {
      final storage = ref.read(secureStorageServiceProvider);

      if (enable) {
        // Test biometric authentication first
        final biometricService = ref.read(biometricServiceProvider);
        final result = await biometricService.authenticate(
          localizedReason: 'Verify your identity to enable biometric login',
        );

        if (!result.success) {
          if (mounted) {
            showErrorDialog(
              context,
              result.errorMessage ?? 'Biometric authentication failed',
            );
          }
          setState(() => _isLoadingBiometric = false);
          return;
        }

        // Check if email is saved (required for biometric login)
        final email = await storage.getSavedEmail();

        if (email == null) {
          if (mounted) {
            showErrorDialog(
              context,
              'Please enable "Remember me" when logging in to use biometric authentication',
            );
          }
          setState(() => _isLoadingBiometric = false);
          return;
        }

        await storage.setBiometricEnabled(true);

        if (mounted) {
          SuccessDialog.show(
            context,
            title: 'Enabled',
            message: 'Biometric login enabled',
            autoDismissDuration: const Duration(milliseconds: 800),
          );
        }
      } else {
        await storage.setBiometricEnabled(false);

        if (mounted) {
          SuccessDialog.show(
            context,
            title: 'Disabled',
            message: 'Biometric login disabled',
            autoDismissDuration: const Duration(milliseconds: 800),
          );
        }
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Failed to update biometric setting: ${e.toString()}',
        );
      }
    } finally {
      setState(() => _isLoadingBiometric = false);
    }
  }

  void _showMfaSetupOptions() {
    GlassBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose MFA Method',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Email OTP
            Card(
              child: ListTile(
                leading: const Icon(CupertinoIcons.envelope, color: AppColors.primaryTeal),
                title: Text(MfaMethod.email.displayName),
                subtitle: Text(MfaMethod.email.description),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _handleEnableEmailMfa();
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // TOTP
            Card(
              child: ListTile(
                leading: const Icon(CupertinoIcons.qrcode, color: AppColors.slateBlue),
                title: Text(MfaMethod.totp.displayName),
                subtitle: Text(MfaMethod.totp.description),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _handleEnableTotpMfa();
                },
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEnableEmailMfa() async {
    setState(() => _isLoadingMfa = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.enableEmailMfa();

      if (mounted) {
        SuccessDialog.show(
          context,
          title: 'Enabled',
          message: 'Email MFA enabled successfully',
          autoDismissDuration: const Duration(milliseconds: 800),
        );
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Failed to enable email MFA: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoadingMfa = false);
    }
  }

  Future<void> _handleEnableTotpMfa() async {
    setState(() => _isLoadingMfa = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final authState = ref.read(authNotifierProvider);
      final mfaService = ref.read(mfaServiceProvider);

      // Generate TOTP secret
      final secret = await authRepository.enableTotpMfa();
      final email = authState.user?.email ?? '';

      // Generate URI for QR code
      final uri = mfaService.generateTotpUri(
        email: email,
        secret: secret,
      );

      if (mounted) {
        // Show QR code dialog
        _showTotpSetupDialog(secret, uri);
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Failed to enable TOTP MFA: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoadingMfa = false);
    }
  }

  void _showTotpSetupDialog(String secret, String uri) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Setup Authenticator App'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '1. Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.)',
              ),
              const SizedBox(height: AppSizes.md),
              QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Or enter this key manually:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.sm),
              SelectableText(
                secret,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: AppSizes.lg),
              const Text(
                '2. Enter the 6-digit code from your app:',
              ),
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              codeController.dispose();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                showErrorDialog(context, 'Please enter a 6-digit code');
                return;
              }

              try {
                final authRepository = ref.read(authRepositoryProvider);
                await authRepository.verifyAndActivateTotpMfa(
                  secret: secret,
                  code: code,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                SuccessDialog.show(
                  context,
                  title: 'Enabled',
                  message: 'TOTP MFA enabled successfully',
                  autoDismissDuration: const Duration(milliseconds: 800),
                );
                setState(() {});
              } catch (e) {
                if (!context.mounted) return;
                showErrorDialog(context, 'Invalid code: ${e.toString()}');
              } finally {
                codeController.dispose();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDisableMfa() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable MFA'),
        content: const Text(
          'Are you sure you want to disable multi-factor authentication? This will make your account less secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingMfa = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.disableMfa();

      if (mounted) {
        SuccessDialog.show(
          context,
          title: 'Disabled',
          message: 'MFA has been disabled',
          autoDismissDuration: const Duration(milliseconds: 800),
        );
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Failed to disable MFA: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoadingMfa = false);
    }
  }
}
