import 'package:chat_app/app/controllers/home_controller.dart';
import 'package:chat_app/app/controllers/message_controller.dart';
import 'package:chat_app/app/controllers/theme_controller.dart';
import 'package:chat_app/app/models/user_model.dart';
import 'package:chat_app/app/screens/home/widgets/user_search_delegate.dart';
import 'package:chat_app/app/themes/theme_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final ThemeController themeController = Get.find();
  final MessageController messageController = Get.put(MessageController());

  final storage = GetStorage();

  // Reactive login state
  final RxBool isLoggedIn = false.obs;

  // Reactive selected tab index
  final RxInt _selectedIndex = 0.obs;

  HomeScreen({Key? key}) : super(key: key) {
    // Initialize login state from storage
    isLoggedIn.value = storage.hasData('user_id');
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
  }

  // Call this method after successful login somewhere in your login flow
  void onUserLoggedIn() {
    isLoggedIn.value = true;
  }

  // Centralized logout logic
  void onUserLoggedOut() {
    isLoggedIn.value = false;
    storage.erase();
    Get.offAllNamed('/LoginScreen');
  }

  Widget _buildUsersTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = storage.read('user_isAdmin') == true;

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

            if (!isAdmin && user.id == storage.read('user_id')) {
              return const SizedBox.shrink();
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Stack(
                  children: [
                    CircleAvatar(
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
                    if (homeController.onlineUserIds.contains(user.id))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(user.fullName, style: theme.textTheme.bodyLarge),
                subtitle: Text(user.email, style: theme.textTheme.bodySmall),
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

  Widget _buildMessagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final isAdmin = storage.read('user_isAdmin') == true;

      if (homeController.users.isEmpty) {
        return const Center(child: Text("No users available"));
      }

      return RefreshIndicator(
        onRefresh: homeController.fetchUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: homeController.users.length,
          itemBuilder: (context, index) {
            final user = homeController.users[index];

            if (!isAdmin && user.id == storage.read('user_id')) {
              return const SizedBox.shrink();
            }

            final isOnline = homeController.onlineUserIds.contains(user.id);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Stack(
                  children: [
                    CircleAvatar(
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
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(user.fullName, style: theme.textTheme.bodyLarge),
                subtitle: Text("Tap to chat", style: theme.textTheme.bodySmall),
                trailing: Icon(Icons.chat, color: colorScheme.primary),
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

  Widget _buildSettingsTab(BuildContext context) {
    final fullName = storage.read('user_fullName') ?? "User";
    final email = storage.read('user_email') ?? "user@example.com";
    final profilePic = storage.read('user_profilePic');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  profilePic != null ? NetworkImage(profilePic) : null,
              child:
                  profilePic == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
            ),
            const SizedBox(height: 16),
            Text(fullName, style: theme.textTheme.titleLarge),
            Text(email, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/EditProfileScreen'),
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => showThemeSelectorSheet(),
                );
              },
              icon: const Icon(Icons.brightness_6),
              label: const Text("Change Theme"),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.logout, color: colorScheme.onPrimary),
              label: Text(
                "Logout",
                style: TextStyle(color: colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onUserLoggedOut,
            ),
          ],
        ),
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
      _buildMessagesTab(context),
      _buildSettingsTab(context),
    ];

    return Obx(
      () => Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.background,
          elevation: 1,
          title: Obx(() {
            if (isLoggedIn.value) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary.withAlpha(40),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Hello, $fullName 👋",
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
          actions: [
            if (_selectedIndex.value == 0)
              IconButton(
                icon: Icon(Icons.search, color: colorScheme.primary),
                tooltip: 'Search Users',
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: UserSearchDelegate(homeController.users),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.brightness_6),
              color: colorScheme.primary,
              tooltip: 'Change Theme',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => showThemeSelectorSheet(),
                );
              },
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: IndexedStack(
            index: _selectedIndex.value,
            key: ValueKey<int>(_selectedIndex.value),
            children: tabs,
          ),
        ),
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: _selectedIndex.value,
            onTap: _onItemTapped,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
              BottomNavigationBarItem(
                icon: Icon(Icons.message),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
