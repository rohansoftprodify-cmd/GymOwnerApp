import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingItem> _items(ColorScheme colorScheme) => [
    OnboardingItem(
      title: 'Gym Ops In One Place',
      description: 'Manage members, attendance, products, and promotions from one dashboard.',
      icon: Icons.space_dashboard_rounded,
      accent: colorScheme.primary,
    ),
    OnboardingItem(
      title: 'Fast Daily Attendance',
      description: 'Mark check-ins/check-outs quickly and monitor active members in real-time.',
      icon: Icons.how_to_reg_rounded,
      accent: colorScheme.secondary,
    ),
    OnboardingItem(
      title: 'Grow Revenue Smarter',
      description: 'Track pending fees, run offers, and measure sales with clear insights.',
      icon: Icons.trending_up_rounded,
      accent: colorScheme.tertiary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = _items(colorScheme);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.fitness_center_rounded, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  AppText(
                    'Gym Owner',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.accent.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            item.icon,
                            size: 64,
                            color: item.accent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppText(
                          item.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          item.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPage == index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage != items.length - 1)
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: const Text('Skip', style: TextStyle(fontSize: 13)),
                        )
                      else
                        const Spacer(),
                      const Spacer(),
                      AppPrimaryButton(
                        onPressed: () {
                          if (_currentPage == items.length - 1) {
                            context.go('/login');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: _currentPage == items.length - 1 ? Icons.login_rounded : Icons.arrow_forward_rounded,
                        label: _currentPage == items.length - 1 ? 'Start' : 'Next',
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
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
}
