import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_gradient_button.dart';
import '../../core/widgets/glass_morphic_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'Student';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                      _field(_usernameController, 'Username', Icons.alternate_email),
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
                          fillColor: Colors.white.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const ['Student', 'Parent', 'Staff', 'Driver']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (value) => setState(() => _role = value ?? 'Student'),
                      ),
                      const SizedBox(height: 24),
                      CustomGradientButton(
                        text: 'CREATE ACCOUNT',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registration endpoint to be connected by backend policy.'),
                            ),
                          );
                        },
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
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
