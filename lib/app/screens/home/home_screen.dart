import 'package:chat_app/app/controllers/home_controller.dart';
import 'package:chat_app/app/controllers/message_controller.dart';
import 'package:chat_app/app/controllers/theme_controller.dart';
import 'package:chat_app/app/themes/theme_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final ThemeController themeController = Get.find();
  final MessageController messageController = Get.put(MessageController());

  final storage = GetStorage();
  final RxBool isLoggedIn = false.obs;
  final RxInt _selectedIndex = 0.obs;
  final RxBool showOnlineUsers = true.obs;

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

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildMessagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = storage.read('user_isAdmin') == true;

    return Obx(() {
      if (homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final allUsers =
          homeController.users
              .where((u) => isAdmin || u.id != storage.read('user_id'))
              .toList();

      // Filter users based on search query
      final filteredUsers =
          homeController.filteredUsers
              .where((u) => isAdmin || u.id != storage.read('user_id'))
              .toList();

      final onlineUsers =
          allUsers.where((u) => homeController.isUserOnline(u.id)).toList();

      return RefreshIndicator(
        onRefresh: homeController.refreshUsers,
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Messages",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            // Show notifications
                            Get.snackbar(
                              'Notifications',
                              'You have ${homeController.unreadCount.value} unread messages',
                              snackPosition: SnackPosition.TOP,
                              duration: const Duration(seconds: 2),
                            );
                          },
                        ),
                        if (homeController.unreadCount.value > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${homeController.unreadCount.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Enhanced Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search messages and users...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.primary,
                      ),
                      suffixIcon:
                          homeController.searchQuery.value.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: homeController.clearSearch,
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: homeController.updateSearchQuery,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Online Users Section
            if (onlineUsers.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Online (${onlineUsers.length})",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              showOnlineUsers.value
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: colorScheme.primary,
                            ),
                            onPressed: () => showOnlineUsers.toggle(),
                          ),
                        ],
                      ),
                    ),
                    if (showOnlineUsers.value)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: onlineUsers.length,
                          itemBuilder: (context, index) {
                            final user = onlineUsers[index];
                            return GestureDetector(
                              onTap: () {
                                Get.toNamed(
                                  '/ChatScreen',
                                  arguments: {
                                    'userId': user.id,
                                    'userName': user.fullName,
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 3,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: colorScheme.primary
                                            .withAlpha(40),
                                        backgroundImage:
                                            user.profilePic != null
                                                ? NetworkImage(user.profilePic!)
                                                : null,
                                        child:
                                            user.profilePic == null
                                                ? Text(
                                                  user.fullName.isNotEmpty
                                                      ? user.fullName[0]
                                                          .toUpperCase()
                                                      : '',
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                )
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        user.fullName.split(" ").first,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Recent Chats Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "Recent Chats",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),

            // Enhanced Chat List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = filteredUsers[index];
                final isOnline = homeController.isUserOnline(user.id);
                final hasUnread = user.unreadCount > 0;
                final isTyping = user.isTyping;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasUnread ? colorScheme.primary.withAlpha(20) : null,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        hasUnread
                            ? Border.all(
                              color: colorScheme.primary.withAlpha(50),
                            )
                            : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      children: [
                        Hero(
                          tag: 'avatar_${user.id}',
                          child: CircleAvatar(
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
                                        fontSize: 18,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (user.lastMessageTime != null)
                          Text(
                            _formatTime(user.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  hasUnread
                                      ? colorScheme.primary
                                      : Colors.grey.shade600,
                              fontWeight:
                                  hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (isTyping)
                          Row(
                            children: [
                              Text(
                                "Typing",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 20,
                                height: 10,
                                child: Row(
                                  children: [
                                    for (int i = 0; i < 3; i++)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            user.lastMessage?.isNotEmpty == true
                                ? user.lastMessage!
                                : "Tap to start chatting...",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  user.lastMessage?.isNotEmpty == true
                                      ? (hasUnread
                                          ? colorScheme.onSurface
                                          : Colors.grey.shade600)
                                      : Colors.grey.shade500,
                              fontWeight:
                                  hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.unreadCount.toString(),
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                      ],
                    ),
                    onTap: () {
                      homeController.markMessagesAsRead(user.id);
                      Get.toNamed(
                        '/ChatScreen',
                        arguments: {
                          'userId': user.id,
                          'userName': user.fullName,
                        },
                      );
                    },
                  ),
                );
              }, childCount: filteredUsers.length),
            ),

            // Empty State
            if (filteredUsers.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          homeController.searchQuery.value.isNotEmpty
                              ? "No users found matching '${homeController.searchQuery.value}'"
                              : "No chats yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          homeController.searchQuery.value.isNotEmpty
                              ? "Try searching with a different term"
                              : "Start a conversation with someone!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.primary.withAlpha(40),
                      backgroundImage:
                          profilePic != null ? NetworkImage(profilePic) : null,
                      child:
                          profilePic == null
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color: colorScheme.primary,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Settings Options
          _buildSettingsOption(
            context,
            icon: Icons.person_outline,
            title: "Edit Profile",
            subtitle: "Update your personal information",
            onTap: () => Get.toNamed('/ProfileScreen'),
          ),

          _buildSettingsOption(
            context,
            icon: Icons.palette_outlined,
            title: "Appearance",
            subtitle: "Customize your theme",
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => showThemeSelectorSheet(),
              );
            },
          ),

          _buildSettingsOption(
            context,
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage your notification preferences",
            onTap: () {
              // TODO: Implement notification settings
              Get.snackbar(
                'Coming Soon',
                'Notification settings will be available soon!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),

          _buildSettingsOption(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Privacy & Security",
            subtitle: "Control your privacy settings",
            onTap: () {
              // TODO: Implement privacy settings
              Get.snackbar(
                'Coming Soon',
                'Privacy settings will be available soon!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),

          _buildSettingsOption(
            context,
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "Get help and contact support",
            onTap: () {
              // TODO: Implement help section
              Get.snackbar(
                'Help',
                'For support, please contact us at support@example.com',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),

          _buildSettingsOption(
            context,
            icon: Icons.info_outline,
            title: "About",
            subtitle: "App version and information",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Let's Chat",
                applicationVersion: "1.0.0",
                applicationIcon: Icon(
                  Icons.chat,
                  size: 48,
                  color: colorScheme.primary,
                ),
                children: [
                  const Text("A modern chat application built with Flutter."),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Logout Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [colorScheme.error, colorScheme.error.withOpacity(0.8)],
              ),
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onUserLoggedOut();
                            },
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: Obx(() {
            if (isLoggedIn.value) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primary.withAlpha(40),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Let's Chat",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                icon: const Icon(Icons.refresh),
                onPressed: homeController.refreshUsers,
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
          () => Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex.value,
              onTap: _onItemTapped,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
              backgroundColor: colorScheme.surface,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.message_outlined),
                      if (homeController.unreadCount.value > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              homeController.unreadCount.value > 9
                                  ? '9+'
                                  : homeController.unreadCount.value.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: const Icon(Icons.message),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
