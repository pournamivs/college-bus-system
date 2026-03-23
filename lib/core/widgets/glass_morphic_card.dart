import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassMorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;

  const GlassMorphicCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.borderRadius = 24,
    this.padding,
    this.width,
    this.height,
    this.margin,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color ?? AppColors.glassBase.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
