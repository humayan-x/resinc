import 'package:flutter/material.dart';

import '../screens/home_navigation_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../services/preferences_service.dart';
import '../state/theme_controller.dart';
import '../utils/constants.dart';
import 'theme/app_theme.dart';

/// The root application widget for ReSinc.
class ResincApp extends StatefulWidget {
  final PreferencesService? preferencesService;

  const ResincApp({
    super.key,
    this.preferencesService,
  });

  @override
  State<ResincApp> createState() => _ResincAppState();
}

class _ResincAppState extends State<ResincApp> {
  late final ThemeController _themeController;
  late final PreferencesService _preferencesService;
  bool _isLoading = true;
  bool _hasSeenOnboarding = true;

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
    _themeController = ThemeController(preferencesService: _preferencesService);
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final seen = await _preferencesService.hasSeenOnboarding();
    await _themeController.loadSavedTheme();
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = seen;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fontFamily = 'PlusJakartaSans';

    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: _themeController.themeMode,
          darkTheme: AppTheme.darkTheme(fontFamily),
          theme: AppTheme.lightTheme(fontFamily),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            );
          },
          home: _isLoading
              ? const SizedBox.shrink()
              : (!_hasSeenOnboarding
                  ? OnboardingScreen(
                      preferencesService: _preferencesService,
                      themeController: _themeController,
                      onComplete: () {
                        setState(() {
                          _hasSeenOnboarding = true;
                        });
                      },
                    )
                  : HomeNavigationScreen(
                      themeController: _themeController,
                      preferencesService: _preferencesService,
                      autoShowOnboarding: false,
                    )),
        );
      },
    );
  }
}
