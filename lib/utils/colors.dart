import 'package:flutter/material.dart';

class AppColor {
  // Light mode colors
  static const Color primary = Color(0xFF0066FF); // Bright blue
  static const Color secondary = Color(0xFF708090); // Slate gray
  static const Color tertiary = Color(0xFF00F0FF); // ✅ FIXED: CYAN (was 0xFF00FF0F which is GREEN)
  static const Color neutral = Color(0xFF0F172A); // Dark navy
  static const Color background = Color(0xFFFDFDFD); // Off white
  static const Color warning = Color(0xFFF4A261); // Orange
  static const Color error = Color(0xFFE76F51); // Red
  static const Color success = Color(0xFF2A9D8F); // Green

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkBorder = Color(0xFF3D3D3D);
}