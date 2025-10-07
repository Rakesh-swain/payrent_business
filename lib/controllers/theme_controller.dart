// lib/controllers/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payrent_business/config/theme.dart';

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController {
  // 🎨 Theme state management
  final Rx<AppThemeMode> _themeMode = AppThemeMode.system.obs;
  final RxBool _isDarkMode = false.obs;
  
  AppThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _isDarkMode.value;
  ThemeData get currentTheme => _isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme;
  
  static const String _themeKey = 'app_theme_mode';
  
  @override
  void onInit() {
    super.onInit();
    _initializeTheme();
    _setupSystemThemeListener();
  }

  // 🌟 Initialize theme from shared preferences and system
  Future<void> _initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        final themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => AppThemeMode.system,
        );
        _setThemeMode(themeMode, saveToPrefs: false);
      } else {
        _setThemeMode(AppThemeMode.system, saveToPrefs: false);
      }
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      _setThemeMode(AppThemeMode.system, saveToPrefs: false);
    }
  }

  // 🌙 Setup system theme change listener
  void _setupSystemThemeListener() {
    final window = WidgetsBinding.instance.window;
    window.onPlatformBrightnessChanged = () {
      if (_themeMode.value == AppThemeMode.system) {
        _updateThemeBasedOnSystem();
      }
    };
    
    // Initial system theme detection
    if (_themeMode.value == AppThemeMode.system) {
      _updateThemeBasedOnSystem();
    }
  }

  // ⚙️ Update theme based on system settings
  void _updateThemeBasedOnSystem() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    if (_isDarkMode.value != isDark) {
      _isDarkMode.value = isDark;
      _updateSystemUIOverlay();
    }
  }

  // 🎯 Set theme mode (public API)
  Future<void> setThemeMode(AppThemeMode mode) async {
    await _setThemeMode(mode, saveToPrefs: true);
  }

  // 🔧 Internal theme mode setter
  Future<void> _setThemeMode(AppThemeMode mode, {required bool saveToPrefs}) async {
    if (_themeMode.value == mode) return;
    
    _themeMode.value = mode;
    
    switch (mode) {
      case AppThemeMode.light:
        _isDarkMode.value = false;
        break;
      case AppThemeMode.dark:
        _isDarkMode.value = true;
        break;
      case AppThemeMode.system:
        _updateThemeBasedOnSystem();
        break;
    }
    
    _updateSystemUIOverlay();
    
    if (saveToPrefs) {
      await _saveThemePreference(mode);
    }
    
    // Update GetX theme
    Get.changeTheme(currentTheme);
  }

  // 💾 Save theme preference to SharedPreferences
  Future<void> _saveThemePreference(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // 📱 Update system UI overlay based on current theme
  void _updateSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode.value 
            ? Brightness.light 
            : Brightness.dark,
        statusBarBrightness: _isDarkMode.value 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarColor: _isDarkMode.value 
            ? AppTheme.darkSurface 
            : AppTheme.lightSurface,
        systemNavigationBarIconBrightness: _isDarkMode.value 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }

  // 🔄 Toggle between light and dark modes
  Future<void> toggleTheme() async {
    final newMode = _isDarkMode.value ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  // 🎨 Get theme-aware colors
  Color get primaryColor => AppTheme.primaryColor;
  Color get successColor => AppTheme.successColor;
  Color get warningColor => AppTheme.warningColor;
  Color get errorColor => AppTheme.errorColor;
  
  Color get backgroundColor => _isDarkMode.value 
      ? AppTheme.darkBackground 
      : AppTheme.lightBackground;
      
  Color get surfaceColor => _isDarkMode.value 
      ? AppTheme.darkSurface 
      : AppTheme.lightSurface;
      
  Color get textColor => _isDarkMode.value 
      ? AppTheme.darkText 
      : AppTheme.lightText;
      
  Color get textSecondaryColor => _isDarkMode.value 
      ? AppTheme.darkTextSecondary 
      : AppTheme.lightTextSecondary;
      
  Color get textTertiaryColor => _isDarkMode.value 
      ? AppTheme.darkTextTertiary 
      : AppTheme.lightTextTertiary;

  // 🎨 Get theme-aware gradients
  List<Color> get primaryGradient => AppTheme.primaryGradient;
  List<Color> get successGradient => AppTheme.successGradient;
  List<Color> get warningGradient => AppTheme.warningGradient;

  // ✨ Get theme-aware decorations
  BoxDecoration modernCard({bool withShadow = true}) =>
      AppTheme.modernCardDecoration(
        isDark: _isDarkMode.value,
        withShadow: withShadow,
      );

  BoxDecoration gradientCard(List<Color> colors, {bool withShadow = false}) =>
      AppTheme.gradientDecoration(
        colors: colors,
        withShadow: withShadow,
      );

  BoxDecoration glassCard({double opacity = 0.1}) =>
      AppTheme.glassDecoration(
        isDark: _isDarkMode.value,
        opacity: opacity,
      );

  // 📊 Theme mode display names
  String get themeModeDisplayName {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  // 🔥 Animation duration for theme transitions
  static const Duration transitionDuration = Duration(milliseconds: 300);
}