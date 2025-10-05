import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Track Your Finances',
      description: 'Get a complete overview of your income, expenses, and net worth in one place.',
      icon: Icons.account_balance_wallet,
    ),
    OnboardingSlide(
      title: 'Split Bills Easily',
      description: 'Share expenses with friends and roommates. Track who owes what with ease.',
      icon: Icons.people,
    ),
    OnboardingSlide(
      title: 'AI-Powered Insights',
      description: 'Get personalized recommendations and spending insights powered by AI.',
      icon: Icons.auto_awesome,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) => _buildSlide(_slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildDot(index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  if (_currentPage == _slides.length - 1)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/signup'),
                            child: const Text('Get Started'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Already have an account? Log in'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Skip'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emeraldGreen, AppColors.tealBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 80,
              color: AppColors.white,
            ),
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
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.emeraldGreen : AppColors.textTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}
