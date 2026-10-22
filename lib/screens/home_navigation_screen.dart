import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../services/saved_service.dart';
import '../state/saved_controller.dart';
import '../state/theme_controller.dart';
import '../state/workbench_controller.dart';
import '../utils/constants.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/workbench_action_bar.dart';
import 'onboarding/onboarding_screen.dart';
import 'saved/saved_tab.dart';
import 'settings/settings_tab.dart';
import 'workbench/workbench_tab.dart';

/// Top-level scaffold managing floating navigation across Workbench, Saved, and Settings tabs.
class HomeNavigationScreen extends StatefulWidget {
  final ThemeController themeController;
  final SavedService? savedService;
  final WorkbenchController? workbenchController;
  final PreferencesService? preferencesService;
  final bool autoShowOnboarding;

  const HomeNavigationScreen({
    super.key,
    required this.themeController,
    this.savedService,
    this.workbenchController,
    this.preferencesService,
    this.autoShowOnboarding = true,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  late final SavedService _savedService;
  late final WorkbenchController _workbenchController;
  late final SavedController _savedController;
  late final PreferencesService _preferencesService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _savedService = widget.savedService ?? SavedService();
    _workbenchController = widget.workbenchController ?? WorkbenchController();
    _savedController = SavedController(savedService: _savedService);
    _preferencesService = widget.preferencesService ?? PreferencesService();

    // Initial load of saved items
    _savedController.loadSaved();

    if (widget.autoShowOnboarding) {
      _checkOnboarding();
    }
  }

  void _checkOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final seen = await _preferencesService.hasSeenOnboarding();
      if (!seen && mounted) {
        _openGuide();
      }
    });
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          preferencesService: _preferencesService,
          themeController: widget.themeController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    if (widget.workbenchController == null) _workbenchController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _savedController.loadSaved();
    }
  }

  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    if (index == 1) {
      // Refresh saved items when navigating to Saved tab
      _savedController.loadSaved();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _save() async {
    final item = await _workbenchController.saveToGallery(_savedService);
    if (!mounted) return;
    if (item != null) _savedController.loadSaved();
    final message = item != null
        ? 'Image saved to Gallery!'
        : _workbenchController.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppConstants.backgroundDark
        : AppConstants.backgroundLight;

    final screens = [
      WorkbenchTab(
        controller: _workbenchController,
        themeController: widget.themeController,
        onOpenGuide: _openGuide,
      ),
      SavedTab(controller: _savedController),
      SettingsTab(
        savedController: _savedController,
        themeController: widget.themeController,
        onOpenGuide: _openGuide,
      ),
    ];

    return ListenableBuilder(
      listenable: _workbenchController,
      builder: (context, _) {
        final editing = _currentIndex == 0 && _workbenchController.hasImage;
        final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
        final showTabNavigation = routeIsCurrent && !editing;
        return PopScope(
          canPop: !editing,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || !editing || _workbenchController.isBusy) return;
            if (_workbenchController.hasResult) {
              _workbenchController.clearResult();
            } else {
              _workbenchController.reset();
            }
          },
          child: Scaffold(
            backgroundColor: backgroundColor,
            extendBody: true,
            body: PageView(
              controller: _pageController,
              physics: showTabNavigation
                  ? null
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: screens
                  .map((screen) => _RetainedTab(child: screen))
                  .toList(),
            ),
            bottomNavigationBar: !routeIsCurrent
                ? null
                : showTabNavigation
                ? FloatingBottomBar(
                    selectedIndex: _currentIndex,
                    onItemSelected: _onTabSelected,
                  )
                : WorkbenchActionBar(
                    controller: _workbenchController,
                    onSave: _save,
                  ),
          ),
        );
      },
    );
  }
}

class _RetainedTab extends StatefulWidget {
  final Widget child;
  const _RetainedTab({required this.child});
  @override
  State<_RetainedTab> createState() => _RetainedTabState();
}

class _RetainedTabState extends State<_RetainedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
