import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find<ThemeController>();

  final _themeMode = ThemeMode.system.obs;
  final _isDarkMode = false.obs;

  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
    _updateSystemBarStyle();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // Default to system
    _themeMode.value = ThemeMode.values[themeIndex];
    
    // Check system brightness for system mode
    if (_themeMode.value == ThemeMode.system) {
      _isDarkMode.value = Get.isPlatformDarkMode;
    } else {
      _isDarkMode.value = _themeMode.value == ThemeMode.dark;
    }
    
    _updateSystemBarStyle();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.value.index);
  }

  // Switch to light theme
  Future<void> switchToLightTheme() async {
    _themeMode.value = ThemeMode.light;
    _isDarkMode.value = false;
    await _saveThemePreference();
    _updateSystemBarStyle();
    Get.changeTheme(getLightTheme());
  }

  // Switch to dark theme
  Future<void> switchToDarkTheme() async {
    _themeMode.value = ThemeMode.dark;
    _isDarkMode.value = true;
    await _saveThemePreference();
    _updateSystemBarStyle();
    Get.changeTheme(getDarkTheme());
  }

  // Switch to system theme
  Future<void> switchToSystemTheme() async {
    _themeMode.value = ThemeMode.system;
    _isDarkMode.value = Get.isPlatformDarkMode;
    await _saveThemePreference();
    _updateSystemBarStyle();
    Get.changeTheme(_isDarkMode.value ? getDarkTheme() : getLightTheme());
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_themeMode.value == ThemeMode.light) {
      await switchToDarkTheme();
    } else if (_themeMode.value == ThemeMode.dark) {
      await switchToLightTheme();
    } else {
      // If system, toggle to opposite of current system setting
      if (_isDarkMode.value) {
        await switchToLightTheme();
      } else {
        await switchToDarkTheme();
      }
    }
  }

  // Get current theme data
  ThemeData getCurrentTheme() {
    return _isDarkMode.value ? getDarkTheme() : getLightTheme();
  }

  // Update system UI overlay style based on current theme
  void _updateSystemBarStyle() {
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
            ? const Color(0xFF121212) 
            : Colors.white,
        systemNavigationBarIconBrightness: _isDarkMode.value 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }

  // Light Theme Data
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0056D2),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0056D2),
        onPrimary: Colors.white,
        secondary: const Color(0xFF26C6DA),
        onSecondary: Colors.white,
        tertiary: const Color(0xFF9C27B0),
        surface: Colors.white,
        onSurface: const Color(0xFF1A1A1A),
        background: const Color(0xFFF8F9FA),
        onBackground: const Color(0xFF1A1A1A),
        error: const Color(0xFFE53E3E),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }

  // Dark Theme Data
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4A90E2),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF4A90E2),
        onPrimary: Colors.black,
        secondary: const Color(0xFF26C6DA),
        onSecondary: Colors.black,
        tertiary: const Color(0xFFBA68C8),
        surface: const Color(0xFF1E1E1E),
        onSurface: const Color(0xFFE0E0E0),
        background: const Color(0xFF121212),
        onBackground: const Color(0xFFE0E0E0),
        error: const Color(0xFFCF6679),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}