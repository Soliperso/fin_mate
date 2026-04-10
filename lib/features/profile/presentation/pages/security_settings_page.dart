import 'package:easy_localization/easy_localization.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('security.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Authentication Methods ─────────────────────────────────
            _sectionLabel(context, 'security.authMethods'.tr()),
            const SizedBox(height: AppSizes.sm),
            _buildCard(context, isDark, children: [
              // Biometric tile (only if hardware is available)
              isBiometricAvailableAsync.when(
                data: (isAvailable) {
                  if (!isAvailable) return const SizedBox.shrink();
                  return FutureBuilder<bool>(
                    future: storage.isBiometricEnabled(),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSwitchTile(
                            context,
                            isDark: isDark,
                            icon: Icons.fingerprint,
                            iconBg: AppColors.brandTeal.withValues(alpha: 0.14),
                            iconColor: AppColors.brandTeal,
                            title: 'security.biometricLogin'.tr(),
                            subtitle: FutureBuilder<String?>(
                              future: ref
                                  .read(biometricServiceProvider)
                                  .getPrimaryBiometricType(),
                              builder: (context, typeSnapshot) {
                                final type = typeSnapshot.data ?? 'Biometric';
                                return Text(
                                  'security.biometricSub'.tr(namedArgs: {'type': type}),
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                            value: isEnabled,
                            onChanged: _isLoadingBiometric
                                ? null
                                : _handleBiometricToggle,
                          ),
                          _buildDivider(context, isDark),
                        ],
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),

              // MFA tile
              FutureBuilder<bool>(
                future: storage.isMfaEnabled(),
                builder: (context, snapshot) {
                  final isMfaEnabled = snapshot.data ?? false;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSwitchTile(
                        context,
                        isDark: isDark,
                        icon: CupertinoIcons.shield_fill,
                        iconBg: AppColors.systemBlue.withValues(alpha: 0.14),
                        iconColor: AppColors.systemBlue,
                        title: 'security.mfa'.tr(),
                        subtitle: Text(
                          isMfaEnabled
                              ? 'security.mfaEnabled'.tr()
                              : 'security.mfaSub'.tr(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                      if (isMfaEnabled) ...[
                        _buildDivider(context, isDark),
                        FutureBuilder<String?>(
                          future: storage.getMfaMethod(),
                          builder: (context, methodSnapshot) {
                            final method = methodSnapshot.data;
                            final mfaMethodEnum =
                                MfaMethodExtension.fromString(method);
                            return _buildActionTile(
                              context,
                              isDark: isDark,
                              icon: method == 'email'
                                  ? CupertinoIcons.envelope_fill
                                  : CupertinoIcons.qrcode,
                              iconBg: AppColors.systemPurple.withValues(alpha: 0.14),
                              iconColor: AppColors.systemPurple,
                              title: mfaMethodEnum?.displayName ?? 'Unknown Method',
                              subtitle: 'security.mfaChangeSub'.tr(),
                              trailing: TextButton(
                                onPressed: _showMfaSetupOptions,
                                child: Text('security.mfaChange'.tr()),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Password ──────────────────────────────────────────────
            _sectionLabel(context, 'security.changePassword'.tr()),
            const SizedBox(height: AppSizes.sm),
            _buildCard(context, isDark, children: [
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.lock_fill,
                iconBg: AppColors.systemOrange.withValues(alpha: 0.14),
                iconColor: AppColors.systemOrange,
                title: 'security.changePassword'.tr(),
                subtitle: 'security.changePasswordSub'.tr(),
                trailing: const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: AppColors.systemGray3),
                onTap: _showChangePasswordDialog,
              ),
            ]),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ── Layout helpers (match Settings page style) ────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
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

  Widget _buildCard(BuildContext context, bool isDark,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Widget subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primaryTeal,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            trailing,
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
              result.errorMessage ?? 'auth.login.biometricFailed'.tr(),
            );
          }
          setState(() => _isLoadingBiometric = false);
          return;
        }

        // Check if email is saved (required for biometric login)
        var email = await storage.getSavedEmail();

        if (email == null) {
          // Fall back to the currently authenticated user's email
          final authState = ref.read(authNotifierProvider);
          email = authState.user?.email;

          if (email == null) {
            if (mounted) {
              showErrorDialog(
                context,
                'Unable to retrieve your email. Please sign out and sign in again.',
              );
            }
            setState(() => _isLoadingBiometric = false);
            return;
          }

          // Save so the login screen can use it for biometric sign-in
          await storage.saveEmail(email);
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
          'security.failedToUpdateBiometric'.tr(),
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
              'security.chooseMfaMethod'.tr(),
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
              child: Text('common.cancel'.tr()),
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
          message: 'security.emailMFAEnabled'.tr(),
          autoDismissDuration: const Duration(milliseconds: 800),
        );
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'security.failedToEnableEmailMFA'.tr());
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
        showErrorDialog(context, 'security.failedToEnableTOTP'.tr());
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
        title: Text('security.totpSetupTitle'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('security.totpSetupStep1'.tr()),
              const SizedBox(height: AppSizes.md),
              QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'security.totpSetupManual'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.sm),
              SelectableText(
                secret,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: AppSizes.lg),
              Text('security.totpSetupStep2'.tr()),
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
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                showErrorDialog(context, 'security.enterSixDigitCode'.tr());
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
                  message: 'security.totpEnabled'.tr(),
                  autoDismissDuration: const Duration(milliseconds: 800),
                );
                setState(() {});
              } catch (e) {
                if (!context.mounted) return;
                showErrorDialog(context, 'security.invalidCode'.tr());
              } finally {
                codeController.dispose();
              }
            },
            child: Text('security.totpVerify'.tr()),
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
        title: Text('security.disableMfaTitle'.tr()),
        content: Text('security.disableMfaContent'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('security.disableMfaConfirm'.tr()),
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
        showErrorDialog(context, 'security.failedToDisableMFA'.tr());
      }
    } finally {
      setState(() => _isLoadingMfa = false);
    }
  }

  void _showChangePasswordDialog() {
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    int calcStrength(String pw) {
      int score = 0;
      if (pw.length >= 8) score++;
      if (pw.contains(RegExp(r'[A-Z]'))) score++;
      if (pw.contains(RegExp(r'[0-9]'))) score++;
      if (pw.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
      return score;
    }

    bool isLoading = false;
    bool showNewPw = false;
    bool showConfirmPw = false;

    GlassBottomSheet.show(
      context: context,
      isDismissible: true,
      child: StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final String newPw = newPwController.text;
          final String confirmPw = confirmPwController.text;

          final strength = calcStrength(newPw);
          final hasMin8 = newPw.length >= 8;
          final hasUpper = newPw.contains(RegExp(r'[A-Z]'));
          final hasNumber = newPw.contains(RegExp(r'[0-9]'));
          final hasSpecial = newPw.contains(RegExp(r'[^A-Za-z0-9]'));
          final passwordsMatch = confirmPw.isNotEmpty && newPw == confirmPw;
          final confirmMismatch = confirmPw.isNotEmpty && newPw != confirmPw;

          final strengthColor = strength == 0
              ? AppColors.systemGray4
              : strength == 1
                  ? AppColors.error
                  : strength == 2
                      ? AppColors.warning
                      : strength == 3
                          ? AppColors.systemBlue
                          : AppColors.success;

          final strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];

          Widget reqRow(bool met, String label) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      met
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 13,
                      color: met ? AppColors.success : AppColors.systemGray3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: met
                            ? AppColors.success
                            : isDark
                                ? AppColors.systemGray
                                : AppColors.systemGray2,
                      ),
                    ),
                  ],
                ),
              );

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSizes.lg,
              right: AppSizes.lg,
              top: AppSizes.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ───────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.systemOrange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Icon(
                        CupertinoIcons.lock_fill,
                        color: AppColors.systemOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'security.changePassword'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'security.changePasswordHint'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // ── New Password ──────────────────────────────────────
                TextField(
                  controller: newPwController,
                  obscureText: !showNewPw,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'security.newPassword'.tr(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPw
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 18,
                        color: AppColors.systemGray,
                      ),
                      onPressed: () => setState(() => showNewPw = !showNewPw),
                    ),
                  ),
                ),

                // ── Strength bar ──────────────────────────────────────
                if (newPw.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: List.generate(4, (i) {
                      final filled = i < strength;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: filled
                                ? strengthColor
                                : (isDark
                                    ? AppColors.systemGray3
                                        .withValues(alpha: 0.2)
                                    : AppColors.systemGray5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (strengthLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      strengthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: strengthColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.sm),
                  reqRow(hasMin8, 'At least 8 characters'),
                  reqRow(hasUpper, 'Uppercase letter'),
                  reqRow(hasNumber, 'Number'),
                  reqRow(hasSpecial, 'Special character'),
                ],

                // ── Confirm Password ──────────────────────────────────
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: confirmPwController,
                  obscureText: !showConfirmPw,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'security.confirmNewPassword'.tr(),
                    errorText:
                        confirmMismatch ? 'security.passwordMismatch'.tr() : null,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (confirmPw.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              passwordsMatch
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.xmark_circle_fill,
                              size: 16,
                              color: passwordsMatch
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            showConfirmPw
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                            size: 18,
                            color: AppColors.systemGray,
                          ),
                          onPressed: () =>
                              setState(() => showConfirmPw = !showConfirmPw),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Actions ───────────────────────────────────────────
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: isLoading || !hasMin8 || confirmMismatch || !passwordsMatch
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .updatePassword(newPw);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            newPwController.dispose();
                            confirmPwController.dispose();
                            SuccessDialog.show(
                              context,
                              title: 'Updated',
                              message: 'security.passwordChanged'.tr(),
                              autoDismissDuration:
                                  const Duration(milliseconds: 800),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => isLoading = false);
                            showErrorDialog(
                              context,
                              'security.failedToChangePassword'.tr(),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.buttonHeightMd),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('security.updatePassword'.tr()),
                ),
                const SizedBox(height: AppSizes.sm),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                          newPwController.dispose();
                          confirmPwController.dispose();
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.buttonHeightMd),
                  ),
                  child: Text('common.cancel'.tr()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
