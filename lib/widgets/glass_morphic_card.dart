import 'package:flutter/material.dart';
import 'dart:ui';

class GlassMorphCard extends StatelessWidget {
  final Widget child;
  final double blurIntensity;
  final Color color;
  final BorderRadiusGeometry borderRadius;

  const GlassMorphCard({
    Key? key,
    required this.child,
    this.blurIntensity = 20.0,
    this.color = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}