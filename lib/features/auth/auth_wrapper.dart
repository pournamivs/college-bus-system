import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    // Wait briefly for Firebase to completely initialize internal streams
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[AUTH WRAPPER] No active user session. Routing to /login');
      if (mounted) context.go('/login');
      return;
    }

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        debugPrint('[AUTH WRAPPER] User document missing in Firestore. Booting out.');
        await _auth.signOut();
        if (mounted) context.go('/login');
        return;
      }

      final role = (userDoc.data()?['role'] ?? 'unassigned').toString().toLowerCase();
      debugPrint('[AUTH WRAPPER] Valid User Authenticated. Role Detected: $role -> Executing V4 Isolation Route.');

      if (!mounted) return;

      switch (role) {
        case 'admin':
          context.go('/admin');
          break;
        case 'driver':
          context.go('/driver');
          break;
        case 'staff':
          context.go('/staff');
          break;
        case 'student':
        default:
          context.go('/student');
          break;
      }
    } catch (e) {
      debugPrint('[AUTH WRAPPER] Error fetching user role: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 140),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Authenticating Environment...',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
