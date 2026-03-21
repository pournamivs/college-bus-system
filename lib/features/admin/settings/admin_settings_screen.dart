import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: const Text('Change Admin Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.route, color: AppColors.primary),
            title: const Text('Manage Routes & Stops'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: AppColors.primary),
            title: const Text('Manage Vehicles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: AppColors.primary),
            title: const Text('Manage Attendance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info, color: AppColors.primary),
            title: Text('App Info'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
