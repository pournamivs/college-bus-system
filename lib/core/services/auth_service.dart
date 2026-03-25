import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const Map<String, Map<String, String>> _demoAccounts = {
    'admin': {'password': 'Admin@2026', 'role': 'admin', 'name': 'Admin'},
    'driver1': {'password': 'driver123', 'role': 'driver', 'name': 'Driver 1'},
    'student1': {'password': 'pass123', 'role': 'student', 'name': 'Student 1'},
    'staff1': {'password': 'staff123', 'role': 'staff', 'name': 'Staff 1'},
    'parent1': {'password': 'parent123', 'role': 'parent', 'name': 'Parent 1'},
  };

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final username = email.trim();
    final baseUrl = ApiConstants.apiBaseUrl;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': username,
              'password': password,
            }),
          )
            .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storeSession(data);
        return data;
      }
    } catch (e) {
      debugPrint('AuthService login failed: $e');
    }

    return {
      'error': 'Cannot connect to server. Please check your internet connection.',
    };
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = (data['user'] as Map<String, dynamic>? ?? {});
    await prefs.setString('token', (data['access_token'] ?? '').toString());
    await prefs.setString('role', (user['role'] ?? '').toString());
    await prefs.setString(
      'name',
      (user['name'] ?? user['username'] ?? 'User').toString(),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
