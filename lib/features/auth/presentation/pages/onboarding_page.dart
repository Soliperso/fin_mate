import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _entranceController;
  late Animation<double> _entranceFade;

  List<OnboardingSlide> get _slides => [
    OnboardingSlide(
      title: 'onboarding.slide1.title'.tr(),
      description: 'onboarding.slide1.description'.tr(),
      icon: CupertinoIcons.chart_pie_fill,
      color: AppColors.brandTeal,
    ),
    OnboardingSlide(
      title: 'onboarding.slide2.title'.tr(),
      description: 'onboarding.slide2.description'.tr(),
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.systemPurple,
    ),
    OnboardingSlide(
      title: 'onboarding.slide3.title'.tr(),
      description: 'onboarding.slide3.description'.tr(),
      icon: CupertinoIcons.lightbulb_fill,
      color: AppColors.systemOrange,
    ),
  ];

  Color get _currentColor => _slides[_currentPage].color;
  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _entranceFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background — separate layer so ripples render above it
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _currentColor.withValues(alpha: 0.06),
                    _currentColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
            // Content on top — transparent Material gives ripples a surface to render on
            Material(
              color: Colors.transparent,
              child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top spacer to make room for Skip button
                    const SizedBox(height: AppSizes.xxl),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemCount: _slides.length,
                        itemBuilder: (context, index) =>
                            _buildSlide(_slides[index], index),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.lg,
                        0,
                        AppSizes.lg,
                        AppSizes.lg,
                      ),
                      child: Column(
                        children: [
                          // Page indicator dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (index) => _buildDot(index == _currentPage),
                            ),
                          ),
                          const SizedBox(height: AppSizes.xl),
                          // Bottom action area
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: _isLastPage
                                ? _buildFinalActions()
                                : _buildInterimActions(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Skip button — top-right, hidden on last slide
                Positioned(
                  top: 0,
                  right: AppSizes.sm,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isLastPage ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: _isLastPage ? null : () => context.push('/login'),
                      child: Text(
                        'common.skip'.tr(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(index),
              children: [
                // Layered illustration
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background blob
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.05),
                      ),
                    ),
                    // Outer ring
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.08),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.14),
                      ),
                    ),
                    // Inner icon container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.20),
                      ),
                      child: Icon(
                        slide.icon,
                        size: 44,
                        color: slide.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xxl),
                Text(
                  slide.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  slide.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterimActions() {
    return SizedBox(
      key: const ValueKey('interim'),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Text('common.next'.tr()),
      ),
    );
  }

  Widget _buildFinalActions() {
    return Column(
      key: const ValueKey('final'),
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/signup'),
            child: Text(
              'common.getStarted'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        TextButton(
          onPressed: () => context.push('/login'),
          child: Text('onboarding.alreadyHaveAccount'.tr()),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? _currentColor : AppColors.textTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
