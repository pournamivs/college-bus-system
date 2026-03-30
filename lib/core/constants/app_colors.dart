import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Purple Gradient
  static const Color primary = Color(0xFF6A1B9A);
  static const Color primaryDark = Color(0xFF4A148C);
  static const Color primaryLight = Color(0xFF8E24AA);
  static const Color secondary = Color(0xFF8E24AA);
  
  // Neutral/Background
  static const Color background = Color(0xFFF8F9FA); // White/light grey background
  static const Color surface = Colors.white; // Light grey / White cards
  static const Color accent = Color(0xFF8E24AA);

  // Glassmorphism Base (White with low opacity)
  static const Color glassBase = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textLight = Color(0xFF9AA0A6);
  
  // Status
  static const Color success = Color(0xFF34A853); // Green (active trip/success)
  static const Color error = Color(0xFFEA4335); // Red (emergency/alerts)
  static const Color warning = Color(0xFFFBBC04); // Yellow/Orange (fines/pending)
  static const Color info = Color(0xFF4285F4);
  
  // Others
  static const Color divider = Color(0xFFE8EAED);
}
