import 'package:chat_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/app/controllers/theme_controller.dart';

Widget showThemeSelectorSheet() {
  final ThemeController themeController = Get.find();

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

            // System options
            ListTile(
              title: const Text("System Default"),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeController.themeMode.value,
                onChanged: (val) {
                  if (val != null) {
                    themeController.setThemeMode(val);
                    Get.back();
                  }
                },
              ),
            ),
            ListTile(
              title: const Text("Light Theme"),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeController.themeMode.value,
                onChanged: (val) {
                  if (val != null) {
                    themeController.setThemeMode(val);
                    Get.back();
                  }
                },
              ),
            ),
            ListTile(
              title: const Text("Dark Theme"),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeController.themeMode.value,
                onChanged: (val) {
                  if (val != null) {
                    themeController.setThemeMode(val);
                    Get.back();
                  }
                },
              ),
            ),

            const Divider(),

            // Custom themes (excluding built-in ones)
            ...AppThemes.allThemes.entries
                .where((entry) => entry.key != 'Light' && entry.key != 'Dark')
                .map(
                  (entry) => ListTile(
                    title: Text(entry.key),
                    leading: Radio<String>(
                      value: entry.key,
                      groupValue: themeController.currentCustomTheme.value,
                      onChanged: (val) {
                        if (val != null) {
                          themeController.setCustomTheme(val);
                          Get.back();
                        }
                      },
                    ),
                  ),
                )
                .toList(),

            const Divider(),

            // Reset option
            TextButton(
              onPressed: () {
                themeController.setThemeMode(ThemeMode.system);
                Get.back();
              },
              child: const Text("Reset to System Default"),
            ),
          ],
        ),
      ),
    ),
  );
}
