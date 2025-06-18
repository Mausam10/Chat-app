import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/app/themes/app_theme.dart';
import 'package:chat_app/app/controllers/theme_controller.dart';

Widget showThemeSelectorSheet() {
  final themeController = Get.find<ThemeController>();

  return Obx(
    () => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose Theme",
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Buttons for system, light, dark
            ToggleButtons(
              isSelected: List.generate(3, (index) {
                final modes = [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ];
                final selectedMode = themeController.themeMode.value;
                if (modes[index] == ThemeMode.light) {
                  return selectedMode == ThemeMode.light &&
                      themeController.currentCustomTheme.isEmpty;
                }
                return selectedMode == modes[index];
              }),
              onPressed: (index) {
                final modes = [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ];
                themeController.setThemeMode(modes[index]);
                Get.back();
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("System"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Light"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Dark"),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Custom Themes", style: Get.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),

            // Custom theme preview tiles
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  AppThemes.allThemes.keys
                      .where((k) => k != 'Light' && k != 'Dark')
                      .map((themeName) {
                        final theme = AppThemes.allThemes[themeName]!;
                        final isSelected =
                            themeController.currentCustomTheme.value ==
                            themeName;

                        // Estimate text color for contrast
                        final backgroundColor = theme.scaffoldBackgroundColor;
                        final brightness = ThemeData.estimateBrightnessForColor(
                          backgroundColor,
                        );
                        final textColor =
                            brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black;

                        return GestureDetector(
                          onTap: () {
                            themeController.setCustomTheme(themeName);
                            Get.back();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.blue
                                        : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            width: 120,
                            height: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  themeName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    themeController.setCustomTheme(themeName);
                                    Get.back();

                                    // Get the newly applied ThemeData after setting the theme
                                    final newTheme =
                                        AppThemes.allThemes[themeName]!;

                                    Get.snackbar(
                                      "Theme Applied",
                                      "$themeName theme is now active",
                                      snackPosition: SnackPosition.BOTTOM,
                                      duration: const Duration(seconds: 2),
                                      backgroundColor:
                                          newTheme.colorScheme.surface,
                                      colorText: newTheme.colorScheme.onSurface,
                                      margin: const EdgeInsets.all(16),
                                      borderRadius: 12,
                                      snackStyle: SnackStyle.FLOATING,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(60, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text(
                                    "Apply",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
