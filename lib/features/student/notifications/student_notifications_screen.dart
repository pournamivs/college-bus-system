import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          Color iconColor = AppColors.primary;
          IconData icon = Icons.notifications;
          String type = 'General';
          
          if (index == 0) {
            iconColor = AppColors.error;
            icon = Icons.warning;
            type = 'Fine Alert';
          } else if (index == 1) {
            iconColor = AppColors.warning;
            icon = Icons.account_balance_wallet;
            type = 'Fee Reminder';
          }
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor),
              ),
              title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text('This is a notification body explaining the details of the alert.'),
              ),
              trailing: const Text('2h ago', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
