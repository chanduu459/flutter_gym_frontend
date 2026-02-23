import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth_container_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/members_screen.dart';
import 'screens/menu_screens.dart';
import 'screens/plans_screen.dart';
import 'screens/subscriptions_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymSaaS Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthContainerScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/auth': (context) => const AuthContainerScreen(),
        '/members': (context) => const MembersScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/plans': (context) => const PlansScreen(),
        '/subscriptions': (context) => const SubscriptionsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
