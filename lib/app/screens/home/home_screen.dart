import 'package:chat_app/app/controllers/home_controller.dart';
import 'package:chat_app/app/controllers/message_controller.dart';
import 'package:chat_app/app/controllers/theme_controller.dart';
import 'package:chat_app/app/themes/theme_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final ThemeController themeController = Get.find();
  final MessageController messageController = Get.put(MessageController());

  final storage = GetStorage();
  final RxBool isLoggedIn = false.obs;
  final RxInt _selectedIndex = 0.obs;

  HomeScreen({Key? key}) : super(key: key) {
    isLoggedIn.value = storage.hasData('user_id');
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
  }

  void onUserLoggedOut() {
    isLoggedIn.value = false;
    storage.erase();
    Get.offAllNamed('/LoginScreen');
  }

  Widget _buildMessagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = storage.read('user_isAdmin') == true;

    return Obx(() {
      if (homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final users =
          homeController.users
              .where((u) => isAdmin || u.id != storage.read('user_id'))
              .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Chats",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Messenger",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 🔵 Online avatars
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isOnline = homeController.onlineUserIds.contains(user.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
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
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(
                          user.fullName.split(" ").first,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 📨 Chat List
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isOnline = homeController.onlineUserIds.contains(user.id);

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 2,
                          right: 2,
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
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Tap to chat...",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "1h",
                        style: TextStyle(fontSize: 12),
                      ), // Static for now
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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
          ),
        ],
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
              onPressed: () => Get.toNamed('/ProfileScreen'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final fullName = storage.read('user_fullName') ?? "User";

    final tabs = [_buildMessagesTab(context), _buildSettingsTab(context)];

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
                    "Let's Chat",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
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
