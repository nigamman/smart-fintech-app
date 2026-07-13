import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standard shadows used across the application.
/// Keep shadows subtle to maintain a premium look.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1F000000), // 12% black
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}