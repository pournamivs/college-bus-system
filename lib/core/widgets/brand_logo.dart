import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showBackground;

  const BrandLogo({
    super.key,
    this.size = 96,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        Icons.location_on_rounded,
        size: size * 0.86,
        color: Colors.white,
      ),
    );

    final bus = Positioned(
      bottom: size * 0.17,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.12,
          vertical: size * 0.04,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.directions_bus_rounded,
          color: AppColors.primary,
          size: size * 0.28,
        ),
      ),
    );

    final stack = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [icon, bus],
      ),
    );

    if (!showBackground) return stack;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Center(child: stack),
    );
  }
}
