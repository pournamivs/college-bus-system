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

    for (final baseUrl in ApiConstants.candidateApiBaseUrls) {
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
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          ApiConstants.setApiBaseUrl(baseUrl);
          await _storeSession(data);
          return data;
        }
      } catch (e) {
        debugPrint('AuthService login attempt failed for $baseUrl: $e');
      }
    }

    // Fallback to demo accounts for local testing if remote auth is unavailable.
    if (_demoAccounts.containsKey(username.toLowerCase())) {
      final demo = _demoAccounts[username.toLowerCase()];
      if (demo != null && demo['password'] == password) {
        final data = {
          'access_token': 'demo_token_${username.toLowerCase()}',
          'user': {
            'username': username,
            'role': demo['role'],
            'name': demo['name'],
          },
        };
        await _storeSession(data);
        return data;
      }
    }

    return {
      'error':
          'Cannot login. Check backend is running and reachable on your network.',
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
