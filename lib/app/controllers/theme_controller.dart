import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _themeModeKey = 'themeMode';
  final _customThemeKey = 'customTheme';

  Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  RxString currentCustomTheme = ''.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _loadThemeMode();
    currentCustomTheme.value = _box.read(_customThemeKey) ?? '';
    _applyTheme();
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

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    currentCustomTheme.value = ''; // Reset custom theme
    _saveThemeMode(mode);
    _applyTheme();
  }

  void setCustomTheme(String themeName) {
    currentCustomTheme.value = themeName;
    _box.write(_customThemeKey, themeName);
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(
      currentCustomTheme.value.isEmpty ? themeMode.value : ThemeMode.light,
    );
  }

  void _saveThemeMode(ThemeMode mode) {
    _box.write(_themeModeKey, mode.toString().split('.').last);
  }
}
