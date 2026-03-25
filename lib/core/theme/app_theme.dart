import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6A1B9A); // Purple
  static const Color secondaryColor = Color(0xFFAB47BC); // Light Purple
  static const Color backgroundColor = Color(0xFFF3E5F5); // Light Background
  static const Color textColor = Color(0xFF212121); // Dark Text
  static const Color accentColor = Color(0xFFD5006D); // Pink Accent

  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textColor,
  );

  // Button Theme
  static ButtonStyle buttonStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Card Theme
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}