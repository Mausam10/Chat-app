import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/user_controller.dart';

class HomeScreen extends StatelessWidget {
  final storage = GetStorage();
  final userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fullName = storage.read('user_fullName') ?? "User";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text("Chat App", style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.background,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            onPressed: () {
              storage.erase();
              Get.offAllNamed('/LoginScreen');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (userController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userController.users.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        return RefreshIndicator(
          onRefresh: () async => userController.fetchUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userController.users.length,
            itemBuilder: (context, index) {
              final user = userController.users[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withAlpha(30),
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
                title: Text(user.fullName, style: theme.textTheme.bodyLarge),
                subtitle: Text(user.email, style: theme.textTheme.bodySmall),
                trailing: Icon(
                  Icons.chat_bubble_outline,
                  color: colorScheme.primary,
                ),
                onTap: () {
                  Get.toNamed(
                    '/ChatScreen',
                    arguments: {'userId': user.id, 'userName': user.fullName},
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }
}
