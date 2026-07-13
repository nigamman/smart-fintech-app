import 'package:flutter/material.dart';

/// Centralized color palette for the entire application.
/// Never use Colors.red, Colors.green, etc. directly in widgets.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF111827);
  static const Color accent = Color(0xFF4F46E5);

  // Backgrounds
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE5E7EB);

  // Status
  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // Text
  static const Color primaryText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color disabledText = Color(0xFF9CA3AF);

  // Others
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}