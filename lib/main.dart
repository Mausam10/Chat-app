import 'package:chat_app/app/controllers/message_controller.dart';
import 'package:chat_app/app/controllers/theme_controller.dart';
import 'package:chat_app/app/screens/auth/login_screen.dart';
import 'package:chat_app/app/screens/auth/register_screen.dart';
import 'package:chat_app/app/screens/chat/chat_screen.dart';
import 'package:chat_app/app/screens/home/home_screen.dart';
import 'package:chat_app/app/screens/onboarding/onboarding_screen.dart';
import 'package:chat_app/app/screens/splash/splash_screen.dart';
import 'package:chat_app/app/services/socket_service.dart';
import 'package:chat_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  await dotenv.load(fileName: "assets/.env");
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(ThemeController());
  Get.put(MessageController());
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
        title: 'Lets Chat',

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

        initialRoute: '/splashScreen',
        getPages: [
          GetPage(name: '/splashScreen', page: () => const SplashScreen()),
          GetPage(
            name: '/onboardingScreen',
            page: () => const OnboardingScreen(),
          ),
          GetPage(name: '/LoginScreen', page: () => LoginScreen()),
          GetPage(name: '/RegisterScreen', page: () => RegisterScreen()),
          GetPage(name: '/HomeScreen', page: () => HomeScreen()),
          GetPage(name: '/ChatScreen', page: () => ChatScreen()),
        ],
      );
    });
  }
}
