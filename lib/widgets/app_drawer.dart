import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/drawer_viewmodel.dart';
import '../viewmodels/login_viewmodel.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerState = ref.watch(drawerViewModelProvider);
    final drawerViewModel = ref.read(drawerViewModelProvider.notifier);
    final loginState = ref.watch(loginViewModelProvider);

    // Update drawer with user data from login state
    if (loginState.userName != null && loginState.userRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        drawerViewModel.updateUserData(
          loginState.userName,
          loginState.userRole,
        );
      });
    }

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Logo and Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'GymSaaS Pro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => drawerViewModel.closeDrawer(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 20),
            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dashboard
                      _DrawerMenuItem(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        isSelected:
                            drawerState.selectedItem == MenuItem.dashboard,
                        onTap: () {
                          drawerViewModel.selectMenuItem(MenuItem.dashboard);
                          Navigator.of(context).pushReplacementNamed(
                            '/dashboard',
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Members
                      _DrawerMenuItem(
                        icon: Icons.people,
                        label: 'Members',
                        isSelected:
                            drawerState.selectedItem == MenuItem.members,
                        onTap: () {
                          drawerViewModel.selectMenuItem(MenuItem.members);
                          Navigator.of(context)
                              .pushReplacementNamed('/members');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Attendance
                      _DrawerMenuItem(
                        icon: Icons.person_add,
                        label: 'Attendance',
                        isSelected:
                            drawerState.selectedItem == MenuItem.attendance,
                        onTap: () {
                          drawerViewModel.selectMenuItem(MenuItem.attendance);
                          Navigator.of(context)
                              .pushReplacementNamed('/attendance');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Plans
                      _DrawerMenuItem(
                        icon: Icons.card_membership,
                        label: 'Plans',
                        isSelected:
                            drawerState.selectedItem == MenuItem.plans,
                        onTap: () {
                          drawerViewModel.selectMenuItem(MenuItem.plans);
                          Navigator.of(context).pushReplacementNamed('/plans');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Subscriptions
                      _DrawerMenuItem(
                        icon: Icons.subscriptions,
                        label: 'Subscriptions',
                        isSelected:
                            drawerState.selectedItem == MenuItem.subscriptions,
                        onTap: () {
                          drawerViewModel
                              .selectMenuItem(MenuItem.subscriptions);
                          Navigator.of(context)
                              .pushReplacementNamed('/subscriptions');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Notifications
                      _DrawerMenuItem(
                        icon: Icons.notifications,
                        label: 'Notifications',
                        isSelected:
                            drawerState.selectedItem == MenuItem.notifications,
                        onTap: () {
                          drawerViewModel
                              .selectMenuItem(MenuItem.notifications);
                          Navigator.of(context)
                              .pushReplacementNamed('/notifications');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Settings
                      _DrawerMenuItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        isSelected:
                            drawerState.selectedItem == MenuItem.settings,
                        onTap: () {
                          drawerViewModel.selectMenuItem(MenuItem.settings);
                          Navigator.of(context)
                              .pushReplacementNamed('/settings');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),

            // User Profile Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            drawerState.userName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // User Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drawerState.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drawerState.userRole,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.exit_to_app,
                          color: Colors.red, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        // Clear drawer state
                        drawerViewModel.logout();
                        // Clear login state
                        ref.read(loginViewModelProvider.notifier).logout();
                        // Navigate to auth screen
                        Navigator.of(context)
                            .pushReplacementNamed('/auth');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[200] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}


