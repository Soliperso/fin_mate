import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _exitController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingFadeAnimation;
  late Animation<double> _exitAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _exitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOut,
      ),
    );

    _entryController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Start auth check immediately — runs in parallel with the splash animation
    final userFuture = ref
        .read(currentUserProvider.future)
        .then<Object?>((u) => u)
        .catchError((_) => null);

    // Minimum display time so the splash doesn't flash too briefly
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Await auth result — usually already resolved by now
    Object? user;
    try {
      user = await userFuture;
    } catch (_) {
      // Network error or Supabase unavailable — navigate to onboarding
    }

    if (!mounted) return;

    await _exitController.forward();

    if (mounted) {
      if (user != null) {
        context.go('/dashboard');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _exitAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.brandTeal, AppColors.splashTeal],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon with subtle glow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/updated_dollar_symbol.png',
                            width: 180,
                            height: 180,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        // App Name
                        Text(
                          'app.name'.tr(),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        // Tagline
                        Text(
                          'app.tagline'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        // Loading indicator — fades in after entry animation
                        FadeTransition(
                          opacity: _loadingFadeAnimation,
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0x80FFFFFF), // white54
                              ),
                              strokeWidth: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
