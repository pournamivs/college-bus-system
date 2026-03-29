import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_button.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  State<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isProcessing = false;

  Future<void> _simulateBiometricVerify() async {
    setState(() => _isProcessing = true);
    
    // Simulate hardware delay
    await Future.delayed(const Duration(seconds: 2));
    
    final uid = await _authService.getUid();
    if (uid != null) {
      await _firestoreService.writeBiometricAttendance(uid, 'present');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric Verified: Marked Present'), backgroundColor: AppColors.success),
        );
      }
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 100, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'External Scanner Simulation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Clicking below simulates a hardware payload sending an instant \'present\' attendance record to Firestore via the Biometric endpoint.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                AppButton(
                  text: 'Simulate Fingerprint Scan',
                  onPressed: _simulateBiometricVerify,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
