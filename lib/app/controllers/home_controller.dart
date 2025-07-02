import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../services/socket_service.dart';
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
    _initSocket();
    fetchUsers();
  }

  void _initSocket() {
    final userId = storage.read('user_id') ?? '';
    final token = storage.read('auth_token') ?? '';
    const baseUrl = 'http://192.168.1.70:5001';

    if (userId.isNotEmpty && token.isNotEmpty) {
      socketService = SocketService(baseUrl: baseUrl);
      socketService.initSocket(userId: userId, token: token);
      socketService.connect();
      Get.put(socketService);
      socketService.onOnlineUsersUpdated((data) {
        onlineUserIds.assignAll(data);
      });
    }
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final token = storage.read('auth_token');
      final res = await http.get(
        Uri.parse('http://192.168.1.70:5001/api/users/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        users.assignAll(data.map((e) => UserModel.fromJson(e)).toList());
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    socketService.disconnect();
    super.onClose();
  }
}
