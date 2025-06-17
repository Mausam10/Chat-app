import 'package:chat_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:chat_app/app/controllers/theme_controller.dart';
import 'package:chat_app/app/screens/auth/login_screen.dart';
import 'package:chat_app/app/screens/auth/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(ThemeController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String customTheme = themeController.currentCustomTheme.value;
      final ThemeMode mode = themeController.themeMode.value;

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lets-Chat',

        // Use ThemeMode only if no custom theme is selected
        themeMode: customTheme.isEmpty ? mode : ThemeMode.light,

        // If custom theme is selected, apply it; otherwise use default light theme
        theme: AppThemes.allThemes[customTheme] ?? ThemeData.light(),

        // Dark theme used only when themeMode == dark
        darkTheme: ThemeData.dark(),

        builder: (context, child) {
          return AnimatedTheme(
            data: Theme.of(context),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: child!,
          );
        },

        initialRoute: '/LoginScreen',
        getPages: [
          GetPage(name: '/LoginScreen', page: () => LoginScreen()),
          GetPage(name: '/RegisterScreen', page: () => RegisterScreen()),
        ],
      );
    });
  }
}
