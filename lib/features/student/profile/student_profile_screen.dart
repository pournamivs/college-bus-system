import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alex Johnson',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Adm No: SNGCE/2023/1042',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Expandable Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildExpansionTile(
                    title: 'Academic Info',
                    icon: Icons.school_rounded,
                    children: [
                      _buildInfoRow('Reg No', 'SNG19CS012'),
                      _buildInfoRow('Department', 'Computer Science'),
                      _buildInfoRow('Batch', '2023-2027'),
                      _buildInfoRow('Semester', 'S4'),
                      _buildInfoRow('Academic Year', '2024-2025'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExpansionTile(
                    title: 'Personal Info',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildInfoRow('Gender', 'Male'),
                      _buildInfoRow('DOB', '15 Aug 2002'),
                      _buildInfoRow('Blood Group', 'O+ve'),
                      _buildInfoRow('Phone', '+91 9876543210'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExpansionTile(
                    title: 'Transport Info',
                    icon: Icons.directions_bus_rounded,
                    children: [
                      _buildInfoRow('Route', 'Route A - Ernakulam'),
                      _buildInfoRow('Bus Number', 'KL-01-AB-1234'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExpansionTile(
                    title: 'Bank Details',
                    icon: Icons.account_balance_rounded,
                    children: [
                      _buildInfoRow('Bank Name', 'State Bank of India'),
                      _buildInfoRow('Branch', 'Kolenchery'),
                      _buildInfoRow('Account Number', '**** **** 1234'),
                      _buildInfoRow('IFSC Code', 'SBIN0001234'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Options
                  CustomCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                          ),
                          title: const Text('View Attendance Record', style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {}, // Handled by StudentDashboard or internal router
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.lock_rounded, color: AppColors.primary),
                          ),
                          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile({required String title, required IconData icon, required List<Widget> children}) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
