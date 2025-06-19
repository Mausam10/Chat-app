import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class HomeController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString welcomeMessage = "Welcome to Home Screen!".obs;

  final storage = GetStorage();

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;

      final token = storage.read('auth_token');
      if (token == null) {
        Get.snackbar("Unauthorized", "Token not found");
        return;
      }

      final response = await http.get(
        Uri.parse(
          'http://192.168.56.1:5001/users',
        ), // replace with correct route
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        users.assignAll(data.map((json) => UserModel.fromJson(json)).toList());
      } else {
        print(
          "Failed to fetch users: ${response.statusCode} - ${response.body}",
        );
        Get.snackbar("Error", "Failed to load users");
      }
    } catch (e) {
      print("Exception in fetchUsers: $e");
      Get.snackbar("Error", "Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  void updateWelcomeMessage(String newMessage) {
    welcomeMessage.value = newMessage;
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsers(); // Fetch users on controller initialization
  }

  @override
  void onClose() {
    super.onClose();
  }
}
