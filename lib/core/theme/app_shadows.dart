import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const small = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const medium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];
}