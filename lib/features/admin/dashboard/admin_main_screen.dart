import 'package:flutter/material.dart';
import 'package:track_my_bus/core/constants/app_colors.dart';
import 'package:track_my_bus/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:track_my_bus/features/admin/students/admin_students_screen.dart';
import 'package:track_my_bus/features/admin/drivers/admin_drivers_screen.dart';
import 'package:track_my_bus/features/admin/fees/admin_fees_screen.dart';
import 'package:track_my_bus/features/admin/settings/admin_settings_screen.dart';
import 'package:track_my_bus/features/admin/payments/admin_payments_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminMapScreen(),
    const AdminEmergenciesScreen(),
    const AdminRoutesScreen(),
    const AdminPaymentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'SOS'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Fees'),
        ],
      ),
    );
  }
}
