import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:track_my_bus/core/constants/app_colors.dart';
import 'package:track_my_bus/core/services/auth_service.dart';
import 'package:track_my_bus/core/widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final role = await _authService.getRole();
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn || role == null || role.isEmpty) {
      context.go('/login');
      return;
    }

    switch (role.toLowerCase()) {
      case 'admin':
        context.go('/admin');
        break;
      case 'driver':
        context.go('/driver');
        break;
      case 'staff':
        context.go('/staff');
        break;
      case 'parent':
        context.go('/parent');
        break;
      default:
        context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 120),
            const SizedBox(height: 24),
            const Text(
              'TrackMyBus',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sree Narayana Gurukulam College of Engineering',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
