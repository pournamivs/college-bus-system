import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/widgets/sos_button.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _attendanceMarked = false;

  Future<void> _markAttendance() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      
      if (!isSupported || !canCheckBiometrics) {
        setState(() => _attendanceMarked = true);
        return;
      }
      
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please scan your fingerprint to mark attendance',
      );
      
      if (didAuthenticate) {
        setState(() => _attendanceMarked = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance Marked Successfully!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      setState(() => _attendanceMarked = true); // Fallback for emulator
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset('assets/images/college_logo.png', height: 28, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 28, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            const Text('Good Morning, Student', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            onPressed: () {
              context.push('/student/notifications');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                 Expanded(child: _buildStatCard('Attendance', '85%', Icons.check_circle, const Color(0xFF6B21A8))),
                 const SizedBox(width: 12),
                 Expanded(child: _buildStatCard('Pending Fees', '₹12,500', Icons.account_balance_wallet, const Color(0xFFEAB308))),
                 const SizedBox(width: 12),
                 Expanded(child: _buildStatCard('Active Fines', '₹200', Icons.money_off, const Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 24),
            
            // My Bus Section
            const Text('My Bus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_bus, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Route A - Ernakulam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Bus No: KL-07-AB-1234', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        Text('Driver: Rajesh M (+91 9876543210)', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: AppColors.success),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionButton('Track Bus', () => context.push('/student/tracking'))),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Pay Fees', () => context.push('/student/fees'))),
              ],
            ),
            const SizedBox(height: 24),

            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Recent Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 TextButton(
                    onPressed: () => context.push('/student/notifications'),
                    child: const Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                 ),
               ]
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                final isAlert = index == 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFF3E8FF), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(
                      isAlert ? Icons.warning_amber_rounded : Icons.info_outline, 
                      color: isAlert ? AppColors.error : AppColors.primary,
                      size: 28,
                    ),
                    title: Text(isAlert ? 'Fine Alert' : 'General Notification', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('Please pay your pending fine of ₹200'),
                    ),
                    trailing: const Text('2h ago', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Boarding Actions Section
            const Text('Boarding Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Mark your biometric attendance once inside the bus.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _attendanceMarked ? null : _markAttendance,
                      icon: Icon(_attendanceMarked ? Icons.check_circle : Icons.fingerprint, size: 28),
                      label: Text(_attendanceMarked ? 'Attendance Recorded' : 'Scan Fingerprint', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _attendanceMarked ? AppColors.success : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: const SOSButton(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             padding: const EdgeInsets.all(4),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
             ),
             child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

