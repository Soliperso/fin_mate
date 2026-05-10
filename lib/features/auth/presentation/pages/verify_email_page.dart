import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/auth_providers.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailPage({
    required this.email,
    super.key,
  });

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpCode.length == 6;

  void _onDigitChanged(int index, String value) {
    if (value.length == 6) {
      // User pasted a full code — distribute across boxes
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      setState(() => _errorMessage = null);
      _handleVerify();
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() => _errorMessage = null);

    if (_isComplete) {
      _handleVerify();
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _handleVerify() async {
    if (!_isComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).verifyEmailOTP(
            email: widget.email,
            token: _otpCode,
          );

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'auth.verify.emailVerified'.tr(),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'auth.verify.invalidCode'.tr();
          // Clear boxes so user can re-enter
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).resendOTP(widget.email);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message:
              'auth.verify.codeSentTo'.tr(namedArgs: {'email': widget.email}),
          duration: const Duration(seconds: 4),
        );
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
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
                      CupertinoIcons.envelope_badge,
                      size: 58,
                      color: AppColors.primaryTeal.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'auth.verify.title'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'auth.verify.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xxl),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                      6,
                      (i) => _OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            isDark: isDark,
                            onChanged: (v) => _onDigitChanged(i, v),
                            onKey: (e) => _onKeyDown(i, e),
                          )),
                ),

                const SizedBox(height: AppSizes.md),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.exclamationmark_circle,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.xl),

                ElevatedButton(
                  onPressed:
                      (_isComplete && !_isVerifying) ? _handleVerify : null,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('auth.verify.verifyButton'.tr()),
                ),

                const SizedBox(height: AppSizes.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.verify.didntReceive'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isResending ? null : _handleResend,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('auth.verify.resend'.tr()),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'auth.verify.alreadyConfirmed'.tr(),
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6, // allows paste of full code
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isDark
                ? AppColors.tertiarySystemBackgroundDark
                : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryTeal,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
