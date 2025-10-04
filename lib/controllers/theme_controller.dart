import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  // Theme mode options
  static const String themeKey = 'theme_mode';
  
  // Observable theme mode
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;
  
  // Check if dark mode is currently active
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return Get.isDarkMode;
    }
    return _themeMode.value == ThemeMode.dark;
  }
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }
  
  // Load saved theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(themeKey);
      
      if (themeModeString != null) {
        switch (themeModeString) {
          case 'light':
            _themeMode.value = ThemeMode.light;
            break;
          case 'dark':
            _themeMode.value = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode.value = ThemeMode.system;
            break;
        }
        
        // Update GetX theme
        Get.changeThemeMode(_themeMode.value);
      }
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }
  
  // Save theme mode to shared preferences
  Future<void> _saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeKey, mode);
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  // Set light theme
  Future<void> setLightMode() async {
    _themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);
    await _saveThemeMode('light');
  }
  
  // Set dark theme
  Future<void> setDarkMode() async {
    _themeMode.value = ThemeMode.dark;
    Get.changeThemeMode(ThemeMode.dark);
    await _saveThemeMode('dark');
  }
  
  // Set system theme
  Future<void> setSystemMode() async {
    _themeMode.value = ThemeMode.system;
    Get.changeThemeMode(ThemeMode.system);
    await _saveThemeMode('system');
  }
  
  // Toggle between light and dark mode (skipping system)
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setLightMode();
    } else {
      await setDarkMode();
    }
  }
  
  // Get theme mode display name
  String getThemeModeName() {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
