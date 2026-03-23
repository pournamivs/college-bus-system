import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/theme.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final accessToken = data['access_token'];
        await prefs.setString('token', accessToken);
        await prefs.setString('role', data['user']['role']);
        await prefs.setString('name', data['user']['name']);
        await prefs.setString('assigned_stop', data['user']['assigned_stop'] ?? '');

        // FCM Logic
        try {
          final messaging = FirebaseMessaging.instance;
          await messaging.requestPermission();
          final fcmToken = await messaging.getToken();
          if (fcmToken != null) {
            await http.post(
              Uri.parse('${AppConstants.apiBaseUrl}/api/auth/fcm-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode({'fcm_token': fcmToken}),
            );
          }
        } catch (e) {
          debugPrint('FCM Setup Error: $e');
        }

        if (data['user']['role'] == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver');
        } else if (data['user']['role'] == 'student') {
          Navigator.pushReplacementNamed(context, '/student');
        } else if (data['user']['role'] == 'staff') {
          Navigator.pushReplacementNamed(context, '/staff');
        } else if (data['user']['role'] == 'parent') {
          Navigator.pushReplacementNamed(context, '/parent');
        } else if (data['user']['role'] == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unknown Role: ${data['user']['role']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: Invalid credentials')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: Make sure API is running.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: Icon(Icons.directions_bus, size: 80, color: Colors.indigo),
              ),
              SizedBox(height: 24),
              Text('TrackMyBus', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.indigo.shade900)),
              Text('Native Mobile Portal', style: TextStyle(fontSize: 16, color: Colors.indigo.shade400)),
              SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.indigo),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.indigo),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  child: _isLoading 
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
