import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class HomeController extends GetxController {
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final storage = GetStorage();

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;

      final token = storage.read('auth_token');
      if (token == null || token.toString().trim().isEmpty) {
        Get.snackbar("Unauthorized", "Please login first");
        await Future.delayed(Duration(milliseconds: 200));
        Get.offAllNamed('/LoginScreen');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.56.1/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // Validate response format
        if (data is List) {
          users.assignAll(
            data.map((json) => UserModel.fromJson(json)).toList(),
          );
        } else {
          Get.snackbar("Unexpected Response", "Server returned invalid data.");
        }
      } else if (response.statusCode == 401) {
        Get.snackbar("Unauthorized", "Session expired, please login again");
        await storage.remove('auth_token');
        await Future.delayed(Duration(milliseconds: 200));
        Get.offAllNamed('/LoginScreen');
      } else {
        Get.snackbar("Error", "Failed to load users (${response.statusCode})");
        print("Failed response: ${response.body}");
      }
    } catch (e) {
      print("Fetch users error: $e");
      Get.snackbar("Error", "Something went wrong while loading users.");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // Automatically called when controller is created
  }
}
