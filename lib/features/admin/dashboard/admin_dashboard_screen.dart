import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/app_button.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/college_logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StatCard(label: 'Total Students', value: '1,240', icon: Icons.school, backgroundColor: AppColors.primary),
                  StatCard(label: 'Total Buses', value: '15', icon: Icons.directions_bus, backgroundColor: AppColors.success),
                  StatCard(label: 'Pending Fees', value: '₹4.5L', icon: Icons.account_balance_wallet, backgroundColor: AppColors.warning),
                  StatCard(label: 'Active Fines', value: '₹12K', icon: Icons.money_off, backgroundColor: AppColors.error),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(text: 'Add Student', onPressed: () {}),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(text: 'Add Driver', onPressed: () {}),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(text: 'View Reports', onPressed: () {}),
            
            const SizedBox(height: 24),
            SectionHeader(title: 'Recent Activity', onSeeAll: () {}),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.history, color: AppColors.primary),
                    ),
                    title: Text(index % 2 == 0 ? 'Fee Payment Received' : 'Maintenance Logged'),
                    subtitle: Text(index % 2 == 0 ? 'Student Rahul paid ₹12,500' : 'Bus KL-07-AB-1234 sent for oil change'),
                    trailing: const Text('2h ago', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

