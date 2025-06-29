import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/user_model.dart';

class HomeController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<String> onlineUserIds = <String>[].obs;

  final RxBool isLoading = false.obs;
  final storage = GetStorage();
  late IO.Socket socket;

  String? get currentUserId => storage.read('user_id');
  bool get isAdmin => storage.read('user_isAdmin') ?? false;

  // Connect to socket
  void initSocketConnection() {
    final userId = currentUserId;
    if (userId == null) {
      print("No userId found, socket connection not initialized.");
      return;
    }

    socket = IO.io(
      'http://192.168.56.1:5001',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'userId': userId})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("Connected to socket server as $userId");
      Get.snackbar("Socket", "Connected to server");
    });

    socket.on("getOnlineUsers", (data) {
      print("Received online users from socket: $data");
      if (data is List) {
        onlineUserIds.assignAll(data.cast<String>());
      }
    });

    socket.onDisconnect((_) {
      print("Disconnected from socket");
      Get.snackbar("Socket", "Disconnected from server");
    });

    socket.onError((err) {
      print("Socket error: $err");
      Get.snackbar("Socket Error", err.toString());
    });
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

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    initSocketConnection();
  }

  @override
  void onClose() {
    socket.dispose();
    super.onClose();
  }
}
