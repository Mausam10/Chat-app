import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage _box = GetStorage();
  final String _themeModeKey = 'themeMode';
  final String _customThemeKey = 'customTheme';

  // Reactive variables for theme mode and custom theme name
  Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  RxString currentCustomTheme = ''.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _loadThemeMode();
    currentCustomTheme.value = _loadCustomTheme();

    // Apply the loaded theme
    Get.changeThemeMode(themeMode.value);
  }

  ThemeMode _loadThemeMode() {
    final saved = _box.read(_themeModeKey);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _loadCustomTheme() {
    return _box.read(_customThemeKey) ?? '';
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _box.write(_themeModeKey, mode.toString().split('.').last);

    // Clear custom theme when changing ThemeMode
    clearCustomTheme();

    debugPrint("Theme mode changed to: $mode");
  }

  void setCustomTheme(String themeName) {
    currentCustomTheme.value = themeName;

    // When a custom theme is selected, force light mode for proper display
    themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);

    _box.write(_customThemeKey, themeName);
    _box.write(_themeModeKey, 'light'); // Save light mode as active

    debugPrint("Custom theme set to: $themeName");
  }

  void clearCustomTheme() {
    if (currentCustomTheme.value.isNotEmpty) {
      currentCustomTheme.value = '';
      _box.remove(_customThemeKey);
      debugPrint("Custom theme cleared");
    }
  }
}
