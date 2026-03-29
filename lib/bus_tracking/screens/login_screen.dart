import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'driver_screen.dart';
import 'student_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '9497753716');
  final TextEditingController _otpController = TextEditingController();
  
  String? _verificationId;
  bool _isLoading = false;
  bool _otpSent = false;

  // Format phone number strictly to E.164 Indian format
  String _formatPhoneNumber(String phone) {
    phone = phone.trim();
    phone = phone.replaceAll(RegExp(r'[\s\-]'), ''); // Remove spaces and dashes

    if (phone.startsWith('+91')) {
      return phone;
    }

    if (phone.startsWith('0')) {
      phone = phone.substring(1); // Remove leading zero
    }

    return '+91$phone'; // Ensure +91 prefix
  }

  Future<void> _verifyPhone() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) return;

    final formattedPhone = _formatPhoneNumber(rawPhone);

    // Validation: ensure exactly 10 digits strictly after the +91 prefix
    final digitsOnly = formattedPhone.replaceFirst('+91', '');
    if (digitsOnly.length != 10 || int.tryParse(digitsOnly) == null) {
      _showError('Invalid phone number. Must be exactly 10 digits.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null || _otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Invalid OTP');
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Login failed: ${e.toString()}');
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        String newRole = 'student';
        final formattedPhone = _formatPhoneNumber(_phoneController.text);
        if (formattedPhone == '+919497753716') {
          newRole = 'driver';
        }
        // Auto-create a default user to prevent "Access denied"
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'role': newRole,
          'bus_id': 'bus1',
          'phone': formattedPhone,
        });
        userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      }
      String role = userDoc['role'];
      setState(() => _isLoading = false);
      if (role == 'admin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminScreen()));
      } else if (role == 'driver') {
        String busId = userDoc['bus_id'];
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DriverScreen(busId: busId)));
      } else if (role == 'student') {
        String busId = userDoc['bus_id'];
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StudentScreen(busId: busId)));
      } else {
        _showError('Unknown role');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error fetching profile: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E6FF2), Color(0xFF00B4DB)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_bus_filled_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to track your bus or manage trips',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    if (!_otpSent) ...[
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g. 9876543210',
                          prefixIcon: const Icon(Icons.phone_rounded),
                          prefixText: '+91 ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _verifyPhone,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Send Verification Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                    ] else ...[
                      TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                       _isLoading
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _verifyOTP,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Verify & Secure Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _otpSent = false;
                                      _verificationId = null;
                                      _otpController.clear();
                                    });
                                  },
                                  child: const Text('OTP Expired? Request new code'),
                                )
                              ],
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
