import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/glass_morphic_card.dart';
import '../../core/widgets/custom_gradient_button.dart';

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

  final AuthService _authService = AuthService();

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter both username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (data != null) {
        if (data['error'] != null) {
          setState(() => _errorMessage = data['error'].toString());
          return;
        }
        if (!mounted) return;
        
        final String role = data['user']['role'].toLowerCase();
        if (role == 'admin') context.go('/admin');
        else if (role == 'driver') context.go('/driver');
        else if (role == 'staff') context.go('/staff');
        else if (role == 'parent') context.go('/parent');
        else if (role == 'student') context.go('/student');
        else context.go('/student');
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials for $_role.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Check internet, backend, and BASE_URL.';
      });
      debugPrint("LOGIN ERROR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              Color(0xFF4C1D95), // Deeper Purple
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo Area
                const BrandLogo(size: 108),
                const SizedBox(height: 24),
                const Text(
                  'TrackMyBus',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                ),
                const Text(
                  'Manage Your Daily Commute',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                
                GlassMorphicCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username / Email',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 20),
                      _buildRoleDropdown(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                      const SizedBox(height: 32),
                      CustomGradientButton(
                        text: 'LOGIN',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildDemoCredentials(),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredentials() {
    return GlassMorphicCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Demo Logins (Click to use)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade900,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _demoItem('Admin', 'admin', 'Admin@2026', 'admin'),
          _demoItem('Driver', 'driver1', 'driver123', 'driver'),
          _demoItem('Student', 'student1', 'pass123', 'student'),
          _demoItem('Staff', 'staff1', 'staff123', 'staff'),
          _demoItem('Parent', 'parent1', 'parent123', 'parent'),
        ],
      ),
    );
  }

  Widget _demoItem(String title, String user, String pass, String role) {
    return InkWell(
      onTap: () {
        setState(() {
          _usernameController.text = user;
          _passwordController.text = pass;
          _role = title;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
            Text('$user / $pass', style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
              onPressed: onTogglePassword,
            )
          : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _role,
          decoration: const InputDecoration(border: InputBorder.none),
          items: ['Student', 'Admin', 'Driver', 'Staff', 'Parent']
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (value) => setState(() => _role = value!),
        ),
      ),
    );
  }
}
