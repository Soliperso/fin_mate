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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Methods',
              style: Theme.of(context).textTheme.titleLarge,
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
                      child: SwitchListTile(
                        title: const Text('Biometric Login'),
                        subtitle: FutureBuilder<String?>(
                          future: ref.read(biometricServiceProvider).getPrimaryBiometricType(),
                          builder: (context, typeSnapshot) {
                            final type = typeSnapshot.data ?? 'Biometric';
                            return Text('Use $type to sign in quickly');
                          },
                        ),
                        value: isEnabled,
                        onChanged: _isLoadingBiometric
                            ? null
                            : (value) => _handleBiometricToggle(value),
                        secondary: const Icon(Icons.fingerprint),
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
                        leading: const Icon(Icons.security),
                        title: const Text('Multi-Factor Authentication'),
                        subtitle: Text(
                          isMfaEnabled
                              ? 'MFA is enabled for extra security'
                              : 'Add an extra layer of security',
                        ),
                        trailing: Switch(
                          value: isMfaEnabled,
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
                      if (isMfaEnabled) ...[
                        const Divider(height: 1),
                        FutureBuilder<String?>(
                          future: storage.getMfaMethod(),
                          builder: (context, methodSnapshot) {
                            final method = methodSnapshot.data;
                            final mfaMethodEnum = MfaMethodExtension.fromString(method);

                            return ListTile(
                              leading: Icon(
                                method == 'email' ? Icons.email : Icons.qr_code,
                                size: 20,
                              ),
                              title: Text(
                                mfaMethodEnum?.displayName ?? 'Unknown Method',
                                style: Theme.of(context).textTheme.bodyMedium,
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),

            Card(
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement change password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password change coming soon!'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Biometric authentication failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoadingBiometric = false);
          return;
        }

        // Check if credentials are saved
        final email = await storage.getSavedEmail();
        final password = await storage.getSavedPassword();

        if (email == null || password == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable "Remember me" when logging in to use biometric authentication'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          setState(() => _isLoadingBiometric = false);
          return;
        }

        await storage.setBiometricEnabled(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await storage.setBiometricEnabled(false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login disabled'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update biometric setting: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingBiometric = false);
    }
  }

  void _showMfaSetupOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (context) => Padding(
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
                leading: const Icon(Icons.email, color: AppColors.emeraldGreen),
                title: Text(MfaMethod.email.displayName),
                subtitle: Text(MfaMethod.email.description),
                trailing: const Icon(Icons.chevron_right),
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
                leading: const Icon(Icons.qr_code, color: AppColors.slateBlue),
                title: Text(MfaMethod.totp.displayName),
                subtitle: Text(MfaMethod.totp.description),
                trailing: const Icon(Icons.chevron_right),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email MFA enabled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable email MFA: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable TOTP MFA: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a 6-digit code'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                final authRepository = ref.read(authRepositoryProvider);
                await authRepository.verifyAndActivateTotpMfa(
                  secret: secret,
                  code: code,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('TOTP MFA enabled successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid code: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MFA disabled'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable MFA: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingMfa = false);
    }
  }
}
