import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_morphic_card.dart';

class AdminStudentBulkUploadScreen extends StatefulWidget {
  const AdminStudentBulkUploadScreen({super.key});

  @override
  State<AdminStudentBulkUploadScreen> createState() => _AdminStudentBulkUploadScreenState();
}

class _AdminStudentBulkUploadScreenState extends State<AdminStudentBulkUploadScreen> {
  final TextEditingController _csvController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = '';

  Future<void> _processWebUpload() async {
    if (_csvController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Parsing CSV Data...';
    });

    final lines = _csvController.text.trim().split('\n');
    int successCount = 0;
    int errorCount = 0;
    
    // We instantiate a secondary Firebase Auth instance so the Admin doesn't get logged out!
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'BulkUploadTempApp',
        options: Firebase.app().options,
      );
      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final FirebaseFirestore db = FirebaseFirestore.instance;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line.toLowerCase().startsWith('name')) continue;

        final parts = line.split(',');
        if (parts.length < 4) {
          errorCount++;
          continue;
        }

        final String name = parts[0].trim();
        final String email = parts[1].trim();
        final String busId = parts[2].trim();
        final double fee = double.tryParse(parts[3].trim()) ?? 0.0;
        final String password = "password123"; // Default password

        setState(() => _statusMessage = 'Creating user: $email...');

        try {
          // Check if already exists in Firestore (to prevent overriding)
          final existing = await db.collection('users').where('email', isEqualTo: email).get();
          if (existing.docs.isNotEmpty) {
            errorCount++;
            continue;
          }

          // Create Auth Profile securely
          final credential = await tempAuth.createUserWithEmailAndPassword(
            email: email, 
            password: password,
          );

          if (credential.user != null) {
            final uid = credential.user!.uid;
            await db.collection('users').doc(uid).set({
              'uid': uid,
              'name': name,
              'email': email,
              'role': 'student',
              'busId': busId,
              'total_fee': fee,
              'paid_amount': 0.0,
              'pending_amount': fee,
              'penalty': 0.0,
              'parent_name': 'Unknown',
              'parent_phone': '0000000000',
              'createdAt': FieldValue.serverTimestamp(),
            });
            successCount++;
          }
        } catch (e) {
          debugPrint('Failed bulk upload for $email: $e');
          errorCount++;
        }
      }
    } catch (e) {
      debugPrint('Secondary Firebase init failed: $e');
      setState(() => _statusMessage = 'Failed to initialize Auth proxy: $e');
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Upload Complete!\nSuccess: $successCount\nFailures/Duplicates: $errorCount';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mass Insertion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassMorphicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Paste CSV data in the following format:\nName,Email,BusId,Fee\nExample:\nJohn Doe,john@test.com,bus1,45000'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _csvController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Paste CSV here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isProcessing) 
                    const Center(child: CircularProgressIndicator())
                  else
                    AppButton(
                      text: 'Process Bulk Upload',
                      onPressed: _processWebUpload,
                    ),
                ],
              ),
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              GlassMorphicCard(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    _statusMessage, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
