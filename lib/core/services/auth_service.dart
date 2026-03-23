import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('token', data['access_token']);
        await prefs.setString('role', data['user']['role']);
        await prefs.setString('name', data['user']['name']);
        
        return data;
      }
    } catch (e) {
      print("AuthService Login Error: $e");
    }
    return null;
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
}
