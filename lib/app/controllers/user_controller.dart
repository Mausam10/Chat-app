import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart'; // Your user model import

class UsersController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  final storage = GetStorage();
  final String baseUrl = "http://192.168.56.1:5001/api/users";

  Future<void> fetchUsers() async {
    final token = storage.read('auth_token');
    if (token == null || token.isEmpty) {
      Get.snackbar(
        "Unauthorized",
        "Please login first",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        users.value = data.map((json) => UserModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        Get.snackbar(
          "Unauthorized",
          "Session expired, please login again",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        // Optional: clear storage and redirect to login
        await storage.erase();
        Get.offAllNamed('/LoginScreen');
      } else {
        Get.snackbar(
          "Error",
          "Failed to fetch users. Status: ${response.statusCode}",
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "An unexpected error occurred: $e",
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
