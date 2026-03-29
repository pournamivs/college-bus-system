import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Future<Map<String, dynamic>?> login(String email, String password, {String selectedRole = 'student'}) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final userData = await _firestore.getUser(credential.user!.uid);
        Map<String, dynamic> data;
        if (userData.exists) {
          data = userData.data() as Map<String, dynamic>;
        } else {
          // Auto-create default user document
          data = {
            'uid': credential.user!.uid,
            'email': credential.user!.email ?? email.trim(),
            'name': (credential.user!.email ?? email.trim()).split('@')[0],
            'role': selectedRole.toLowerCase(),
            'busId': 'bus1',
            'driverId': '',
            'total_fee': 50000,
            'paid_amount': 0,
            'pending_amount': 50000,
            'penalty': 0,
            'parent_name': 'Parent Name',
            'parent_phone': '0000000000',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set(data);
        }
        await _storeSession(credential.user!.uid, data);
        debugPrint('✅ Role Authenticated: ${data['role']} for UID: ${credential.user!.uid}');
        return {
          'user': data,
          'uid': credential.user!.uid,
        };
      }
      throw Exception('Authentication failed.');
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred during login.";
      if (e.code == 'user-not-found') message = "No user found with this email.";
      else if (e.code == 'wrong-password') message = "Incorrect password.";
      else if (e.code == 'invalid-email') message = "Invalid email format.";
      else if (e.code == 'user-disabled') message = "Your account has been disabled.";
      throw Exception(message);
    } catch (e) {
      debugPrint('AuthService login failed: $e');
      throw Exception('Connection failed. Please check your network.');
    }
  }

  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? busId,
    String? routeId,
  }) async {
    try {
      debugPrint('[AUTH SERVICE] Initiating createUserWithEmailAndPassword for ${email.trim()}');
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        debugPrint('[AUTH SERVICE] Auth Success: ${credential.user!.uid}');
        final userData = {
          'uid': credential.user!.uid,
          'email': email,
          'name': name,
          'role': role,
          'busId': busId ?? '',
          'driverId': '',
          'routeId': routeId ?? '',
          'total_fee': 50000.0,
          'paid_amount': 0.0,
          'pending_amount': 50000.0,
          'penalty': 0.0,
          'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore.createUser(credential.user!.uid, userData);
        debugPrint('[AUTH SERVICE] Firestore User Document successfully mounted.');
        
        await _storeSession(credential.user!.uid, userData);
        return {'user': userData};
      }
      throw Exception('Registration failed at FirebaseAuth token return.');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH SERVICE] Firebase Auth Exception: ${e.code}');
      String message = "Registration failed.";
      if (e.code == 'email-already-in-use') message = "This email is already in use.";
      else if (e.code == 'weak-password') message = "The password provided is too weak.";
      else if (e.code == 'invalid-email') message = "Invalid email format.";
      throw Exception(message);
    } catch (e) {
      debugPrint('[AUTH SERVICE] Unexpected Register Error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _storeSession(String uid, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('role', (data['role'] ?? '').toString());
    await prefs.setString('name', (data['name'] ?? 'User').toString());
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      debugPrint('[AUTH SERVICE] Password updated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH SERVICE] Password change error: ${e.code}');
      String message = "Failed to change password.";
      if (e.code == 'wrong-password') message = "Current password is incorrect.";
      else if (e.code == 'weak-password') message = "New password is too weak.";
      else if (e.code == 'requires-recent-login') message = "Please log in again before changing password.";
      throw Exception(message);
    } catch (e) {
      debugPrint('[AUTH SERVICE] Unexpected password change error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}
