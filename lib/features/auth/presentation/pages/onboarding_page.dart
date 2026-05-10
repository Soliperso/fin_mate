import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/secure_storage_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _entranceController;
  late Animation<double> _entranceFade;

  late AnimationController _hintController;
  Animation<double> _hintFade = const AlwaysStoppedAnimation(0.0);

  List<OnboardingSlide> get _slides => [
        OnboardingSlide(
          title: 'onboarding.slide1.title'.tr(),
          description: 'onboarding.slide1.description'.tr(),
          icon: CupertinoIcons.chart_pie_fill,
          color: AppColors.brandTeal,
          features: ['Custom categories', 'Monthly reports', 'Spending limits'],
        ),
        OnboardingSlide(
          title: 'onboarding.slide2.title'.tr(),
          description: 'onboarding.slide2.description'.tr(),
          icon: CupertinoIcons.creditcard_fill,
          color: AppColors.systemPurple,
          features: [
            'Avalanche & Snowball',
            'Payoff timeline',
            'Interest tracker'
          ],
        ),
        OnboardingSlide(
          title: 'onboarding.slide3.title'.tr(),
          description: 'onboarding.slide3.description'.tr(),
          icon: CupertinoIcons.lightbulb_fill,
          color: AppColors.systemOrange,
          features: ['Balance forecast', 'Spending alerts', 'Smart tips'],
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

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _hintFade = CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOut,
    );

    _entranceController.forward().then((_) => _runSwipeHint());
  }

  Future<void> _runSwipeHint() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await _hintController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await _hintController.reverse();
  }

  Future<void> _markSeenAndGo(String route) async {
    await ref.read(secureStorageServiceProvider).saveHasSeenOnboarding();
    if (mounted) context.push(route);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _hintController.dispose();
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
            // Animated gradient background
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
            Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
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
                              // Segment progress indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _slides.length,
                                  (index) =>
                                      _buildSegment(index == _currentPage),
                                ),
                              ),
                              const SizedBox(height: AppSizes.xl),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                        opacity: animation, child: child),
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
                          onPressed: _isLastPage
                              ? null
                              : () => _markSeenAndGo('/login'),
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
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.05),
                      ),
                    ),
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.08),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.color.withValues(alpha: 0.14),
                      ),
                    ),
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
                const SizedBox(height: AppSizes.lg),
                _buildFeatureChips(slide),
                // Swipe hint — only on first slide, fades in/out once
                if (index == 0) ...[
                  const SizedBox(height: AppSizes.md),
                  FadeTransition(
                    opacity: _hintFade,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_left,
                            size: 11, color: AppColors.textTertiary),
                        const SizedBox(width: 5),
                        Text(
                          'Swipe to explore',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 5),
                        Icon(CupertinoIcons.arrow_right,
                            size: 11, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips(OnboardingSlide slide) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      alignment: WrapAlignment.center,
      children: slide.features
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: slide.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(color: slide.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_alt,
                      size: 11, color: slide.color),
                  const SizedBox(width: 4),
                  Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      color: slide.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInterimActions() {
    return SizedBox(
      key: const ValueKey('interim'),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        icon: const Icon(CupertinoIcons.arrow_right, size: 17),
        label: Text('common.next'.tr()),
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
            onPressed: () => _markSeenAndGo('/signup'),
            child: Text(
              'common.getStarted'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        TextButton(
          onPressed: () => _markSeenAndGo('/login'),
          child: Text('onboarding.alreadyHaveAccount'.tr()),
        ),
      ],
    );
  }

  Widget _buildSegment(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 28 : 8,
      height: 4,
      decoration: BoxDecoration(
        color: isActive
            ? _currentColor
            : AppColors.textTertiary.withValues(alpha: 0.4),
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
  final List<String> features;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}
