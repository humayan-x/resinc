import 'package:flutter/material.dart';

import '../../services/preferences_service.dart';
import '../../state/theme_controller.dart';
import '../../utils/constants.dart';
import '../home_navigation_screen.dart';

/// Full-screen, typographic onboarding experience with clean left-aligned text.
class OnboardingScreen extends StatefulWidget {
  final PreferencesService? preferencesService;
  final ThemeController? themeController;
  final VoidCallback? onComplete;

  const OnboardingScreen({
    super.key,
    this.preferencesService,
    this.themeController,
    this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (widget.preferencesService != null) {
      await widget.preferencesService!.setHasSeenOnboarding(true);
    }

    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeNavigationScreen(
            themeController:
                widget.themeController ??
                ThemeController(preferencesService: widget.preferencesService),
            preferencesService: widget.preferencesService,
          ),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppConstants.backgroundDark
        : AppConstants.backgroundLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isDark ? AppConstants.logoWhite : AppConstants.logoDark,
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 3),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            style: TextButton.styleFrom(foregroundColor: mutedColor),
            child: const Text(
              'Skip',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Left-aligned, typographic slides below the center
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildSlide(
                    title: 'Hit Strict Target Size Ceilings',
                    subtitle: 'Need an image under 100 KB for a portal, email, or application form? ReSinc adjusts image quality and dimensions, then verifies the output fits your chosen limit.',
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  _buildSlide(
                    title: 'Zero Cloud. 100% On-Device.',
                    subtitle: 'Zero network permissions in the manifest. Your photos never leave your hardware, never touch external servers, and work seamlessly in airplane mode.',
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  _buildSlide(
                    title: 'Purge Hidden EXIF & GPS Tags',
                    subtitle: 'Camera parameters, device serial numbers, and exact GPS coordinates are automatically stripped on export. Non-destructive: your original files remain untouched.',
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),

            // 3. Bottom Controls: Left-aligned indicator pills & Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Expanding Page Indicator
                  Row(
                    children: List.generate(_pageCount, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppConstants.primaryAccent
                              : (isDark
                                    ? AppConstants.borderDark
                                    : AppConstants.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Row
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        IconButton.outlined(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: textColor,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppConstants.borderDark
                                  : AppConstants.borderLight,
                            ),
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pageCount - 1
                                      ? 'Get Started'
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pageCount - 1
                                      ? Icons.bolt_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pushes the text block below the vertical center
          const Spacer(flex: 3),
          Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: mutedColor,
              fontSize: 15.5,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
