import 'package:chat_app/app/controllers/home_controller.dart';
import 'package:chat_app/app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final storage = GetStorage();

  HomeScreen({Key? key}) : super(key: key);

  final RxInt _selectedIndex = 0.obs;

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
  }

  Widget _buildUsersTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (homeController.users.isEmpty) {
        return const Center(child: Text("No users found"));
      }

      return RefreshIndicator(
        onRefresh: homeController.fetchUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: homeController.users.length,
          itemBuilder: (context, index) {
            final UserModel user = homeController.users[index];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withAlpha(40),
                  backgroundImage:
                      user.profilePic != null
                          ? NetworkImage(user.profilePic!)
                          : null,
                  child:
                      user.profilePic == null
                          ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '',
                            style: TextStyle(color: colorScheme.primary),
                          )
                          : null,
                ),
                title: Text(user.fullName, style: theme.textTheme.bodyLarge),
                subtitle: Text(user.email, style: theme.textTheme.bodySmall),
                trailing:
                    user.isAdmin
                        ? Icon(
                          Icons.admin_panel_settings,
                          color: colorScheme.primary,
                        )
                        : null,
                onTap: () {
                  Get.toNamed(
                    '/ChatScreen',
                    arguments: {'userId': user.id, 'userName': user.fullName},
                  );
                },
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildProfileTab(BuildContext context) {
    final fullName = storage.read('user_fullName') ?? "User";
    final email = storage.read('user_email') ?? "user@example.com";
    final profilePic = storage.read('user_profilePic');
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                profilePic != null ? NetworkImage(profilePic) : null,
            child:
                profilePic == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 12),
          Text(fullName, style: theme.textTheme.headlineSmall),
          Text(email, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text("Logout"),
        onPressed: () {
          storage.erase();
          Get.offAllNamed('/LoginScreen');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fullName = storage.read('user_fullName') ?? "User";

    final tabs = [
      _buildUsersTab(context),
      _buildProfileTab(context),
      _buildSettingsTab(),
    ];

    return Obx(
      () => Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withAlpha(40),
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
                  style: TextStyle(color: colorScheme.primary, fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Text("Hello, $fullName 👋", style: theme.textTheme.titleLarge),
            ],
          ),
          backgroundColor: colorScheme.background,
          elevation: 1,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: colorScheme.primary),
              onPressed: () {
                // TODO: Add search functionality
              },
            ),
          ],
        ),
        body: tabs[_selectedIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex.value,
          onTap: _onItemTapped,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
