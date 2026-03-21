import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _role = 'Student';
  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1)); // Simulate API

    if (!mounted) return;

    if (_role == 'Student' && _usernameController.text == 'student1' && _passwordController.text == 'pass123') {
      context.go('/student');
    } else if (_role == 'Admin' && _usernameController.text == 'admin' && _passwordController.text == 'Admin@2026') {
      context.go('/admin');
    } else if (_role == 'Driver' && _usernameController.text == 'driver1' && _passwordController.text == 'driver123') {
      context.go('/driver');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid credentials for $_role';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo Placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(Icons.directions_bus, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sree Narayana Gurukulam College of Engineering',
                style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              Card(
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text('Welcome Back', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.primaryDark)),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _usernameController,
                        label: 'Username',
                        prefixIcon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: AppColors.textSecondary),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: ['Student', 'Admin', 'Driver']
                            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                            .toList(),
                        onChanged: (value) => setState(() => _role = value!),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Login',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Demo: student1/pass123 | admin/Admin@2026\nDriver: driver1/driver123',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
