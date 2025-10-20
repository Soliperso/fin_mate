import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';

/// Page to handle email confirmation and password reset callbacks from Supabase
class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  bool _isProcessing = true;
  String _message = 'Processing...';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      // Get the current session after email confirmation
      final session = supabase.auth.currentSession;

      if (session != null) {
        // User is authenticated after email confirmation
        setState(() {
          _isSuccess = true;
          _message = 'Email confirmed successfully!';
          _isProcessing = false;
        });

        // Wait a moment to show success message
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Navigate to dashboard
          context.go('/dashboard');
        }
      } else {
        // No session found - might be password reset or expired link
        setState(() {
          _isSuccess = false;
          _message = 'Email confirmed! Please log in to continue.';
          _isProcessing = false;
        });

        // Wait a moment then redirect to login
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Verification failed. Please try again.';
        _isProcessing = false;
      });

      // Redirect to login after showing error
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator()
                else
                  Icon(
                    _isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                    size: 80,
                    color: _isSuccess ? AppColors.success : AppColors.warning,
                  ),
                const SizedBox(height: AppSizes.xl),
                Text(
                  _message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                if (!_isProcessing) ...[
                  Text(
                    _isSuccess
                        ? 'Redirecting to dashboard...'
                        : 'Redirecting to login...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  TextButton(
                    onPressed: () {
                      if (_isSuccess) {
                        context.go('/dashboard');
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(_isSuccess ? 'Go to Dashboard' : 'Go to Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
