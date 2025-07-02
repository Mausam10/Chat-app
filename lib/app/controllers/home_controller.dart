import 'dart:convert';
import 'package:chat_app/app/services/socket_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class HomeController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<String> onlineUserIds = <String>[].obs;

  final RxBool isLoading = false.obs;
  final storage = GetStorage();

  late final SocketService socketService;

  String? get currentUserId => storage.read('user_id');

  @override
  void onInit() {
    super.onInit();
    initSocket();
    fetchUsers();
  }

  void initSocket() {
    final userId = storage.read('user_id') ?? '';
    final authToken = storage.read('auth_token') ?? '';
    const baseUrl = 'http://192.168.56.1:5001';

    if (userId.isNotEmpty && authToken.isNotEmpty) {
      final socketService = SocketService(baseUrl: baseUrl);
      socketService.initSocket(userId: userId, token: authToken);
      Get.put(socketService);

      socketService.connect();

      socketService.socket.on("getOnlineUsers", (data) {
        if (data is List) {
          onlineUserIds.assignAll(data.cast<String>());
          print("✅ Online users updated: $onlineUserIds");
        }
      });
    } else {
      print("⚠️ Cannot initialize socket: Missing userId or authToken.");
    }
  }

  @override
  void onClose() {
    socketService.disconnect();
    super.onClose();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;

      final token = storage.read('auth_token');
      if (token == null || token.toString().trim().isEmpty) {
        Get.snackbar("Unauthorized", "Please login first");
        await Future.delayed(const Duration(milliseconds: 200));
        Get.offAllNamed('/LoginScreen');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.56.1:5001/api/users/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Fetch users response status: ${response.statusCode}");
      print("Fetch users response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
        await Future.delayed(const Duration(milliseconds: 200));
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
}
