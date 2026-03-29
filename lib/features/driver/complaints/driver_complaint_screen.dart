import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_button.dart';

class DriverComplaintScreen extends StatefulWidget {
  const DriverComplaintScreen({super.key});

  @override
  State<DriverComplaintScreen> createState() => _DriverComplaintScreenState();
}

class _DriverComplaintScreenState extends State<DriverComplaintScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _msgController = TextEditingController();
  
  String _issueType = 'Vehicle Issue';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_msgController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    
    try {
      final uid = await _authService.getUid();
      if (uid != null) {
        await _firestoreService.submitComplaint(
          userId: uid,
          role: 'driver',
          type: _issueType,
          message: _msgController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report filed successfully'), backgroundColor: AppColors.success),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance & Alerts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Issue Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _issueType,
              items: const [
                DropdownMenuItem(value: 'Vehicle Issue', child: Text('Vehicle Issue')),
                DropdownMenuItem(value: 'Route Delay', child: Text('Route Delay')),
                DropdownMenuItem(value: 'Conflict', child: Text('Conflict')),
                DropdownMenuItem(value: 'Fuel', child: Text('Fuel Level Low')),
              ],
              onChanged: (val) => setState(() => _issueType = val!),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _msgController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Provide specifics (e.g. Engine light on, Road block building up...)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              AppButton(text: 'Submit Report', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
