import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _stopController = TextEditingController();
  String _selectedRole = 'student';
  bool _isLoading = false;

  final List<String> _roles = ['student', 'driver', 'staff', 'parent', 'admin'];

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole,
          'assigned_stop': _selectedRole == 'student' ? _stopController.text : null,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Successful! Please login.')));
        Navigator.pop(context);
      } else {
        final body = jsonDecode(response.body);
        final error = body['detail'] ?? 'Error ${response.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $error'), duration: Duration(seconds: 5)));
      }
    } catch (e) {
      debugPrint("REGISTRATION ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Connection Error: $e\nCheck your IP: ${AppConstants.apiBaseUrl}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 8),
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account'), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join TrackMyBus', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
            SizedBox(height: 8),
            Text('Experience smart college transport tracking', style: TextStyle(color: Colors.grey.shade600)),
            SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Register As',
                prefixIcon: Icon(Icons.app_registration),
              ),
              items: _roles.map((role) => DropdownMenuItem(
                value: role,
                child: Text(role.toUpperCase()),
              )).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            if (_selectedRole == 'student') ...[
              SizedBox(height: 16),
              TextField(
                controller: _stopController,
                decoration: InputDecoration(
                  labelText: 'Assigned Bus Stop (Optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'e.g. Library, Main Gate',
                ),
              ),
            ],
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('CREATE ACCOUNT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
