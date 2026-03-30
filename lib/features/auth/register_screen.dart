import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_gradient_button.dart';
import '../../core/widgets/glass_morphic_card.dart';
import '../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // Changed from username to email
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  String _role = 'Student';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final email = _emailController.text.trim();
    final pwd = _passwordController.text;
    final name = _nameController.text.trim();

    if (name.isEmpty || email.isEmpty || pwd.isEmpty) {
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email format.');
      return;
    }

    if (pwd.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[REGISTER UI] Attempting registration for $email as $_role');
      final res = await _authService.register(
        email: email,
        password: pwd,
        name: name,
        role: _role.toLowerCase(),
      );

      if (res != null) {
        if (res['error'] != null) {
           setState(() => _errorMessage = res['error']);
        } else {
           if (!mounted) return;
           
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Registration Successful!'), backgroundColor: AppColors.success),
           );
           
           context.go('/${_role.toLowerCase()}');
        }
      }
    } catch (e) {
      debugPrint('[REGISTER UI] Auth Error: $e');
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF4C1D95)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassMorphicCard(
                  borderRadius: 20,
                  child: Column(
                    children: [
                      _field(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 14),
                      _field(_emailController, 'Email Address', Icons.alternate_email),
                      const SizedBox(height: 14),
                      _field(
                        _passwordController,
                        'Password',
                        Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const ['Student', 'Parent', 'Staff', 'Driver', 'Admin']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (value) => setState(() => _role = value ?? 'Student'),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 24),
                      CustomGradientButton(
                        text: 'CREATE ACCOUNT',
                        isLoading: _isLoading,
                        onPressed: _register,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
