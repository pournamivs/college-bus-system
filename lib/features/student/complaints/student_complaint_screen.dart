import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_button.dart';

class StudentComplaintScreen extends StatefulWidget {
  const StudentComplaintScreen({super.key});

  @override
  State<StudentComplaintScreen> createState() => _StudentComplaintScreenState();
}

class _StudentComplaintScreenState extends State<StudentComplaintScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _msgController = TextEditingController();
  
  String _issueType = 'Bus Issue';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_msgController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    
    try {
      final uid = await _authService.getUid();
      if (uid != null) {
        await _firestoreService.submitComplaint(
          userId: uid,
          role: 'student',
          type: _issueType,
          message: _msgController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint filed successfully'), backgroundColor: AppColors.success),
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
        title: const Text('Report an Issue'),
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
                DropdownMenuItem(value: 'Bus Issue', child: Text('Bus Issue')),
                DropdownMenuItem(value: 'Driver Issue', child: Text('Driver Issue')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
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
                hintText: 'Please detail your issue here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              AppButton(text: 'Submit Complaint', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
