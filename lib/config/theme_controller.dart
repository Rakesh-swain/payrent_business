import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const _storageKey = 'payrent_theme_mode';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;

  ThemeMode get themeMode => _themeMode.value;

  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.dark) return true;
    if (_themeMode.value == ThemeMode.light) return false;
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  @override
  void onInit() {
    super.onInit();
    _loadPersistedTheme();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    update();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }

  Future<void> cycleThemeMode() async {
    ThemeMode next;
    switch (_themeMode.value) {
      case ThemeMode.system:
        next = ThemeMode.light;
        break;
      case ThemeMode.light:
        next = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        next = ThemeMode.system;
        break;
    }
    await setThemeMode(next);
  }

  void updateBrightness(Brightness platformBrightness) {
    if (_themeMode.value == ThemeMode.system) {
      update();
    }
  }

  Future<void> _loadPersistedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) return;

    switch (stored) {
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        break;
      case 'light':
        _themeMode.value = ThemeMode.light;
        break;
      default:
        _themeMode.value = ThemeMode.system;
    }
    update();
  }
}
