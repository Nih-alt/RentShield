import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/database/hive_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: Icons.shield_outlined,
      title: 'Welcome to\nRent Shield',
      subtitle:
          'Protect your security deposit with documented proof of property condition.',
      accent: AppColors.primary,
    ),
    _PageData(
      icon: Icons.camera_alt_outlined,
      title: 'Document\nEverything',
      subtitle:
          'Inspect every room during move-in and move-out. Capture photos, notes, and condition ratings for each item.',
      accent: AppColors.success,
    ),
    _PageData(
      icon: Icons.picture_as_pdf_rounded,
      title: 'Generate\nProfessional Reports',
      subtitle:
          'Create PDF reports comparing move-in vs move-out condition. Share them as evidence if disputes arise.',
      accent: AppColors.accent,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _skip() => _complete();

  Future<void> _complete() async {
    await HiveService.setOnboardingCompleted();
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : _skip,
                      child: Text(
                        'Skip',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),

            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? _pages[_currentPage].accent
                          : AppColors.border,
                      borderRadius: AppRadius.borderRadiusPill,
                    ),
                  ),
                ),
              ),
            ),

            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].accent,
                    foregroundColor: isLast
                        ? AppColors.textOnAccent
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: AppTypography.button.copyWith(
                      color: isLast ? AppColors.textOnAccent : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _PageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with double ring decoration
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.accent.withValues(alpha: 0.08),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  size: 44,
                  color: data.accent,
                ),
              ),
            ),
          ),
          AppSpacing.vXxl,
          AppSpacing.vMd,
          Text(
            data.title,
            style: AppTypography.h1.copyWith(
              fontSize: 26,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vLg,
          Text(
            data.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
