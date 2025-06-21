import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:chat_app/app/screens/home/home_screen.dart';
import 'package:chat_app/app/utils/safe_navigator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final storage = GetStorage();

  Future<void> loginUser(String email, String password) async {
    final url = Uri.parse("http://localhost:5001/api/auth/login"); //for web
    // final url = Uri.parse("http://192.168.56.1/api/auth/login"); //for emulator

    try {
      isLoading.value = true;

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.contains('application/json') ??
              false)) {
        if (response.body.isEmpty) {
          Get.snackbar(
            "Error",
            "Empty response received from server.",
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          return;
        }

        final data = jsonDecode(response.body);

        // Save token if present (optional)
        final token = data['token'];
        if (token != null) {
          await storage.write('auth_token', token);
        }

        // Save user details
        await storage.write('user_id', data['_id']);
        await storage.write('user_fullName', data['fullName']);
        await storage.write('user_email', data['email']);
        await storage.write('user_profilePic', data['profilePic']);

        // Delay snackbar and navigation to avoid _debugLocked error
        Future.delayed(Duration.zero, () {
          Get.snackbar(
            "Welcome!",
            "Login successful",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );

          // Further delay navigation so snackbar gets rendered cleanly
          SafeNavigator.to(() => HomeScreen());
        });
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          "Login Failed",
          data["message"] ?? "Invalid credentials or server error",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } on SocketException {
      Get.snackbar(
        "Network Error",
        "No internet connection.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } on TimeoutException {
      Get.snackbar(
        "Timeout",
        "The server took too long to respond.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } catch (e, stack) {
      print("Login error: $e\n$stack");
      Get.snackbar(
        "Unexpected Error",
        "Something went wrong. Try again.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
