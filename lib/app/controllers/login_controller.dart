import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final storage = GetStorage();

  Future<void> loginUser(String email, String password) async {
    final url = Uri.parse("http://192.168.56.1:5001/api/auth/login");
    // Use http://10.0.2.2:5001 for Android emulator instead of localhost

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

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final token = data['token'];

          // Store token securely
          if (token != null) {
            await storage.write('auth_token', token);
          }

          Get.snackbar(
            "Welcome!",
            "Login successful",
            snackPosition: SnackPosition.TOP,
          );

          Get.offAllNamed('/HomeScreen');
        } else {
          Get.snackbar(
            "Login Failed",
            data["message"] ?? "Invalid credentials",
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
        }
      } else {
        print('Unexpected response format: Not JSON');
        Get.snackbar(
          "Error",
          "Unexpected response from server.",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } on TimeoutException catch (_) {
      Get.snackbar(
        "Timeout",
        "The request timed out. Please try again later.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        "Error",
        "Something went wrong. Try again later.",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
