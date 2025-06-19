import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;
  final isLoading = false.obs;

  final storage = GetStorage();

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final token = storage.read('auth_token');

      final response = await http.get(
        Uri.parse("http://192.168.56.1:5001/users"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        users.assignAll(data.map((json) => UserModel.fromJson(json)).toList());
      } else {
        print("Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }
}
